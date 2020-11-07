import Config

config :ex_azure_storage, http_adapter: HTTPoison

import_config "#{Mix.env()}.exs"
