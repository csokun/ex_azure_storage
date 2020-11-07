defmodule AzureStorage.Blob do
  alias AzureStorage.Request
  import AzureStorage.Parser
  @storage_service "blob"

  def list_containers(account_name, account_key) do
    query = "?comp=list"

    Request.get(account_name, account_key, @storage_service, query)
    |> parse_enumeration_results("Container")
  end

  def get_container_properties(account_name, account_key, container) do
    query = "#{container}?restype=container"
    Request.get(account_name, account_key, @storage_service, query)
  end

  def get_container_metadata(account_name, account_key, container) do
    query = "#{container}?restype=container&comp=metadata"
    Request.get(account_name, account_key, @storage_service, query)
  end

  def set_container_metadata(account_name, account_key, container, metadata) do
    query = "#{container}?restype=container&comp=metadata"

    options =
      metadata
      |> Enum.map(fn {k, v} -> %{"x-ms-meta-#{k}": v} end)

    Request.put(account_name, account_key, @storage_service, query, options)
  end

  # @dev - filter by prefix
  def list_blobs(account_name, account_key, container) do
    query = "#{container}?restype=container&comp=list&maxresults=1"

    Request.get(account_name, account_key, @storage_service, query)
    |> parse_enumeration_results("Blob")
  end

  def create_container(account_name, account_key, container) do
    # @dev
    # version: 2019-02-02+ requires
    # x-ms-default-encryption-scope
    # x-ms-deny-encryption-scope-override: (true | false)
    query = "#{container}?restype=container"
    Request.put(account_name, account_key, @storage_service, query)
  end

  def delete_container(account_name, account_key, container) do
    query = "#{container}?restype=container"
    Request.delete(account_name, account_key, @storage_service, query)
  end
end
