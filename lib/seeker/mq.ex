defmodule Seeker.MQ do
  require Logger
  use GenServer
  use AMQP
  alias Seeker.Message

  def produce(key, message) do
    GenServer.cast(Seeker.MQ, {:produce, key, message})
  end

  def start_link do
    GenServer.start_link(__MODULE__, [], name: Seeker.MQ)
  end

  def init(_) do
    {:ok, chan, queue, keys, exchange} = mq_connect
    state = %{
      chan:     chan,
      queue:    queue,
      keys:     keys,
      exchange: exchange,
    }
    {:ok, state}
  end

  def handle_cast({:produce, key, message}, state) do
    Basic.publish(state[:chan], state[:exchange], state[:keys][key], message)
    {:noreply, state}
  end

  # Sent by the broker when the consumer is unexpectedly cancelled (such as after a queue deletion)
  def handle_info({:basic_cancel, %{consumer_tag: consumer_tag}}, state) do
    {:stop, :normal, state}
  end
  # Message delivery
  def handle_info({:basic_deliver, payload, %{delivery_tag: tag}}, state) do
    spawn fn -> consume(state[:chan], tag, payload) end
    {:noreply, state}
  end
  # Channel process is down
  def handle_info({:DOWN, _, :process, _pid, _reason}, state) do
    {:ok, chan, queue, keys, exchange} = mq_connect
    {:noreply, %{state | chan:     chan,
                         queue:    queue,
                         keys:     keys,
                         exchange: exchange}}
  end
  # Catch-all
  def handle_info(_, state) do
    {:noreply, state}
  end

  defp generate_mq_vars do
    mq_path = Application.get_env(:seeker, :amqp_path)
    cfg_exchange = Application.get_env(:seeker, :amqp_exchange)
    cfg_raw = Application.get_env(:seeker, :amqp_queue_raw)
    cfg_key_message = Application.get_env(:seeker, :amqp_key_message)
    cfg_key_guild = Application.get_env(:seeker, :amqp_key_guild)

    exchange = "auriga.#{cfg_exchange}"
    queue_raw = "#{exchange}.#{cfg_raw}"
    keys = %{
      message: "auriga.#{cfg_key_message}",
      guild:   "auriga.#{cfg_key_guild}",
    }

    {:ok, mq_path, queue_raw, keys, exchange}
  end

  defp mq_connect do
    {:ok, mq_path, queue_cons, keys, exchange} = generate_mq_vars
    mq_path_censored = Regex.replace(~r/:[^\/].+@/, mq_path, ":[REDACTED]@")
    Logger.info("Connecting to AMQP server at #{mq_path_censored}")

    case Connection.open(mq_path) do
      {:ok, conn} ->
        Process.monitor(conn.pid)
        {:ok, chan} = Channel.open(conn)
        Basic.qos(chan, prefetch_count: 10)
        {:ok, _consumer_tag} = Basic.consume(chan, queue_cons)
        Logger.info("Connected")
        {:ok, chan, queue_cons, keys, exchange}
      {:error, error} ->
        Logger.error("AMQP connection problem: #{inspect error}")
        :timer.sleep(5000)
        mq_connect
    end
  end

  defp consume(chan, tag, payload) do
    Message.process(payload)
    Basic.ack(chan, tag)
  end

end
