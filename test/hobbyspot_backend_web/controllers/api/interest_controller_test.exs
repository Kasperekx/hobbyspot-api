defmodule HobbyspotBackendWeb.Api.InterestControllerTest do
  use HobbyspotBackendWeb.ConnCase, async: true

  import HobbyspotBackend.AccountsFixtures

  alias HobbyspotBackend.Accounts

  describe "GET /api/interests" do
    test "returns the active MVP interest catalog", %{conn: conn} do
      conn = get(conn, ~p"/api/interests")

      assert %{"data" => interests} = json_response(conn, 200)

      assert Enum.map(interests, & &1["slug"]) == [
               "dog_walks",
               "running",
               "cycling",
               "board_games",
               "photography"
             ]

      assert Enum.map(interests, & &1["name"]) == [
               "Psy i spacery",
               "Bieganie",
               "Rower",
               "Planszowki",
               "Fotografia"
             ]

      assert Enum.all?(interests, &is_binary(&1["id"]))
      assert Enum.all?(interests, &is_binary(&1["description"]))
      assert Enum.all?(interests, &is_binary(&1["icon"]))
    end
  end

  describe "PUT /api/users/me/interests" do
    test "requires an authenticated user", %{conn: conn} do
      conn = put(conn, ~p"/api/users/me/interests", %{"interests" => ["running"]})

      assert %{"errors" => %{"detail" => "Unauthorized"}} = json_response(conn, 401)
    end

    test "stores selected user interests by slug", %{conn: conn} do
      user = user_fixture()
      token = Accounts.generate_user_session_token(user)

      conn =
        conn
        |> put_req_header("authorization", "Bearer #{encode_token(token)}")
        |> put(~p"/api/users/me/interests", %{
          "interests" => ["running", "dog_walks", "running"]
        })

      assert %{
               "data" => %{
                 "onboarding" => %{
                   "interests" => [
                     %{
                       "slug" => "dog_walks",
                       "name" => "Psy i spacery",
                       "notifications_enabled" => true
                     },
                     %{
                       "slug" => "running",
                       "name" => "Bieganie",
                       "notifications_enabled" => true
                     }
                   ]
                 }
               }
             } = json_response(conn, 200)

      conn =
        build_conn()
        |> put_req_header("authorization", "Bearer #{encode_token(token)}")
        |> get(~p"/api/users/me")

      assert %{
               "data" => %{
                 "onboarding" => %{
                   "interests" => [
                     %{"slug" => "dog_walks"},
                     %{"slug" => "running"}
                   ]
                 }
               }
             } = json_response(conn, 200)
    end

    test "replaces previous selected user interests", %{conn: conn} do
      user = user_fixture()
      token = Accounts.generate_user_session_token(user)
      encoded_token = encode_token(token)

      conn
      |> put_req_header("authorization", "Bearer #{encoded_token}")
      |> put(~p"/api/users/me/interests", %{"interests" => ["dog_walks", "running"]})
      |> json_response(200)

      conn =
        build_conn()
        |> put_req_header("authorization", "Bearer #{encoded_token}")
        |> put(~p"/api/users/me/interests", %{"interests" => ["photography"]})

      assert %{
               "data" => %{
                 "onboarding" => %{
                   "interests" => [
                     %{"slug" => "photography", "name" => "Fotografia"}
                   ]
                 }
               }
             } = json_response(conn, 200)
    end

    test "rejects an empty interest selection", %{conn: conn} do
      user = user_fixture()
      token = Accounts.generate_user_session_token(user)

      conn =
        conn
        |> put_req_header("authorization", "Bearer #{encode_token(token)}")
        |> put(~p"/api/users/me/interests", %{"interests" => []})

      assert %{"errors" => %{"interests" => [_]}} = json_response(conn, 422)
    end

    test "rejects unknown interests", %{conn: conn} do
      user = user_fixture()
      token = Accounts.generate_user_session_token(user)

      conn =
        conn
        |> put_req_header("authorization", "Bearer #{encode_token(token)}")
        |> put(~p"/api/users/me/interests", %{"interests" => ["running", "unknown"]})

      assert %{"errors" => %{"interests" => [_]}} = json_response(conn, 422)
    end
  end

  defp encode_token(token), do: Base.url_encode64(token, padding: false)
end
