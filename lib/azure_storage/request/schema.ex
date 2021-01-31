defmodule AzureStorage.Request.Schema do
  def build_options,
    do: [
      method: [
        type: :string,
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
        default: []
      ]
    ]
end
