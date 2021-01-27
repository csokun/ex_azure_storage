defmodule AzureStorage.Table.EntityGenerator do
  alias AzureStorage.Table.Entity

  def int32(value), do: Entity.new(value, "Edm.Int32")
  def int64(value), do: Entity.new(value, "Edm.Int64")
  def binary(value), do: Entity.new(value, "Edm.Binary")
  def boolean(value), do: Entity.new(value, "Edm.Boolean")
  def string(value), do: Entity.new(value, "Edm.String")
  def guid(value), do: Entity.new(value, "Edm.Guid")
  def double(value), do: Entity.new(value, "Edm.Double")
  def date_time(value), do: Entity.new(value, "Edm.DateTime")
end
