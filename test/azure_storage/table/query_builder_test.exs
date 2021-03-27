defmodule AzureStorage.Table.QueryBuilderTest do
  use ExUnit.Case, async: true
  alias AzureStorage.Table.Query
  import AzureStorage.Table.QueryBuilder

  @table "Table1"

  setup do
    %{query: Query.table(@table)}
  end

  describe "filter" do
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

  describe "compile" do
    test "it should be able to build query from filter expression", %{query: query} do
      assert "#{@table}?$filter=(F1%20ne%20'V1')%20or%20(F2%20eq%202)&$top=1000" =
               query
               |> where("F1", :ne, "V1")
               |> or_where("F2", :eq, 2)
               |> compile()
    end
  end
end
