defmodule AzureStorage.Request.SharedKey do
  @moduledoc false
  require Logger
  alias AzureStorage.Request.Context

  def sign_request(
        %Context{
          service: service,
          headers: headers,
          account: %{name: account_name, key: account_key}
        } = context
      ) do
    data =
      case service do
        "table" -> context |> table_service_request()
        _ -> context |> generic_service_request()
      end

    signature = sign(account_key, data)
    auth_key = %{"authorization" => "SharedKey #{account_name}:#{signature}"}

    headers =
      headers
      |> Map.merge(auth_key)
      |> Map.to_list()
      |> Enum.filter(fn
        {_, ""} -> false
        _ -> true
      end)

    Logger.debug(
      "data: #{inspect(data)}\nsignature: #{inspect(auth_key)}\nheaders: #{inspect(headers)}"
    )

    headers
  end

  #
  # helpers
  #

  defp sign(account_key, data) do
    key =
      account_key
      |> Base.decode64!()

    :crypto.hmac(:sha256, key, data)
    |> Base.encode64()
  end

  defp table_service_request(%Context{headers: headers, method: method} = context) do
    canonical_resource = context |> Context.get_canonical_resource()
    content_type = headers |> get_content_type()

    [
      method_atom_to_string(method),
      "\n",
      "\n",
      content_type,
      "\n",
      headers[:"x-ms-date"],
      "\n",
      canonical_resource
    ]
    |> IO.iodata_to_binary()
  end

  defp generic_service_request(%Context{method: method, headers: headers} = context) do
    canonical_resource = context |> Context.get_canonical_resource()
    canonical_headers = context |> Context.get_canonical_headers()
    headers_uri_str = "#{canonical_headers}\n#{canonical_resource}"
    content_length = headers |> get_content_length()
    content_type = headers |> get_content_type()

    [
      method_atom_to_string(method),
      "\n",
      "\n",
      "\n",
      content_length,
      "\n",
      "\n",
      content_type,
      "\n",
      "\n",
      "\n",
      "\n",
      "\n",
      "\n",
      "\n",
      headers_uri_str
    ]
    |> IO.iodata_to_binary()
  end

  defp method_atom_to_string(method), do: method |> Atom.to_string() |> String.upcase()

  defp get_content_length(headers) do
    Map.get(headers, :"content-length", "")
  end

  defp get_content_type(headers) do
    Map.get(headers, :"Content-Type", "")
  end
end
