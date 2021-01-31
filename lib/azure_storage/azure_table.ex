defmodule AzureStorage.Table do
  @moduledoc """
  Azure Table Service
  ref. https://docs.microsoft.com/en-us/rest/api/storageservices/table-service-rest-api
  """
  alias AzureStorage.Table.EntityDescriptor
  alias AzureStorage.Request.Context
  import AzureStorage.Request

  def retrieve_entity(%Context{service: "table"} = context, table_name, partition_key, row_key) do
    query =
      "#{table_name}(PartitionKey='#{partition_key}',RowKey='#{row_key}')"
      |> String.replace("'", "%27")

    context
    |> build(method: "GET", path: query)
    |> request()
  end

  @doc """
  Deletes an existing entity in a table.
  """
  def delete_entity(
        %Context{service: "table"} = context,
        table_name,
        partition_key,
        row_key,
        etag \\ "*"
      ) do
    query =
      "#{table_name}(PartitionKey='#{partition_key}',RowKey='#{row_key}')"
      |> String.replace("'", "%27")

    headers = [
      {:"if-match", etag}
    ]

    context
    |> build(method: "DELETE", path: query, headers: headers)
    |> request()
  end

  @doc """
  ref. https://docs.microsoft.com/en-us/rest/api/storageservices/insert-entity
  """
  def insert_entity(
        %Context{service: "table"} = context,
        table_name,
        %EntityDescriptor{} = entity_descriptor
      ) do
    query = "#{table_name}"
    body = entity_descriptor |> Jason.encode!()

    headers = [
      {:Prefer, "return-no-content"},
      {:"Content-Type", "application/json"}
    ]

    context
    |> build(method: "POST", path: query, body: body, headers: headers)
    |> request()
  end
end
