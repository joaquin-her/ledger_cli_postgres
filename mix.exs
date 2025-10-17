defmodule Ledger.MixProject do
  use Mix.Project

  def project do
    [
      app: :ledger,
      version: "0.2.0",
      elixir: "~> 1.18",
      start_permanent: Mix.env() == :prod,
      deps: deps(),
      escript: escripts(),
      name: "ledger",
      aliases: aliases(),

      test_coverage: [
        summary: [threshold: 80],
        output: ".volumes/cover"
      ]
    ]
  end

  # Run "mix help compile.app" to learn about applications.
  def application do
    [
      extra_applications: [:logger],
      mod: {Ledger.Application, []}
    ]
  end

  defp escripts do
    [main_module: Ledger.CLI]
  end

  # Run "mix help deps" to learn about dependencies.
  defp deps do
    [
      # {:dep_from_hexpm, "~> 0.3.0"},
      {:ecto_sql, "~> 3.10" },
      {:postgrex, ">= 0.0.0"},
      {:faker, "~> 0.19.0-alpha.1", only: :test}
    ]
  end

  defp aliases do
    [
     "remake-db": ["ecto.drop "," ecto.create "," ecto.migrate"]
    ]
  end
end
