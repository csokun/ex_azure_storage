defmodule Az.QueryStringify do
  @typep options :: Keyword.t()

  @callback to_query_string(options) :: {:ok, String.t()}
end
