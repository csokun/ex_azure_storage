defmodule TestExAzureStorage do
  use ExUnit.Case
  alias AzureStorage.Blob

  @account_name Application.compile_env(:ex_azure_storage, :account_name, "")
  @account_key Application.compile_env(:ex_azure_storage, :account_key, "")
  @container "tmp"

  setup_all do
    {:ok, context} = AzureStorage.create_blob_service(@account_name, @account_key)
    %{context: context}
  end

  test "can paginate", %{context: context} do
    first_page = Blob.list_blobs(context, @container, maxresults: 1)
    {:ok, %{items: %{
      "Name" => name,
      "Properties" => properties
    }, marker: marker}} = first_page
    assert is_binary(name)
    assert is_map(properties)

    second_page = Blob.list_blobs(context, @container, marker: marker, maxresults: 1)
    {:ok, %{items: %{
      "Name" => name,
      "Properties" => properties
    }}} = second_page
    assert is_binary(name)
    assert is_map(properties)
  end
end
