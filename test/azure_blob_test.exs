defmodule AzureStorage.BlobTest do
  use ExUnit.Case, async: true
  alias AzureStorage.Blob

  @account_name Application.get_env(:ex_azure_storage, :account_name, "")
  @account_key Application.get_env(:ex_azure_storage, :account_key, "")

  setup_all do
    container = "bookings"
    {:ok, context} = AzureStorage.create_blob_service(@account_name, @account_key)
    # ignore exists error
    context |> Blob.create_container(container)
    %{context: context, container: container}
  end

  describe "list_containers" do
    test "it should be able to list blob containers", %{context: context} do
      # arrange
      1..4
      |> Enum.each(fn i ->
        context |> Blob.create_container("container#{i}")
      end)

      assert {:ok, %{items: [_, _], marker: marker}} =
               context
               |> Blob.list_containers(maxresults: 2)

      assert marker != nil
    end
  end

  describe "get_container_properties" do
    test "it should be able to get container properties", %{
      context: context,
      container: container
    } do
      assert {:ok, _} = context |> Blob.get_container_properties(container)
    end
  end

  describe "leasing" do
    test "it should be able to acquire lease for a given blob", %{
      context: context,
      container: container
    } do
      filename = "room-#{UUID.uuid4()}.json"

      context
      |> Blob.put_blob("bookings", filename, "{\"checkIn\": \"2021-01-01\"}")

      assert {:ok, lease} = context |> Blob.acquire_lease(container, filename)
      assert %{"ETag" => _, "lease_id" => _} = lease
    end

    test "it should be able to release acquired lease", %{context: context, container: container} do
      filename = "room-#{UUID.uuid4()}.json"

      context
      |> Blob.put_blob("bookings", filename, "{\"checkIn\": \"2021-01-01\"}")

      assert {:ok, %{"lease_id" => lease_id}} = context |> Blob.acquire_lease(container, filename)

      assert {:ok, _} = context |> Blob.lease_release(container, filename, lease_id)
    end
  end

  describe "get_blob_content" do
    test "it should be able to get text blob content", %{context: context, container: container} do
      # arrange
      filename = "file-#{UUID.uuid4()}.txt"
      content = "hello world"

      context
      |> Blob.put_blob(container, filename, content)

      assert {:ok, ^content} = context |> Blob.get_blob_content(container, filename)
    end

    test "it should be able to get json blob content", %{context: context, container: container} do
      # arrange
      filename = "cache-#{UUID.uuid4()}.json"
      content = "{\"data\": []}"

      context
      |> Blob.put_blob(container, filename, content,
        content_type: "application/json;charset=\"utf-8\""
      )

      assert {:ok, %{"data" => []}} =
               context |> Blob.get_blob_content(container, filename, json: true)
    end
  end
end
