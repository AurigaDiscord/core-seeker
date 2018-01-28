defmodule Seeker do
  require Logger
  use Application

  def start(_type, _args) do
    Logger.info "Starting seeker application"
    Confex.resolve_env!(:seeker)

    import Supervisor.Spec, warn: false
    sup_children = [
      worker(Seeker.MQ, []),
    ]
    sup_opts = [strategy: :one_for_one, name: Seeker.Supervisor]
    Supervisor.start_link(sup_children, sup_opts)
  end

end
