defmodule AzureStorage.QueueTest do
  use ExUnit.Case, async: true
  alias AzureStorage.Queue
  use ExVCR.Mock, adapter: ExVCR.Adapter.Hackney

  @account_name Application.get_env(:ex_azure_storage, :account_name, "")
  @account_key Application.get_env(:ex_azure_storage, :account_key, "")

  setup do
    ExVCR.Config.cassette_library_dir("fixture/azure_queue")
    :ok
  end

  describe "get_messages" do
    setup do
      {:ok, context} = AzureStorage.create_queue_service(@account_name, @account_key)
      %{context: context}
    end

    test "it should return error QueueNotFound when queue container does not exist", %{
      context: context
    } do
      use_cassette "queue_get_messages_container_not_exist" do
        assert {:error, "QueueNotFound"} = context |> Queue.get_messages("unknownq")
      end
    end

    test "it should return empty list when no queue item in the container", %{context: context} do
      use_cassette "queue_get_messages_container_empty" do
        assert {:ok, []} = context |> Queue.get_messages("empty")
      end
    end

    test "it should return queue items when queue container is not empty", %{context: context} do
      use_cassette "queue_get_messages_has_items" do
        assert {:ok,
                [
                  %{
                    "DequeueCount" => "1",
                    "ExpirationTime" => "Mon, 15 Mar 2021 07:37:58 GMT",
                    "InsertionTime" => "Mon, 08 Mar 2021 07:37:58 GMT",
                    "MessageId" => "bb3ab409-25b7-4db3-8b70-18e6a93561d1",
                    "MessageText" => "dGVzdGluZyBtZXNzYWdl",
                    "PopReceipt" => "AgAAAAMAAAAAAAAAkanu8u4T1wE=",
                    "TimeNextVisible" => "Mon, 08 Mar 2021 07:45:02 GMT"
                  }
                  | _
                ]} = context |> Queue.get_messages("busyq", number_of_messages: 2)
      end
    end
  end

  describe "delete_message" do
    setup do
      {:ok, context} = AzureStorage.create_queue_service(@account_name, @account_key)
      %{context: context}
    end

    test "it should be able to delete message", %{context: context} do
      use_cassette "queue_delete_message" do
        assert {:ok, ""} =
                 context
                 |> Queue.delete_message("busyq", %{
                   "MessageId" => "bb3ab409-25b7-4db3-8b70-18e6a93561d1",
                   "PopReceipt" => "AgAAAAMAAAAAAAAAkanu8u4T1wE="
                 })
      end
    end

    test "it should return error if message not found", %{context: context} do
      use_cassette "queue_delete_message_not_found" do
        assert {:error, "MessageNotFound"} =
                 context
                 |> Queue.delete_message("busyq", %{
                   "MessageId" => "bb3ab409-25b7-5db3-8b70-18e6a93561d1",
                   "PopReceipt" => "AgAAAAMAAAAAAAAAkanu8u4T1wE="
                 })
      end
    end
  end
end
