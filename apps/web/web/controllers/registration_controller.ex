defmodule Web.RegistrationController do
  use Web.Web, :controller

  plug :scrub_params, "registration" when action in [:register]

  def register(conn, %{"registration" => params}) do
    case Typi.register(params) do
      {:ok, _registration} ->
        conn
        |> put_status(:ok)
        |> json(%{})
      {:error, changeset} ->
        conn
        |> put_status(:unprocessable_entity)
        |> json(%{errors: %{registration: "invalid input"}})
    end
  end
end
