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
  def project do
    [
      app: @app,
      version: @version,
      elixir: "~> 1.10",
      start_permanent: Mix.env() == :prod,
      compilers: [@app] ++ Mix.compilers(),
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
