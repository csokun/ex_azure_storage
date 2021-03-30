defmodule AzureStorage.MixProject do
  use Mix.Project

  @version "0.1.1"
  @repo_url "https://github.com/csokun/ex_azure_storage"

  def project do
    [
      app: :ex_azure_storage,
      version: @version,
      elixir: "~> 1.11",
      start_permanent: Mix.env() == :prod,
      # elixirc_paths: elixirc_paths(Mix.env()),
      deps: deps(),

      # Hex
      package: package(),
      description:
        "Elixir Azure Storage REST Client support Blob, Queue, Fileshare and TableStorage service",

      # Docs
      name: "AzureStorage",
      docs: docs()
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
      {:jason, "~> 1.2"},
      {:exvcr, "~> 0.12.2", only: :test},
      {:mox, "~> 1.0.0", only: :test},
      {:httpoison, "~> 1.7.0"},
      {:nimble_options, "~> 0.3.5"},
      {:ex_doc, "~> 0.23", only: :dev, runtime: false},
      {:credo, "~> 1.4", only: [:dev, :test], runtime: false}
    ]
  end

  defp package do
    [
      maintainers: ["Sokun Chorn"],
      licenses: ["Apache 2.0"],
      links: %{"GitHub" => @repo_url}
    ]
  end

  defp docs() do
    [
      main: "AzureStorage",
      source_ref: "v#{@version}",
      source_url: @repo_url
    ]
  end
end
