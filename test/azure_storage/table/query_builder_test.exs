defmodule AzureStorage.Table.QueryBuilderTest do
  use ExUnit.Case, async: true
  alias AzureStorage.Table.Query
  import AzureStorage.Table.QueryBuilder

  setup do
    %{query: Query.table("Table1")}
  end

  describe "query builder" do
    test "it should be able to query string field", %{query: query} do
      assert %{filter: ["(F1%20eq%20'V1')"]} = query |> where("F1", :eq, "V1")
    end

    test "it should be able to query multiple fields", %{query: query} do
      assert %{
               filter: [
                 "and%20(F2%20eq%20datetime'2021-03-20 07:26:11.097457Z')",
                 "(F1%20eq%20'V1')"
               ]
             } =
               query
               |> where("F1", :eq, "V1")
               |> where("F2", :eq, ~U[2021-03-20T07:26:11.097457Z])
    end
  end
end
