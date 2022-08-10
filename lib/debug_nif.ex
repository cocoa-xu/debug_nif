defmodule :debug_nif do
  @moduledoc false

  @on_load :load_nif
  def load_nif do
    nif_file = '#{:code.priv_dir(:debug_nif)}/debug'
    nif_file =
      if File.exists?("#{nif_file}.so") do
        nif_file
      else
        Path.expand("#{:code.priv_dir(:debug_nif)}/../../priv/debug")
        |> String.to_charlist()
      end

    case :erlang.load_nif(nif_file, 0) do
      :ok -> :ok
      {:error, {:reload, _}} -> :ok
      {:error, reason} -> IO.puts("Failed to load nif: #{reason}")
    end
  end

  def run_shell(_args), do: :erlang.nif_error(:not_loaded)
end
