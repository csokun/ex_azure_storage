defmodule ListBlobsTest do
  use ExUnit.Case
  alias AzureStorage.Blob

  @account_name Application.compile_env(:ex_azure_storage, :account_name, "")
  @account_key Application.compile_env(:ex_azure_storage, :account_key, "")
  @container "tmp"
  @blob_prefix "list-blobs-tests"
  @fixture_files [
    "fixtures/2WE4HZPD57KVPL4RQKCB4PUG42SQ2RMJ.pdf",
    "fixtures/2ZJG56HD3YEZGEQZL4RFOYNIMTZISHDX.pdf"
  ]

  setup_all do
    {:ok, context} = AzureStorage.create_blob_service(@account_name, @account_key)
    ensure_container(context)
    seed_container(context)
    %{context: context}
  end

  test "can paginate", %{context: context} do
    assert {:ok, %{items: first_items, marker: marker}} =
             Blob.list_blobs(context, @container, prefix: @blob_prefix, maxresults: 1)

    assert_blob_shape(first_items)

    assert {:ok, %{items: second_items}} =
             Blob.list_blobs(context, @container,
               marker: marker,
               prefix: @blob_prefix,
               maxresults: 1
             )

    assert_blob_shape(second_items)
  end

  defp ensure_container(context) do
    case Blob.create_container(context, @container) do
      {:ok, _} -> :ok
      {:error, "ContainerAlreadyExists"} -> :ok
      {:error, reason} -> flunk("failed to create container: #{reason}")
    end
  end

  defp seed_container(context) do
    Enum.each(@fixture_files, fn file_path ->
      put_fixture_blob(context, file_path)
    end)
  end

  defp put_fixture_blob(context, file_path) do
    blob_name = Path.join(@blob_prefix, Path.basename(file_path))
    contents = File.read!(file_path)

    case Blob.put_binary_blob(context, @container, blob_name, contents) do
      {:ok, _} -> :ok
      {:error, "BlobAlreadyExists"} -> :ok
      {:error, reason} -> flunk("failed to seed blob #{blob_name}: #{reason}")
    end
  end

  defp assert_blob_shape(items) do
    blob =
      case items do
        [%{} = first | _] -> first
        %{} = single -> single
      end

    assert is_binary(blob["Name"])
    assert is_map(blob["Properties"])
  end
end
