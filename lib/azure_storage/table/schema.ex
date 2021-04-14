defmodule AzureStorage.Table.Schema do
  def retrieve_entity_options,
    do: [
      as: [
        type: {:in, [:json, :entity]},
        default: :json,
        doc: "return result as `json` or `AzureStorage.Table.EntityDescriptor`"
      ]
    ]

  def query_entities_options,
    do: [
      as: [
        type: {:in, [:json, :entity]},
        default: :json,
        doc: "return result as `json` or `AzureStorage.Table.EntityDescriptor`"
      ],
      continuation_token: [
        type: :string,
        default: "",
        doc: "Continuation token required to fetch paged results"
      ]
    ]
end
