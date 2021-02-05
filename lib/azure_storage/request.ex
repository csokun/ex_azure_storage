defmodule AzureStorage.Request do
  require Logger
  alias AzureStorage.Request.{Context, SharedKey}
  alias Http.Client

  def build(%Context{} = context, config \\ []), do: Context.build(context, config)

  def request(%Context{method: :get, url: url} = context) do
    headers = context |> SharedKey.sign_request()
    Client.get(url, headers, [])
  end

  def request(%Context{method: :delete, url: url} = context) do
    headers = context |> SharedKey.sign_request()
    Client.delete(url, headers, [])
  end

  def request(%Context{method: :post, url: url, body: body} = context) do
    headers = context |> SharedKey.sign_request()
    Client.post(url, body, headers, [])
  end

  def request(%Context{method: :put, url: url, body: body} = context) do
    headers = context |> SharedKey.sign_request()
    Client.put(url, body, headers, [])
  end
end
