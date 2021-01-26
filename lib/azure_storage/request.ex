defmodule AzureStorage.Request do
  alias AzureStorage.Core.Account
  alias Http.Client
  @api_version "2019-07-07"
  @content_type "application/xml"

  def get(
        %Account{name: account_name} = account,
        storage_service,
        query,
        options \\ []
      ) do
    method = "GET"
    url = "https://#{account_name}.#{storage_service}.core.windows.net/#{query}"
    headers = account |> setup_request_headers(storage_service, method, query)
    Client.get(url, headers, options)
  end

  def put(%Account{} = account, storage_service, query) do
    put(account, storage_service, query, "", [])
  end

  def put(
        %Account{name: account_name} = account,
        storage_service,
        query,
        body,
        options \\ []
      ) do
    method = "PUT"
    url = "https://#{account_name}.#{storage_service}.core.windows.net/#{query}"

    content_length =
      case String.length(body) do
        0 -> ""
        len -> "#{len}"
      end

    headers = account |> setup_request_headers(storage_service, method, query, content_length)
    Client.put(url, body, headers, options)
  end

  def post(%Account{name: account_name} = account, storage_service, query, body, options \\ []) do
    method = "POST"
    url = "https://#{account_name}.#{storage_service}.core.windows.net/#{query}"

    content_length =
      case String.length(body) do
        0 -> ""
        len -> "#{len}"
      end

    headers = account |> setup_request_headers(storage_service, method, query, content_length)
    Client.post(url, body, headers, options)
  end

  def delete(%Account{name: account_name} = account, storage_service, query, options \\ []) do
    method = "DELETE"
    url = "https://#{account_name}.#{storage_service}.core.windows.net/#{query}"
    headers = account |> setup_request_headers(storage_service, method, query)
    Client.delete(url, headers, options)
  end

  # -------------------- helpers -----------------------

  defp setup_request_headers(
         %Account{name: account_name, key: account_key},
         storage_service,
         method,
         query,
         content_length \\ ""
       ) do
    headers = generate_headers(storage_service)
    canonical_headers = headers |> get_canonical_headers()

    canonical_resource = get_canonical_resource(storage_service, account_name, query)

    # build sign payload
    now = get_date()

    data =
      case storage_service do
        "table" ->
          "#{method}\n\n\n#{now}\n#{canonical_resource}"

        _ ->
          headers_uri_str = "#{canonical_headers}\n#{canonical_resource}"
          "#{method}\n\n\n#{content_length}\n\n#{@content_type}\n\n\n\n\n\n\n#{headers_uri_str}"
      end

    # table
    headers =
      headers ++
        [
          {:"x-ms-version", "2018-03-28"},
          {:"x-ms-date", now}
        ]

    key =
      account_key
      |> Base.decode64!()

    signature =
      :crypto.hmac(:sha256, key, data)
      |> Base.encode64()

    auth_key = {:authorization, "SharedKey #{account_name}:#{signature}"}

    [auth_key | headers]
  end

  defp generate_headers("table") do
    [
      {:accept, "application/json;odata=minimalmetadata"},
      {:dataserviceversion, "3.0;NetFx"}
    ]
  end

  defp generate_headers(_) do
    [
      {:"x-ms-version", @api_version},
      {:"x-ms-date", get_date()},
      {:"Content-Type", @content_type}
    ]
  end

  defp get_date() do
    DateTime.utc_now()
    |> Calendar.strftime("%a, %d %b %Y %H:%M:%S GMT")
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

  defp get_canonical_resource("table", account_name, query) do
    "/#{account_name}/#{query}"
  end

  defp get_canonical_resource(_, account_name, query) do
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

    IO.puts("#{canonical} - #{query_string}")

    case canonical == query_string do
      true -> "/#{account_name}/#{canonical}"
      false -> "/#{account_name}/#{container}\n#{canonical}"
    end
  end
end
