defmodule AzureStorage.FileShare do
  @moduledoc """
    Azure File Service

    ref. https://docs.microsoft.com/en-us/rest/api/storageservices/file-service-rest-api

    ```
    {:ok, context} = AzureStorage.create_fileshare_service("account_name", "account_key")
    context |> list_shares()
    ```
  """
  alias AzureStorage.Request.Context
  alias AzureStorage.File.Schema
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
  """
  def list_directories(%Context{service: "file"} = context, share, path, options \\ []) do
    {:ok, _} = NimbleOptions.validate(options, Schema.list_directories_and_files_options())
    query = "#{share}/#{path}?restype=directory&comp=list"

    context
    |> build(method: :get, path: query)
    |> request()
    |> parse_body_response()
    |> case do
      {:ok, %{"EnumerationResults" => %{"#content" => content}}} ->
        directories = get_in(content, ["Entries", "Directory"])
        marker = get_in(content, ["NextMarker"])
        {:ok, %{Items: directories, NextMarker: marker}}

      error ->
        error
    end
  end

  def directory_exists(%Context{service: "file"} = context, share, path) do
    query = "#{share}/#{path}?restype=directory"

    context
    |> build(method: :get, path: query)
    |> request()
    |> parse_body_response()
  end

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
end
