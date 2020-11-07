defmodule AzureStorage.Queue do
  alias AzureStorage.Request
  import AzureStorage.Parser

  @storage_service "queue"

  def list_queues(account_name, account_key) do
    query = "?comp=list"

    Request.get(account_name, account_key, @storage_service, query)
    |> parse_enumeration_results("Queue")
  end

  def create_message(account_name, account_key, query_name, message) do
    # default 7 days
    message_ttl = 7 * 24 * 60 * 60 * 60
    query = "#{query_name}/messages?visibilitytimeout=0&message_ttl=#{message_ttl}"
    encoded_message = message |> Base.encode64()
    body = "<QueueMessage><MessageText>#{encoded_message}</MessageText></QueueMessage>"

    Request.post(account_name, account_key, @storage_service, query, body)
    |> parse_queue_message_response()
  end

  def get_messages(account_name, account_key, queue_name) do
    query = "#{queue_name}/messages?visibilitytimeout=30&numofmessages=2"

    Request.get(account_name, account_key, @storage_service, query)
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
