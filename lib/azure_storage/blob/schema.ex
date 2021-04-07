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

  def put_blob_options,
    do: [
      content_type: [
        type: :string,
        doc: "Content-Type",
        default: "text/plain;charset=\"utf-8\""
      ]
    ]

  def acquire_lease_options,
    do: [
      duration: [
        type: :integer,
        default: 15,
        doc:
          "Specifies the duration of the lease, in seconds, or negative on(-1) for a lease that never expires. A non-inifinite lease can be between 15 and 60 seconds."
      ],
      propose_lease_id: [
        type: :string,
        default: "",
        doc: "Proposed lease ID, in a GUID string format."
      ]
    ]
end
