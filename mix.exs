defmodule TypedEnum.MixProject do
  use Mix.Project

  def project do
    [
      app: :typed_enum,
      version: "0.1.0",
      elixir: "~> 1.11",
      start_permanent: Mix.env() == :prod,
      elixirc_paths: elixirc_paths(Mix.env()),
      deps: deps()
    ]
  end

  # Specifies which paths to compile per environment.
  defp elixirc_paths(:test), do: ["lib", "test/support"]
  defp elixirc_paths(_), do: ["lib"]

  def application(),
    do: [extra_applications: [:logger]]

  defp deps(),
    do: [{:ecto, "~> 3.7"}]
end
