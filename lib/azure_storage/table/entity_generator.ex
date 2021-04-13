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

  @doc """
  Convert json response to `AzureStorage.Table.EntityDescriptor`
  """
  @spec map_to_entity_descriptor(map()) :: EntityDescriptor.t()
  def map_to_entity_descriptor(json)
      when is_map(json) do
    json
    |> Map.to_list()
    |> Enum.filter(fn {k, _} ->
      # remove @odata.type properties and odata.metadata
      !(k == "odata.metadata" || String.ends_with?(k, "@odata.type"))
    end)
    |> Enum.reduce(%EntityDescriptor{}, fn
      {"PartitionKey", value}, ed ->
        ed |> partition_key(value)

      {"RowKey", value}, ed ->
        ed |> row_key(value)

      {"Timestamp", value}, ed ->
        {:ok, date, _} = DateTime.from_iso8601(value)
        Map.put(ed, :Timestamp, date_time(date))

      {"odata.etag", value}, ed ->
        %{ed | ETag: value}

      {prop, value}, ed ->
        property_type = Map.get(json, "#{prop}@odata.type", nil)

        entity =
          case property_type do
            nil ->
              auto_prop_type(value)

            "Edm.DateTime" ->
              {:ok, date, _} = DateTime.from_iso8601(value)
              Entity.new(date, property_type)

            _ ->
              Entity.new(value, property_type)
          end

        ed |> EntityDescriptor.update_field(prop, entity)
    end)
  end

  # ----- helpers
  defp auto_prop_type(value) when is_boolean(value), do: Entity.new(value, "Edm.Boolean")
  defp auto_prop_type(value) when is_float(value), do: Entity.new(value, "Edm.Double")
  defp auto_prop_type(value) when is_integer(value), do: Entity.new(value, "Edm.Int32")
  defp auto_prop_type(value), do: Entity.new(value, "Edm.String")
end
