# Mobile Location API

Status: planned endpoint contract. The `user_locations` table and PostGIS setup
already exist; this document describes the API contract to implement next.

Base URL for local development:

```text
http://localhost:4000
```

All requests and responses use JSON. Send this header for request bodies:

```http
Content-Type: application/json
```

Authenticated requests must include:

```http
Authorization: Bearer <token>
```

## Location object

```json
{
  "id": "c33bd41c-75f3-4a7e-a177-d338dc673f56",
  "latitude": 52.2297,
  "longitude": 21.0122,
  "city": "Warszawa",
  "country_code": "PL",
  "label": "Warszawa",
  "search_radius_meters": 5000,
  "source": "manual",
  "inserted_at": "2026-06-06T21:01:42Z",
  "updated_at": "2026-06-06T21:01:42Z"
}
```

The backend stores `latitude` and `longitude` as decimal values and derives a
PostGIS `coordinates geography(Point, 4326)` value in the database. Mobile does
not send or receive the generated `coordinates` field directly.

## Update Current User Location

Creates or replaces the authenticated user's current location.

```http
PUT /api/users/me/location
Authorization: Bearer <token>
```

Request body:

```json
{
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
```

Field rules:

- `latitude` is required and must be between `-90` and `90`.
- `longitude` is required and must be between `-180` and `180`.
- `search_radius_meters` is required and must be between `100` and `100000`.
- `source` is required and must be either `manual` or `gps`.
- `city` is optional, max `160` characters.
- `country_code` is optional, exactly `2` characters when present.
- `label` is optional, max `160` characters.

Recommended defaults:

- `search_radius_meters`: `5000`
- `source`: `manual` when the user chooses a city/area manually
- `source`: `gps` when the value comes from device location permission

Success response: `200 OK`

```json
{
  "data": {
    "location": {
      "id": "c33bd41c-75f3-4a7e-a177-d338dc673f56",
      "latitude": 52.2297,
      "longitude": 21.0122,
      "city": "Warszawa",
      "country_code": "PL",
      "label": "Warszawa",
      "search_radius_meters": 5000,
      "source": "manual",
      "inserted_at": "2026-06-06T21:01:42Z",
      "updated_at": "2026-06-06T21:01:42Z"
    }
  }
}
```

Validation error response: `422 Unprocessable Entity`

```json
{
  "errors": {
    "latitude": ["must be less than or equal to 90"],
    "longitude": ["must be less than or equal to 180"],
    "search_radius_meters": ["must be greater than or equal to 100"]
  }
}
```

Missing or invalid token response: `401 Unauthorized`

```json
{
  "errors": {
    "detail": "Unauthorized"
  }
}
```

## Recommended mobile onboarding flow

1. Ask the user for location permission or let them choose a city/area manually.
2. Convert the selected place into `latitude`, `longitude`, and display fields.
3. Call `PUT /api/users/me/location`.
4. Store the returned `data.location` in app state.
5. Continue to the next onboarding step.

If the user skips location, mobile should not call this endpoint. The backend can
continue returning `null` or no location until the user provides one.

## Privacy notes

This location is for matching, discovery, and notification relevance. It should
not be shown publicly as the user's exact location. For public event discovery,
prefer approximate labels such as city, district, or area name.

## cURL example

```bash
curl -i -X PUT http://localhost:4000/api/users/me/location \
  -H "authorization: Bearer $HOBBYSPOT_AUTH_TOKEN" \
  -H 'content-type: application/json' \
  -d '{"location":{"latitude":52.2297,"longitude":21.0122,"city":"Warszawa","country_code":"PL","label":"Warszawa","search_radius_meters":5000,"source":"manual"}}'
```
