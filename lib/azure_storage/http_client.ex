defmodule Http.Client do
  @moduledoc false
  require Logger

  def http_adapter, do: Application.get_env(:ex_azure_storage, :http_adapter, HTTPoison)

  def request(method, url, body, headers, options) do
    http_options = get_http_request_options(options)

    http_adapter().request(method, url, body, headers, http_options)
    |> process_response
  end

  defp process_response(
         {:ok, %HTTPoison.Response{status_code: status_code, body: body, headers: headers}}
       ),
       do: {:ok, %{body: body, headers: headers, status_code: status_code}}

  defp process_response({:error, %HTTPoison.Error{reason: {_, reason}}}),
    do: {:error, reason}

  defp process_response({:error, %HTTPoison.Error{reason: reason}}),
    do: {:error, reason}

  defp get_http_request_options(options) do
    # not a good idea ref. https://github.com/edgurgel/httpoison/issues/381
    # tls issue resolved by: mix deps.update certifi
    # default_options = [ssl: [versions: [:"tlsv1.2"]]]
    default_options = []
    Keyword.merge(default_options, options)
  end
end
