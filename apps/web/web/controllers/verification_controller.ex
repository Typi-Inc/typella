defmodule Web.VerificationController do
  use Web.Web, :controller

  plug :scrub_params, "verification" when action in [:create]

  def register(conn, %{"verification" => params}) do
    case Typi.verify(params) do
      {:ok, jwt} ->
        conn
        |> put_status(:created)
        |> put_in_resp(%{jwt: "jwt"})
      {:error, changeset} ->
        conn
        |> put_status(:unprocessable_entity)
        |> json(%{errors: %{verification: ["invalid input"]}})
    end
  end
end
