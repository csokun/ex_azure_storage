defmodule AzureStorage.TableTest do
  use ExUnit.Case, async: true
  alias AzureStorage.Table.Query
  alias AzureStorage.Table
  import AzureStorage.Table.QueryBuilder
  use ExVCR.Mock, adapter: ExVCR.Adapter.Hackney

  @account_name Application.get_env(:ex_azure_storage, :account_name, "")
  @account_key Application.get_env(:ex_azure_storage, :account_key, "")

  setup do
    ExVCR.Config.cassette_library_dir("fixture/azure_table")
    {:ok, context} = AzureStorage.create_table_service(@account_name, @account_key)
    %{context: context}
  end

  describe "retrieve_entity" do
    test "it should return entity when record found", %{context: context} do
      use_cassette "retrieve_entity_when_exists" do
        assert {:ok,
                %{
                  "Active" => true,
                  "Name" => "Sokun Chorn",
                  "PartitionKey" => "partition_key_1",
                  "RowKey" => "row_key_1",
                  "Score" => 2_000_000,
                  "Timestamp" => "2021-02-22T10:18:17.5460809Z",
                  "odata.etag" => "W/\"datetime'2021-02-22T10%3A18%3A17.5460809Z'\"",
                  "odata.metadata" =>
                    "https://account-name.table.core.windows.net/$metadata#test/@Element"
                }} = context |> Table.retrieve_entity("test", "partition_key_1", "row_key_1")
      end
    end

    test "it should return error when record is not found", %{context: context} do
      use_cassette "retrieve_entity_non_exists" do
        assert {:error, "ResourceNotFound"} =
                 context |> Table.retrieve_entity("test", "partition_key_1", "row_key_2")
      end
    end
  end

  describe "query_entities" do
    test "it should be able to query entities", %{context: context} do
      use_cassette "query_entities_results" do
        query =
          Query.table("test")
          |> where("PartitionKey", :eq, "partition_key_1")
          |> top(1)

        assert {:ok, [_], continuation_token} = context |> Table.query_entities(query)

        assert "NextPartitionKey=1!20!cGFydGl0aW9uX2tleV8x&NextRowKey=1!12!cm93X2tleV8z" =
                 continuation_token
      end
    end

    test "it should be able to query entities with continuation_token", %{context: context} do
      use_cassette "query_entities_w_continuation_token_results" do
        query =
          Query.table("test")
          |> where("PartitionKey", :eq, "partition_key_1")
          |> top(1)

        continuation_token =
          "NextPartitionKey=1!20!cGFydGl0aW9uX2tleV8x&NextRowKey=1!12!cm93X2tleV8z"

        assert {:ok, [_], new_continuation_token} =
                 context |> Table.query_entities(query, continuation_token)

        assert "NextPartitionKey=1!20!cGFydGl0aW9uX2tleV8x&NextRowKey=1!12!cm93X2tleV80" =
                 new_continuation_token

        assert continuation_token != new_continuation_token
      end
    end
  end
end
