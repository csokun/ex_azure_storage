defmodule AzureStorage.Table.EntityGeneratorTest do
  use ExUnit.Case, async: true
  alias AzureStorage.Table.{Entity, EntityDescriptor}
  import AzureStorage.Table.EntityGenerator

  test "it should be able to convert json to entity descriptor" do
    entity = %{
      "PartitionKey" => "partition_key_1",
      "RowKey" => "row_key_1",
      "Val1" => 20,
      "Val2" => 20.4,
      "Val2@odata.type" => "Edm.Double",
      "Val3" => true,
      "Name" => "Sokun",
      "odata.etag" => "etag_value"
    }

    assert %EntityDescriptor{
             PartitionKey: %Entity{"$": "Edm.String", _: "partition_key_1"},
             RowKey: %Entity{"$": "Edm.String", _: "row_key_1"},
             ETag: "etag_value"
           } = map_to_entity_descriptor(entity)
  end
end
