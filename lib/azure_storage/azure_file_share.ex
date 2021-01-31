defmodule AzureStorage.FileShare do
  alias AzureStorage.Request.Context
  import AzureStorage.Request
  import AzureStorage.Parser

  def list_shares(%Context{service: "file"} = context) do
    query = "?comp=list"

    context
    |> build(method: "GET", path: query)
    |> request()
    |> parse_enumeration_results("Share")
  end

  def create_share(%Context{service: "file"} = context, share) do
    query = "#{share}?restype=share"

    context
    |> build(method: "PUT", path: query)
    |> request()
  end

  def delete_share(%Context{service: "file"} = context, share) do
    query = "#{share}?restype=share"

    context
    |> build(method: "DELETE", path: query)
    |> request()
  end
end
