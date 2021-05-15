defmodule AzureStorage.Queue.Schema do
  @moduledoc false
  @visibility_timeout [
    type: :integer,
    required: false,
    doc: "Message visibility timeout in second"
  ]

  def create_message_options,
    do: [
      visibilitytimeout: @visibility_timeout ++ [default: 0],
      messagettl: [
        type: :integer,
        required: false,
        default: 7 * 24 * 3600,
        doc: "Message time to live in second"
      ],
      timeout: [
        type: :pos_integer,
        default: 30,
        required: false
      ]
    ]

  def get_messages_options,
    do: [
      visibilitytimeout: @visibility_timeout ++ [default: 30],
      numofmessages: [
        type: :integer,
        required: false,
        doc: "Number of messages to retrieve from the queue, up to a maximum of 32.",
        default: 1
      ],
      timeout: [
        type: :pos_integer,
        default: 30,
        required: false
      ]
    ]

  def update_message_options,
    do: [
      visibilitytimeout: @visibility_timeout ++ [default: 0],
      timeout: [
        type: :pos_integer,
        default: 30,
        required: false
      ]
    ]
end
