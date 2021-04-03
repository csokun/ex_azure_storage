defmodule AzureStorage.Table do
  @moduledoc """
  Azure Table Service

  ref. https://docs.microsoft.com/en-us/rest/api/storageservices/table-service-rest-api

  ```
  {:ok, context} = AzureStorage.create_table_service("account_name", "account_key")
  context |> retrieve_entity("partition_key_value", "row_key_value")
  ```
  """
  alias AzureStorage.Table.{EntityDescriptor, Query, Entity}
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
  The Insert Entity operation inserts a new entity into a table.

  ref. https://docs.microsoft.com/en-us/rest/api/storageservices/insert-entity

  ```
  alias AzureStorage.Table.EntityDescriptor
  import AzureStorage.Table.EntityGenerator

  entity = %EntityDescriptor{}
    |> partition_key("partition_key_1")
    |> row_key("row_key_1")
    |> string("Message", "Hello World")

  context |> AzureStorage.Table.insert_entity("table1", entity)
  ```
  """
  @spec insert_entity(Context.t(), String.t(), EntityDescriptor.t()) ::
          {:ok, EntityDescriptor.t()} | {:error, String.t()}
  def insert_entity(
        %Context{service: "table"} = context,
        table_name,
        %EntityDescriptor{} = entity_descriptor
      ) do
    query = "#{table_name}"
    body = entity_descriptor |> Jason.encode!()

    headers = %{
      "Prefer" => "return-no-content",
      :"Content-Type" => "application/json"
    }

    context
    |> build(method: :post, path: query, body: body, headers: headers)
    |> request()
    |> parse_entity_change_response()
  end

  @doc """
  The Update Entity operation updates an existing entity in a table.

  The Update Entity operation replaces the entire entity and can be used to remove properties.
  """
  def update_entity(
        %Context{service: "table"} = context,
        table_name,
        %EntityDescriptor{ETag: etag} = entity_descriptor
      ) do
    keys = entity_descriptor |> get_entity_keys()
    query = "#{table_name}(#{keys})"
    body = entity_descriptor |> Jason.encode!()

    # conditional update
    if_match =
      case etag do
        nil -> "*"
        _ -> etag
      end

    headers = %{
      "Prefer" => "return-no-content",
      :"Content-Type" => "application/json",
      "If-Match" => if_match
    }

    context
    |> build(method: :put, path: query, body: body, headers: headers)
    |> request()
    |> parse_entity_change_response()
  end

  def merge_entity(
        %Context{service: "table"} = context,
        table_name,
        %EntityDescriptor{ETag: etag} = entity_descriptor
      ) do
    keys = entity_descriptor |> get_entity_keys()
    query = "#{table_name}(#{keys})"
    body = entity_descriptor |> Jason.encode!()

    # conditional update
    if_match =
      case etag do
        nil -> "*"
        _ -> etag
      end

    headers = %{
      "Prefer" => "return-no-content",
      :"Content-Type" => "application/json",
      "If-Match" => if_match
    }

    context
    |> build(method: :merge, path: query, body: body, headers: headers)
    |> request()
    |> parse_entity_change_response()
  end

  # ------------ helpers

  defp parse_query_entities_response(
         {:ok, %{"odata.metadata" => _metadata, "value" => entities}, headers}
       ) do
    continuation_token = headers |> parse_continuation_token
    {:ok, entities, continuation_token}
  end

  defp parse_entity_change_response({:ok, _, headers}) do
    headers
    |> Enum.find(fn
      {"ETag", _} -> true
      _ -> false
    end)
    |> case do
      nil -> {:ok, nil}
      {"ETag", etag} -> {:ok, %{"ETag" => etag}}
    end
  end

  defp parse_entity_change_response({:error, reason}), do: {:error, reason}

  defp get_entity_keys(%EntityDescriptor{} = entity_descriptor) do
    entity_descriptor
    |> Map.take([:PartitionKey, :RowKey])
    |> Map.to_list()
    |> Enum.map(fn {key, %Entity{_: value}} -> "#{key}=%27#{value}%27" end)
    |> Enum.join(",")
  end
end
