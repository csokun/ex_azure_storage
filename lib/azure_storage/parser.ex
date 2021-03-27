defmodule AzureStorage.Parser do
  def parse_enumeration_results({:error, reason}, _), do: {:error, reason}

  def parse_enumeration_results(
        {:ok,
         %{
           "EnumerationResults" => %{
             "#content" => content
           }
         }, _headers},
        prop
      ) do
    marker = get_in(content, ["NextMarker"])
    shares = get_in(content, ["#{prop}s", "#{prop}"])

    case is_map(marker) do
      true ->
        {:ok, %{Items: shares, NextMarker: nil}}

      _ ->
        {:ok, %{Items: shares, NextMarker: marker}}
    end
  end

  def parse_body_response({:ok, body, _}), do: {:ok, body}
  def parse_body_response({:error, reason}), do: {:error, reason}
end
