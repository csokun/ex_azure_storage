# AzureStorage  [![Build Status](https://github.com/csokun/ex_azure_storage/workflows/CI/badge.svg?branch=master)](https://github.com/csokun/ex_azure_storage/actions?query=workflow%3ACI)

Elixir Azure Storage Rest API Client. Support Azure Blob, Queue, Fileshare and Table Storage.

## Installation

The package can be installed
by adding `ex_azure_storage` to your list of dependencies in `mix.exs`:

```elixir
def deps do
  [
    {:ex_azure_storage, "~> 0.1.1"}
  ]
end
```
## Usage

Common usage

```elixir
{:ok, context} = AzureStorage.create_queue_service("azure-account-name", "azure-account-key")
queue_name="sampleq"

context
  |> AzureStorage.Queue.get_messages(queue_name, [number_of_messages: 25, visibility_timeout: 60])
  |> IO.inspect()

```

Full documentation can be found at [https://hexdocs.pm/ex_azure_storage](https://hexdocs.pm/ex_azure_storage).
