# HobbyspotBackend

Backend for Hobbyspot, a real-time social app for finding nearby people who want
to do the same activities.

## Requirements

* Elixir 1.18+
* Erlang/OTP 27+
* Docker with Docker Compose

## Local setup

Start Postgres 17 with PostGIS:

```bash
docker compose up -d postgres
```

Install dependencies, create the database, run migrations, seed data, and build
assets:

```bash
mix setup
```

To start your Phoenix server:

* Start Phoenix endpoint with `mix phx.server` or inside IEx with `iex -S mix phx.server`

Now you can visit [`localhost:4000`](http://localhost:4000) from your browser.

## Database configuration

The local defaults match `docker-compose.yml`:

```bash
POSTGRES_USER=postgres
POSTGRES_PASSWORD=postgres
POSTGRES_HOSTNAME=localhost
POSTGRES_PORT=5432
POSTGRES_DB=hobbyspot_backend_dev
POSTGRES_TEST_DB=hobbyspot_backend_test
```

Copy `.env.example` to `.env` if you want a local reference file, then export the
values in your shell before running Mix commands that should use custom values.

## Verification

```bash
mix test
mix precommit
```

## API docs

* Scalar API reference: http://localhost:4000/docs
* OpenAPI JSON: http://localhost:4000/api/openapi.json
* [Mobile auth API](docs/api/auth.md)
* [Mobile location API](docs/api/location.md)

Ready to run in production? Please [check our deployment guides](https://hexdocs.pm/phoenix/deployment.html).

## Learn more

* Official website: https://www.phoenixframework.org/
* Guides: https://hexdocs.pm/phoenix/overview.html
* Docs: https://hexdocs.pm/phoenix
* Forum: https://elixirforum.com/c/phoenix-forum
* Source: https://github.com/phoenixframework/phoenix
