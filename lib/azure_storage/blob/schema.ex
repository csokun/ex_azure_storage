defmodule AzureStorage.Blob.Schema do
  def list_blobs_options,
    do: [
      max_results: [
        type: :pos_integer,
        default: 1
      ],
      prefix: [
        type: :string,
        required: false
      ]
    ]

  def create_blob_options,
    do: [
      content_type: [
        type: :string,
        default: "text/plain;charset=\"utf-8\""
      ]
    ]
end
