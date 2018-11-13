defmodule ExBanking.Application do
  use Application

  def start(_type, _spec) do
    import Supervisor.Spec

    children = [
      supervisor(ExBanking.Supervisor, []),
      supervisor(Registry, [:unique, ExBanking.Registry])
    ]

    Supervisor.start_link(children, strategy: :one_for_all)
  end
end
