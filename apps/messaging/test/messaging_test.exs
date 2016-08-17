defmodule MessagingTest do
  use Messaging.RethinkDBCase

  @message_event %{
    "type" => "message",
    "channel_id" => 123,
    "user" => 1,
    "text" => "Hello, World!"
  }

  @create_channel_event %{
    "type" => "create_channel",
    "channel" => %{
      "name" => "fun",
      "creator" => 123,
      "participants" => [1, 2, 3]
    }
  }

  test "when event is injected into the system, it is stored into the main table", %{conn: conn} do
    Messaging.process @message_event
    :timer.sleep 100
    assert %Collection{data: [message_event]} =
      table(events_table_name)
      |> RethinkDB.run(conn)

    for key <- Map.keys(@message_event) do
      assert Map.get(message_event, key) == Map.get(@message_event, key)
    end
  end

  test "when event is create_channel, the channel is created, channel_created event" <>
    " is stored into the main table and channel participants table", %{conn: conn} do
    Messaging.process @create_channel_event
    :timer.sleep 100
    assert %Collection{data: [channel]} =
      table(channels_table_name)
      |> RethinkDB.run(conn)

    for key <- Map.keys(@create_channel_event["channel"]) do
      assert Map.get(channel, key) == Map.get(@create_channel_event["channel"], key)
    end

    :timer.sleep 100
    assert %Collection{data: [channel_created_event]} =
      table(events_table_name)
      |> RethinkDB.run(conn)

    for key <- Map.keys(@create_channel_event["channel"]) do
      assert Map.get(channel_created_event["channel"], key) == Map.get(@create_channel_event["channel"], key)
    end

    expected_event = %{
      "type" => "channel_created",
      "channel" => @create_channel_event["channel"]
    }
    for user_id <- @create_channel_event["channel"]["participants"] do
      assert %Collection{data: [received_event]} =
        table(user_events_table_name.(user_id))
        |> RethinkDB.run(conn)
      assert received_event["type"] == "channel_created"
      for key <- Map.keys(expected_event["channel"]) do
        assert Map.get(received_event["channel"], key) == Map.get(expected_event["channel"], key)
      end
    end
  end

  test "when event is a message it is stored to channel participants' table", %{conn: conn} do
    participants = 1..3 |> Enum.to_list
    %Record{data: %{"generated_keys" => [id]}} =
      table(channels_table_name)
      |> insert(%{
        participants: participants
      })
      |> RethinkDB.run(conn)

    event = Map.put(@message_event, "channel_id", id)
    Messaging.process(event)
    :timer.sleep 100
    for user_id <- participants do
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
    {:ok, _session} = Messaging.connect(self, user_id, :os.system_time(:milli_seconds))

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
