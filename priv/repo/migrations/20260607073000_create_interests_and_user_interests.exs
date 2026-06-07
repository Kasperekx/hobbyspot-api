defmodule HobbyspotBackend.Repo.Migrations.CreateInterestsAndUserInterests do
  use Ecto.Migration
  import Ecto.Query

  @interests [
    %{
      id: "11111111-1111-4111-8111-111111111111",
      slug: "dog_walks",
      name: "Psy i spacery",
      description: "Spacery z psem i luzne wyjscia na zewnatrz.",
      icon: "dog",
      position: 1
    },
    %{
      id: "22222222-2222-4222-8222-222222222222",
      slug: "running",
      name: "Bieganie",
      description: "Wspolne biegi, easy runy i treningi w okolicy.",
      icon: "footprints",
      position: 2
    },
    %{
      id: "33333333-3333-4333-8333-333333333333",
      slug: "cycling",
      name: "Rower",
      description: "Krotkie przejazdy, trasy rowerowe i spontaniczne ustawki.",
      icon: "bike",
      position: 3
    },
    %{
      id: "44444444-4444-4444-8444-444444444444",
      slug: "board_games",
      name: "Planszowki",
      description: "Planszowki, karcianki i wieczory przy stole.",
      icon: "dice-5",
      position: 4
    },
    %{
      id: "55555555-5555-4555-8555-555555555555",
      slug: "photography",
      name: "Fotografia",
      description: "Spacery fotograficzne, plenery i wspolne robienie zdjec.",
      icon: "camera",
      position: 5
    }
  ]

  def change do
    create table(:interests, primary_key: false) do
      add :id, :binary_id, primary_key: true
      add :slug, :string, null: false
      add :name, :string, null: false
      add :description, :text, null: false
      add :icon, :string, null: false
      add :is_active, :boolean, null: false, default: true
      add :position, :integer, null: false

      timestamps(type: :utc_datetime)
    end

    create unique_index(:interests, [:slug])
    create index(:interests, [:is_active, :position])

    create table(:user_interests, primary_key: false) do
      add :id, :binary_id, primary_key: true
      add :user_id, references(:users, type: :binary_id, on_delete: :delete_all), null: false

      add :interest_id, references(:interests, type: :binary_id, on_delete: :delete_all),
        null: false

      add :notifications_enabled, :boolean, null: false, default: true

      timestamps(type: :utc_datetime)
    end

    create index(:user_interests, [:user_id])
    create index(:user_interests, [:interest_id])
    create unique_index(:user_interests, [:user_id, :interest_id])

    execute(&seed_interests/0, &delete_seeded_interests/0)
  end

  defp seed_interests do
    timestamp = NaiveDateTime.utc_now(:second)

    entries =
      Enum.map(@interests, fn interest ->
        interest
        |> Map.put(:id, Ecto.UUID.dump!(interest.id))
        |> Map.merge(%{
          inserted_at: timestamp,
          updated_at: timestamp
        })
      end)

    repo().insert_all("interests", entries,
      on_conflict: {:replace, [:name, :description, :icon, :is_active, :position, :updated_at]},
      conflict_target: :slug
    )
  end

  defp delete_seeded_interests do
    slugs = Enum.map(@interests, & &1.slug)
    repo().delete_all(from(i in "interests", where: i.slug in ^slugs))
  end
end
