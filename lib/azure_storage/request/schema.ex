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
end
