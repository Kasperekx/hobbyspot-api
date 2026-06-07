# Mobile Location Flow

Location is collected during onboarding through:

```http
PATCH /api/users/me/onboarding
```

There is no separate `/api/users/me/location` endpoint. The location sent during
onboarding is stored as the user's default discovery location.

## Purpose

The default discovery location is not live tracking. It answers this product
question:

```text
If the app does not have a fresh device location, where should we show nearby events?
```

For real-time event discovery later, mobile should send fresh coordinates to the
event search/feed endpoint. The backend can then use PostGIS to return events
within the requested radius. If fresh coordinates are unavailable, the backend
can fall back to the saved onboarding location.

## Recommended onboarding UX

1. Show a location step during onboarding.
2. Explain that location is used to show nearby events.
3. Offer two actions:
   - `Use my current location`
   - `Choose manually`
4. If the user taps `Use my current location`, trigger the native iOS/Android
   permission prompt.
5. If permission is granted, read device coordinates and send `source: "gps"`.
6. If permission is denied, show manual city/area search.
7. If the user chooses manually, geocode the city/area and send `source: "manual"`.
8. To complete onboarding, send location and selected interests in one
   `PATCH /api/users/me/onboarding` request with `completed: true`.

Recommended product rule: location should be required to finish onboarding, but
GPS permission should not be required. The user can always choose a city/area
manually.

## Location object

```json
{
  "latitude": 52.2297,
  "longitude": 21.0122,
  "city": "Warszawa",
  "country_code": "PL",
  "label": "Warszawa",
  "search_radius_meters": 5000,
  "source": "manual"
}
```

The backend stores `latitude` and `longitude` as decimal values and derives a
PostGIS `coordinates geography(Point, 4326)` value in the database. Mobile does
not send or receive the generated `coordinates` field directly.

## Field rules

- `latitude` is required when `location` is sent and must be between `-90` and `90`.
- `longitude` is required when `location` is sent and must be between `-180` and `180`.
- `search_radius_meters` is required when `location` is sent and must be between `100` and `100000`.
- `source` is required when `location` is sent and must be either `manual` or `gps`.
- `city` is optional, max `160` characters.
- `country_code` is optional, exactly `2` characters when present.
- `label` is optional, max `160` characters.

Recommended defaults:

- `search_radius_meters`: `5000`
- `source`: `manual` when the user chooses a city/area manually
- `source`: `gps` when the value comes from device location permission

## GPS permission accepted

Request:

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
      "source": "gps"
    }
  }
}
```

## Manual city selection

Request:

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
    }
  }
}
```

## Complete onboarding

Mobile can send all onboarding data at the end of the flow:

```json
{
  "onboarding": {
    "profile": {
      "avatar_url": "https://example.com/avatar.png",
      "full_name": "Ada Lovelace",
      "birth_date": "1994-04-12"
    },
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

Success response returns the updated `data.onboarding` object:

```json
{
  "data": {
    "onboarding": {
      "profile": {
        "avatar_url": "https://example.com/avatar.png",
        "full_name": "Ada Lovelace",
        "birth_date": "1994-04-12"
      },
      "location": {
        "latitude": 52.2297,
        "longitude": 21.0122,
        "city": "Warszawa",
        "country_code": "PL",
        "label": "Warszawa",
        "search_radius_meters": 5000,
        "source": "manual"
      },
      "interests": [
        {
          "slug": "dog_walks",
          "name": "Psy i spacery",
          "notifications_enabled": true
        },
        {
          "slug": "running",
          "name": "Bieganie",
          "notifications_enabled": true
        }
      ],
      "completed": true
    }
  }
}
```

## Privacy notes

This location is for matching, discovery, and notification relevance. It should
not be shown publicly as the user's exact location. For public event discovery,
prefer approximate labels such as city, district, or area name.

## cURL example

```bash
curl -i -X PATCH http://localhost:4000/api/users/me/onboarding \
  -H "authorization: Bearer $HOBBYSPOT_AUTH_TOKEN" \
  -H 'content-type: application/json' \
  -d '{"onboarding":{"location":{"latitude":52.2297,"longitude":21.0122,"city":"Warszawa","country_code":"PL","label":"Warszawa","search_radius_meters":5000,"source":"manual"},"interests":["dog_walks"],"completed":true}}'
```
