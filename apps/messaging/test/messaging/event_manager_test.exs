defmodule Messaging.EventManagerTest do
  use ExUnit.Case, async: true

  alias Messaging.EventManager

  setup do
    {:ok, _} = EventManager.start_link
    :ok
  end

  @tag hello: "hello"
  test "processes can subscribe to topics" do
    pid = spawn(fn -> :ok end)
    assert EventManager.subscribers("foo") == []
    assert :ok = EventManager.subscribe(self, "foo")
    assert :ok = EventManager.subscribe(pid, "foo")
    assert :ok = EventManager.subscribe(self, "foo")
    assert EventManager.subscribers("foo") == [self, pid]
  end

  test "publish sends events" do
    assert :ok = EventManager.subscribe(self, "foo")
    assert EventManager.subscribers("foo") == [self]
    assert :ok = EventManager.broadcast("foo", :hello)
    # TODO need to find better way
    Process.sleep(100)
    assert_received :hello
  end

  test "unsubscribe deletes topic subscription" do
    pid = spawn(fn -> :ok end)
    assert :ok = EventManager.subscribe(self, "topic1")
    assert :ok = EventManager.subscribe(pid, "topic1")

    assert EventManager.subscribers("topic1") == [self, pid]
    assert :ok = EventManager.unsubscribe(self, "topic1")
    assert EventManager.subscribers("topic1") == [pid]
  end

  test "unsubscribe deletes topic when there are no more subscriptions" do
    assert :ok = EventManager.subscribe(self, "topic1")
    assert :ok = EventManager.unsubscribe(self, "topic1")
    assert EventManager.topics == []
  end

  test "unsubscribe when topic does not exist" do
    assert :ok = EventManager.unsubscribe(self, "notexistent")
    assert EventManager.subscribers("notexistent") == []
    assert EventManager.topics == []
  end

  test "pid is unsubscribed when DOWN" do
    {pid, ref} = spawn_monitor fn -> :timer.sleep(:infinity) end
    assert :ok = EventManager.subscribe(self, "topic2")
    assert :ok = EventManager.subscribe(pid, "topic2")
    assert :ok = EventManager.subscribe(pid, "topic3")

    Process.exit(pid, :kill)
    assert_receive {:DOWN, ^ref, _, _, _}

    assert EventManager.subscribers("topic2") == [self]
    assert EventManager.topics == ["topic2"]
  end
end
