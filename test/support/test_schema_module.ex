defmodule TestSchemaModule do
  use Ecto.Schema

  @primary_key false
  embedded_schema do
    field(:integer_val, TypedEnumTest.Integer)
    field(:string_val, TypedEnumTest.String)
  end
end
