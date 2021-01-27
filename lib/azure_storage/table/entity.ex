defmodule AzureStorage.Table.Entity do
  defstruct _: "", "$": ""

  def new(value, type), do: %__MODULE__{_: value, "$": type}
end
