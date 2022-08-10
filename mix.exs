defmodule DebugNif.MixProject do
  use Mix.Project

  def project do
    [
      app: :debug_nif,
      version: "0.1.0",
      elixir: "~> 1.10",
      start_permanent: Mix.env() == :prod,
      deps: [],
      escript: [
        main_module: DebugNIF.CLI,
        comment: "escript for debugging a NIF library."
      ]
    ]
  end

  def application do
    []
  end
end
