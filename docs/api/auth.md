# Mobile Auth API

Base URL for local development:

```text
http://localhost:4000
```

All requests and responses use JSON. Send this header for request bodies:

```http
Content-Type: application/json
```

Authenticated requests must also include:

```http
Authorization: Bearer <token>
```

The token is returned by registration and login. Store it in secure device
storage, for example Keychain on iOS or Keystore-backed secure storage on
Android. Do not store it in plain AsyncStorage or logs.

## Response shape

Auth endpoints return account data separately from onboarding state:

```json
{
  "data": {
    "user": {
      "id": "95aa0a64-82d8-4118-ae75-603e28b399d9",
      "email": "user@example.com",
      "confirmed_at": null
    },
    "onboarding": {
      "profile": {
        "avatar_url": null,
        "full_name": null,
        "birth_date": null
      },
      "location": null,
      "interests": [],
      "completed": false
    }
  }
}
```

`user.id` is a UUID string. `confirmed_at` is `null` until the account is
confirmed through the web/email confirmation flow.

`onboarding.location` is the user's default discovery location. It is used as a
fallback for event discovery when mobile does not provide a fresh device
location.

`onboarding.interests` contains the user's selected MVP hobbies. At least one
interest is required to finish onboarding, but profile fields can stay empty and
be updated later.

## Register

Creates a user with email and password and returns an auth token.

```http
POST /api/users/register
```

Request body:

```json
{
  "user": {
    "email": "user@example.com",
    "password": "hello world!"
  }
}
```

Password rules:

- Minimum length: 12 characters
- Maximum length: 72 bytes

Success response: `201 Created`

```json
{
  "data": {
    "token": "base64url-session-token",
    "user": {
      "id": "95aa0a64-82d8-4118-ae75-603e28b399d9",
      "email": "user@example.com",
      "confirmed_at": null
    },
    "onboarding": {
      "profile": {
        "avatar_url": null,
        "full_name": null,
        "birth_date": null
      },
      "location": null,
      "interests": [],
      "completed": false
    }
  }
}
```

Validation error response: `422 Unprocessable Entity`

```json
{
  "errors": {
    "email": ["must have the @ sign and no spaces"],
    "password": ["should be at least 12 character(s)"]
  }
}
```

## Log In

Authenticates an existing user and returns a new auth token.

```http
POST /api/users/log-in
```

Request body:

```json
{
  "user": {
    "email": "user@example.com",
    "password": "hello world!"
  }
}
```

Success response: `200 OK`

```json
{
  "data": {
    "token": "base64url-session-token",
    "user": {
      "id": "95aa0a64-82d8-4118-ae75-603e28b399d9",
      "email": "user@example.com",
      "confirmed_at": null
    },
    "onboarding": {
      "profile": {
        "avatar_url": null,
        "full_name": null,
        "birth_date": null
      },
      "location": null,
      "interests": [],
      "completed": false
    }
  }
}
```

Invalid credentials response: `401 Unauthorized`

```json
{
  "errors": {
    "detail": "Invalid email or password"
  }
}
```

## Current User

Returns the currently authenticated user and onboarding state for a valid bearer
token.

```http
GET /api/users/me
Authorization: Bearer <token>
```

Success response: `200 OK`

```json
{
  "data": {
    "user": {
      "id": "95aa0a64-82d8-4118-ae75-603e28b399d9",
      "email": "user@example.com",
      "confirmed_at": null
    },
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
      ],
      "completed": true
    }
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

## Update Onboarding

Saves profile fields, default discovery location, selected interests, and
completion state collected during onboarding.

```http
PATCH /api/users/me/onboarding
Authorization: Bearer <token>
```

Request body:

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

Partial updates are supported. Mobile can send only `profile`, only `location`,
only `interests`, only `completed`, or all of them together. The final onboarding
submit should send one request with location, interests, and `completed: true`.
The backend saves the update in a single database transaction.

`birth_date` must use ISO date format: `YYYY-MM-DD`.

When `completed` is `true`, the backend requires:

- saved `location`
- at least one selected interest

Profile fields are optional and can be updated later.

Location field rules:

- `latitude` is required when `location` is sent and must be between `-90` and `90`.
- `longitude` is required when `location` is sent and must be between `-180` and `180`.
- `search_radius_meters` is required when `location` is sent and must be between `100` and `100000`.
- `source` is required when `location` is sent and must be either `manual` or `gps`.
- `city` is optional, max `160` characters.
- `country_code` is optional, exactly `2` characters when present.
- `label` is optional, max `160` characters.

Success response: `200 OK`

```json
{
  "data": {
    "user": {
      "id": "95aa0a64-82d8-4118-ae75-603e28b399d9",
      "email": "user@example.com",
      "confirmed_at": null
    },
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
      ],
      "completed": true
    }
  }
}
```

Validation error response: `422 Unprocessable Entity`

```json
{
  "errors": {
    "birth_date": ["is invalid"],
    "latitude": ["must be less than or equal to 90"],
    "interests": ["is required"]
  }
}
```

## Log Out

Revokes the current bearer token.

```http
DELETE /api/users/log-out
Authorization: Bearer <token>
```

Success response: `204 No Content`

After a successful logout, remove the token from secure device storage. Further
requests using that token will return `401 Unauthorized`.

## Recommended mobile flow

1. On registration or login, read `data.token`, `data.user`, and `data.onboarding`.
2. Store `data.token` in secure device storage.
3. Keep `data.user` and `data.onboarding` in app state for the current session.
4. Add `Authorization: Bearer <token>` to authenticated requests.
5. On app launch, load the stored token and call `GET /api/users/me`.
6. If `/me` returns `200`, restore the signed-in session.
7. If `data.onboarding.completed` is `false`, show the onboarding flow.
8. Load available hobbies with `GET /api/interests`.
9. During the location step, use GPS permission or manual city selection.
10. Keep profile, location, and interests in local mobile state during onboarding.
11. Finish onboarding with one `PATCH /api/users/me/onboarding` request.
12. If `/me` returns `401`, delete the stored token and show the login screen.
13. On logout, call `DELETE /api/users/log-out`, then delete the stored token.

## cURL examples

Register:

```bash
curl -i -X POST http://localhost:4000/api/users/register \
  -H 'content-type: application/json' \
  -d '{"user":{"email":"user@example.com","password":"hello world!"}}'
```

Log in:

```bash
curl -i -X POST http://localhost:4000/api/users/log-in \
  -H 'content-type: application/json' \
  -d '{"user":{"email":"user@example.com","password":"hello world!"}}'
```

Current user:

```bash
curl -i http://localhost:4000/api/users/me \
  -H "authorization: Bearer $HOBBYSPOT_AUTH_TOKEN"
```

Update onboarding:

```bash
curl -i -X PATCH http://localhost:4000/api/users/me/onboarding \
  -H "authorization: Bearer $HOBBYSPOT_AUTH_TOKEN" \
  -H 'content-type: application/json' \
  -d '{"onboarding":{"profile":{"avatar_url":"https://example.com/avatar.png","full_name":"Ada Lovelace","birth_date":"1994-04-12"},"location":{"latitude":52.2297,"longitude":21.0122,"city":"Warszawa","country_code":"PL","label":"Warszawa","search_radius_meters":5000,"source":"manual"},"interests":["dog_walks","running"],"completed":true}}'
```

Log out:

```bash
curl -i -X DELETE http://localhost:4000/api/users/log-out \
  -H "authorization: Bearer $HOBBYSPOT_AUTH_TOKEN"
```
