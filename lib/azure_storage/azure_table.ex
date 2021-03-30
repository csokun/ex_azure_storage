defmodule AzureStorage.Table do
  @moduledoc """
  Azure Table Service

  ref. https://docs.microsoft.com/en-us/rest/api/storageservices/table-service-rest-api

  ```
  {:ok, context} = AzureStorage.create_table_service("account_name", "account_key")
  context |> retrieve_entity("partition_key_value", "row_key_value")
  ```
  """
  alias AzureStorage.Table.{EntityDescriptor, Query}
  alias AzureStorage.Request.Context
  import AzureStorage.Table.QueryBuilder
  import AzureStorage.Request
  import AzureStorage.Parser

  @doc """
  Retrieve an entity by PartitionKey and RowKey
  """
  def retrieve_entity(%Context{service: "table"} = context, table_name, partition_key, row_key) do
    query =
      "#{table_name}(PartitionKey='#{partition_key}',RowKey='#{row_key}')"
      |> String.replace("'", "%27")

    context
    |> build(method: :get, path: query)
    |> request()
    |> parse_body_response()
  end

  @doc """
  Query entities from a table storage
  """
  @spec query_entities(Context.t(), Query.t()) :: {:ok, list(), String.t()} | {:error, String.t()}
  def query_entities(%Context{service: "table"} = context, %Query{} = query),
    do: query_entities(context, query, nil)

  @doc """
  Query entities from a table storage with `continuation_token`.
  """
  @spec query_entities(Context.t(), Query.t(), String.t() | nil) ::
          {:ok, list(), String.t()} | {:error, String.t()}
  def query_entities(%Context{service: "table"} = context, %Query{} = query, continuation_token) do
    odata_query = query |> compile()

    path =
      case continuation_token do
        nil -> odata_query
        _ -> "#{odata_query}&#{continuation_token}"
      end

    context
    |> build(method: :get, path: path)
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
end
