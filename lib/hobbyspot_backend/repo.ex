defmodule HobbyspotBackend.Repo do
  use Ecto.Repo,
    otp_app: :hobbyspot_backend,
    adapter: Ecto.Adapters.Postgres
end
