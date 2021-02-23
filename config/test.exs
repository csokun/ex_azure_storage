import Config
account_name = System.get_env("AZ_ACCOUNT_NAME") || "dummy"
account_key = System.get_env("AZ_ACCOUNT_KEY") || "ZHVtbXk="

config :ex_azure_storage,
  http_adapter: HTTPoison,
  account_name: account_name,
  account_key: account_key

config :exvcr,
  filter_sensitive_data: [
    [pattern: account_name, placeholder: "account-name"]
  ],
  filter_request_headers: ["authorization"]

# config :ex_azure_storage, http_adapter: HttpClientMock

# Print only warnings and errors during test
config :logger, level: :warn
