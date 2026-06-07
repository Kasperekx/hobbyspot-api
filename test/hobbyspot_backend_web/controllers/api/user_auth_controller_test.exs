defmodule HobbyspotBackendWeb.Api.UserAuthControllerTest do
  use HobbyspotBackendWeb.ConnCase, async: true

  import HobbyspotBackend.AccountsFixtures

  alias HobbyspotBackend.Accounts

  @password valid_user_password()

  describe "POST /api/users/register" do
    test "registers a user with email and password and returns a bearer token", %{conn: conn} do
      email = unique_user_email()

      conn =
        post(conn, ~p"/api/users/register", %{
          "user" => %{
            "email" => email,
            "password" => @password
          }
        })

      assert %{
               "data" => %{
                 "token" => token,
                 "user" => %{
                   "id" => id,
                   "email" => ^email,
                   "avatar_url" => nil,
                   "full_name" => nil,
                   "birth_date" => nil,
                   "onboarding_completed" => false
                 }
               }
             } = json_response(conn, 201)

      assert is_binary(id)
      assert is_binary(token)
      assert {user, _inserted_at} = Accounts.get_user_by_session_token(decode_token!(token))
      assert user.email == email
      assert Accounts.get_user_by_email_and_password(email, @password)
    end

    test "returns validation errors for invalid registration data", %{conn: conn} do
      conn =
        post(conn, ~p"/api/users/register", %{
          "user" => %{
            "email" => "not-an-email",
            "password" => "short"
          }
        })

      assert %{
               "errors" => %{
                 "email" => [_],
                 "password" => [_]
               }
             } = json_response(conn, 422)
    end
  end

  describe "POST /api/users/log-in" do
    test "logs in with email and password and returns a bearer token", %{conn: conn} do
      user =
        user_fixture()
        |> set_password()

      conn =
        post(conn, ~p"/api/users/log-in", %{
          "user" => %{
            "email" => user.email,
            "password" => @password
          }
        })

      assert %{
               "data" => %{
                 "token" => token,
                 "user" => %{
                   "id" => user_id,
                   "email" => email,
                   "avatar_url" => avatar_url,
                   "full_name" => full_name,
                   "birth_date" => birth_date,
                   "onboarding_completed" => onboarding_completed
                 }
               }
             } = json_response(conn, 200)

      assert user_id == user.id
      assert email == user.email
      assert avatar_url == user.avatar_url
      assert full_name == user.full_name
      assert birth_date == user.birth_date
      assert onboarding_completed == user.onboarding_completed

      assert {session_user, _inserted_at} =
               Accounts.get_user_by_session_token(decode_token!(token))

      assert session_user.id == user.id
      assert session_user.email == user.email
    end

    test "returns unauthorized for invalid credentials", %{conn: conn} do
      user =
        user_fixture()
        |> set_password()

      conn =
        post(conn, ~p"/api/users/log-in", %{
          "user" => %{
            "email" => user.email,
            "password" => "bad password"
          }
        })

      assert %{"errors" => %{"detail" => "Invalid email or password"}} = json_response(conn, 401)
    end
  end

  describe "GET /api/users/me" do
    test "returns the authenticated user", %{conn: conn} do
      user = user_fixture()
      token = Accounts.generate_user_session_token(user)

      conn =
        conn
        |> put_req_header("authorization", "Bearer #{encode_token(token)}")
        |> get(~p"/api/users/me")

      assert %{
               "data" => %{
                 "user" => %{
                   "id" => user_id,
                   "email" => email,
                   "avatar_url" => avatar_url,
                   "full_name" => full_name,
                   "birth_date" => birth_date,
                   "onboarding_completed" => onboarding_completed
                 }
               }
             } = json_response(conn, 200)

      assert user_id == user.id
      assert email == user.email
      assert avatar_url == user.avatar_url
      assert full_name == user.full_name
      assert birth_date == user.birth_date
      assert onboarding_completed == user.onboarding_completed
    end

    test "returns unauthorized without a valid bearer token", %{conn: conn} do
      conn = get(conn, ~p"/api/users/me")

      assert %{"errors" => %{"detail" => "Unauthorized"}} = json_response(conn, 401)
    end
  end

  describe "PATCH /api/users/me/onboarding" do
    test "updates onboarding profile fields and marks onboarding as completed", %{conn: conn} do
      user = user_fixture()
      token = Accounts.generate_user_session_token(user)

      conn =
        conn
        |> put_req_header("authorization", "Bearer #{encode_token(token)}")
        |> patch(~p"/api/users/me/onboarding", %{
          "user" => %{
            "avatar_url" => "https://example.com/avatar.png",
            "full_name" => "Ada Lovelace",
            "birth_date" => "1994-04-12"
          }
        })

      assert %{
               "data" => %{
                 "user" => %{
                   "id" => user_id,
                   "email" => email,
                   "avatar_url" => "https://example.com/avatar.png",
                   "full_name" => "Ada Lovelace",
                   "birth_date" => "1994-04-12",
                   "onboarding_completed" => true
                 }
               }
             } = json_response(conn, 200)

      assert user_id == user.id
      assert email == user.email

      updated_user = Accounts.get_user!(user.id)
      assert updated_user.avatar_url == "https://example.com/avatar.png"
      assert updated_user.full_name == "Ada Lovelace"
      assert updated_user.birth_date == ~D[1994-04-12]
      assert updated_user.onboarding_completed
    end

    test "returns validation errors for invalid onboarding data", %{conn: conn} do
      user = user_fixture()
      token = Accounts.generate_user_session_token(user)

      conn =
        conn
        |> put_req_header("authorization", "Bearer #{encode_token(token)}")
        |> patch(~p"/api/users/me/onboarding", %{
          "user" => %{
            "birth_date" => "not-a-date"
          }
        })

      assert %{"errors" => %{"birth_date" => [_]}} = json_response(conn, 422)
      refute Accounts.get_user!(user.id).onboarding_completed
    end
  end

  describe "DELETE /api/users/log-out" do
    test "deletes the current bearer token", %{conn: conn} do
      user = user_fixture()
      token = Accounts.generate_user_session_token(user)
      encoded_token = encode_token(token)

      conn =
        conn
        |> put_req_header("authorization", "Bearer #{encoded_token}")
        |> delete(~p"/api/users/log-out")

      assert response(conn, 204)
      refute Accounts.get_user_by_session_token(token)
    end
  end

  defp encode_token(token), do: Base.url_encode64(token, padding: false)

  defp decode_token!(token) do
    Base.url_decode64!(token, padding: false)
  end
end
