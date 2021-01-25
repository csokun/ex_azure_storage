defmodule AzureStorage.Blob do
  alias AzureStorage.Core.Account
  alias AzureStorage.Request
  import AzureStorage.Parser
  @storage_service "blob"

  def list_containers(%Account{} = account) do
    query = "?comp=list"

    account
    |> Request.get(@storage_service, query)
    |> parse_enumeration_results("Container")
  end

  def get_container_properties(%Account{} = account, container) do
    query = "#{container}?restype=container"

    account
    |> Request.get(@storage_service, query)
  end

  def get_container_metadata(%Account{} = account, container) do
    query = "#{container}?restype=container&comp=metadata"

    account
    |> Request.get(@storage_service, query)
  end

  def set_container_metadata(%Account{} = account, container, metadata) do
    query = "#{container}?restype=container&comp=metadata"

    # TODO: sanitize meta-key
    options =
      metadata
      |> Enum.map(fn {k, v} -> %{"x-ms-meta-#{k}": v} end)

    body = ""

    account
    |> Request.put(@storage_service, query, body, options)
  end

  # @dev - filter by prefix
  def list_blobs(%Account{} = account, container) do
    query = "#{container}?restype=container&comp=list&maxresults=1"

    account
    |> Request.get(@storage_service, query)
    |> parse_enumeration_results("Blob")
  end

  def create_container(%Account{} = account, container) do
    # @dev
    # version: 2019-02-02+ requires
    # x-ms-default-encryption-scope
    # x-ms-deny-encryption-scope-override: (true | false)
    query = "#{container}?restype=container"

    account
    |> Request.put(@storage_service, query)
  end

  def delete_container(%Account{} = account, container) do
    query = "#{container}?restype=container"

    account
    |> Request.delete(@storage_service, query)
  end

  def create_blob(%Account{} = account, container, name, content, content_type) do
    query = "#{container}/#{name}"
    body = content
    options = %{"x-ms-blob-type": content_type, "x-ms-blob-content-encoding": "UTF8"}

    account
    |> Request.put(@storage_service, query, body, options)
  end

  def get_blob_content(%Account{} = account, container, blob_name) do
    query = "#{container}/#{blob_name}"

    account
    |> Request.get(@storage_service, query)
  end

  def delete_blob(%Account{} = account, container, blob_name) do
    query = "#{container}/#{blob_name}"

    account
    |> Request.delete(@storage_service, query)
  end
end
