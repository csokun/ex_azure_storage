defmodule AzureStorage.Parser do
  @moduledoc false
  require Logger

  def parse_response_body_as_json(
        {:ok, %{status_code: status_code, body: body, headers: headers}}
      ) do
    content_type = get_content_type(headers)

    content =
      case {content_type, body} do
        {"application/json" <> _, _} ->
          case Jason.decode(body) do
            {:ok, json} -> json
            {:error, _} -> body
          end

        {"application/xml", _} ->
          XmlToMap.naive_map(body)

        _ ->
          body
      end

    case status_code in [200, 201, 202, 204] do
      true ->
        {:ok, content, headers}

      false ->
        parse_error_response(content)
    end
  end

  def parse_response_body_as_json({:error, _} = response), do: response

  def parse_enumeration_results(
        {:ok,
         %{
           "EnumerationResults" => %{
             "#content" => content
           }
         }, _},
        prop
      ) do
    marker = get_in(content, ["NextMarker"])
    shares = get_in(content, ["#{prop}s", "#{prop}"])

    case is_map(marker) do
      true ->
        {:ok, %{items: shares, marker: nil}}

      _ ->
        {:ok, %{items: shares, marker: marker}}
    end
  end

  def parse_enumeration_results(response), do: response

  def parse_body_response({:ok, body, _}), do: {:ok, body}
  def parse_body_response(response), do: response

  def parse_body_headers_response({:ok, body, headers}),
    do: {:ok, body, headers |> headers_to_attributes}

  def parse_body_headers_response(response), do: response

  def parse_continuation_token(headers) do
    continuation_headers =
      headers
      |> Enum.reduce([], fn {header_name, value}, acc ->
        case header_name do
          "x-ms-continuation-" <> prop ->
            acc ++ ["#{normalize_continuation_prop(prop)}=#{value}"]

          _ ->
            acc
        end
      end)

    case continuation_headers do
      [] -> nil
      _ -> Enum.join(continuation_headers, "&")
    end
  end

  # --- helpers
  defp get_content_type(headers) do
    case Enum.find(headers, fn {k, _} -> String.downcase(k) == "content-type" end) do
      {_, content_type} -> content_type
      _ -> ""
    end
  end

  defp parse_error_response(body) do
    case body do
      %{
        "Error" => %{
          "Code" => reason,
          "Message" => message,
          "AuthenticationErrorDetail" => detail
        }
      } ->
        Logger.debug("#{message}\n#{inspect(detail)}")
        {:error, reason}

      %{"Error" => %{"Code" => reason, "Message" => message}} ->
        Logger.debug(message)
        {:error, reason}

      %{"odata.error" => %{"code" => code}} ->
        {:error, code}

      response ->
        response |> IO.inspect()
        {:error, ""}
    end
  end

  defp normalize_continuation_prop(prop) do
    case prop do
      "nextpartitionkey" -> "NextPartitionKey"
      "nextrowkey" -> "NextRowKey"
      "nexttablename" -> "NextTableName"
      other -> other
    end
  end

  defp headers_to_attributes(headers) when is_list(headers) do
    headers
    |> Enum.filter(fn
      {"Content-" <> _, _} -> true
      {"ETag", _} -> true
      {"x-ms-" <> _, _} -> true
      _ -> false
    end)
    |> Enum.into(%{})
  end
end
