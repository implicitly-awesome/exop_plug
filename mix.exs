defmodule ExopPlug.MixProject do
  use Mix.Project

  def project do
    [
      app: :exop_plug,
      version: "1.0.0",
      elixir: "~> 1.9",
      start_permanent: Mix.env() == :prod,
      deps: deps()
    ]
  end

  def application do
    []
  end

  defp deps do
    [
      {:plug, "~> 1.8"},
      {:exop, "~> 1.3.4"}
    ]
  end
end
