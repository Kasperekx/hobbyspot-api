defmodule HobbyspotBackendWeb.ApiDocsController do
  use HobbyspotBackendWeb, :controller

  alias HobbyspotBackendWeb.OpenApiSpec

  def openapi(conn, _params) do
    json(conn, OpenApiSpec.spec())
  end

  def scalar(conn, _params) do
    html(conn, scalar_html())
  end

  defp scalar_html do
    """
    <!doctype html>
    <html lang="en">
      <head>
        <meta charset="utf-8" />
        <meta name="viewport" content="width=device-width, initial-scale=1" />
        <title>Hobbyspot API | Scalar</title>
        <style>
          body {
            margin: 0;
            min-height: 100vh;
          }
        </style>
      </head>
      <body>
        <script id="api-reference" data-url="/api/openapi.json"></script>
        <script src="https://cdn.jsdelivr.net/npm/@scalar/api-reference"></script>
      </body>
    </html>
    """
  end
end
