defmodule TypedEnumTest do
  use ExUnit.Case, async: true
  import Ecto.Changeset

  describe "string version" do
    test "returns correct values as atoms" do
      assert [:val_1, :val_2, :val_3] = TypedEnumTest.String.values(:atoms)
    end

    test "returns correct values as strings" do
      assert ["val_1", "val_2", "val_3"] = TypedEnumTest.String.values(:strings)
    end

    test "casts correctly in schema" do
      assert {:ok, %TestSchemaModule{string_val: :val_1}} =
               %TestSchemaModule{}
               |> cast(%{"string_val" => "val_1"}, [:string_val])
               |> apply_action(:insert)

      assert {:ok, %TestSchemaModule{string_val: :val_1}} =
               %TestSchemaModule{}
               |> cast(%{"string_val" => :val_1}, [:string_val])
               |> apply_action(:insert)
    end

    test "schema equality works" do
      assert true = TypedEnumTest.String.equal?(:val_1, "val_1")
    end

    test "dumps correctly" do
      assert %{string_val: "val_1"} =
               Ecto.embedded_dump(%TestSchemaModule{string_val: :val_1}, :json)

      assert %{string_val: "val_1"} =
               Ecto.embedded_dump(%TestSchemaModule{string_val: "val_1"}, :json)
    end
  end

  describe "integer version" do
    test "returns correct values as integers" do
      assert [1, 2, 3] = TypedEnumTest.Integer.values(:ints)
    end

    test "returns correct values as atoms" do
      assert [:val_1, :val_2, :val_3] = TypedEnumTest.Integer.values(:atoms)
    end

    test "returns correct values as strings" do
      assert ["val_1", "val_2", "val_3"] = TypedEnumTest.Integer.values(:strings)
    end

    test "casts correctly in schema" do
      assert {:ok, %TestSchemaModule{integer_val: :val_1}} =
               %TestSchemaModule{}
               |> cast(%{"integer_val" => "val_1"}, [:integer_val])
               |> apply_action(:insert)

      assert {:ok, %TestSchemaModule{integer_val: :val_1}} =
               %TestSchemaModule{}
               |> cast(%{"integer_val" => :val_1}, [:integer_val])
               |> apply_action(:insert)

      assert {:ok, %TestSchemaModule{integer_val: :val_1}} =
               %TestSchemaModule{}
               |> cast(%{"integer_val" => 1}, [:integer_val])
               |> apply_action(:insert)
    end

    test "dumps correctly" do
      assert %{integer_val: 1} =
               Ecto.embedded_dump(%TestSchemaModule{integer_val: "val_1"}, :json)

      assert %{integer_val: 1} = Ecto.embedded_dump(%TestSchemaModule{integer_val: :val_1}, :json)

      assert %{integer_val: 1} = Ecto.embedded_dump(%TestSchemaModule{integer_val: 1}, :json)
    end

    test "schema equality works" do
      assert true = TypedEnumTest.Integer.equal?(:val_1, "val_1")
      assert true = TypedEnumTest.Integer.equal?(1, :val_1)
      assert true = TypedEnumTest.Integer.equal?("val_1", 1)
    end
  end

  test "can set clauses for cast/1" do
    assert {:ok, :val_1} = TypedEnumTest.Clauses.cast("to_replace")
    assert {:ok, :val_1} = TypedEnumTest.Clauses.cast(:to_replace)

    assert {:ok, %TestSchemaClauses{clauses: :val_1}} =
             %TestSchemaClauses{}
             |> cast(%{"clauses" => "to_replace"}, [:clauses])
             |> apply_action(:insert)
  end

  test "equal works when overriden get_term" do
    assert true = TypedEnumTest.Clauses.equal?(:val_1, "to_replace")

    assert true = TypedEnumTest.Clauses.equal?("val_1", :to_replace)
  end
end
