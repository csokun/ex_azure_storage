defmodule AzureStorage.Queue do
  @moduledoc """
  ref. https://docs.microsoft.com/en-us/rest/api/storageservices/queue-service-rest-api
  """
  alias AzureStorage.Core.Account
  alias AzureStorage.Request
  import AzureStorage.Parser

  @storage_service "queue"

  @doc """
  This operation lists all of the queues in a given storage account.
  """
  def list_queues(%Account{} = account) do
    query = "?comp=list"

    account
    |> Request.get(@storage_service, query)
    |> parse_enumeration_results("Queue")
  end

  @doc """
  The Create Queue operation creates a queue in a storage account.
  ref. https://docs.microsoft.com/en-us/rest/api/storageservices/create-queue4
  """
  def create_queue(%Account{} = account, name) do
    query = name

    account
    |> Request.put(@storage_service, query)
  end

  @doc """
  The Delete Queue operation permanently deletes the specified queue.
  ref. https://docs.microsoft.com/en-us/rest/api/storageservices/delete-queue3
  """
  def delete_queue(%Account{} = account, name) do
    query = name

    account
    |> Request.delete(@storage_service, query)
  end

  @doc """
  The Put Message operation adds a new message to the back of the message queue.
  A visibility timeout can also be specified to make the message invisible until the visibility timeout expires.
  A message must be in a format that can be included in an XML request with UTF-8 encoding.
  The encoded message can be up to 64 KiB in size for versions 2011-08-18 and newer, or 8 KiB in size for previous versions.
  ref. https://docs.microsoft.com/en-us/rest/api/storageservices/put-message
  """
  def create_message(%Account{} = account, query_name, message) do
    # default 7 days
    messagettl = 7 * 24 * 60 * 60 * 60
    query = "#{query_name}/messages?visibilitytimeout=0&messagettl=#{messagettl}"
    encoded_message = message |> Base.encode64()
    body = "<QueueMessage><MessageText>#{encoded_message}</MessageText></QueueMessage>"

    account
    |> Request.post(@storage_service, query, body)
    |> parse_queue_message_response()
  end

  @doc """
  The Get Messages operation retrieves one or more messages from the front of the queue.
  ref. https://docs.microsoft.com/en-us/rest/api/storageservices/get-messages
  """
  def get_messages(%Account{} = account, queue_name) do
    # default visibilityTimeout 30s
    query = "#{queue_name}/messages?visibilitytimeout=30&numofmessages=2"

    account
    |> Request.get(@storage_service, query)
    |> parse_queue_messages_response()
  end

  defp parse_queue_message_response({:ok, %{"QueueMessagesList" => list}}) do
    case list == %{} do
      true ->
        {:ok, []}

      _ ->
        message = get_in(list, ["QueueMessage"])
        {:ok, %{Message: message}}
    end
  end

  defp parse_queue_messages_response({:ok, %{"QueueMessagesList" => list}}) do
    case list == %{} do
      true ->
        {:ok, []}

      _ ->
        messages = get_in(list, ["QueueMessage"])
        {:ok, %{Items: messages}}
    end
  end
end
