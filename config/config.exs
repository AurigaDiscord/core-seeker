use Mix.Config

config :seeker,
  amqp_path:        {:system, "AMQP_PATH", "amqp://guest:guest@localhost"},
  amqp_exchange:    {:system, "AMQP_EXCHANGE", "topic"},
  amqp_queue_raw:   {:system, "AMQP_QUEUE_RAW", "raw"},
  amqp_key_message: {:system, "AMQP_KEY_MESSAGE", "parse"},
  amqp_key_guild:   {:system, "AMQP_KEY_GUILD", "guild"}

config :logger, :console,
  level: :info,
  format: "$date $time $metadata[$level] $levelpad$message\n"

config :tzdata, :autoupdate, :disabled
