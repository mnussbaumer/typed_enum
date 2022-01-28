defmodule TypedEnum do
  @moduledoc """
  A module to allow you to use Enum's in ecto schemas, while automatically deriving
  their type definition.

  Usage:

  ```elixir
  defmodule InvoiceStatus do
    use TypedEnum, values: [:paid, :open, :closed, :rejected, :processing]
  end
  ```

  And then in your schema(s):

  ```elixir
  defmodule Invoice do
    schema("invoices") do
       belongs_to :user, User
       field :status, InvoiceStatus, default: :open
    end
  end
  ```

  In this case the values will be dumped at the Database layer into strings.

  ```
  table invoices:
  user_id references -> users
  status -> string/varchar/text/etc
  ```

  In case you want to use it as a proper integer enum, make the `:values` option be
  a keyword list with the key the atom and value the integer to which it corresponds:

  ```elixir
  defmodule InvoiceStatus do
    use TypedEnum, values: [processing: 0, open: 1, paid: 2, closed: 3, rejected: 4]
  end
  ```

  The usage is the same, but in this case the column value will be serialized to its
  integer representation instead of a string. You can still cast string values, and
  in your app logic deal with their atom versions.

  Check the test cases to see examples.
  """

  defmacro __before_compile__(_env) do
    # these are inserted in the before_compile hook to give opportunity to the
    # implementing module to define additional variations
    quote do
      def cast(_), do: :error
      def dump(_), do: :error
      defp get_term(data), do: data
    end
  end

  defmacro __using__(opts) do
    values = Keyword.fetch!(opts, :values)
    mod = __CALLER__.module

    is_int_enum? = Keyword.keyword?(values)

    case is_int_enum? do
      true ->
        :ok = validate_int_enum(values)
        bind_as_integer_version(values, mod)

      false ->
        :ok = validate_string_enum(values)
        bind_as_stringed_version(values, mod)
    end
  end

  defp validate_int_enum(values) do
    with {_, true} <- {:length, length(values) > 0},
         {_, true} <- {:format, Enum.all?(values, &valid_int_enum?/1)} do
      :ok
    else
      error -> raise_error(error)
    end
  end

  defp validate_string_enum(values) do
    with {_, true} <- {:length, length(values) > 0},
         {_, true} <- {:format, Enum.all?(values, &is_atom/1)} do
      :ok
    else
      error -> raise_error(error)
    end
  end

  defp valid_int_enum?({k, v}),
    do: is_atom(k) and is_integer(v)

  defp raise_error({:length, _}),
    do: raise("TypedEnum expects `:values` to be a list or keyword list with at least 1 element")

  defp raise_error({:format, _}),
    do:
      raise(
        "TypedEnum expects the format of `:values` to be a keywordlist with the atom version as the key and an integer as the value (e.g.: [atom_key: 1, another_possible: 2, ...]), or a list of atoms for the string enum version (e.g.: [:atom_key, :another_possible, ...])"
      )

  defp bind_as_integer_version(values, mod) do
    quote bind_quoted: [atoms_ints: values, mod: mod] do
      @before_compile TypedEnum

      atom_integer_map =
        Enum.reduce(atoms_ints, %{}, fn {atom_val, int}, acc ->
          Map.put(acc, atom_val, int)
        end)

      string_integer_map =
        Enum.reduce(atom_integer_map, %{}, fn {atom_val, int}, acc ->
          Map.put(acc, Atom.to_string(atom_val), int)
        end)

      string_atom_map =
        Enum.reduce(atoms_ints, %{}, fn {atom_val, _}, acc ->
          Map.put(acc, Atom.to_string(atom_val), atom_val)
        end)

      integer_atom_map =
        Enum.reduce(atoms_ints, %{}, fn {atom_val, int}, acc ->
          Map.put(acc, int, atom_val)
        end)

      strings = Enum.map(atoms_ints, fn {atom_val, _} -> Atom.to_string(atom_val) end)
      atoms = Enum.map(atoms_ints, fn {atom_val, _} -> atom_val end)
      ints = Enum.map(atoms_ints, fn {_, int} -> int end)

      @behaviour Ecto.Type
      @impl Ecto.Type
      def type, do: :integer

      Module.put_attribute(mod, :valid_atoms, atoms)
      Module.put_attribute(mod, :valid_strings, strings)
      Module.put_attribute(mod, :valid_ints, ints)
      Module.put_attribute(mod, :validation_mappings, string_atom_map)
      Module.put_attribute(mod, :validation_mappings_atoms, atom_integer_map)
      Module.put_attribute(mod, :validation_mappings_strings, string_integer_map)
      Module.put_attribute(mod, :validation_mappings_ints, integer_atom_map)

      @type t() :: unquote(Enum.reduce(Enum.reverse(atoms), &{:|, [], [&1, &2]}))

      @spec values(:atoms | :strings | :ints) :: list(t()) | list(String.t()) | list(integer())
      @doc "Given a desired `format` returns the matching values for that `format`, where `format` can be `:ints | :atoms | :strings`"
      def values(type \\ :atoms)
      def values(:ints), do: unquote(ints)
      def values(:atoms), do: unquote(atoms)
      def values(:strings), do: unquote(strings)

      @impl Ecto.Type
      def load(data), do: cast(data)

      @impl Ecto.Type
      @doc false
      def cast(data) when is_atom(data) and data in unquote(atoms),
        do: {:ok, data}

      def cast(data) when is_binary(data) and data in unquote(strings),
        do: {:ok, @validation_mappings[data]}

      def cast(data) when is_integer(data) and data in unquote(ints),
        do: {:ok, @validation_mappings_ints[data]}

      @impl Ecto.Type
      @doc false
      def dump(data) when is_atom(data) and data in unquote(atoms),
        do: {:ok, @validation_mappings_atoms[data]}

      def dump(data) when is_binary(data) and data in unquote(strings),
        do: {:ok, @validation_mappings_strings[data]}

      def dump(data) when is_integer(data) and data in unquote(ints), do: {:ok, data}

      @doc "Dumps but raises in case of non-valid data"
      def dump!(data) do
        case dump(data) do
          {:ok, value} ->
            value

          _ ->
            raise Ecto.CastError,
              message: "Unable to dump:: #{inspect(data)} ::into:: #{inspect(unquote(mod))}",
              type: unquote(mod),
              value: data
        end
      end

      @impl Ecto.Type
      @doc false
      def embed_as(_), do: :dump

      @impl Ecto.Type
      @doc false
      def equal?(term_1, term_1), do: true
      def equal?(term_1, term_2), do: get_term(term_1) == get_term(term_2)

      defp get_term(data) when is_atom(data) and data in unquote(atoms),
        do: @validation_mappings_atoms[data]

      defp get_term(data) when is_binary(data) and data in unquote(strings),
        do: @validation_mappings_strings[data]

      defp get_term(data) when is_integer(data) and data in unquote(ints),
        do: data
    end
  end

  defp bind_as_stringed_version(values, mod) do
    quote bind_quoted: [atoms: values, mod: mod] do
      @before_compile TypedEnum

      strings = Enum.map(atoms, fn entry -> Atom.to_string(entry) end)
      mapped = Enum.zip(strings, atoms) |> Enum.into(%{})

      @behaviour Ecto.Type
      @impl Ecto.Type
      def type, do: :string

      Module.put_attribute(mod, :valid_atoms, atoms)
      Module.put_attribute(mod, :valid_strings, strings)
      Module.put_attribute(mod, :validation_mappings, mapped)

      @type t() :: unquote(Enum.reduce(Enum.reverse(atoms), &{:|, [], [&1, &2]}))

      @spec values(:atoms | :strings) :: list(t()) | list(String.t())
      @doc "Given a desired `format` returns the matching values for that `format`, where `format` can be `:atoms | :strings`"
      def values(type \\ :atoms)
      def values(:atoms), do: unquote(atoms)
      def values(:strings), do: unquote(strings)

      @impl Ecto.Type
      def load(data), do: cast(data)

      @impl Ecto.Type
      @doc false
      def cast(data) when is_atom(data) and data in unquote(atoms), do: {:ok, data}

      def cast(data) when is_binary(data) and data in unquote(strings),
        do: {:ok, String.to_atom(data)}

      @impl Ecto.Type
      @doc false
      def dump(data) when is_atom(data) and data in unquote(atoms),
        do: {:ok, Atom.to_string(data)}

      def dump(data) when is_binary(data) and data in unquote(strings),
        do: {:ok, data}

      @doc "Dumps but raises in case of non-valid data"
      def dump!(data) do
        case dump(data) do
          {:ok, value} ->
            value

          _ ->
            raise Ecto.CastError,
              message: "Unable to dump:: #{inspect(data)} ::into:: #{inspect(unquote(mod))}",
              type: unquote(mod),
              value: data
        end
      end

      @impl Ecto.Type
      @doc false
      def embed_as(_), do: :dump

      @impl Ecto.Type
      @doc false
      def equal?(term_1, term_1), do: true
      def equal?(term_1, term_2), do: get_term(term_1) == get_term(term_2)

      defp get_term(data) when is_atom(data) and data in unquote(atoms),
        do: data

      defp get_term(data) when is_binary(data) and data in unquote(strings),
        do: @validation_mappings[data]
    end
  end
end
