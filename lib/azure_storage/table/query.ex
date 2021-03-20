defmodule AzureStorage.Table.Query do
  defstruct table: nil, filter: nil, selct: nil, top: 1000

  def table(name) do
    %__MODULE__{table: name}
  end
end
