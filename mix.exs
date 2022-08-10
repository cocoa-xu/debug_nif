defmodule Mix.Tasks.Compile.DebugNif do
  use Mix.Task

  def run(_) do
    case :os.type() do
      {:unix, _} ->
        root_dir = :code.root_dir()
        erts_dir = Path.join(root_dir, "erts-#{:erlang.system_info(:version)}")
        erts_include_dir = System.get_env("ERTS_INCLUDE_DIR", Path.join(erts_dir, "include"))
        System.put_env("ERTS_INCLUDE_DIR", erts_include_dir)
        System.put_env("MIX_APP_PATH", Mix.Project.app_path())
        cache_opts = if System.get_env("MIX_XDG"), do: %{os: :linux}, else: %{}
        cache_dir = :filename.basedir(:user_cache, "", cache_opts)
        System.put_env("ERLANG_CACHE_DIR", cache_dir)

        opts = [
          into: IO.stream(:stdio, :line),
          stderr_to_stdout: true,
          cd: Path.expand(File.cwd!()),
        ]

        Mix.Project.ensure_structure()
        {%IO.Stream{}, status} = System.cmd("make", [], opts)
        Mix.Project.ensure_structure()

        case status do
          0 -> :ok
          _ ->
            Mix.raise(~s{Could not compile" (exit status: #{status}).\n})
        end

      _ ->
        Mix.raise("Windows is not supported yet.")
    end
  end
end

defmodule DebugNif.MixProject do
  use Mix.Project

  @app :debug_nif
  @version "0.1.0"
  @github_url "https://github.com/cocoa-xu/debug_nif"
  def project do
    [
      app: @app,
      version: @version,
      download_base_url: "#{@github_url}/releases/download/v#{@version}",
      elixir: "~> 1.10",
      start_permanent: Mix.env() == :prod,
      compilers: [@app] ++ Mix.compilers(),
      deps: deps(),
      escript: [
        main_module: DebugNIF.CLI,
        comment: "escript for debugging a NIF library."
      ],
      description: "escript for debugging a NIF library.",
      docs: docs(),
      package: package(),
    ]
  end

  def application do
    [extra_applications: [:logger, :crypto, :inets, :public_key]]
  end

  defp deps do
    [
      {:castore, "~> 0.1"},
      {:ex_doc, "~> 0.28", only: :docs, runtime: false}
    ]
  end

  defp docs do
    [
      main: "DebugNIF.CLI",
      source_ref: "v#{@version}",
      source_url: @github_url
    ]
  end

  defp package() do
    [
      name: to_string(@app),
      files: ~w(c_src lib mix.exs README* LICENSE* Makefile),
      licenses: ["Apache-2.0"],
      links: %{"GitHub" => @github_url}
    ]
  end
end
