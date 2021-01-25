defmodule AzureStorage.BlobTest do
  use ExUnit.Case, async: true
  alias AzureStorage.Core.Account
  alias AzureStorage.Blob
  import Mox

  setup :verify_on_exit!

  @account_name "sample"
  @account_key "ZHVtbXk="

  describe "list_containers" do
    setup do
      {:ok, account} = Account.new(@account_name, @account_key)
      %{account: account}
    end

    test "it should be able to list blob containers", %{account: account} do
      HttpClientMock
      |> expect(:get, fn _url, _headers, _options ->
        {:error, %HTTPoison.Error{reason: "Not found"}}
      end)

      result = account |> Blob.list_containers()
      assert {:error, "Not found"} == result
    end
  end
end
