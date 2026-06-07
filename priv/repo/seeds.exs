# Script for populating the database. You can run it as:
#
#     mix run priv/repo/seeds.exs
#
# Inside the script, you can read and write to any of your
# repositories directly:
#
#     HobbyspotBackend.Repo.insert!(%HobbyspotBackend.SomeSchema{})
#
# We recommend using the bang functions (`insert!`, `update!`
# and so on) as they will fail if something goes wrong.

alias HobbyspotBackend.Accounts.Interest
alias HobbyspotBackend.Repo

timestamp = NaiveDateTime.utc_now(:second)

interests = [
  %{
    id: "11111111-1111-4111-8111-111111111111",
    slug: "dog_walks",
    name: "Psy i spacery",
    description: "Spacery z psem i luzne wyjscia na zewnatrz.",
    icon: "dog",
    is_active: true,
    position: 1,
    inserted_at: timestamp,
    updated_at: timestamp
  },
  %{
    id: "22222222-2222-4222-8222-222222222222",
    slug: "running",
    name: "Bieganie",
    description: "Wspolne biegi, easy runy i treningi w okolicy.",
    icon: "footprints",
    is_active: true,
    position: 2,
    inserted_at: timestamp,
    updated_at: timestamp
  },
  %{
    id: "33333333-3333-4333-8333-333333333333",
    slug: "cycling",
    name: "Rower",
    description: "Krotkie przejazdy, trasy rowerowe i spontaniczne ustawki.",
    icon: "bike",
    is_active: true,
    position: 3,
    inserted_at: timestamp,
    updated_at: timestamp
  },
  %{
    id: "44444444-4444-4444-8444-444444444444",
    slug: "board_games",
    name: "Planszowki",
    description: "Planszowki, karcianki i wieczory przy stole.",
    icon: "dice-5",
    is_active: true,
    position: 4,
    inserted_at: timestamp,
    updated_at: timestamp
  },
  %{
    id: "55555555-5555-4555-8555-555555555555",
    slug: "photography",
    name: "Fotografia",
    description: "Spacery fotograficzne, plenery i wspolne robienie zdjec.",
    icon: "camera",
    is_active: true,
    position: 5,
    inserted_at: timestamp,
    updated_at: timestamp
  }
]

Repo.insert_all(Interest, interests,
  on_conflict: {:replace, [:name, :description, :icon, :is_active, :position, :updated_at]},
  conflict_target: :slug
)
