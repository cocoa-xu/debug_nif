defmodule :debug_nif do
  @moduledoc false

  defp get_nif_file do
    cache_opts = if System.get_env("MIX_XDG"), do: %{os: :linux}, else: %{}
    cache_dir = :filename.basedir(:user_cache, "", cache_opts)

    [
      '#{:code.priv_dir(:debug_nif)}/debug',
      String.to_charlist(Path.expand("#{:code.priv_dir(:debug_nif)}/../../priv/debug")),
      String.to_charlist(Path.expand(Path.join([cache_dir, "debug_nif", "priv", "debug"])))
    ]
    |> Enum.map(fn candidate ->
      {candidate, File.exists?("#{candidate}.so")}
    end)
    |> Enum.reject(fn {_path, exists?} -> exists? == false end)
    |> Enum.at(0)
    |> elem(0)
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
