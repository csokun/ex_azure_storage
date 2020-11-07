defmodule AzureStorage.BlobTest do
  use ExUnit.Case, async: true
  alias AzureStorage.Blob
  import Mox

  setup :verify_on_exit!

  @account_name "sample"
  @account_key "ZHVtbXk="

  describe "list_containers" do
    test "it should be able to list blob containers" do
      HttpClientMock
      |> expect(:get, fn _url, _headers, _options ->
        {:error, "Not found"}
      end)

      result = Blob.list_containers(@account_name, @account_key)
      assert {:error, "Not found"} == result
    end
  end
end
