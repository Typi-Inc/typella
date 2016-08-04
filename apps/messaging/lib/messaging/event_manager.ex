defmodule Messaging.EventManager do
  use GenServer

  def start_link do
    GenServer.start_link(__MODULE__, :ok, name: __MODULE__)
  end

  def subscribe(pid, topic) do
    GenServer.cast(__MODULE__, {:subscribe, %{pid: pid, topic: topic}})
  end

  def broadcast(topic, event) do
    GenServer.cast(__MODULE__, {:broadcast, %{topic: topic, event: event}})
  end

  def unsubscribe(pid, topic) do
    GenServer.cast(__MODULE__, {:unsubscribe, %{pid: pid, topic: topic}})
  end

  def subscribers(topic) do
    GenServer.call(__MODULE__, {:subscribers, topic})
  end

  def topics do
    GenServer.call(__MODULE__, :topics)
  end

  def init(:ok) do
    {:ok, {%{}, %{}}}
  end

  def handle_cast({:subscribe, %{pid: pid, topic: topic}}, {state, refs}) do
    ref = Process.monitor(pid)
    subscribers = get_subscribers(topic, state)
    new_state =
      if Enum.member?(subscribers, pid) do
        state
      else
        Map.put(state, topic, subscribers ++ [pid])
      end
    {:noreply, {new_state, Map.put(refs, ref, pid)}}
  end

  def handle_cast({:broadcast, %{topic: topic, event: event}}, {state, refs}) do
    for subscriber <- get_subscribers(topic, state) do
      send(subscriber, event)
    end
    {:noreply, {state, refs}}
  end

  def handle_cast({:unsubscribe, %{pid: pid, topic: topic}}, {state, refs}) do
    subscribers = get_subscribers(topic, state)
    new_subscribers = List.delete(subscribers, pid)
    new_state =
      case new_subscribers do
        [] -> Map.delete(state, topic)
        _ -> Map.put(state, topic, new_subscribers)
      end
    {:noreply, {new_state, refs}}
  end

  def handle_call({:subscribers, topic}, _from, {state, refs}) do
    {:reply, get_subscribers(topic, state), {state, refs}}
  end

  def handle_call(:topics, _from, {state, refs}) do
    {:reply, get_topics(state), {state, refs}}
  end

  def handle_info({:DOWN, ref, :process, _pid, _reason}, {state, refs}) do
    {pid, refs} = Map.pop(refs, ref)
  end

  defp get_subscribers(topic, state) do
    Map.get(state, topic, [])
  end

  defp get_topics(state) do
    Map.keys(state)
  end
end
