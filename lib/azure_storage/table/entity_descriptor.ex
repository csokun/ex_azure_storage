defmodule AzureStorage.Table.EntityDescriptor do
  alias AzureStorage.Table.Entity

  defstruct PartitionKey: %Entity{},
            RowKey: %Entity{},
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
  def encode(%AzureStorage.Table.EntityDescriptor{} = ed, _opts) do
    ed
    |> Map.take([:PartitionKey, :RowKey, :ETag])
    |> Map.merge(ed |> Map.get(:Fields))
    |> Jason.encode!()
  end
end
