defmodule AzureStorage do
  alias AzureStorage.Core.Account
  alias AzureStorage.Request.Context

  def create_blob_service(account_name, account_key),
    do: create_service(account_name, account_key, "blob")

  def create_fileshare_service(account_name, account_key),
    do: create_service(account_name, account_key, "file")

  def create_queue_service(account_name, account_key),
    do: create_service(account_name, account_key, "queue")

  def create_table_service(account_name, account_key),
    do: create_service(account_name, account_key, "table")

  # -------- helpers -------

  defp create_service(account_name, account_key, service, api_version \\ "2019-07-07") do
    case Account.new(account_name, account_key) do
      {:ok, account} ->
        {:ok, account |> Context.create(service, api_version)}

      {:error, reason} ->
        {:error, reason}
    end
  end
end
