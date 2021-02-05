defmodule AzureStorage.Blob do
  @moduledoc """
  Blob Service
  """

  alias AzureStorage.Request.Context
  alias AzureStorage.Blob.Schema
  import AzureStorage.Request
  import AzureStorage.Parser

  @doc """
  The List Containers operation returns a list of the containers under the specified storage account.
  """
  def list_containers(%Context{service: "blob"} = context) do
    query = "?comp=list"

    context
    |> build(method: :get, path: query)
    |> request()
    |> parse_enumeration_results("Container")
  end

  @doc """
  The Get Container Properties operation returns all user-defined metadata and system properties for the specified container.
  The data returned does not include the container's list of blobs.
  """
  def get_container_properties(%Context{service: "blob"} = context, container) do
    query = "#{container}?restype=container"

    context
    |> build(method: :get, path: query)
    |> request()
  end

  @doc """
  The Get Container Metadata operation returns all user-defined metadata for the container.
  """
  def get_container_metadata(%Context{service: "blob"} = context, container) do
    query = "#{container}?restype=container&comp=metadata"

    context
    |> build(method: :get, path: query)
    |> request()
  end

  @doc """
  The Set Container Metadata operation sets one or more user-defined name-value pairs for the specified container.
  """
  def set_container_metadata(%Context{service: "blob"} = context, container, metadata) do
    query = "#{container}?restype=container&comp=metadata"

    # TODO: sanitize meta-key
    headers =
      metadata
      |> Enum.map(fn {k, v} -> %{"x-ms-meta-#{k}": v} end)

    context
    |> build(method: :put, body: "", path: query, headers: headers)
    |> request()
  end

  @doc """
  The List Blobs operation returns a list of the blobs under the specified container.
  """
  def list_blobs(%Context{service: "blob"} = context, container, options \\ []) do
    {:ok, opts} = NimbleOptions.validate(options, Schema.list_blobs_options())
    max_results = opts[:max_results]

    prefix =
      case String.length(opts[:prefix]) do
        0 -> []
        _ -> ["&prefix=", opts[:prefix]]
      end

    query =
      ([
         container,
         "?restype=container",
         container,
         "&comp=list",
         "&maxresults=",
         max_results
       ] ++ prefix)
      |> IO.iodata_to_binary()

    context
    |> build(method: :get, path: query)
    |> request()
    |> parse_enumeration_results("Blob")
  end

  @doc """
  The Create Container operation creates a new container under the specified account.
  If the container with the same name already exists, the operation fails.
  """
  def create_container(%Context{service: "blob"} = context, container) do
    # @dev
    # version: 2019-02-02+ requires
    # x-ms-default-encryption-scope
    # x-ms-deny-encryption-scope-override: (true | false)
    query = "#{container}?restype=container"

    headers = %{
      :"x-ms-blob-public-access" => "blob",
      :"x-ms-default-encryption-scope" => "$account-encryption-key",
      :"x-ms-deny-encryption-scope-override" => false,
      :"Content-Type" => "application/octet-stream"
    }

    context
    |> build(method: :put, path: query, headers: headers)
    |> request()
  end

  @doc """
  The Delete Container operation marks the specified container for deletion.
  The container and any blobs contained within it are later deleted during garbage collection.
  """
  def delete_container(%Context{service: "blob"} = context, container) do
    query = "#{container}?restype=container"

    context
    |> build(method: :delete, path: query)
    |> request()
  end

  def create_blob(
        %Context{service: "blob"} = context,
        container,
        filename,
        content,
        _options \\ []
      ) do
    query = "#{container}/#{filename}"
    headers = [{:"x-ms-blob-type", "BlockBlob"}, {:"x-ms-blob-content-encoding", "UTF8"}]

    context
    |> build(method: :put, path: query, body: content, headers: headers)
    |> request()
  end

  def get_blob_content(%Context{service: "blob"} = context, container, blob_name) do
    query = "#{container}/#{blob_name}"

    context
    |> build(method: :get, path: query)
    |> request()
  end

  def delete_blob(%Context{service: "blob"} = context, container, blob_name) do
    query = "#{container}/#{blob_name}"

    context
    |> build(method: :delete, path: query)
    |> request()
  end
end
