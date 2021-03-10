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
end
