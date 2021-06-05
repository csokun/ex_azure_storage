defmodule AzureStorage.TableTest do
  use ExUnit.Case, async: true
  alias AzureStorage.Table.{Entity, EntityDescriptor, Query}
  alias AzureStorage.Table
  import AzureStorage.Table.EntityGenerator
  import AzureStorage.Table.QueryBuilder

  @account_name Application.get_env(:ex_azure_storage, :account_name, "")
  @account_key Application.get_env(:ex_azure_storage, :account_key, "")

  setup_all do
    table = "test"
    {:ok, context} = AzureStorage.create_table_service(@account_name, @account_key)
    # ignore error
    context |> AzureStorage.Table.create_table(table)
    %{context: context, table: table}
  end

  describe "retrieve_entity" do
    test "it should return entity when record found", %{context: context, table: table} do
      # arrange
      p_key = "retrieve_entity"
      r_key = UUID.uuid4()

      ed =
        %EntityDescriptor{}
        |> partition_key(p_key)
        |> row_key(r_key)
        |> string("Name", "Sokun Chorn")
        |> int32("Score", 2_000_000)
        |> boolean("Active", true)

      context |> Table.insert_entity(table, ed)

      # act & assertion
      assert {:ok, %EntityDescriptor{}} =
               context
               |> Table.retrieve_entity(table, p_key, r_key, as: :entity)
    end

    test "it should return error when record is not found", %{context: context, table: table} do
      # arrange
      p_key = UUID.uuid4()
      r_key = UUID.uuid4()

      assert {:error, "ResourceNotFound"} = context |> Table.retrieve_entity(table, p_key, r_key)
    end
  end

  describe "query_entities" do
    defp insert_entities(context, table, p_key) do
      ed =
        %EntityDescriptor{}
        |> partition_key(p_key)
        |> string("Name", UUID.uuid4())

      1..5
      |> Enum.each(fn i ->
        context |> Table.insert_entity(table, ed |> row_key("row_key_#{i}"))
      end)
    end

    test "it should be able to query entities", %{context: context, table: table} do
      # load data
      p_key = "query_entities"
      context |> insert_entities(table, p_key)

      query =
        Query.table(table)
        |> where("PartitionKey", :eq, p_key)
        |> top(1)

      # act & assert
      assert {:ok, [_], continuation_token} = context |> Table.query_entities(query)

      assert {:ok, [_], new_continuation_token} =
               context |> Table.query_entities(query, continuation_token: continuation_token)

      assert continuation_token != new_continuation_token
    end
  end

  describe "update_entity" do
    test "it should be able to update existing entity", %{context: context, table: table} do
      # arrange
      p_key = "update_entity_1"
      r_key = UUID.uuid4()

      ed =
        %EntityDescriptor{}
        |> partition_key(p_key)
        |> row_key(r_key)
        |> string("Name", "Linux")
        |> int32("Encoded", 42)

      {:ok, etag} = context |> Table.insert_entity(table, ed)

      ed2 =
        %EntityDescriptor{}
        |> partition_key(p_key)
        |> row_key(r_key)
        |> string("FirstName", "Sokun")

      ed2 = %{ed2 | ETag: Map.get(etag, "ETag")}
      assert {:ok, _} = context |> Table.update_entity(table, ed2)
    end

    test "it should not be able to update existing entity if etag mismatched", %{
      context: context,
      table: table
    } do
      # arrange
      p_key = "update_entity_2"

      ed =
        %EntityDescriptor{}
        |> partition_key(p_key)
        |> row_key("row_key_#{UUID.uuid4()}")
        |> string("Name", "Linux")
        |> int32("Encoded", 42)

      {:ok, _} = context |> Table.insert_entity(table, ed)

      ed2 = %{ed | ETag: "W/\"datetime'2021-04-03T04%3A24%3A09.6050786Z'\""}

      assert {:error, "UpdateConditionNotSatisfied"} = context |> Table.update_entity(table, ed2)
    end
  end

  describe "merge_entity" do
    test "it should be able to merge entity properties", %{context: context, table: table} do
      # arrange
      p_key = "merge_entity"
      r_key = UUID.uuid4()

      ed =
        %EntityDescriptor{}
        |> partition_key(p_key)
        |> row_key(r_key)
        |> string("Name", "Linux")
        |> int32("Encoded", 42)

      {:ok, etag} = context |> Table.insert_entity(table, ed)

      ed2 =
        %EntityDescriptor{}
        |> partition_key(p_key)
        |> row_key(r_key)
        |> string("FirstName", "Sokun")

      ed2 = %{ed2 | ETag: Map.get(etag, "ETag")}
      assert {:ok, _} = context |> Table.merge_entity(table, ed2)

      assert {:ok,
              %{
                Fields: %{
                  "Encoded" => %Entity{"$": "Edm.Int32", _: 42},
                  "FirstName" => %Entity{"$": "Edm.String", _: "Sokun"},
                  "Name" => %Entity{"$": "Edm.String", _: "Linux"}
                }
              }} =
               context
               |> Table.retrieve_entity(table, p_key, r_key, as: :entity)

      assert {
               :ok,
               %{
                 "Encoded" => 42,
                 "FirstName" => "Sokun",
                 "Name" => "Linux",
                 "PartitionKey" => ^p_key,
                 "RowKey" => ^r_key,
                 "Timestamp" => _,
                 "odata.etag" => _,
                 "odata.metadata" => _
               }
             } = context |> Table.retrieve_entity(table, p_key, r_key)
    end
  end

  describe "delete_entity" do
    test "it should be able to delete an entity", %{context: context, table: table} do
      # arrange
      p_key = "delete_entity"
      r_key = UUID.uuid4()

      ed =
        %EntityDescriptor{}
        |> partition_key(p_key)
        |> row_key(r_key)
        |> string("Name", "Linux")

      {:ok, etag} = context |> Table.insert_entity(table, ed)

      assert {:ok, ""} =
               context
               |> Table.delete_entity(table, p_key, r_key, Map.get(etag, "ETag"))
    end
  end
end
