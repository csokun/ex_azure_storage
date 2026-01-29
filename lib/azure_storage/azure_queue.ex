defmodule AzureStorage.Queue do
  @moduledoc """
  Azure Queue Storage

  ref. https://docs.microsoft.com/en-us/rest/api/storageservices/queue-service-rest-api

  ```
  {:ok, context} = AzureStorage.create_queue_service("account_name", "account_key")
  context |> list_queues()
  ```
  """
  alias AzureStorage.Request.Context
  alias AzureStorage.Queue.Schema
  import AzureStorage.Request
  import AzureStorage.Parser

  @doc """
  This operation lists all of the queues in a given storage account.
  """
  @spec list_queues(Context.t()) ::
          {:ok, %{items: list() | [], marker: String.t() | nil}} | {:error, String.t()}
  def list_queues(%Context{service: "queue"} = context) do
    query = "?comp=list"

    context
    |> build(method: :get, path: query)
    |> request()
    |> parse_enumeration_results("Queue")
  end

  @doc """
  The Create Queue operation creates a queue in a storage account.

  ref. https://docs.microsoft.com/en-us/rest/api/storageservices/create-queue4

  ```
  context |> create_queue("booking-queue")
  ```
  """
  def create_queue(%Context{service: "queue"} = context, name) do
    query = name

    context
    |> build(method: :put, path: query)
    |> request()
    |> parse_body_response()
  end

  @doc """
  The Delete Queue operation permanently deletes the specified queue.

  ref. https://docs.microsoft.com/en-us/rest/api/storageservices/delete-queue3

  ```
  context |> delete_queue("booking-queue")
  ```
  """
  def delete_queue(%Context{service: "queue"} = context, name) do
    query = name

    context
    |> build(method: :delete, path: query)
    |> request()
    |> parse_body_response()
  end

  @doc """
  The Put Message operation adds a new message to the back of the message queue.

  A visibility timeout can also be specified to make the message invisible until the visibility timeout expires.
  A message must be in a format that can be included in an XML request with UTF-8 encoding.
  The encoded message can be up to 64 KiB in size for versions 2011-08-18 and newer, or 8 KiB in size for previous versions.

  ref. https://docs.microsoft.com/en-us/rest/api/storageservices/put-message

  ```
  context |> create_message("booking-queue", "hello world")
  ```
  """
  def create_message(%Context{service: "queue"} = context, queue_name, text, options \\ []) do
    {:ok, opts} = NimbleOptions.validate(options, Schema.create_message_options())
    filtered_opts = Enum.reject(opts, fn {_key, value} -> is_nil(value) end)
    query = "#{queue_name}/messages?#{encode_query(filtered_opts)}"

    context
    |> build(method: :post, path: query, body: create_message_body_xml(text))
    |> request()
    |> parse_queue_message_response()
  end

  @doc """
  Update queue item commonly use for updating queue item visibility timeout as well as queue message body

  ```
  {:ok, messages} = context |> get_messages("booking-queue")
  [head | tail] = messages

  context |> update_message("booking-queue", head, "hello world!")
  ```

  Supported options: \n#{NimbleOptions.docs(Schema.create_message_options())}
  """
  def update_message(
        %Context{service: "queue"} = context,
        queue_name,
        %{"MessageId" => message_id, "PopReceipt" => pop_receipt},
        text,
        options \\ []
      ) do
    {:ok, opts} = NimbleOptions.validate(options, Schema.update_message_options())
    query = build_message_path(queue_name, message_id, pop_receipt, opts)

    context
    |> build(method: :put, path: query, body: create_message_body_xml(text))
    |> request()
    |> parse_body_response()
  end

  @doc """
  Azure Queue items can be retrieve by calling `get_messages/3`.

  However, queue items are not remove from storage. Therefore, client need to send request to delete queue item when it is done processing.
  """
  def delete_message(%Context{service: "queue"} = context, queue_name, %{
        "MessageId" => message_id,
        "PopReceipt" => pop_receipt
      }) do
    query = build_message_path(queue_name, message_id, pop_receipt)

    context
    |> build(method: :delete, path: query)
    |> request()
    |> parse_body_response()
  end

  @doc """
  The Get Messages operation retrieves one or more messages from the front of the queue.

  ref. https://docs.microsoft.com/en-us/rest/api/storageservices/get-messages

  Supported options: \n#{NimbleOptions.docs(Schema.get_messages_options())}
  """
  @spec get_messages(Context.t(), String.t(), keyword()) ::
          {:ok, list() | []} | {:error, String.t()}
  def get_messages(%Context{service: "queue"} = context, queue_name, options \\ []) do
    {:ok, opts} = NimbleOptions.validate(options, Schema.get_messages_options())
    query = "#{queue_name}/messages?#{encode_query(opts)}"

    context
    |> build(method: :get, path: query)
    |> request()
    |> parse_queue_messages_response()
  end

  #
  # Helpers
  #

  defp parse_queue_message_response({:error, _} = response), do: response

  defp parse_queue_message_response({:ok, %{"QueueMessagesList" => list}, _headers}) do
    case list == %{} do
      true ->
        {:ok, nil}

      _ ->
        message = get_in(list, ["QueueMessage"])
        {:ok, %{message: message}}
    end
  end

  defp parse_queue_messages_response({:error, _} = response), do: response

  defp parse_queue_messages_response({:ok, %{"QueueMessagesList" => list}, _headers}) do
    case list == nil do
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

  defp build_message_path(queue_name, message_id, pop_receipt, options \\ []) do
    query_params =
      options
      |> Enum.reject(fn {_key, value} -> is_nil(value) end)
      |> Keyword.put(:popreceipt, pop_receipt)
      |> encode_query()

    "#{queue_name}/messages/#{message_id}?#{query_params}"
  end

  defp create_message_body_xml(message) do
    encoded_message = message |> Base.encode64()
    "<QueueMessage><MessageText>#{encoded_message}</MessageText></QueueMessage>"
  end
end
