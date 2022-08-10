defmodule :debug_nif do
  @moduledoc false
  require Logger

  defp current_system_architecture do
    # get current target triplet from `:erlang.system_info/1`
    system_architecture = to_string(:erlang.system_info(:system_architecture))
    current = String.split(system_architecture, "-", trim: true)
    case length(current) do
      4 ->
        {:ok, "#{Enum.at(current, 0)}-#{Enum.at(current, 2)}-#{Enum.at(current, 3)}"}
      3 ->
        case :os.type() do
          {:unix, :darwin} ->
            # could be something like aarch64-apple-darwin21.0.0
            # but we don't really need the last 21.0.0 part
            if String.match?(Enum.at(current, 2), ~r/^darwin.*/) do
              {:ok, "#{Enum.at(current, 0)}-#{Enum.at(current, 1)}-darwin"}
            else
              {:ok, system_architecture}
            end
          _ ->
            {:ok, system_architecture}
        end
      _ ->
        {:error, "cannot decide current target"}
    end
  end

  defp download_nif_artifact(url) do
    url = String.to_charlist(url)

    {:ok, _} = Application.ensure_all_started(:inets)
    {:ok, _} = Application.ensure_all_started(:ssl)

    if proxy = System.get_env("HTTP_PROXY") || System.get_env("http_proxy") do
      Logger.debug("Using HTTP_PROXY: #{proxy}")
      %{host: host, port: port} = URI.parse(proxy)

      :httpc.set_options([{:proxy, {{String.to_charlist(host), port}, []}}])
    end

    if proxy = System.get_env("HTTPS_PROXY") || System.get_env("https_proxy") do
      Logger.debug("Using HTTPS_PROXY: #{proxy}")
      %{host: host, port: port} = URI.parse(proxy)
      :httpc.set_options([{:https_proxy, {{String.to_charlist(host), port}, []}}])
    end

    # https://erlef.github.io/security-wg/secure_coding_and_deployment_hardening/inets
    # cacertfile = CAStore.file_path() |> String.to_charlist()

    http_options = [
      ssl: [
        # verify: :verify_peer,
        # cacertfile: cacertfile,
        # depth: 2,
        customize_hostname_check: [
          match_fun: :public_key.pkix_verify_hostname_match_fun(:https)
        ]
      ]
    ]

    options = [body_format: :binary]

    case :httpc.request(:get, {url, []}, http_options, options) do
      {:ok, {{_, 200, _}, _headers, body}} ->
        {:ok, body}

      other ->
        {:error, "couldn't fetch NIF from #{url}: #{inspect(other)}"}
    end
  end

  @base_url Mix.Project.config()[:download_base_url]
  @version Mix.Project.config()[:version]
  defp get_nif_file do
    cache_opts = if System.get_env("MIX_XDG"), do: %{os: :linux}, else: %{}
    cache_dir = :filename.basedir(:user_cache, "", cache_opts)
    debug_nif_priv = Path.join([cache_dir, "debug_nif", "priv"])
    cached_nif_file = Path.expand(Path.join([debug_nif_priv, "debug"]))

    existing_nif_file =
      [
        '#{:code.priv_dir(:debug_nif)}/debug',
        String.to_charlist(Path.expand("#{:code.priv_dir(:debug_nif)}/../../priv/debug")),
        String.to_charlist(cached_nif_file)
      ]
      |> Enum.map(fn candidate ->
        {candidate, File.exists?("#{candidate}.so")}
      end)
      |> Enum.reject(fn {_path, exists?} -> exists? == false end)

    if Enum.count(existing_nif_file) == 0 do

      with {:ok, target} <- current_system_architecture(),
           {:ok, nif_file} <- download_nif_artifact("#{@base_url}/debug-#{target}-#{@version}.so") do
        File.mkdir_p(debug_nif_priv)
        File.write!("#{cached_nif_file}.so", nif_file)
        String.to_charlist(cached_nif_file)
      else
         {:error, error} -> raise error
      end
    else
      existing_nif_file
      |> Enum.at(0)
      |> elem(0)
    end
  end

  @on_load :load_nif
  def load_nif do
    nif_file = get_nif_file()
    case :erlang.load_nif(nif_file, 0) do
      :ok -> :ok
      {:error, {:reload, _}} -> :ok
      {:error, reason} -> IO.puts("Failed to load nif: #{reason}")
    end
  end

  def run_shell(_args), do: :erlang.nif_error(:not_loaded)
end
