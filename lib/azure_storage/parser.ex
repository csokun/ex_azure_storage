defmodule AzureStorage.Parser do
  @moduledoc false
  require Logger

  def parse_response_body_as_json(
        {:ok, %{status_code: status_code, body: body, headers: headers}}
      ) do
    content_type = get_content_type(headers)

    content =
      case content_type do
        "application/json" <> _ -> Jason.decode!(body)
        "application/xml" -> XmlToMap.naive_map(body)
        _ -> body
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
        {:ok, %{Items: shares, NextMarker: nil}}

      _ ->
        {:ok, %{Items: shares, NextMarker: marker}}
    end
  end

  def parse_enumeration_results(response), do: response

  def parse_body_response({:ok, body, _}), do: {:ok, body}
  def parse_body_response(response), do: response

  def parse_continuation_token(headers) do
    continuation_headers =
      headers
      |> Enum.filter(fn
        {"x-ms-continuation-" <> _, _} -> true
        _ -> false
      end)
      |> Enum.map(fn {"x-ms-continuation-" <> prop, value} -> "#{prop}=#{value}" end)

    case length(continuation_headers) do
      0 -> nil
      _ -> continuation_headers |> Enum.join("&")
    end
  end

  # --- helpers
  defp get_content_type(headers) do
    case Enum.find(headers, fn {k, _} -> k == "Content-Type" end) do
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
end
