defmodule Web.UserChannel do
  use Web.Web, :channel

  def join("user:" <> user_id, %{last_seen_event_ts: last_seen_event_ts}, socket) do
    if authorized?(user_id, socket) do
      send self(), {:after_join, user_id, last_seen_event_ts}
      {:ok, socket}
    else
      {:error, %{reason: "unauthorized"}}
    end
  end

  def handle_info({:after_join, user_id, last_seen_event_ts}, socket) do
    {:ok, _} = Web.Presence.track(socket, socket.assigns.current_user.id, %{})
    {:ok, session} = Messaging.connect(self, user_id, last_seen_event_ts)
    {:noreply, assign(socket, :session, session)}
  end

  def handle_info({:event, event}, socket) do
    push socket, "event", event
    {:noreply, socket}
  end

  # def handle_in("contacts", %{"contacts" => contacts}, socket) do
  #   {:noreply, socket}
  # end

  def handle_in("event", event, socket) do
    Messaging.process(event)
    {:noreply, socket}
  end

  defp authorized?(user_id, socket) do
    String.to_integer(user_id) == socket.assigns.current_user.id
  end
end
