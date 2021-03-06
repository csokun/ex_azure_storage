defmodule Http.Client do
  require Logger

  @moduledoc """
  HTTP Client
  """
  def http_adapter, do: Application.get_env(:ex_azure_storage, :http_adapter, HTTPoison)

  @spec get(any, any, any) :: {:error, any} | {:ok, any}
  def get(url, headers, options) do
    http_adapter().get(url, headers, options)
    |> process_response()
  end

  def put(url, body, headers, options) do
    http_adapter().put(url, body, headers, options)
    |> process_response()
  end

  def post(url, body, headers, options) do
    http_adapter().post(url, body, headers, options)
    |> process_response()
  end

  def delete(url, headers, options) do
    http_adapter().delete(url, headers, options)
    |> process_response()
  end

  defp process_response(
         {:ok, %HTTPoison.Response{status_code: status_code, body: body, headers: headers}}
       )
       when status_code in [200, 201, 202, 204],
       do: {:ok, parse_body(get_content_type(headers), body)}

  defp process_response(
         {:ok, %HTTPoison.Response{status_code: _status, body: body, headers: headers}}
       ) do
    case parse_body(get_content_type(headers), body) do
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

  defp process_response({:error, %HTTPoison.Error{reason: {_, reason}}}),
    do: {:error, reason}

  defp process_response({:error, %HTTPoison.Error{reason: reason}}),
    do: {:error, reason}

  # defp process_response({:error, reason}), do: {:error, reason}

  defp parse_body("", ""), do: ""
  defp parse_body("application/json" <> _, body), do: Jason.decode!(body)
  defp parse_body(_, body), do: XmlToMap.naive_map(body)

  defp get_content_type(headers) do
    case Enum.find(headers, fn {k, _} -> k == "Content-Type" end) do
      {_, content_type} -> content_type
      _ -> ""
    end
  end
end
