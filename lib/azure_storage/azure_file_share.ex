defmodule AzureStorage.FileShare do
  alias AzureStorage.Request
  import AzureStorage.Parser
  @storage_service "file"

  def list_shares(account_name, account_key) do
    query = "?comp=list"

    Request.get(account_name, account_key, @storage_service, query)
    |> parse_enumeration_results("Share")
  end

  def create_share(account_name, account_key, share) do
    query = "#{share}?restype=share"

    Request.put(account_name, account_key, @storage_service, query)
  end

  @spec delete_share(any, binary, any) :: {:error, any} | {:ok, any}
  def delete_share(account_name, account_key, share) do
    query = "#{share}?restype=share"
    Request.delete(account_name, account_key, @storage_service, query)
  end
end
