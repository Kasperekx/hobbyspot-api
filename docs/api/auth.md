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

## User object

```json
{
  "id": "95aa0a64-82d8-4118-ae75-603e28b399d9",
  "email": "user@example.com",
  "avatar_url": null,
  "full_name": null,
  "birth_date": null,
  "confirmed_at": null,
  "onboarding_completed": false
}
```

`id` is a UUID string. `confirmed_at` is `null` until the account is confirmed
through the web/email confirmation flow. `avatar_url`, `full_name`, and
`birth_date` are `null` until the user fills them during onboarding.

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
      "avatar_url": null,
      "full_name": null,
      "birth_date": null,
      "confirmed_at": null,
      "onboarding_completed": false
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
      "avatar_url": null,
      "full_name": null,
      "birth_date": null,
      "confirmed_at": null,
      "onboarding_completed": false
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

Returns the currently authenticated user for a valid bearer token.

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
      "avatar_url": null,
      "full_name": null,
      "birth_date": null,
      "confirmed_at": null,
      "onboarding_completed": false
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

## Complete Onboarding

Saves profile fields collected during onboarding and marks onboarding as
completed.

```http
PATCH /api/users/me/onboarding
Authorization: Bearer <token>
```

Request body:

```json
{
  "user": {
    "avatar_url": "https://example.com/avatar.png",
    "full_name": "Ada Lovelace",
    "birth_date": "1994-04-12"
  }
}
```

`birth_date` must use ISO date format: `YYYY-MM-DD`.

Success response: `200 OK`

```json
{
  "data": {
    "user": {
      "id": "95aa0a64-82d8-4118-ae75-603e28b399d9",
      "email": "user@example.com",
      "avatar_url": "https://example.com/avatar.png",
      "full_name": "Ada Lovelace",
      "birth_date": "1994-04-12",
      "confirmed_at": null,
      "onboarding_completed": true
    }
  }
}
```

Validation error response: `422 Unprocessable Entity`

```json
{
  "errors": {
    "birth_date": ["is invalid"]
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

1. On registration or login, read `data.token` and `data.user`.
2. Store `data.token` in secure device storage.
3. Keep `data.user` in app state for the current session.
4. Add `Authorization: Bearer <token>` to authenticated requests.
5. On app launch, load the stored token and call `GET /api/users/me`.
6. If `/me` returns `200`, restore the signed-in session.
7. If `data.user.onboarding_completed` is `false`, show the onboarding flow.
8. During the location step, use the [Mobile location API](location.md).
9. When profile onboarding is complete, call `PATCH /api/users/me/onboarding`.
10. If `/me` returns `401`, delete the stored token and show the login screen.
11. On logout, call `DELETE /api/users/log-out`, then delete the stored token.

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

Complete onboarding:

```bash
curl -i -X PATCH http://localhost:4000/api/users/me/onboarding \
  -H "authorization: Bearer $HOBBYSPOT_AUTH_TOKEN" \
  -H 'content-type: application/json' \
  -d '{"user":{"avatar_url":"https://example.com/avatar.png","full_name":"Ada Lovelace","birth_date":"1994-04-12"}}'
```

Log out:

```bash
curl -i -X DELETE http://localhost:4000/api/users/log-out \
  -H "authorization: Bearer $HOBBYSPOT_AUTH_TOKEN"
```
