defmodule AzureStorage.Table.Query do
  defstruct table: nil, filter: nil, select: nil, top: 1000

  @type t :: %AzureStorage.Table.Query{
          table: String.t(),
          filter: list(String.t()) | nil,
          select: String.t() | nil,
          top: integer
        }

  @spec table(String.t()) :: t()
  def table(name) do
    %__MODULE__{table: name}
  end
end
