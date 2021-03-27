defmodule AzureStorage.Table do
  @moduledoc """
  Azure Table Service
  ref. https://docs.microsoft.com/en-us/rest/api/storageservices/table-service-rest-api
  """
  alias AzureStorage.Table.{EntityDescriptor, Query}
  alias AzureStorage.Request.Context
  import AzureStorage.Table.QueryBuilder
  import AzureStorage.Request
  import AzureStorage.Parser

  def retrieve_entity(%Context{service: "table"} = context, table_name, partition_key, row_key) do
    query =
      "#{table_name}(PartitionKey='#{partition_key}',RowKey='#{row_key}')"
      |> String.replace("'", "%27")

    context
    |> build(method: :get, path: query)
    |> request()
    |> parse_body_response()
  end

  def query_entities(%Context{service: "table"} = context, %Query{} = query) do
    odata_query = query |> compile()

    context
    |> build(method: :get, path: odata_query)
    |> request()
    |> parse_query_entities_response()
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
    |> build(method: :delete, path: query, headers: headers)
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
    |> build(method: :post, path: query, body: body, headers: headers)
    |> request()
  end

  defp parse_query_entities_response(
         {:ok, %{"odata.metadata" => _metadata, "value" => entities}, headers}
       ) do
    continuation_token = headers |> parse_continuation_token
    {:ok, entities, continuation_token}
  end

  defp parse_continuation_token(_headers) do
    nil
  end
end
