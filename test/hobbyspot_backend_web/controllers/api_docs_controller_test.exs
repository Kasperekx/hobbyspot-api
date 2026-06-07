defmodule HobbyspotBackendWeb.ApiDocsControllerTest do
  use HobbyspotBackendWeb.ConnCase, async: true

  describe "GET /api/openapi.json" do
    test "returns the mobile API OpenAPI specification", %{conn: conn} do
      conn = get(conn, ~p"/api/openapi.json")

      assert %{
               "openapi" => openapi_version,
               "info" => %{
                 "title" => "Hobbyspot API",
                 "version" => "0.1.0"
               },
               "paths" => paths,
               "components" => %{"schemas" => schemas}
             } = json_response(conn, 200)

      assert String.starts_with?(openapi_version, "3.")

      assert Map.has_key?(paths, "/api/users/register")
      assert Map.has_key?(paths, "/api/users/log-in")
      assert Map.has_key?(paths, "/api/users/me")
      assert Map.has_key?(paths, "/api/users/me/onboarding")
      assert Map.has_key?(paths, "/api/users/me/location")
      assert Map.has_key?(paths, "/api/users/log-out")

      assert schemas["User"]["properties"]["id"] == %{"type" => "string", "format" => "uuid"}
      assert schemas["Location"]["properties"]["id"] == %{"type" => "string", "format" => "uuid"}

      assert schemas["LocationRequest"]["properties"]["location"]["properties"][
               "search_radius_meters"
             ]["default"] == 5000

      assert schemas["LocationRequest"]["properties"]["location"]["properties"]["source"][
               "enum"
             ] == ["manual", "gps"]
    end
  end

  describe "GET /docs" do
    test "returns the Scalar API reference page", %{conn: conn} do
      conn = get(conn, ~p"/docs")
      body = html_response(conn, 200)

      assert body =~ "Hobbyspot API"
      assert body =~ "api-reference"
      assert body =~ "/api/openapi.json"
      assert body =~ "Scalar"
    end
  end
end
