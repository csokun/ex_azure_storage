defmodule AzureStorage.FileShare do
  alias AzureStorage.Core.Account
  alias AzureStorage.Request
  import AzureStorage.Parser

  @storage_service "file"

  def list_shares(%Account{} = account) do
    query = "?comp=list"

    account
    |> Request.get(@storage_service, query)
    |> parse_enumeration_results("Share")
  end

  def create_share(%Account{} = account, share) do
    query = "#{share}?restype=share"

    account
    |> Request.put(@storage_service, query)
  end

  def delete_share(%Account{} = account, share) do
    query = "#{share}?restype=share"

    account
    |> Request.delete(@storage_service, query)
  end
end
