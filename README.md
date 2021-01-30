# AzureStorage  [![Build Status](https://github.com/csokun/ex_azure_storage/workflows/CI/badge.svg?branch=master)](https://github.com/csokun/ex_azure_storage/actions?query=workflow%3ACI)

Elixir Azure Storage Rest API Client.

## Installation

If [available in Hex](https://hex.pm/docs/publish), the package can be installed
by adding `az` to your list of dependencies in `mix.exs`:

```elixir
def deps do
  [
    {:ex_azure_storage, "~> 0.1.0"}
  ]
end
```
## Usage

Common usage

```elixir
import AzureStorage.Core.Account
import AzureStorage.Queue

account = %Account{name: "azure-account-name", key: "azure-account-key"}
queue_name="sampleq"

account 
  |> Queue.get_messages(queue_name, [number_of_messages: 25, visibility_timeout: 60])

```

Documentation can be generated with [ExDoc](https://github.com/elixir-lang/ex_doc)
and published on [HexDocs](https://hexdocs.pm). Once published, the docs can
be found at [https://hexdocs.pm/az](https://hexdocs.pm/az).
