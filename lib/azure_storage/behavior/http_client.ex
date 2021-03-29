defmodule Http.Client.Behaviour do
  @moduledoc false
  alias HTTPoison.Response
  alias HTTPoison.AsyncResponse
  alias HTTPoison.Error

  @typep url :: binary()
  @typep body :: {:form, [{atom(), any()}]}
  @typep headers :: [{atom, binary}] | [{binary, binary}] | %{binary => binary}
  @typep options :: Keyword.t()

  @callback get(url, headers, options) ::
              {:ok, Response.t() | AsyncResponse.t()} | {:error, Error.t()}

  @callback post(url, body, headers, options) ::
              {:ok, map()} | {:error, binary() | map()}

  @callback put(url, body, headers, options) ::
              {:ok, Response.t() | AsyncResponse.t()} | {:error, Error.t()}

  @callback delete(url, headers, options) ::
              {:ok, Response.t() | AsyncResponse.t()} | {:error, Error.t()}
end
