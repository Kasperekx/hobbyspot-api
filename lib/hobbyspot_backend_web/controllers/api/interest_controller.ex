defmodule HobbyspotBackendWeb.Api.InterestController do
  use HobbyspotBackendWeb, :controller

  alias HobbyspotBackend.Accounts
  alias HobbyspotBackendWeb.Api.UserResponse

  def index(conn, _params) do
    interests =
      Accounts.list_interests()
      |> Enum.map(&UserResponse.catalog_interest_json/1)

    json(conn, %{data: interests})
  end

  def update_user_interests(conn, %{"interests" => interest_slugs}) do
    user = conn.assigns.current_scope.user

    case Accounts.update_user_interests(user, interest_slugs) do
      {:ok, user} ->
        json(conn, %{data: UserResponse.user_data(user)})

      {:error, %Ecto.Changeset{} = changeset} ->
        conn
        |> put_status(:unprocessable_entity)
        |> json(%{errors: errors_on(changeset)})
    end
  end

  def update_user_interests(conn, _params) do
    conn
    |> put_status(:unprocessable_entity)
    |> json(%{errors: %{interests: ["can't be blank"]}})
  end

  defp errors_on(changeset) do
    Ecto.Changeset.traverse_errors(changeset, fn {message, opts} ->
      Regex.replace(~r"%{(\w+)}", message, fn _, key ->
        opts |> Keyword.get(String.to_existing_atom(key), key) |> to_string()
      end)
    end)
  end
end
