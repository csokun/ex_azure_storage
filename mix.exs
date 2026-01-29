defmodule AzureStorage.MixProject do
  use Mix.Project

  @version "0.1.8"
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
      {:elixir_xml_to_map, "~> 3.1"},
      {:jason, "~> 1.4"},
      {:httpoison, "~> 2.3"},
      {:nimble_options, "~> 1.1.1"},
      {:uuid, "~> 1.1", only: :test, runtime: false},
      {:ex_doc, "~> 0.40.0", only: :dev, runtime: false},
      {:credo, "~> 1.7", only: [:dev, :test], runtime: false}
    ]
  end

  defp package do
    [
      maintainers: ["Sokun Chorn"],
      licenses: ["MIT"],
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
