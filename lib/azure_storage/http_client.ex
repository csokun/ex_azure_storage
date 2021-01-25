defmodule Http.Client do
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

  defp process_response({:ok, %HTTPoison.Response{status_code: status_code, body: body}})
       when status_code in [200, 201, 204],
       do: {:ok, parse_body(body)}

  defp process_response({:ok, %HTTPoison.Response{status_code: status_code, body: body}}) do
    {
      :error,
      %{
        status_code: status_code,
        body: parse_body(body)
      }
    }
  end

  defp process_response({:error, %HTTPoison.Error{reason: {_, reason}}}),
    do: {:error, reason}

  defp process_response({:error, %HTTPoison.Error{reason: reason}}),
    do: {:error, reason}

  # defp process_response({:error, reason}), do: {:error, reason}

  defp parse_body(""), do: ""
  defp parse_body(body), do: XmlToMap.naive_map(body)
end
