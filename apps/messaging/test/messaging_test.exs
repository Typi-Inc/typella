defmodule MessagingTest do
  use Messaging.RethinkDBCase

  @message_event %{
    "type" => "message",
    "channel" => 123,
    "user" => 1,
    "text" => "Hello, World!"
  }

  @create_channel_event %{
    "type" => "channel",
    "channel" => %{
      "name": "fun",
      "creator": 123
    }
  }

  test "when event is injected into the system, it is stored into the main table", %{conn: conn} do
    Messaging.broadcast @message_event
    :timer.sleep 100
    assert %Collection{data: [message_event]} =
      table(events_table_name)
      |> RethinkDB.run(conn)
    for key <- Map.keys(@message_event) do
      assert Map.get(message_event, key) == Map.get(@message_event, key)
    end
  end

  test "when event is create_channel, the channel is created", %{conn: conn} do
    Messaging.broadcast @create_channel_event
    :timer.sleep 100
    assert %Collection{data: channels} =
      table(channels_table_name)
      |> RethinkDB.run(conn)
    assert Enum.member?(channels, @channel)
  end

  test "when event is a message it is stored to channel participants' table", %{conn: conn} do
    user_ids = 1..3 |> Enum.to_list
    %Record{data: %{"generated_keys" => [id]}} = table(channels_table_name)
      |> insert(%{
        user_ids: user_ids
      })
      |> RethinkDB.run(conn)

    event = Map.put(@message_event, "channel", id)
    Messaging.broadcast(event)
    :timer.sleep 100
    for user_id <- user_ids do
      assert %Collection{data: [received_event]} =
        table(user_events_table_name.(user_id))
        |> RethinkDB.run(conn)
      for key <- Map.keys(event) do
        assert Map.get(received_event, key) == Map.get(event, key)
      end
    end
  end

  test "connect spawns supervised session", %{conn: conn} do
    user_id = 1
    {:ok, session} = Messaging.connect(self, user_id, :os.system_time(:milli_seconds))

    :timer.sleep(100)
    table(user_events_table_name.(user_id))
    |> insert(@message_event)
    |> RethinkDB.run(conn)

    assert_receive {:event, event}
    for key <- Map.keys(@message_event) do
      assert Map.get(event, key) == Map.get(@message_event, key)
    end
  end
end
