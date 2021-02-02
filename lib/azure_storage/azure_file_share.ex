defmodule AzureStorage.FileShare do
  @moduledoc """
  Azure File Service

  ref. https://docs.microsoft.com/en-us/rest/api/storageservices/file-service-rest-api
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
  The Create Share operation creates a new share under the specified account. If the share with the same name already exists, the operation fails.
  """
  def create_share(%Context{service: "file"} = context, share) do
    query = "#{share}?restype=share"

    context
    |> build(method: :put, path: query)
    |> request()
  end

  @doc """
  The Delete Share operation marks the specified share or share snapshot for deletion. The share or share snapshot and any files contained within it are later deleted during garbage collection.
  """
  def delete_share(%Context{service: "file"} = context, share) do
    query = "#{share}?restype=share"

    context
    |> build(method: :delete, path: query)
    |> request()
  end

  @doc """
  The List Directories and Files operation returns a list of files or directories under the specified share or directory. It lists the contents only for a single level of the directory hierarchy.

  ref. https://docs.microsoft.com/en-us/rest/api/storageservices/list-directories-and-files
  """
  def dir(%Context{service: "file"} = context, share, path, options \\ []) do
    {:ok, _} = NimbleOptions.validate(options, Schema.list_directories_and_files_options())
    query = "#{share}/#{path}?restype=directory&comp=list"

    context
    |> build(method: :get, path: query)
    |> request()
    |> IO.inspect()
  end
end
