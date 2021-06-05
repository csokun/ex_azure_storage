defmodule AzureStorage.Request.Context do
  alias AzureStorage.Request.Schema
  alias AzureStorage.Core.Account

  defstruct service: "",
            account: %Account{name: nil, key: nil},
            method: "",
            headers: %{},
            base_url: "",
            path: "",
            url: "",
            body: ""

  @type t :: %AzureStorage.Request.Context{
          service: String.t(),
          account: Account.t(),
          method: String.t() | atom(),
          headers: map(),
          base_url: String.t(),
          path: String.t(),
          url: String.t(),
          body: String.t()
        }

  def create(%Account{} = account, service, app_version \\ "2019-07-07")
      when is_binary(service) do
    base_url = "https://#{account.name}.#{service}.core.windows.net"

    headers =
      default_service_headers(service)
      |> Map.merge(%{:"x-ms-version" => app_version})

    %__MODULE__{
      account: account,
      headers: headers,
      service: service,
      base_url: base_url,
      url: base_url,
      path: ""
    }
  end

  @doc """
  Build request context

  Supported options\n#{NimbleOptions.docs(Schema.build_options())}
  """
  @spec build(t(), keyword()) :: t()
  def build(
        %__MODULE__{headers: default_headers, base_url: base_url} = context,
        options \\ []
      ) do
    now = get_date()
    {:ok, options} = NimbleOptions.validate(options, Schema.build_options())
    body = options[:body]
    method = options[:method]
    path = options[:path]
    headers_cfg = options[:headers]

    # TODO: improve headers
    content_length =
      case String.length(body) do
        0 ->
          %{}

        value ->
          %{:"content-length" => "#{value}"}
      end

    headers =
      default_headers
      |> Map.merge(headers_cfg)
      |> Map.merge(%{:"x-ms-date" => now})
      |> Map.merge(content_length)

    context
    |> Map.put(:method, method)
    |> Map.put(:headers, headers)
    |> Map.put(:body, body)
    |> Map.put(:path, path)
    |> Map.put(:url, "#{base_url}/#{path}")
  end

  def get_canonical_headers(%__MODULE__{headers: headers}) do
    headers
    |> Map.to_list()
    |> Enum.map(fn {k, v} ->
      case is_atom(k) do
        true -> {Atom.to_string(k), v}
        _ -> {k, v}
      end
    end)
    |> Enum.filter(fn {k, _} ->
      case k do
        "x-ms-" <> _ -> true
        _ -> false
      end
    end)
    |> Enum.sort(:asc)
    # TODO: safeguard - remove \r\n from header value
    |> Enum.map(fn {k, v} -> "#{k}:#{v}" end)
    |> Enum.join("\n")
  end

  def get_canonical_resource(
        %__MODULE__{service: service, account: %{name: account_name}, path: path} = _context
      ) do
    case service do
      "table" ->
        get_table_service_canonical_resource(account_name, path)

      _ ->
        get_generic_service_canonical_resource(account_name, path)
    end
  end

  # ----------------- helpers -----------------
  defp default_service_headers("table") do
    %{
      :accept => "application/json;odata=minimalmetadata",
      :dataserviceversion => "3.0;NetFx"
    }
  end

  defp default_service_headers(_) do
    %{:"Content-Type" => "application/xml"}
  end

  defp get_table_service_canonical_resource(account_name, path) do
    # query_entities - keep table name only
    token = path |> String.split("?")

    resource =
      case length(token) > 1 do
        true ->
          "/#{account_name}/#{Enum.at(token, 0)}"

        false ->
          "/#{account_name}/#{path}"
      end

    resource |> String.replace("'", "%27")
  end

  defp get_generic_service_canonical_resource(account_name, path) do
    query_tokenize = path |> String.split("?")

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

    # IO.puts("#{canonical} - #{query_string}")

    case canonical == query_string do
      true -> "/#{account_name}/#{canonical}"
      false -> "/#{account_name}/#{container}\n#{canonical}"
    end
  end

  defp get_date() do
    DateTime.utc_now()
    |> Calendar.strftime("%a, %d %b %Y %H:%M:%S GMT")
  end
end
