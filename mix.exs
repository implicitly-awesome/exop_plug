defmodule ExopPlug.MixProject do
  use Mix.Project

  @description """
  This library provides a convinient way to validate incoming parameters
  of your Phoenix application's controllers.
  """

  @source_url "https://github.com/madeinussr/exop_plug"

  def project do
    [
      app: :exop_plug,
      version: "1.0.0",
      elixir: "~> 1.9",
      name: "ExopPlug",
      description: @description,
      package: package(),
      deps: deps(),
      source_url: @source_url,
      docs: [extras: ["README.md"]],
      build_embedded: Mix.env() == :prod,
      start_permanent: Mix.env() == :prod
    ]
  end

  def application, do: []

  defp deps do
    [
      {:plug, "~> 1.8"},
      {:exop, "~> 1.3.4"}
    ]
  end

  defp package do
    [
      files: ["lib", "mix.exs", "README.md", "LICENSE"],
      maintainers: ["Andrey Chernykh"],
      licenses: ["MIT"],
      links: %{"Github" => @source_url}
    ]
  end
end
