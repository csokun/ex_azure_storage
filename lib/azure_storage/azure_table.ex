defmodule AzureStorage.Table do
  alias AzureStorage.Core.Account
  alias AzureStorage.Request

  @storage_service "table"

  def retrieve_entity(%Account{} = account, table_name, partition_key, row_key) do
    query =
      "#{table_name}(PartitionKey='#{partition_key}',RowKey='#{row_key}')"
      |> String.replace("'", "%27")

    account
    |> Request.get(@storage_service, query)
  end

  def insert_entity(%Account{} = account, table_name, entity_descriptor \\ %{}) do
    # make sure entity has partition key & row key
    get_in(entity_descriptor, [:PartitionKey, :_])

    account
  end
end
