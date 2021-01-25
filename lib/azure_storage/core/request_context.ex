defmodule AzureStorage.Core.RequestContext do
  alias AzureStorage.Core.Account
  defstruct [:service, :account, :headers, :base_url]

  def create(%Account{} = account, service)
      when is_binary(service) do
    %__MODULE__{
      account: account,
      headers: %{
        "x-ms-version": "2019-07-07",
        "Content-Type": "application/xml"
      },
      service: service,
      base_url: "https://#{account.name}.#{service}.core.windows.net/"
    }
  end

  # def sign(%__MODULE__{} = ctx, uri) do
  # end

  defp clone(%__MODULE__{} = ctx) do
    headers = Map.merge(ctx.headers, %{"x-ms-date": get_current_datetime_utc()})
    Map.merge(ctx, %{headers: headers})
  end

  defp get_current_datetime_utc() do
    DateTime.utc_now()
    |> Calendar.strftime("%a, %d %b %Y %H:%M:%S GMT")
  end
end
