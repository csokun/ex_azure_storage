defmodule AzureStorage.Table.EntityGenerator do
  alias AzureStorage.Table.Entity

  def partition_key(map, value) when is_map(map), do: string(map, "PartitionKey", value)
  def row_key(map, value) when is_map(map), do: string(map, "RowKey", value)

  def int32(map, field, value) when is_map(map), do: Map.put(map, field, int32(value))
  def int32(value), do: Entity.new(value, "Edm.Int32")

  def int64(map, field, value) when is_map(map), do: Map.put(map, field, int64(value))
  def int64(value), do: Entity.new(value, "Edm.Int64")

  def binary(map, field, value) when is_map(map), do: Map.put(map, field, binary(value))
  def binary(value), do: Entity.new(value, "Edm.Binary")

  def boolean(map, field, value) when is_map(map), do: Map.put(map, field, boolean(value))
  def boolean(value), do: Entity.new(value, "Edm.Boolean")

  def string(map, field, value) when is_map(map), do: Map.put(map, field, string(value))
  def string(value), do: Entity.new(value, "Edm.String")

  def guid(map, field, value) when is_map(map), do: Map.put(map, field, guid(value))
  def guid(value), do: Entity.new(value, "Edm.Guid")

  def double(map, field, value) when is_map(map), do: Map.put(map, field, double(value))
  def double(value), do: Entity.new(value, "Edm.Double")

  def date_time(map, field, value) when is_map(map), do: Map.put(map, field, date_time(value))
  def date_time(value), do: Entity.new(value, "Edm.DateTime")
end
