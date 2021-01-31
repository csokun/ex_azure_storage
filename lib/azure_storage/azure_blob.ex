defmodule AzureStorage.Blob do
  alias AzureStorage.Request.Context
  import AzureStorage.Request
  import AzureStorage.Parser

  def list_containers(%Context{service: "blob"} = context) do
    query = "?comp=list"

    context
    |> build(method: "GET", path: query)
    |> request()
    |> parse_enumeration_results("Container")
  end

  def get_container_properties(%Context{service: "blob"} = context, container) do
    query = "#{container}?restype=container"

    context
    |> build(method: "GET", path: query)
    |> request()
  end

  def get_container_metadata(%Context{service: "blob"} = context, container) do
    query = "#{container}?restype=container&comp=metadata"

    context
    |> build(method: "GET", path: query)
    |> request()
  end

  def set_container_metadata(%Context{service: "blob"} = context, container, metadata) do
    query = "#{container}?restype=container&comp=metadata"

    # TODO: sanitize meta-key
    headers =
      metadata
      |> Enum.map(fn {k, v} -> %{"x-ms-meta-#{k}": v} end)

    context
    |> build(method: "PUT", body: "", path: query, headers: headers)
    |> request()
  end

  # @dev - filter by prefix
  def list_blobs(%Context{service: "blob"} = context, container) do
    query = "#{container}?restype=container&comp=list&maxresults=1"

    context
    |> build(method: "GET", path: query)
    |> request()
    |> parse_enumeration_results("Blob")
  end

  def create_container(%Context{service: "blob"} = context, container) do
    # @dev
    # version: 2019-02-02+ requires
    # x-ms-default-encryption-scope
    # x-ms-deny-encryption-scope-override: (true | false)
    query = "#{container}?restype=container"

    context
    |> build(method: "PUT", path: query)
    |> request()
  end

  def delete_container(%Context{service: "blob"} = context, container) do
    query = "#{container}?restype=container"

    context
    |> build(method: "DELETE", path: query)
    |> request()
  end

  def create_blob(%Context{service: "blob"} = context, container, name, content, content_type) do
    query = "#{container}/#{name}"
    headers = [{:"x-ms-blob-type", content_type}, {:"x-ms-blob-content-encoding", "UTF8"}]

    context
    |> build(method: "PUT", path: query, body: content, headers: headers)
    |> request()
  end

  def get_blob_content(%Context{service: "blob"} = context, container, blob_name) do
    query = "#{container}/#{blob_name}"

    context
    |> build(method: "GET", path: query)
    |> request()
  end

  def delete_blob(%Context{service: "blob"} = context, container, blob_name) do
    query = "#{container}/#{blob_name}"

    context
    |> build(method: "DELETE", path: query)
    |> request()
  end
end
