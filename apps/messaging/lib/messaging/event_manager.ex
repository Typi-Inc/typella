defmodule Messaging.EventManager do
  use GenServer

  def start_link(_options) do
    GenServer.start_link(__MODULE__, :ok, [])
  end

  def broadcast(server, event) do
    GenServer.cast(server, {:broadcast, event})
  end

  def init(_options) do
    {:ok, []}
  end

  def handle_cast({:broadcast, event}, state) do
    :poolboy.transaction(:event_saver_pool, fn worker ->
      Messaging.Worker.save_event(worker, event)
    end)
    {:noreply, state}
  end
end
