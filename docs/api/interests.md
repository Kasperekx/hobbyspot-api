# Mobile Interests API

Interests are selected during onboarding and later used for event matching,
push notification relevance, and profile discovery.

The MVP catalog is intentionally small:

```text
dog_walks    -> Psy i spacery
running      -> Bieganie
cycling      -> Rower
board_games  -> Planszowki
photography  -> Fotografia
```

## List interests

Returns active interests for onboarding tiles.

```http
GET /api/interests
```

Success response: `200 OK`

```json
{
  "data": [
    {
      "id": "11111111-1111-4111-8111-111111111111",
      "slug": "dog_walks",
      "name": "Psy i spacery",
      "description": "Spacery z psem i luzne wyjscia na zewnatrz.",
      "icon": "dog"
    },
    {
      "id": "22222222-2222-4222-8222-222222222222",
      "slug": "running",
      "name": "Bieganie",
      "description": "Wspolne biegi, easy runy i treningi w okolicy.",
      "icon": "footprints"
    }
  ]
}
```

## Onboarding selection

Onboarding should send selected interests in the single final onboarding request:

```http
PATCH /api/users/me/onboarding
Authorization: Bearer <token>
```

```json
{
  "onboarding": {
    "location": {
      "latitude": 52.2297,
      "longitude": 21.0122,
      "city": "Warszawa",
      "country_code": "PL",
      "label": "Warszawa",
      "search_radius_meters": 5000,
      "source": "manual"
    },
    "interests": ["dog_walks", "running"],
    "completed": true
  }
}
```

When `completed` is `true`, at least one interest is required.

## Update current user interests

Use this endpoint after onboarding, for example from profile settings.

```http
PUT /api/users/me/interests
Authorization: Bearer <token>
```

Request body:

```json
{
  "interests": ["dog_walks", "running", "board_games"]
}
```

The provided list replaces previous selections. Duplicates are ignored. The
response returns the full current user payload.

Success response: `200 OK`

```json
{
  "data": {
    "onboarding": {
      "interests": [
        {
          "id": "11111111-1111-4111-8111-111111111111",
          "slug": "dog_walks",
          "name": "Psy i spacery",
          "notifications_enabled": true
        },
        {
          "id": "22222222-2222-4222-8222-222222222222",
          "slug": "running",
          "name": "Bieganie",
          "notifications_enabled": true
        }
      ]
    }
  }
}
```

Validation error response: `422 Unprocessable Entity`

```json
{
  "errors": {
    "interests": ["select at least one interest"]
  }
}
```

Unknown slugs also return `422`.

## cURL examples

List interests:

```bash
curl -i http://localhost:4000/api/interests
```

Update interests after onboarding:

```bash
curl -i -X PUT http://localhost:4000/api/users/me/interests \
  -H "authorization: Bearer $HOBBYSPOT_AUTH_TOKEN" \
  -H 'content-type: application/json' \
  -d '{"interests":["dog_walks","running","board_games"]}'
```
