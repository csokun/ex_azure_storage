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
        assert {:ok, %{Items: [_, _], NextMarker: "/account-name/bookings"}} =
                 context |> Blob.list_containers(max_results: 2)
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

  describe "acquire lease" do
    test "it should be able to acquire lease for a given blob", %{context: context} do
      use_cassette "acquire_lease_blob" do
        # arrange
        # TODO: for some reason ExVCR can't capture second PUT request,
        # comment arrange step until figure out what wrong
        # context
        # |> Blob.create_blob("bookings", "hotel-room-a.json", "{\"checkIn\": \"2021-01-01\"}")

        assert {:ok, lease} = context |> Blob.acquire_lease("bookings", "hotel-room-a.json")
        assert %{"ETag" => _, "lease_id" => _} = lease
      end
    end
  end
end
