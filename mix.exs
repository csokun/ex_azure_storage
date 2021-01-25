defmodule ExAzureStorage.MixProject do
  use Mix.Project

  def project do
    [
      app: :ex_azure_storage,
      version: "0.1.0",
      elixir: "~> 1.11",
      start_permanent: Mix.env() == :prod,
      # elixirc_paths: elixirc_paths(Mix.env()),
      deps: deps()
    ]
  end

  # Specifies which paths to compile per environment.
  # defp elixirc_paths(:test), do: ["lib", "test/support"]
  # defp elixirc_paths(_), do: ["lib"]

  # Run "mix help compile.app" to learn about applications.
  def application do
    [
      extra_applications: [:logger],
      mod: {AzureStorage.Application, []}
    ]
  end

  # Run "mix help deps" to learn about dependencies.
  defp deps do
    [
      {:elixir_xml_to_map, "~> 1.0"},
      {:mox, "~> 1.0.0", only: :test},
      {:httpoison, "~> 1.7.0"},
      {:credo, "~> 1.4", only: [:dev, :test], runtime: false}
    ]
  end
end
