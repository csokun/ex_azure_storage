defmodule AzureStorage.Table.EntityDescriptor do
  alias AzureStorage.Table.Entity

  defstruct PartitionKey: %Entity{_: "", "$": "Edm.String"},
            RowKey: %Entity{_: "", "$": "Edm.String"},
            Fields: %{},
            ETag: nil

  def update_field(%__MODULE__{} = entity_descriptor, field_name, %Entity{} = value) do
    fields =
      entity_descriptor
      |> Map.get(:Fields)
      |> Map.put(field_name, value)

    Map.put(entity_descriptor, :Fields, fields)
  end
end

defimpl Jason.Encoder, for: [AzureStorage.Table.EntityDescriptor] do
  alias AzureStorage.Table.Entity

  def encode(%AzureStorage.Table.EntityDescriptor{} = ed, _opts) do
    ed
    |> Map.take([:PartitionKey, :RowKey])
    |> Map.merge(ed |> Map.get(:Fields))
    |> Map.to_list()
    |> Enum.reduce(%{}, fn {prop, %Entity{} = entity}, map ->
      encode_field(map, prop, entity)
    end)
    |> Jason.encode!()
  end

  defp encode_field(map, prop, %Entity{"$": type, _: value}) do
    case type do
      t when t in ["Edm.String", "Edm.Int32", "Edm.Double"] ->
        Map.put(map, prop, value)

      _ ->
        map
        |> Map.put(prop, "#{value}")
        |> Map.put("#{prop}@odata", type)
    end
  end

  defp encode_field(map, _, _), do: map
end
