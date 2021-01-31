import Config

config :ex_azure_storage, http_adapter: HttpClientMock

# Print only warnings and errors during test
config :logger, level: :warn
