defmodule AzureStorageTest do
  use ExUnit.Case

  alias AzureStorage.Request.Context
  alias AzureStorage.Core.Account

  # doctest Az

  @account_name "sample"
  @account_key "ZHVtbXk="
  @generic_headers [{"x-ms-version", "2019-07-07"}, {:"Content-Type", "application/xml"}]

  describe "create blob service" do
    setup do
      {:ok, context} = AzureStorage.create_blob_service(@account_name, @account_key)
      %{context: context}
    end

    test "default blob service context", %{context: context} do
      assert %Context{
               account: %Account{name: @account_name, key: @account_key},
               service: "blob",
               headers: @generic_headers,
               url: "https://sample.blob.core.windows.net",
               base_url: "https://sample.blob.core.windows.net",
               path: ""
             } = context
    end

    test "clone blob service context", %{context: context} do
      %Context{
        headers: headers,
        url: url,
        path: path
      } = context |> Context.clone("GET", "?comp=list")

      assert "https://sample.blob.core.windows.net/?comp=list" = url
      assert "?comp=list" = path
      assert {"x-ms-date", _} = headers |> Enum.find(fn {"x-ms-date", _} -> true end)
    end
  end

  describe "create table service" do
    @table_service_default_headers [
      {"x-ms-version", "2019-07-07"},
      {:accept, "application/json;odata=minimalmetadata"},
      {:dataserviceversion, "3.0;NetFx"}
    ]

    setup do
      {:ok, context} = AzureStorage.create_table_service(@account_name, @account_key)
      %{context: context}
    end

    test "create table service context", %{context: context} do
      assert %Context{
               account: %Account{name: @account_name, key: @account_key},
               service: "table",
               headers: @table_service_default_headers,
               url: "https://sample.table.core.windows.net",
               base_url: "https://sample.table.core.windows.net",
               path: ""
             } = context
    end
  end
end
