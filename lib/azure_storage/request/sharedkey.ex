defmodule AzureStorage.Request.SharedKey do
  alias AzureStorage.Request.Context

  def sign_request(
        %Context{service: service, account: %{name: account_name, key: account_key}} = context
      ) do
    data =
      case service do
        "table" -> context |> table_service_request()
        _ -> context |> generic_service_request()
      end

    signature = sign(account_key, data)

    [{:authorization, "SharedKey: #{account_name}:#{signature}"}]
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

    "#{method}\n\n#{content_type}\n#{headers[:"x-ms-date"]}\n#{canonical_resource}"
  end

  defp generic_service_request(%Context{method: method, headers: headers} = context) do
    canonical_resource = context |> Context.get_canonical_resource()
    canonical_headers = context |> Context.get_canonical_headers()
    headers_uri_str = "#{canonical_headers}\n#{canonical_resource}"
    content_length = headers |> get_content_length()
    content_type = headers |> get_content_type()

    "#{method}\n\n\n#{content_length}\n\n#{content_type}\n\n\n\n\n\n\n#{headers_uri_str}"
  end

  defp get_content_length(headers) do
    case headers[:"content-length"] do
      nil -> ""
      value -> "#{value}"
    end
  end

  defp get_content_type(headers) do
    case headers[:"Content-Type"] do
      nil -> ""
      value -> "#{value}"
    end
  end
end
