defmodule HobbyspotBackendWeb.PageController do
  use HobbyspotBackendWeb, :controller

  def home(conn, _params) do
    render(conn, :home)
  end
end
