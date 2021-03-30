defmodule AzureStorage.Request.Schema do
  @moduledoc false
  def build_options,
    do: [
      method: [
        type: {:in, [:post, :get, :put, :delete]},
        required: true
      ],
      path: [
        type: :string,
        required: true
      ],
      body: [
        type: :string,
        required: false,
        default: ""
      ],
      headers: [
        type: :any,
        required: false,
        default: %{}
      ]
    ]
end
