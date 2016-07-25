defmodule Typi.Mixfile do
  use Mix.Project

  def project do
    [
      app: :typi,
      version: "0.1.0",
      build_path: "../../_build",
      config_path: "../../config/config.exs",
      deps_path: "../../deps",
      lockfile: "../../mix.lock",
      elixir: "~> 1.3",
      build_embedded: Mix.env == :prod,
      start_permanent: Mix.env == :prod,
      deps: deps
    ]
  end

  # Configuration for the OTP application
  #
  # Type "mix help compile.app" for more information
  def application do
    [
      mod: { Typi, [] },
      applications: [
        :logger,
        :postgrex,
        :ecto
      ],
    ]
  end

  # Dependencies can be Hex packages:
  #
  #   {:mydep, "~> 0.3.0"}
  #
  # Or git/path repositories:
  #
  #   {:mydep, git: "https://github.com/elixir-lang/mydep.git", tag: "0.1.0"}
  #
  # To depend on another app inside the umbrella:
  #
  #   {:myapp, in_umbrella: true}
  #
  # Type "mix help deps" for more examples and options
  defp deps do
    [
      { :postgrex, ">= 0.0.0" },
      { :ecto, "~> 2.0.0" },
      { :pot, git: "https://github.com/yuce/pot.git" },
      { :ex_twilio, "~> 0.1.9" },
      { :ex_phone_number, git: "https://github.com/socialpaymentsbv/ex_phone_number", branch: "develop" },
      { :ex_machina, "~> 1.0", only: :test }
    ]
  end
end
