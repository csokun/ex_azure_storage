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
    base_url = get_default_url(service, account.name)

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
      case headers_cfg[:"Content-Type"] do
        "application/octet-stream" ->
          case Kernel.byte_size(body) do
            0 ->
              %{}

            value ->
              %{:"content-length" => "#{value}"}
          end

        _ ->
          case String.length(body) do
            0 ->
              %{}

            value ->
              %{:"content-length" => "#{value}"}
          end
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
    |> Enum.flat_map(fn
      {k, v} when is_atom(k) -> [{Atom.to_string(k), v}]
      {k, v} -> [{k, v}]
    end)
    |> Enum.filter(fn {k, _v} -> String.starts_with?(k, "x-ms-") end)
    |> Enum.sort(:asc)
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

    table_path =
      case token do
        [base | _] -> base
        _ -> path
      end

    resource_prefix = get_resource_prefix(account_name)

    "#{resource_prefix}/#{table_path}"
    |> String.replace("'", "%27")
  end

  def get_generic_service_canonical_resource(account_name, path) do
    {resource_path, query_string} =
      case String.split(path, "?", parts: 2) do
        [resource, query] -> {resource, query}
        [resource] -> {resource, ""}
      end

    canonical_query =
      query_string
      |> String.split("&", trim: true)
      |> Enum.map(fn pair ->
        case String.split(pair, "=", parts: 2) do
          [key, value] -> {String.downcase(key), URI.decode_www_form(value)}
          [key] -> {String.downcase(key), ""}
        end
      end)
      |> Enum.group_by(fn {key, _value} -> key end, fn {_, value} -> value end)
      |> Enum.sort_by(fn {key, _values} -> key end)
      |> Enum.map(fn {key, values} ->
        joined_values =
          values
          |> Enum.sort()
          |> Enum.join(",")

        "#{key}:#{joined_values}"
      end)
      |> Enum.join("\n")

    resource_prefix = get_resource_prefix(account_name)

    canonical_resource =
      case resource_path do
        "" -> "#{resource_prefix}/"
        _ -> "#{resource_prefix}/#{resource_path}"
      end

    case canonical_query do
      "" -> canonical_resource
      _ -> "#{canonical_resource}\n#{canonical_query}"
    end
  end

  defp get_resource_prefix(account_name) do
    case Application.get_env(:ex_azure_storage, :azurite_emulator, false) do
      true -> "/#{account_name}/#{account_name}"
      _ -> "/#{account_name}"
    end
  end

  defp get_date() do
    DateTime.utc_now()
    |> Calendar.strftime("%a, %d %b %Y %H:%M:%S GMT")
  end

  defp get_default_url(service, account_name) do
    case Application.get_env(:ex_azure_storage, :azurite_emulator, false) do
      true ->
        case service do
          "blob" -> "http://127.0.0.1:10000/#{account_name}"
          "queue" -> "http://127.0.0.1:10001/#{account_name}"
          "table" -> "http://127.0.0.1:10002/#{account_name}"
          _ -> raise "Azurite unsupported service: #{service}"
        end

      _ ->
        "https://#{account_name}.#{service}.core.windows.net"
    end
  end
end
