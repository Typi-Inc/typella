defmodule Messaging.SessionSupervisor do
  use Supervisor

  def start_link do
    Supervisor.start_link(__MODULE__, :ok, name: __MODULE__)
  end

  def start_session(opts) do
    Supervisor.start_child(__MODULE__, opts)
  end

  def init(:ok) do
    children = [
      worker(Messaging.Session, [])
    ]

    supervise(children, strategy: :simple_one_for_one)
  end
end
