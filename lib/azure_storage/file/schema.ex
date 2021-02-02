defmodule AzureStorage.File.Schema do
  def list_directories_and_files_options,
    do: [
      prefix: [
        type: :string,
        doc:
          "Filters the results to return only files and directories whose name begins with the specified prefix.",
        required: false
      ],
      max_results: [
        type: :pos_integer,
        required: false,
        default: 1000,
        doc:
          "Specifies the maximum number of files and/or directories to return. If the request does not specify maxresults or specifies a value greater than 5,000, the server will return up to 5,000 items."
      ],
      marker: [
        type: :string,
        required: false,
        doc:
          "A string value that identifies the portion of the list to be returned with the next list operation. The operation returns a marker value within the response body if the list returned was not complete. The marker value may then be used in a subsequent call to request the next set of list items."
      ],
      timeout: [
        type: :pos_integer,
        default: 30,
        required: false,
        doc: "The timeout parameter is expressed in seconds"
      ]
    ]
end
