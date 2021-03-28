defmodule AzureStorage.Core.Account do
  @enforce_keys [:name, :key]
  defstruct [:name, :key]

  @type t :: %AzureStorage.Core.Account{
          name: String.t(),
          key: String.t()
        }

  @spec new(String.t(), String.t()) :: {:ok, t()} | {:error, String.t()}
  def new(name, key) do
    case Base.decode64(key) do
      {:ok, _} ->
        {:ok,
         %__MODULE__{
           name: name,
           key: key
         }}

      :error ->
        {:error, "Invalid key - not base 64"}
    end
  end

  def get(pid) do
    {:ok, account} = :sys.get_state(pid)
    account
  end
end
