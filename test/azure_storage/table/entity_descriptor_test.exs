defmodule AzureStorage.Table.EntityDescriptorTest do
  use ExUnit.Case, async: true
  alias AzureStorage.Table.{Entity, EntityDescriptor}
  import AzureStorage.Table.EntityGenerator

  describe "create entity" do
    test "it should be able to update partition key and row key" do
      ed =
        %EntityDescriptor{}
        |> partition_key("partition-key")
        |> row_key("row-key")

      assert %EntityDescriptor{
               PartitionKey: %Entity{_: "partition-key", "$": "Edm.String"},
               RowKey: %Entity{_: "row-key", "$": "Edm.String"},
               Fields: %{},
               ETag: nil
             } == ed
    end
  end

  describe "json encode" do
    test "it should be able to encode mandatory fields to json" do
      json = %EntityDescriptor{} |> Jason.encode!()

      assert "{\"PartitionKey\":\"\",\"RowKey\":\"\"}" ==
               json
    end

    test "it should be able to encode additional fields" do
      json =
        %EntityDescriptor{}
        |> int32("Age", 32)
        |> Jason.encode!()

      assert "{\"PartitionKey\":\"\",\"RowKey\":\"\",\"Age\":32}" ==
               json
    end
  end
end
