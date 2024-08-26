defmodule AzureStorage.Request.Schema do
  @moduledoc false
  def build_options,
    do: [
      method: [
        type: {:in, [:post, :get, :put, :delete, :merge]},
        doc: "Request method",
        required: true
      ],
      path: [
        type: :string,
        doc: "Request path",
        required: true
      ],
      body: [
        type: :string,
        default: "",
        doc: "Request body"
      ],
      headers: [
        type: :any,
        doc: "Additional request headers",
        default: %{}
      ]
    ]

  def request_options,
    do: [
      response_body: [
        type: {:in, [:full, :json]},
        default: :json
      ],
      timeout: [
        type: :pos_integer,
        default: 30_000
      ]
    ]
end
