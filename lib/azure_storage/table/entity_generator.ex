defmodule AzureStorage.Table.EntityGenerator do
  alias AzureStorage.Table.{Entity, EntityDescriptor}

  def partition_key(%EntityDescriptor{} = entity_descriptor, value),
    do: Map.put(entity_descriptor, :PartitionKey, string(value))

  def row_key(%EntityDescriptor{} = entity_descriptor, value),
    do: Map.put(entity_descriptor, :RowKey, string(value))

  def int32(%EntityDescriptor{} = entity_descriptor, field, value),
    do: EntityDescriptor.update_field(entity_descriptor, field, int32(value))

  def int32(value), do: Entity.new(value, "Edm.Int32")

  def int64(%EntityDescriptor{} = entity_descriptor, field, value),
    do: EntityDescriptor.update_field(entity_descriptor, field, int64(value))

  def int64(value), do: Entity.new(value, "Edm.Int64")

  def binary(%EntityDescriptor{} = entity_descriptor, field, value),
    do: EntityDescriptor.update_field(entity_descriptor, field, binary(value))

  def binary(value), do: Entity.new(value, "Edm.Binary")

  def boolean(%EntityDescriptor{} = entity_descriptor, field, value),
    do: EntityDescriptor.update_field(entity_descriptor, field, boolean(value))

  def boolean(value), do: Entity.new(value, "Edm.Boolean")

  def string(%EntityDescriptor{} = entity_descriptor, field, value),
    do: EntityDescriptor.update_field(entity_descriptor, field, string(value))

  def string(value), do: Entity.new(value, "Edm.String")

  def guid(%EntityDescriptor{} = entity_descriptor, field, value),
    do: EntityDescriptor.update_field(entity_descriptor, field, guid(value))

  def guid(value), do: Entity.new(value, "Edm.Guid")

  def double(%EntityDescriptor{} = entity_descriptor, field, value),
    do: EntityDescriptor.update_field(entity_descriptor, field, double(value))

  def double(value), do: Entity.new(value, "Edm.Double")

  def date_time(%EntityDescriptor{} = entity_descriptor, field, value),
    do: EntityDescriptor.update_field(entity_descriptor, field, date_time(value))

  def date_time(value), do: Entity.new(value, "Edm.DateTime")
end
