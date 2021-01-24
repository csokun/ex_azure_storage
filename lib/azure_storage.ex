defmodule AzureStorage do
  alias AzureStorage.Core.Account

  use GenServer

  def start_link(options) do
    GenServer.start_link(__MODULE__, options, name: __MODULE__)
  end

  def init(%{account: account, key: key}) do
    account = Account.new(account, key)
    {:ok, account}
  end
end
