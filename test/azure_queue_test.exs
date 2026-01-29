defmodule AzureStorage.QueueTest do
  use ExUnit.Case, async: true
  alias AzureStorage.Queue

  @account_name Application.compile_env(:ex_azure_storage, :account_name, "")
  @account_key Application.compile_env(:ex_azure_storage, :account_key, "")

  setup_all do
    {:ok, context} = AzureStorage.create_queue_service(@account_name, @account_key)
    %{context: context}
  end

  describe "get_messages" do
    test "it should return error QueueNotFound when queue container does not exist", %{
      context: context
    } do
      assert {:error, "QueueNotFound"} = context |> Queue.get_messages("unknownq")
    end

    test "it should return empty list when no queue item in the container", %{context: context} do
      # arrange
      queue_name = UUID.uuid4()
      context |> Queue.create_queue(queue_name)

      assert {:ok, []} = context |> Queue.get_messages(queue_name)
      context |> Queue.delete_queue(queue_name)
    end

    test "it should return queue items when queue container is not empty", %{
      context: context
    } do
      # arrange
      queue_name = UUID.uuid4()
      context |> Queue.create_queue(queue_name)

      1..5
      |> Enum.each(fn i ->
        context |> Queue.create_message(queue_name, "hello world! #{i}")
      end)

      assert {:ok,
              [
                %{
                  "DequeueCount" => "1",
                  "ExpirationTime" => _,
                  "InsertionTime" => _,
                  "MessageId" => _,
                  "MessageText" => _,
                  "PopReceipt" => _,
                  "TimeNextVisible" => _
                }
                | _
              ]} = context |> Queue.get_messages(queue_name, numofmessages: 2)

      context |> Queue.delete_queue(queue_name)
    end
  end

  describe "delete_message" do
    test "it should be able to delete message", %{context: context} do
      # arrange
      queue_name = UUID.uuid4()
      context |> Queue.create_queue(queue_name)
      context |> Queue.create_message(queue_name, "testing")
      {:ok, [message | _]} = context |> Queue.get_messages(queue_name)

      assert {:ok, ""} =
               context
               |> Queue.delete_message(queue_name, message)

      assert {:error, "MessageNotFound"} =
               context
               |> Queue.delete_message(queue_name, %{
                 "MessageId" => "bb3ab409-25b7-5db3-8b70-18e6a93561d1",
                 "PopReceipt" => "AgAAAAMAAAAAAAAAkanu8u4T1wE="
               })

      context |> Queue.delete_queue(queue_name)
    end
  end

  describe "update_message" do
    test "it should be able to update message", %{context: context} do
      # arrange
      queue_name = UUID.uuid4()
      context |> Queue.create_queue(queue_name)
      context |> Queue.create_message(queue_name, "testing")
      {:ok, [message | _]} = context |> Queue.get_messages(queue_name)
      text = "Hello World"

      assert {:ok, ""} = context |> Queue.update_message(queue_name, message, text)

      context |> Queue.delete_queue(queue_name)
    end
  end
end
