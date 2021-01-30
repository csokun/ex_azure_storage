defmodule AzureStorage.Queue do
  @moduledoc """
  ref. https://docs.microsoft.com/en-us/rest/api/storageservices/queue-service-rest-api
  """
  alias AzureStorage.Core.Account
  alias AzureStorage.Request
  alias AzureStorage.Queue.Schema
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
  def create_message(%Account{} = account, queue_name, message, options \\ []) do
    {:ok, opts} = NimbleOptions.validate(options, Schema.create_message_options())
    visibility_timeout = opts[:visibility_timeout]
    message_ttl = opts[:message_ttl]

    query =
      "#{queue_name}/messages?visibilitytimeout=#{visibility_timeout}&messagettl=#{message_ttl}"

    body = create_message_body_xml(message)

    account
    |> Request.post(@storage_service, query, body)
    |> parse_queue_message_response()
  end

  def update_message(%Account{} = account, queue_name, pop_receipt, message, options \\ []) do
    {:ok, opts} = NimbleOptions.validate(options, Schema.create_message_options())
    visibility_timeout = opts[:visibility_timeout]

    query =
      "#{queue_name}/messages?popreceipt=#{pop_receipt}visibilitytimeout=#{visibility_timeout}"

    body = create_message_body_xml(message)

    account
    |> Request.put(@storage_service, query, body)
    |> parse_queue_message_response()
  end

  def delete_message(%Account{} = account, queue_name, %{
        "MessageId" => message_id,
        "PopReceipt" => pop_receipt
      }) do
    query = "#{queue_name}/messages/#{message_id}?popreceipt=#{pop_receipt}"

    account
    |> Request.delete(@storage_service, query)
  end

  @doc """
  The Get Messages operation retrieves one or more messages from the front of the queue.
  ref. https://docs.microsoft.com/en-us/rest/api/storageservices/get-messages
  """
  def get_messages(%Account{} = account, queue_name, options \\ []) do
    {:ok, opts} = NimbleOptions.validate(options, Schema.get_messages_options())
    number_of_messages = opts[:number_of_messages]
    visibility_timeout = opts[:visibility_timeout]

    query =
      "#{queue_name}/messages?visibilitytimeout=#{visibility_timeout}&numofmessages=#{
        number_of_messages
      }"

    account
    |> Request.get(@storage_service, query)
    |> parse_queue_messages_response()
  end

  defp parse_queue_message_response({:ok, %{"QueueMessagesList" => list}}) do
    case list == %{} do
      true ->
        {:ok, nil}

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
        items =
          case get_in(list, ["QueueMessage"]) do
            %{} = message -> [message]
            messages -> messages
          end

        {:ok, items}
    end
  end

  defp create_message_body_xml(message) do
    encoded_message = message |> Base.encode64()
    "<QueueMessage><MessageText>#{encoded_message}</MessageText></QueueMessage>"
  end
end
