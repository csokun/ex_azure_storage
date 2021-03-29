defmodule AzureStorage do
  @moduledoc """
  Azure Storage REST Client.

  Before you can start interacting with Azure Storage services. You need to create a `AzureStorage.Request.Context`.

  ## Example

      iex> AzureStorage.create_blob_service("account_name", "account_key")
      {:ok, %AzureStorage.Request.Context{}}

  """
  alias AzureStorage.Core.Account
  alias AzureStorage.Request.Context

  @doc """
   Create a new context to interact with Azure Blob Service
  """
  @spec create_blob_service(String.t(), String.t()) :: {:ok, Context.t()} | {:error, String.t()}
  def create_blob_service(account_name, account_key),
    do: create_service(account_name, account_key, "blob")

  @doc """
  Create a new context to interact with Azure Fileshare service
  """
  @spec create_fileshare_service(String.t(), String.t()) ::
          {:ok, Context.t()} | {:error, String.t()}
  def create_fileshare_service(account_name, account_key),
    do: create_service(account_name, account_key, "file")

  @doc """
  Create a new context to interact with Azure Queue Storage
  """
  @spec create_queue_service(String.t(), String.t()) :: {:ok, Context.t()} | {:error, String.t()}
  def create_queue_service(account_name, account_key),
    do: create_service(account_name, account_key, "queue")

  @doc """
  Create a new context to interact with Azure Table Storage Service
  """
  @spec create_table_service(String.t(), String.t()) :: {:ok, Context.t()} | {:error, String.t()}
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
