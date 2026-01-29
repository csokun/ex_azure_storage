import Config

config :ex_azure_storage,
  http_adapter: HTTPoison,
  # https://github.com/Azure/Azurite/blob/main/README.md#usage-with-azure-storage-sdks-or-tools
  account_name: "devstoreaccount1",
  account_key:
    "Eby8vdM02xNOcqFlqUwJPLlmEtlCDXJ1OUzFT50uSRZ6IFsuFq2UVErCz4I6tq/K1SZFPTOtr/KBHBeksoGMGw==",
  azurite_emulator: true

# config :ex_azure_storage, http_adapter: HttpClientMock

# Print only warnings and errors during test
config :logger, level: :warning
