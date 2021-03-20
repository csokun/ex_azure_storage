defmodule AzureStorage.Table.QueryBuilder do
  alias AzureStorage.Table.Query

  @comparition [
    :eq,
    :ne,
    :le,
    :ge,
    :lt,
    :le
  ]

  def where(%Query{} = query, criteria) when is_bitstring(criteria) do
    add_filter(query, :and, criteria)
  end

  def where(%Query{} = query, field, comparition, value)
      when comparition in @comparition do
    criteria = field(field, comparition, value)
    add_filter(query, :and, criteria)
  end

  def or_where(%Query{} = query, criteria) when is_bitstring(criteria) do
    add_filter(query, :or, criteria)
  end

  def or_where(%Query{} = query, field, comparition, value)
      when comparition in @comparition do
    criteria = field(field, comparition, value)
    add_filter(query, :or, criteria)
  end

  defp add_filter(%Query{filter: filter} = query, connector, criteria)
       when is_bitstring(criteria) and
              connector in [:and, :or] do
    filter =
      case filter do
        nil -> ["(#{criteria})"]
        _ -> ["#{Atom.to_string(connector)} (#{criteria})" | filter]
      end

    %{query | filter: filter}
  end

  defp field(field, comparition, value)
       when comparition in @comparition do
    field_value = field_value(value)
    "#{field} #{Atom.to_string(comparition)} #{field_value}"
  end

  defp field_value(value) when is_number(value) or is_boolean(value), do: "#{value}"

  defp field_value(value) do
    if is_date?(value) do
      "datetime'#{value}'"
    else
      "'#{value |> escape}'"
    end
  end

  def is_date?(date) do
    case date do
      %NaiveDateTime{} -> true
      %DateTime{} -> true
      _ -> false
    end
  end

  defp escape(value) do
    value |> URI.encode()
  end
end
