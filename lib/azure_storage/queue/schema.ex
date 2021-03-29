defmodule AzureStorage.Queue.Schema do
  @moduledoc false
  @visibility_timeout [
    type: :integer,
    required: false,
    doc: "Message visibility timeout in second"
  ]

  def create_message_options,
    do: [
      visibility_timeout: @visibility_timeout ++ [default: 0],
      message_ttl: [
        type: :integer,
        required: false,
        default: 7 * 24 * 3600,
        doc: "Message time to live in second"
      ]
    ]

  def get_messages_options,
    do: [
      visibility_timeout: @visibility_timeout ++ [default: 30],
      number_of_messages: [
        type: :integer,
        required: false,
        default: 1
      ]
    ]

  def update_message_options,
    do: [
      visibility_timeout: @visibility_timeout ++ [default: 0]
    ]
end
