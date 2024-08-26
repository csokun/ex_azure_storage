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
          {:ok, %{items: list() | [], marker: String.t() | nil}} | {:error, String.t()}
  def list_containers(%Context{service: "blob"} = context, options \\ []) do
    {:ok, opts} = NimbleOptions.validate(options, Schema.list_containers_options())
    query = "?comp=list&#{encode_query(opts)}"

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
          {:ok, %{items: list() | [], marker: String.t() | nil}}
          | {:error, String.t()}
  def list_blobs(%Context{service: "blob"} = context, container, options \\ []) do
    {:ok, opts} = NimbleOptions.validate(options, Schema.list_blobs_options())

    max_results =
      case opts[:maxresults] do
        nil -> ""
        _ -> "&maxresults=#{opts[:maxresults]}"
      end

    prefix =
      case opts[:prefix] do
        nil -> ""
        _ -> "&prefix=#{opts[:prefix]}"
      end

    delimiter =
      case opts[:delimiter] do
        nil -> ""
        _ -> "&delimiter=#{opts[:delimiter]}"
      end

    marker =
      case opts[:marker] do
        nil -> ""
        _ -> "&marker=#{opts[:marker]}"
      end

    query = "#{container}?restype=container&comp=list#{max_results}#{prefix}#{delimiter}#{marker}"

    context
    |> build(method: :get, path: query)
    |> request()
    |> parse_enumeration_results("Blob")
  end

  @doc """
  The Create Container operation creates a new container under the specified account.

  If the container with the same name already exists, the operation fails.
  """
  @spec create_container(Context.t(), String.t()) :: {:ok, String.t()} | {:error, String.t()}
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
    |> parse_body_response()
  end

  @doc """
  The Delete Container operation marks the specified container for deletion.

  The container and any blobs contained within it are later deleted during garbage collection.
  """
  @spec delete_container(Context.t(), String.t()) :: {:ok, String.t()} | {:error, String.t()}
  def delete_container(%Context{service: "blob"} = context, container) do
    query = "#{container}?restype=container"

    context
    |> build(method: :delete, path: query)
    |> request()
    |> parse_body_response()
  end

  @doc """
  Create new blob in a blob container

  Supported options\n#{NimbleOptions.docs(Schema.put_blob_options())}

  ```
  {:ok, context} = AzureStorage.create_blob_service("account_name", "account_key")
  context |> put_blob("blobs",
    "cache-key-1.json",
    "{\\"data\\": []}",
    content_type: "application/json;charset=\\"utf-8\\""
  )
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
    |> parse_body_response()
  end

  def put_binary_blob(
    %Context{service: "blob"} = context,
    container,
    filename,
    bytes,
    options \\ []
  ) do
    {:ok, opts} = NimbleOptions.validate(options, Schema.put_blob_options())
    query = "#{container}/#{filename}"
    headers = %{
      "x-ms-blob-type" => "BlockBlob",
      :"Content-Type" => "application/octet-stream"
    }
    context
    |> build(method: :put, path: query, body: bytes, headers: headers)
    |> request(recv_timeout: opts[:recv_timeout], timeout: opts[:timeout])
    |> parse_body_response()
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
  Free acquired lease so other client may immediately acquire a lease against the blob.
  """
  def lease_release(%Context{service: "blob"} = context, container, filename, lease_id) do
    # @dev: action=release is not part of the spec
    # it is here so ExVCR can record the action
    query = "#{container}/#{filename}?comp=lease&action=release"

    headers = %{
      "x-ms-lease-action" => "release",
      "x-ms-lease-id" => lease_id
    }

    context
    |> build(method: :put, path: query, headers: headers)
    |> request()
    |> parse_lease_response()
  end

  @doc """
  The Get Blob operation reads or downloads a blob from the system, including its metadata and properties.

  Supported options\n#{NimbleOptions.docs(Schema.get_blob_options())}

  ```
  # get plain/text content
  {:ok, content, attributes} = context
    |> get_blob_content("container1", "data.txt")
  {:ok, "Hello World!", %{"Content-Type" => "plain/text", ...}}

  # get json content
  context |> get_blob_content("container1", "data.json", json: true)
  {:ok, %{"data" => []}, %{"Content-Type" => "application/json", ...}}
  ```
  """
  def get_blob_content(%Context{service: "blob"} = context, container, filename, options \\ []) do
    {:ok, opts} = NimbleOptions.validate(options, Schema.get_blob_options())
    query = "#{container}/#{filename}"

    headers =
      case String.length(opts[:lease_id]) > 0 do
        true -> %{"x-ms-lease-id" => opts[:lease_id]}
        _ -> %{}
      end

    response_body =
      case opts[:json] do
        true -> :json
        false -> :full
      end

    context
    |> build(method: :get, path: query, headers: headers)
    |> request(response_body: response_body)
    |> parse_body_headers_response()
  end

  @doc """
  Delete blob witin blob container
  """
  def delete_blob(%Context{service: "blob"} = context, container, blob_name) do
    query = "#{container}/#{blob_name}"

    context
    |> build(method: :delete, path: query)
    |> request()
    |> parse_body_response()
  end

  @doc """
  Sharing blob file using Share Access Signature

  Supported options\n#{NimbleOptions.docs(Schema.share_options())}

  Example:

  ```
  # generate URL for sharing a read only access
  context
    |> AzureStorage.Blob.share(
      path: "/bookings/hotel-room-a.json",
      permissions: "r",
      start: "2021-04-10T10:48:02Z",
      expiry: "2021-04-11T13:48:02Z"
      )
    |> HTTPoison.get!([], [ssl: [versions: [:"tlsv1.2"]]])
    |> IO.inspect()
  ```
  """
  def share(
        %Context{service: "blob", account: account, base_url: base_url, headers: headers},
        options \\ []
      ) do
    {:ok, opts} = NimbleOptions.validate(options, Schema.share_options())

    version = headers[:"x-ms-version"]
    now = DateTime.truncate(DateTime.utc_now(), :second)

    start = opts[:start] || DateTime.add(now, -3600, :second) |> DateTime.to_iso8601()

    expiry = opts[:expiry] || DateTime.add(now, 30 * 60, :second) |> DateTime.to_iso8601()

    path =
      case String.starts_with?(opts[:path], "/") do
        true -> String.slice(opts[:path], 1..-1//-1)
        false -> opts[:path]
      end

    string_to_sign =
      [
        opts[:permissions],
        start,
        expiry,
        "/blob/#{account.name}/#{path}",
        "",
        opts[:ip_range],
        "",
        version,
        "b",
        "",
        "",
        "",
        "",
        "",
        ""
      ]
      |> Enum.join("\n")

    signature = account |> sign(string_to_sign)

    query_string =
      %{
        "sp" => opts[:permissions],
        "sv" => version,
        "sr" => "b",
        "st" => start,
        "se" => expiry,
        "sig" => signature
      }
      |> URI.encode_query()

    "#{base_url}/#{path}?#{query_string}"
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

  defp sign(%{key: account_key}, data) do
    {:ok, key} = account_key |> Base.decode64()

    :crypto.mac(:hmac, :sha256, key, data)
    |> Base.encode64()
  end
end
