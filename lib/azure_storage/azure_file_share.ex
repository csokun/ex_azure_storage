defmodule AzureStorage.FileShare do
  require Logger

  @moduledoc """
  Azure File Service

  ref. https://docs.microsoft.com/en-us/rest/api/storageservices/file-service-rest-api

  ```
  {:ok, context} = AzureStorage.create_fileshare_service("account_name", "account_key")
  context |> list_shares()
  ```
  """
  alias AzureStorage.Request.Context
  alias AzureStorage.Fileshare.Schema
  import AzureStorage.Request
  import AzureStorage.Parser

  @doc """
  The List Shares operation returns a list of the shares and share snapshots under the specified account.
  """
  def list_shares(%Context{service: "file"} = context) do
    query = "?comp=list"

    context
    |> build(method: :get, path: query)
    |> request()
    |> parse_enumeration_results("Share")
  end

  @doc """
  The Create Share operation creates a new share under the specified account.
  If the share with the same name already exists, the operation fails.
  """
  def create_share(%Context{service: "file"} = context, share) do
    query = "#{share}?restype=share"

    context
    |> build(method: :put, path: query)
    |> request()
  end

  @doc """
  The Delete Share operation marks the specified share or share snapshot for deletion.
  The share or share snapshot and any files contained within it are later deleted during garbage collection.
  """
  def delete_share(%Context{service: "file"} = context, share) do
    query = "#{share}?restype=share"

    context
    |> build(method: :delete, path: query)
    |> request()
  end

  @doc """
  The List Directories and Files operation returns a list of files or directories under the specified share or directory.
  It lists the contents only for a single level of the directory hierarchy.

  ref. https://docs.microsoft.com/en-us/rest/api/storageservices/list-directories-and-files

  ```
  context |> AzureStorage.FileShare.list_directories("testfileshare", "parent-directory")
  {:ok,
   %{
     directories: [%{"name" => "dir2"}],
     files: [
       %{"name" => "test.txt", "size" => 13},
       %{"name" => "file1", "size" => 5242880}
     ],
     marker: nil
   }
  }
  ```

  Supported options:\n#{NimbleOptions.docs(Schema.list_directories_and_files_options())}
  """
  def list_directories(%Context{service: "file"} = context, share, path, options \\ []) do
    {:ok, opts} = NimbleOptions.validate(options, Schema.list_directories_and_files_options())

    path = "#{share}/#{path}?restype=directory&comp=list&#{encode_query(opts)}"

    context
    |> build(method: :get, path: path)
    |> request()
    |> parse_body_response()
    |> case do
      {:ok, %{"EnumerationResults" => %{"#content" => content}}} ->
        directories =
          get_in(content, ["Entries", "Directory"]) |> parse_list_directories_entries()

        files = get_in(content, ["Entries", "File"]) |> parse_list_directories_entries()

        marker = get_in(content, ["NextMarker"])
        {:ok, %{files: files, directories: directories, marker: marker}}

      error ->
        error
    end
  end

  @doc """
  Check if directories exist.

  ```
  context |> AzureStorage.FileShare.directory_exists("testfileshare", "exist-dir")
  {:ok, ""}

  context |> AzureStorage.FileShare.directory_exists("testfileshare", "not-exist")
  {:error, "ResourceNotFound"}
  ```
  """
  @spec directory_exists(Context.t(), String.t(), String.t()) ::
          {:ok, String.t()} | {:error, String.t()}
  def directory_exists(%Context{service: "file"} = context, share, path) do
    query = "#{share}/#{path}?restype=directory"

    context
    |> build(method: :get, path: query)
    |> request()
    |> parse_body_response()
  end

  @doc """
  Create directory.
  """
  def create_directory(%Context{service: "file"} = context, share, path) do
    query = "#{share}/#{path}?restype=directory"

    headers = %{
      :"x-ms-version" => "2018-03-28"
    }

    context
    |> build(method: :put, path: query, headers: headers)
    |> request()
    |> parse_body_response()
  end

  @doc """
  Delete empty directoy. Attempt to delete non-empty directory will return an `{:error, reason}`
  """
  def delete_directory(%Context{service: "file"} = context, share, path) do
    query = "#{share}/#{path}?restype=directory"

    headers = %{
      :"x-ms-version" => "2018-03-28"
    }

    context
    |> build(method: :delete, path: query, headers: headers)
    |> request()
    |> parse_body_response()
  end

  @doc """
  The Delete File operation immediately removes the file from the storage account.

  Supported options\n#{NimbleOptions.docs(Schema.delete_file_options())}
  """
  @spec delete_file(Context.t(), String.t(), String.t(), keyword()) ::
          {:ok, any} | {:error, String.t()}
  def delete_file(%Context{service: "file"} = context, share, path, options \\ []) do
    {:ok, opts} = NimbleOptions.validate(options, Schema.delete_file_options())
    query = "#{share}/#{path}"

    headers =
      case String.length(opts[:lease_id]) == 0 do
        true -> %{"x-ms-lease-id" => opts[:lease_id]}
        false -> %{}
      end

    context
    |> build(method: :delete, path: query, headers: headers)
    |> request()
    |> parse_body_response()
  end

  # 4Gi
  @max_upload_file_size 4 * 1024 * 1024 * 1024

  # 4MiB
  @max_acceptable_range_in_bytes 4 * 1024 * 1024

  @doc """
  Creates a new file or replaces a file.
  """
  def create_file_from_text(%Context{service: "file"} = context, share, directory, filename, text)
      when is_bitstring(text) do
    path = "#{share}/#{directory}/#{filename}"
    content_length = byte_size(text)

    case content_length > @max_upload_file_size do
      true ->
        {:error, "INVALID_FILE_LENGTH"}

      false ->
        create_file_placeholder(context, path, content_length)
        update_content(context, path, text)
    end
  end

  @doc """
  Reads or downloads a file from the system, including its metadata and properties.

  ```
  context |> AzureStorage.FileShare.get_file("fileshare1", "directory1", "file1")
  {:ok,
    content,
    %{
      "Content-Type" => "application/json",
      "Content-Length" => "20000",
      "ETag" => "...",
      "x-ms-version" => "...",
      ..
    }
  }
  ```
  """
  @spec get_file(Context.t(), String.t(), String.t(), String.t()) ::
          {:ok, binary(), map()} | {:error, String.t()}
  def get_file(%Context{service: "file"} = context, share, directory, filename) do
    cond do
      is_nil(share) or share == "" ->
        {:error, "missing_share"}

      is_nil(filename) or filename == "" ->
        {:error, "missing_filename"}

      true ->
        path = Path.join([share, directory || "", filename])

        context
        |> build(method: :get, path: path)
        |> request(response_body: :full)
        |> parse_body_headers_response()
    end
  end

  # helpers

  defp create_file_placeholder(%Context{service: "file"} = context, path, content_length) do
    headers = %{
      :"x-ms-version" => "2018-03-28",
      "x-ms-type" => "file",
      "x-ms-content-length" => content_length
    }

    context
    |> build(method: :put, path: path, headers: headers)
    |> request()
    |> parse_body_response()
  end

  defp update_content(%Context{} = context, path, content)
       when byte_size(content) <= @max_acceptable_range_in_bytes do
    put_range(context, path, content)
  end

  defp update_content(%Context{} = context, path, content) do
    content
    |> String.graphemes()
    |> Stream.chunk_every(@max_acceptable_range_in_bytes)
    |> Stream.map(&Enum.join/1)
    |> Stream.with_index()
    |> Task.async_stream(
      fn {chunk, index} ->
        context
        |> put_range(path, chunk, index * @max_acceptable_range_in_bytes)
      end,
      max_concurrency: 5,
      # not sure it is a good idea?
      timeout: :infinity
    )
    |> Stream.run()
  end

  # helpers

  defp put_range(%Context{service: "file"} = context, path, content, offset \\ 0) do
    content_length = byte_size(content)

    headers = %{
      :"x-ms-version" => "2018-03-28",
      :"Content-Length" => content_length,
      "x-ms-range" => "bytes=#{offset}-#{offset + content_length - 1}",
      "x-ms-write" => "Update"
    }

    context
    |> build(method: :put, path: "#{path}?comp=range", headers: headers, body: content)
    |> request()
    |> parse_body_response()
  end

  defp parse_list_directories_entries(%{
         "Name" => name,
         "Properties" => %{"Content-Length" => size}
       }),
       do: [%{name: name, size: String.to_integer(size)}]

  defp parse_list_directories_entries(%{"Name" => name, "Properties" => nil}),
    do: [%{name: name}]

  defp parse_list_directories_entries([head | tail]),
    do: parse_list_directories_entries(tail, parse_list_directories_entries(head))

  defp parse_list_directories_entries([], entries), do: entries

  defp parse_list_directories_entries([head | tail], entries),
    do: parse_list_directories_entries(tail, parse_list_directories_entries(head) ++ entries)
end
