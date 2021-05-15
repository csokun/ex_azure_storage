defmodule AzureStorage.BlobTest do
  use ExUnit.Case, async: true
  alias AzureStorage.Blob
  use ExVCR.Mock, adapter: ExVCR.Adapter.Hackney

  @account_name Application.get_env(:ex_azure_storage, :account_name, "")
  @account_key Application.get_env(:ex_azure_storage, :account_key, "")

  setup do
    ExVCR.Config.cassette_library_dir("fixture/azure_blob")
    {:ok, context} = AzureStorage.create_blob_service(@account_name, @account_key)
    %{context: context}
  end

  describe "list_containers" do
    test "it should be able to list blob containers", %{context: context} do
      use_cassette "list_containers" do
        assert {:ok, %{items: [_, _], marker: "/account-name/bookings"}} =
                 context |> Blob.list_containers(maxresults: 2)
      end
    end
  end

  describe "get_container_properties" do
    test "it should be able to get container properties", %{context: context} do
      use_cassette "get_container_properties" do
        assert {:ok, _} = context |> Blob.get_container_properties("bookings")
      end
    end
  end

  describe "leasing" do
    test "it should be able to acquire lease for a given blob", %{context: context} do
      use_cassette "acquire_lease_blob", match_requests_on: [:query] do
        filename = "hotel-room-a.json"

        context
        |> Blob.put_blob("bookings", filename, "{\"checkIn\": \"2021-01-01\"}")

        assert {:ok, lease} = context |> Blob.acquire_lease("bookings", filename)
        assert %{"ETag" => _, "lease_id" => _} = lease
      end
    end

    test "it should be able to release acquired lease", %{context: context} do
      use_cassette "lease_release", match_requests_on: [:query] do
        filename = "hotel-room-b.json"

        context
        |> Blob.put_blob("bookings", filename, "{\"checkIn\": \"2021-01-01\"}")

        assert {:ok, %{"lease_id" => lease_id}} =
                 context |> Blob.acquire_lease("bookings", filename)

        assert {:ok, _} = context |> Blob.lease_release("bookings", filename, lease_id)
      end
    end
  end

  describe "get_blob_content" do
    test "it should be able to get text blob content", %{context: context} do
      use_cassette "get_blob_content_txt" do
        # arrange
        content = "hello world"

        context
        |> Blob.put_blob("bookings", "text1.txt", content)

        assert {:ok, ^content} = context |> Blob.get_blob_content("bookings", "text1.txt")
      end
    end

    test "it should be able to get json blob content", %{context: context} do
      use_cassette "get_blob_content_json" do
        # arrange
        content = "{\"data\": []}"

        context
        |> Blob.put_blob("bookings", "cache-key-1.json", content,
          content_type: "application/json;charset=\"utf-8\""
        )

        assert {:ok, %{"data" => []}} =
                 context |> Blob.get_blob_content("bookings", "cache-key-1.json", json: true)
      end
    end
  end
end
