defmodule AzTest do
  use ExUnit.Case
  # doctest Az

  test "greets the world" do
    assert AzureStorage.hello() == :world
  end
end
