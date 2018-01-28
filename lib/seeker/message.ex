defmodule Seeker.Message do
  require Logger
  alias Seeker.MQ

  @type_message_create "MESSAGE_CREATE"
  @type_guild_create   "GUILD_CREATE"

  def process(msg) do
    {:ok, decoded} = Poison.Parser.parse(msg, keys: :atoms)
    case process_decoded(decoded) do
      {:push, topic, msg_to_push} -> MQ.produce(topic, msg_to_push)
      :nopush                     -> :ok
    end
  end

  defp process_decoded(%{:t => @type_message_create} = msg) do
    d = msg[:d]
    output = %{
      timestamp:  Timex.to_unix(Timex.parse!(d[:timestamp], "{ISO:Extended}")),
      channel_id: d[:channel_id],
      user_id:    d[:author][:id],
      user_name:  d[:author][:username],
      content:    d[:content],
    }
    {:ok, encoded} = Poison.encode(output)
    {:push, :message, encoded}
  end
  defp process_decoded(%{:t => @type_guild_create} = msg) do
    Logger.info("guild, #{msg[:d][:name]}")
    :nopush
  end
  defp process_decoded(_msg) do
    :nopush
  end
  
end
