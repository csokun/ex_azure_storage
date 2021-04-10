defmodule Http.Client.Behaviour do
  @moduledoc false

  @typep method :: :get | :post | :put | :patch | :delete | :options | :head | :merge
  @typep url :: binary()
  @typep body :: {:form, [{atom(), any()}]}
  @typep headers :: [{atom, binary}] | [{binary, binary}] | %{binary => binary}
  @typep options :: Keyword.t()

  @callback request(method, url, body, headers, options) ::
              {:ok, %{status_code: pos_integer, headers: any, body: binary}}
              | {:error, binary() | map()}
end
