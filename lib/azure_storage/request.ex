defmodule AzureStorage.Request do
  require Logger
  alias AzureStorage.Request.{Context, SharedKey, Schema}
  alias Http.Client
  import AzureStorage.Parser

  def build(%Context{} = context, config \\ []), do: Context.build(context, config)

  def request(%Context{method: method, url: url, body: body} = context, options \\ []) do
    {:ok, opts} = NimbleOptions.validate(options, Schema.request_options())

    headers = context |> SharedKey.sign_request()

    Client.request(method, url, body, headers, options)
    |> parse_response(opts[:response_body])
  end

  @doc false
  def encode_query(options \\ []), do: URI.encode_query(options)

  defp parse_response(response, :json), do: parse_response_body_as_json(response)
  defp parse_response({:ok, %{body: body, headers: headers}}, _), do: {:ok, body, headers}
end
