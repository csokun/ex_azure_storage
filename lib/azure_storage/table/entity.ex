defmodule AzureStorage.Table.Entity do
  # defstruct _: "", "$": ""

  def new(value, type), do: %{_: value, "$": type}
end
