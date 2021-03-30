defmodule AzureStorage.Blob.Schema do
  @moduledoc false
  @list_operation [
    max_results: [
      type: :pos_integer,
      default: 1
    ],
    marker: [
      type: :string,
      required: false,
      default: ""
    ],
    prefix: [
      type: :string,
      required: false
    ],
    timeout: [
      type: :pos_integer,
      default: 30,
      required: false
    ]
  ]

  def list_containers_options,
    do: @list_operation

  def list_blobs_options,
    do: @list_operation

  def create_blob_options,
    do: [
      content_type: [
        type: :string,
        default: "text/plain;charset=\"utf-8\""
      ]
    ]
end
