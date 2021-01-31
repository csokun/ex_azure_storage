defmodule AzureStorage.BlobTest do
  use ExUnit.Case, async: true
  alias AzureStorage.Blob
  import Mox

  setup :verify_on_exit!

  @account_name "sample"
  @account_key "ZHVtbXk="

  describe "list_containers" do
    setup do
      {:ok, context} = AzureStorage.create_blob_service(@account_name, @account_key)
      %{context: context}
    end

    test "it should be able to list blob containers", %{context: context} do
      HttpClientMock
      |> expect(:get, fn "https://#{@account_name}.blob.core.windows.net/?comp=list",
                         _headers,
                         _options ->
        {:error, %HTTPoison.Error{reason: "Not found"}}
      end)

      result = context |> Blob.list_containers()
      assert {:error, "Not found"} == result
    end
  end
end
