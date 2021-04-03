defmodule AzureStorage.Table.Entity do
  defstruct _: nil, "$": ""

  @type t :: %AzureStorage.Table.Entity{
          _: String.t(),
          "$": any()
        }

  def new(value, type), do: %__MODULE__{_: value, "$": type}

  # validation methods
end

defimpl Jason.Encoder, for: AzureStorage.Table.Entity do
  def encode(%AzureStorage.Table.Entity{} = entity, _opts) do
    entity |> Map.take([:_, :"$"]) |> Jason.encode!()
  end
end
