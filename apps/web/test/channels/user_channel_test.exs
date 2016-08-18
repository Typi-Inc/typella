defmodule Web.UserChannelTest do
  use Web.ChannelCase
  import RethinkDB.Query
  import Messaging.ConfigHelpers

  setup do
    user = %Typi.User{} |> Typi.Repo.insert!
    {:ok, token, _full_claims} = Guardian.encode_and_sign(user, :token)
    {:ok, socket} = connect(Web.UserSocket, %{"token" => token})
    {:ok, _, socket} = subscribe_and_join(socket, "user:#{user.id}", %{last_seen_event_ts: :os.system_time(:milli_seconds)})
    :timer.sleep 1000 # session needs some time to create a table
    {:ok, socket: socket, user: user}
  end

  test "can only join your channel", %{socket: socket, user: user} do
    assert {:error, %{reason: "unauthorized"}} =
      subscribe_and_join(socket, "user:#{user.id + 1}", %{last_seen_event_ts: :os.system_time(:milli_seconds)})
  end

  test "events are pushed down the socket", %{socket: socket, user: user} do
    # create user tables
    channel_participants = [1, 2, user.id]
    :poolboy.transaction(:rethinkdb_pool, fn conn ->
      for user_id <- channel_participants do
        table_create(user_events_table_name.(user_id))
        |> RethinkDB.run(conn)
      end
    end)

    # create chat channel via event system
    create_channel_event = %{
      "type" => "create_channel",
      "channel" => %{
        "name" => "fun",
        "creator" => user.id,
        "participants" => channel_participants
      }
    }
    ref = push socket, "event", create_channel_event
    assert_push "event", channel_created_event
    assert channel_created_event["type"] == "channel_created"
    for key <- Map.keys(create_channel_event["channel"]) do
      assert Map.get(channel_created_event["channel"], key) == Map.get(create_channel_event["channel"], key)
    end

    # send a message
    message_event = %{
      "type" => "message",
      "channel_id" => channel_created_event["channel"]["id"],
      "user" => user.id,
      "text" => "Hello, World!"
    }
    ref = push socket, "event", message_event

    # assert message is pushed
    assert_push "event", received_message_event
    assert received_message_event["type"] == "message"
    for key <- Map.keys(message_event) do
      assert Map.get(received_message_event, key) == Map.get(message_event, key)
    end
  end
end
