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

  test "can put binary blob 1", %{context: context} do
    file_path = "fixtures/MYKPH7XVYJANM6NEUFMBWLHISDBHMI2C.pdf"
    put_binary_blob(file_path, context)
  end

  test "can put binary blob 2", %{context: context} do
    file_path = "fixtures/2ZJG56HD3YEZGEQZL4RFOYNIMTZISHDX.pdf"
    put_binary_blob(file_path, context)
  end

  test "can put binary blob 3", %{context: context} do
    file_path = "fixtures/2WE4HZPD57KVPL4RQKCB4PUG42SQ2RMJ.pdf"
    put_binary_blob(file_path, context)
  end

  defp put_binary_blob(file_path, context) do
    file = File.open!(file_path)
    content = IO.binread(file, :eof)
    [file_name | _] = file_path |> String.split("/") |> Enum.reverse()
    remote_file_path = "test/#{file_name}"
    {:ok, _} = Blob.put_binary_blob(context, @container, remote_file_path, content)
  end
end
