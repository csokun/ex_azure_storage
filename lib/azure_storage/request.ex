defmodule AzureStorage.Request do
  alias Http.Client
  @api_version "2019-07-07"
  @content_type "application/xml"

  def get(account_name, account_key, storage_service, query, options \\ []) do
    method = "GET"
    url = "https://#{account_name}.#{storage_service}.core.windows.net/#{query}"
    headers = setup_request_headers(account_name, account_key, method, query)
    Client.get(url, headers, options)
  end

  def put(account_name, account_key, storage_service, query) do
    put(account_name, account_key, storage_service, query, "", [])
  end

  def put(account_name, account_key, storage_service, query, body, options \\ []) do
    method = "PUT"
    url = "https://#{account_name}.#{storage_service}.core.windows.net/#{query}"

    content_length =
      case String.length(body) do
        0 -> ""
        len -> "#{len}"
      end

    headers = setup_request_headers(account_name, account_key, method, query, content_length)
    Client.put(url, body, headers, options)
  end

  def post(account_name, account_key, storage_service, query, body, options \\ []) do
    method = "POST"
    url = "https://#{account_name}.#{storage_service}.core.windows.net/#{query}"

    content_length =
      case String.length(body) do
        0 -> ""
        len -> "#{len}"
      end

    headers = setup_request_headers(account_name, account_key, method, query, content_length)
    Client.post(url, body, headers, options)
  end

  def delete(account_name, account_key, storage_service, query, options \\ []) do
    method = "DELETE"
    url = "https://#{account_name}.#{storage_service}.core.windows.net/#{query}"
    headers = setup_request_headers(account_name, account_key, method, query)
    Client.delete(url, headers, options)
  end

  defp setup_request_headers(account_name, account_key, method, query, content_length \\ "") do
    headers = generate_headers()
    canonical_headers = headers |> get_canonical_headers()

    canonical_resource = get_canonical_resource(account_name, query)

    # build sign payload
    headers_uri_str = "#{canonical_headers}\n#{canonical_resource}"
    data = "#{method}\n\n\n#{content_length}\n\n#{@content_type}\n\n\n\n\n\n\n#{headers_uri_str}"
    IO.inspect(data)

    key =
      account_key
      |> Base.decode64!()

    signature =
      :crypto.hmac(:sha256, key, data)
      |> Base.encode64()

    auth_key = {:Authorization, "SharedKey #{account_name}:#{signature}"}

    [auth_key | headers]
    # |> IO.inspect()
  end

  defp generate_headers() do
    [
      {:"x-ms-version", @api_version},
      {:"x-ms-date", get_date()},
      {:"Content-Type", @content_type}
    ]
  end

  defp get_date() do
    DateTime.utc_now()
    |> Calendar.strftime("%a, %d %b %Y %H:%M:%S GMT")

    # |> Timex.format!("{WDshort}, {D} {Mshort} {YYYY} {h24}:{m}:{s} GMT")
  end

  defp get_canonical_headers(headers) do
    headers
    |> Enum.into(%{})
    |> Enum.filter(fn {k, _} ->
      case Atom.to_string(k) do
        "x-ms-" <> _ -> true
        _ -> false
      end
    end)
    |> Enum.sort(:asc)
    # safeguard - remove \r\n from header value
    |> Enum.map(fn {k, v} -> "#{k}:#{v}" end)
    |> Enum.join("\n")
  end

  defp get_canonical_resource(account_name, query) do
    query_tokenize = query |> String.split("?")

    [container, query_string] =
      case length(query_tokenize) > 1 do
        true -> query_tokenize
        false -> ["", Enum.at(query_tokenize, 0)]
      end

    canonical =
      query_string
      |> String.split("&")
      |> Enum.sort(:asc)
      |> Enum.map(fn line -> String.replace(line, "=", ":") end)
      |> Enum.join("\n")

    case canonical == query_string do
      true -> "/#{account_name}/#{canonical}"
      false -> "/#{account_name}/#{container}\n#{canonical}"
    end
  end
end
