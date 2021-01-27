defmodule AzureStorage.Table.Entity do
  defstruct _: "", "$": ""

  def new(value, type), do: %__MODULE__{_: value, "$": type}
end

defimpl Jason.Encoder, for: AzureStorage.Table.Entity do
  def encode(%AzureStorage.Table.Entity{} = entity, _opts) do
    %{_: Map.get(entity, :_, ""), "$": Map.get(entity, :"$")} |> Jason.encode!()
  end
end
