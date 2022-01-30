defmodule TypedEnum.MixProject do
  use Mix.Project

  def project do
    [
      app: :typed_enum,
      version: "0.1.2",
      elixir: "~> 1.11",
      start_permanent: Mix.env() == :prod,
      elixirc_paths: elixirc_paths(Mix.env()),
      deps: deps(),
      source_url: "https://github.com/mnussbaumer/typed_enum",
      homepage_url: "https://hexdocs.pm/typed_enum/readme.html",
      docs: [
        main: "TypedEnum",
        extras: ["README.md"]
      ],
      description:
        "Macro to easily generate independent Enum Ecto.Types with support for integer and string as the underlying representation and atoms for the app logic.",
      package: [
        exclude_patterns: [~r/.*~$/, ~r/#.*#$/],
        licenses: ["MIT"],
        links: %{
          "github/readme" => "https://github.com/mnussbuamer/typed_enum"
        }
      ]
    ]
  end

  # Specifies which paths to compile per environment.
  defp elixirc_paths(:test), do: ["lib", "test/support"]
  defp elixirc_paths(_), do: ["lib"]

  def application(),
    do: [extra_applications: [:logger]]

  defp deps(),
    do: [
      {:ecto, "~> 3.7"},
      {:ex_doc, ">= 0.0.0", only: :dev, runtime: false}
    ]
end
