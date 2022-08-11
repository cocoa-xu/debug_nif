defmodule DebugNIF.CLI do
  @moduledoc """
  usage:
      $ debug_nif {options} arg1 arg2 ...
      # equvilent to call `mix arg1 arg2 ...`
  options:
      --print-only               Only print commands and necessary environment variables
                                 for running the debugger.
      --print-cmd-only           Only print commands for running the debugger.
      --debugger=DEBUGGER        Set which debugger to use. `lldb` is the default for
                                 macOS and `gdb` is the default for linux.

      --generate=TYPE            It's possible to generate an Xcode project on macOS for
                                 debugging or profiling with Xcode.
                                 Currenly, the only valid value is `xcode`.
      --generate-out=DIR         Save generated file to the given directory.
      --generate-overwrite=[yN]  Overwrite existing generated files. Default is no.
      --mix-project-root=ROOT    Specify mix project root. Default is the cwd path when
                                 execute this escript.

  """

  require Logger

  @doc false
  def main([help_opt]) when help_opt == "-h" or help_opt == "--help" do
    IO.puts(@moduledoc)
  end

  def main(args) do
    {opts, cmd_and_args, errors} = parse_args(args)

    case errors do
      [] ->
        process_args(opts, cmd_and_args)

      _ ->
        IO.puts("Bad option:")
        IO.inspect(errors)
        IO.puts(@moduledoc)
    end
  end

  defp parse_args(args) do
    {opts, cmd_and_args, errors} =
      args
      |> OptionParser.parse(
        strict: [
          print_only: :boolean,
          print_cmd_only: :boolean,
          help: :boolean,
          debugger: :string,
          generate: :string,
          generate_out: :string,
          generate_overwrite: :string,
          mix_project_root: :string
        ]
      )

    {opts, cmd_and_args, errors}
  end

  @doc false
  def default_debugger do
    case :os.type() do
      {:unix, :darwin} ->
        {"lldb", ["--"]}

      {:unix, _} ->
        {"gdb", ["--args"]}

      _ ->
        {"gdb", ["--args"]}
    end
  end

  defp generate_project(type = "xcode", cwd, erlexec, commands, user_commands, env, opts) do
    output_dir =
      opts[:generate_out] || raise "Please specify output directory for the #{type} project"

    overwrite =
      case opts[:generate_overwrite] do
        "y" -> true
        "yes" -> true
        "Y" -> true
        "YES" -> true
        "true" -> true
        _ -> false
      end

    output_dir = Path.expand(Path.join([output_dir, "debug_nif.xcodeproj"]))

    if !File.exists?(output_dir) or (File.exists?(output_dir) and overwrite) do
      env =
        Enum.reduce(env, %{}, fn {name, val}, acc ->
          Map.put(acc, name, val)
        end)

      if File.exists?(output_dir) do
        {:ok, _} = File.rm_rf(output_dir)
      end

      with :ok <-
             DebugNIF.Template.Xcode.generate(
               output_dir,
               cwd,
               erlexec,
               commands,
               user_commands,
               env
             ) do
        Logger.info("created #{output_dir}.")
        :ok
      else
        {:error, error} ->
          raise error
      end
    else
      Logger.info("#{output_dir} exists, skipped.")
      :ok
    end
  end

  defp generate_project(unknown, _, _, _, _, _, _) do
    raise "Unknown type '#{unknown}' for --generate. currently valid value is 'xcode'"
  end

  defp process_args(opts, args) do
    if opts[:help] do
      IO.puts(@moduledoc)
    else
      with {"erl " <> commands, 0} <- run_cmd("mix", [], env: [{"ELIXIR_CLI_DRY_RUN", "1"}]) do
        commands = String.split(String.replace(commands, "\n", ""), " ", trim: true)
        root_dir = "#{:code.root_dir()}"
        bin_dir = Path.join([root_dir, "erts-#{:erlang.system_info(:version)}", "bin"])
        erlexec = Path.join([bin_dir, "erlexec"])
        start_boot = Path.join([root_dir, "bin", "start.boot"])

        env = [
          {"BINDIR", bin_dir},
          {"ROOTDIR", root_dir},
          {"START_BOOT", start_boot},
          {"EMU", "beam"}
        ]

        cwd = opts[:mix_project_root] || File.cwd!()

        if opts[:generate] do
          generate_project(opts[:generate], cwd, erlexec, commands, args, env, opts)
        else
          {debugger, debugger_args} =
            case Keyword.get(opts, :debugger, default_debugger()) do
              {debugger, debugger_args} ->
                {debugger, debugger_args}

              debugger ->
                [debugger | debugger_args] = String.split(debugger, " ", trim: true)
                {debugger, debugger_args}
            end

          print_cmd_only = opts[:print_cmd_only] || false
          print_only = opts[:print_only] || false

          args = debugger_args ++ [erlexec] ++ commands ++ args
          debugger = System.find_executable(debugger) || raise "cannot find debugger: #{debugger}"

          if print_only do
            Enum.each(env, fn {name, val} ->
              IO.puts("export #{name}=\"#{val}\"")
            end)
          end

          if print_cmd_only or print_only do
            IO.puts("#{debugger} #{Enum.join(args, " ")}")
          else
            Enum.map(env, fn {name, val} ->
              System.put_env(name, val)
            end)

            saved_cwd = File.cwd!()
            File.cd!(cwd)

            case :debug_nif.run_shell([debugger] ++ args) do
              {:error, msg} ->
                IO.puts("Error: #{msg}")

              {:ok, status} ->
                IO.puts("exited with code: #{status}")
            end

            File.cd!(saved_cwd)
          end
        end
      end
    end
  end

  @doc false
  def run_cmd(binary, args, opts \\ []) do
    default_opts = [
      into: "",
      stderr_to_stdout: true,
      cd: Path.expand(File.cwd!())
    ]

    opts = Keyword.merge(default_opts, opts, fn _k, _d, u -> u end)
    System.cmd(binary, args, opts)
  end
end
