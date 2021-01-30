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
    headers = account |> build_request_headers(storage_service, method, query, options)
    Client.get(url, headers, [])
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

    headers =
      account
      |> build_request_headers(
        storage_service,
        method,
        query,
        content_length_header(body) ++ options
      )

    Client.put(url, body, headers, [])
  end

  def post(%Account{name: account_name} = account, storage_service, query, body, options \\ []) do
    method = "POST"
    url = "https://#{account_name}.#{storage_service}.core.windows.net/#{query}"

    headers =
      account
      |> build_request_headers(
        storage_service,
        method,
        query,
        content_length_header(body) ++ options
      )

    Client.post(url, body, headers, [])
  end

  def delete(%Account{name: account_name} = account, storage_service, query, options \\ []) do
    method = "DELETE"
    url = "https://#{account_name}.#{storage_service}.core.windows.net/#{query}"
    headers = account |> build_request_headers(storage_service, method, query, options)
    Client.delete(url, headers, [])
  end

  # -------------------- helpers -----------------------

  defp build_request_headers(
         %Account{name: account_name} = account,
         "table" = storage_service,
         method,
         query,
         options
       ) do
    headers = generate_headers(storage_service, options)
    # sign payload
    content_type =
      case headers[:"Content-Type"] do
        nil -> ""
        value -> "#{value}"
      end

    canonical_resource = get_canonical_resource(storage_service, account_name, query)
    data = "#{method}\n\n#{content_type}\n#{headers[:"x-ms-date"]}\n#{canonical_resource}"

    auth_key = account |> sign_request(data)
    [auth_key | headers]
  end

  defp build_request_headers(
         %Account{name: account_name} = account,
         storage_service,
         method,
         query,
         options
       ) do
    headers = generate_headers(storage_service, options)
    canonical_headers = headers |> get_canonical_headers()

    # sign payload
    canonical_resource = get_canonical_resource(storage_service, account_name, query)
    headers_uri_str = "#{canonical_headers}\n#{canonical_resource}"

    content_length =
      case headers[:"content-length"] do
        nil -> ""
        value -> "#{value}"
      end

    data = "#{method}\n\n\n#{content_length}\n\n#{@content_type}\n\n\n\n\n\n\n#{headers_uri_str}"

    auth_key = account |> sign_request(data)
    [auth_key | headers]
  end

  defp sign_request(%Account{name: account_name, key: account_key}, data) do
    key =
      account_key
      |> Base.decode64!()

    signature =
      :crypto.hmac(:sha256, key, data)
      |> Base.encode64()

    # IO.puts("data:#{inspect(data)}\nsignature: #{signature}")
    {:authorization, "SharedKey #{account_name}:#{signature}"}
  end

  defp generate_headers("table", options) do
    now = get_date()

    [
      {:accept, "application/json;odata=minimalmetadata"},
      {:dataserviceversion, "3.0;NetFx"},
      {:"x-ms-version", "2018-03-28"},
      {:"x-ms-date", now}
    ] ++ options
  end

  defp generate_headers(_, options) do
    [
      {:"x-ms-version", @api_version},
      {:"x-ms-date", get_date()},
      {:"Content-Type", @content_type}
    ] ++ options
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
      |> Enum.map(fn line -> String.replace(line, "=", ":", global: false) end)
      |> Enum.join("\n")

    IO.puts("#{canonical} - #{query_string}")

    case canonical == query_string do
      true -> "/#{account_name}/#{canonical}"
      false -> "/#{account_name}/#{container}\n#{canonical}"
    end
  end

  defp content_length_header(body) do
    case String.length(body) do
      0 -> []
      len -> [{:"content-length", len}]
    end
  end
end
