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

  test "can put blob", %{context: context} do
    uri = "file:///Users/bgoosman/git/elixir/ex_azure_storage/fixtures/2ZJG56HD3YEZGEQZL4RFOYNIMTZISHDX.pdf"
    ["file:", file_path] =  String.split(uri, "//")
    file = File.open!(file_path)
    content = IO.binread(file, :eof)
    [file_name | _] = file_path |> String.split("/") |> Enum.reverse()
    remote_file_path = "1000/#{file_name}"
    {:ok, _} = Blob.put_binary_blob(context, @container, remote_file_path, content)
  end
end
