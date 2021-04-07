defmodule AzureStorage.Blob do
  @moduledoc """
  Azure Blob Service

  Create Azure Blob Service Request Context before using any of the following methods.

  ```
  {:ok, context} = AzureStorage.create_blob_service("account_name", "account_key")
  context |> list_containers()
  ```
  """
  alias AzureStorage.Request.Context
  alias AzureStorage.Blob.Schema
  import AzureStorage.Request
  import AzureStorage.Parser

  @doc """
  The List Containers operation returns a list of the containers under the specified storage account.

  Supported options:\n#{NimbleOptions.docs(Schema.list_containers_options())}
  """
  @spec list_containers(Context.t(), keyword()) ::
          {:ok, %{Items: list() | [], NextMarker: String.t() | nil}} | {:error, String.t()}
  def list_containers(%Context{service: "blob"} = context, options \\ []) do
    {:ok, opts} = NimbleOptions.validate(options, Schema.list_containers_options())
    query = "?comp=list&maxresults=#{opts[:max_results]}"

    context
    |> build(method: :get, path: query)
    |> request()
    |> parse_enumeration_results("Container")
  end

  @doc """
  The Get Container Properties operation returns all user-defined metadata and system properties for the specified container.  The data returned does not include the container's list of blobs.
  """
  def get_container_properties(%Context{service: "blob"} = context, container) do
    query = "#{container}?restype=container"

    context
    |> build(method: :get, path: query)
    |> request()
    |> parse_body_response()
  end

  @doc """
  The Get Container Metadata operation returns all user-defined metadata for the container.
  """
  def get_container_metadata(%Context{service: "blob"} = context, container) do
    query = "#{container}?restype=container&comp=metadata"

    context
    |> build(method: :get, path: query)
    |> request()
    |> parse_body_response()
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
    |> parse_body_response
  end

  @doc """
  The List Blobs operation returns a list of the blobs under the specified container.

  Supported options:\n#{NimbleOptions.docs(Schema.list_blobs_options())}
  """
  @spec list_blobs(Context.t(), String.t(), keyword()) ::
          {:ok, %{Items: list() | [], NextMarker: String.t() | nil}}
          | {:error, String.t()}
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
      "x-ms-blob-public-access" => "blob",
      "x-ms-default-encryption-scope" => "$account-encryption-key",
      "x-ms-deny-encryption-scope-override" => false,
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

  @doc """
  Create new blob in a blob container

  Supported options\n#{NimbleOptions.docs(Schema.put_blob_options())}

  ```
  {:ok, context} = AzureStorage.create_blob_service("account_name", "account_key")
  context |> put_blob("blobs", "cache-key-1.json", "{\\"data\\": []}", content_type: "application/json;charset=\\"utf-8\\"")
  ```
  """
  def put_blob(
        %Context{service: "blob"} = context,
        container,
        filename,
        content,
        options \\ []
      ) do
    {:ok, opts} = NimbleOptions.validate(options, Schema.put_blob_options())
    query = "#{container}/#{filename}"

    headers = %{
      "x-ms-blob-type" => "BlockBlob",
      "x-ms-blob-content-encoding" => "UTF8",
      :"Content-Type" => opts[:content_type]
    }

    context
    |> build(method: :put, path: query, body: content, headers: headers)
    |> request()
  end

  @doc """
  Acquires a new lease. If container and blob are specified, acquires a blob lease. Otherwise, if only container is specified and blob is null, acquires a container lease.

  Supported options\n#{NimbleOptions.docs(Schema.acquire_lease_options())}
  """
  def acquire_lease(%Context{service: "blob"} = context, container, filename, options \\ []) do
    {:ok, opts} = NimbleOptions.validate(options, Schema.acquire_lease_options())
    query = "#{container}/#{filename}?comp=lease"

    headers = %{
      "x-ms-lease-action" => "acquire",
      "x-ms-lease-duration" => opts[:duration]
    }

    context
    |> build(method: :put, path: query, headers: headers)
    |> request()
    |> parse_lease_response()
  end

  @doc """
  The Get Blob operation reads or downloads a blob from the system, including its metadata and properties.
  """
  def get_blob_content(%Context{service: "blob"} = context, container, blob_name) do
    query = "#{container}/#{blob_name}"

    context
    |> build(method: :get, path: query)
    |> request()
    |> parse_body_response()
  end

  @doc """
  Delete blob witin blob container
  """
  def delete_blob(%Context{service: "blob"} = context, container, blob_name) do
    query = "#{container}/#{blob_name}"

    context
    |> build(method: :delete, path: query)
    |> request()
  end

  # ------------ helpers
  defp parse_lease_response({:ok, _, headers}) do
    props =
      headers
      |> Enum.reduce(%{}, fn
        {"ETag", value}, map -> Map.put(map, "ETag", value)
        {"x-ms-lease-id", value}, map -> Map.put(map, "lease_id", value)
        _, map -> map
      end)

    {:ok, props}
  end

  defp parse_lease_response({:error, reason}), do: {:error, reason}
end
