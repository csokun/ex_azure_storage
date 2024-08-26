defmodule AzureStorage.Blob.Schema do
  @moduledoc false
  @list_operation [
    maxresults: [
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
      ],
      timeout: [
        type: :pos_integer,
        default: 30_000,
        required: false
      ]
    ]

  def get_blob_options,
    do: [
      lease_id: [
        type: :string,
        default: "",
        doc: "Active lease id"
      ],
      json: [
        type: :boolean,
        default: false,
        doc: "If `true` return content is in `map()`"
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

  def share_options,
    do: [
      path: [
        type: :string,
        doc: "sharing path `/<container>/<filename>` for example `/bookings/hotel-room-a.json`",
        required: true
      ],
      permissions: [
        type: :string,
        default: "r",
        required: true
      ],
      start: [
        type: :string,
        doc: "Start from date in ISO-8601 format e.g `2021-04-10T10:48:02Z`",
        required: true
      ],
      expiry: [
        type: :string,
        doc: "Expiry date in ISO-8601 format e.g `2021-04-10T10:48:02Z`",
        required: true
      ]
    ]
end
