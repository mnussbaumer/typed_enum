defmodule TypedEnumTest.Clauses do
  use TypedEnum, values: [:val_1, :val_2, :val_3]

  @test_vals [:to_replace, "to_replace"]

  def cast(data) when data in @test_vals,
    do: {:ok, :val_1}

  defp get_term(data) when data in @test_vals,
    do: :val_1
end

defmodule TestSchemaClauses do
  use Ecto.Schema

  embedded_schema do
    field(:clauses, TypedEnumTest.Clauses)
  end
end
