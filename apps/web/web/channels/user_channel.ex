defmodule Web.UserChannel do
  use Web.Web, :channel

  def join("users:" <> user_id, _payload, socket) do
    if authorized?(user_id, socket) do
      send self(), :after_join
      {:ok, socket}
    else
      {:error, %{reason: "unauthorized"}}
    end
  end

  # def handle_info(:after_join, socket) do
  #   {:ok, _} = Presence.track(socket, socket.assigns.current_user.id, %{})
  #   {:ok, session} = Messaging.Session
  #   {:noreply, socket}
  # end
  #
  # def handle_in("contacts", %{"contacts" => contacts}, socket) do
  #
  # end
  #
  # def handle_in("statuses", %{"statuses" => statuses}, socket) do
  #   for status <- statuses do
  #     handle_in("status", status, socket)
  #   end
  #   {:noreply, socket}
  # end
  #
  # def handle_in("status", %{"id" => message_id, "status" => status} = payload, socket) do
  #   statuses = update_status_and_get_statuses(message_id, status, socket)
  #   broadcast_if_status_changed(statuses, message_id)
  #   {:noreply, socket}
  # end

  defp authorized?(user_id, socket) do
    String.to_integer(user_id) == socket.assigns.current_user.id
  end
end
