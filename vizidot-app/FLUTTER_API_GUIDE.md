# Vizidot Flutter API Guide

This document defines **structure, constants, and rules** for all API usage in the Vizidot Flutter app. Every API call goes through **subclasses of [BaseApi]** (e.g. [MusicApi]). Each endpoint uses a **visibility flag**: **public** (no token) or **private** (use token). It covers request/response logging and consistency with the backend [API_GUIDE](../vizidot-api/API_GUIDE.md).

---

## Table of Contents

1. [Overview](#1-overview)
2. [Base URL & Environment](#2-base-url--environment)
3. [API Constants](#3-api-constants)
4. [Base API & Subclasses](#4-base-api--subclasses)
5. [Visibility Flag: Public vs Private](#5-visibility-flag-public-vs-private)
6. [Request / Response Logging (cURL & Response)](#6-request--response-logging-curl--response)
7. [Public vs Private APIs](#7-public-vs-private-apis)
8. [Auth Token for Private APIs](#8-auth-token-for-private-apis)
9. [HTTP Client & Headers](#9-http-client--headers)
10. [Request / Response Conventions](#10-request--response-conventions)
11. [Error Handling](#11-error-handling)
12. [Project Structure for API Code](#12-project-structure-for-api-code)
13. [Checklist for New API Integration](#13-checklist-for-new-api-integration)

---

## 1. Overview

- **Single base URL**: All API requests use one base URL (from env / `AppConfig`). No hardcoded host URLs in feature code.
- **Base class + subclasses**: [BaseApi](lib/core/network/base_api.dart) provides logging and `execute()`. **Subclasses** (e.g. [MusicApi](lib/core/network/apis/music_api.dart)) contain all API methods per domain. Use subclasses in the app, not `BaseApi` directly.
- **Visibility flag**: Every API call uses [ApiVisibility.public] (no token) or [ApiVisibility.private] (use token). Subclasses pass this when calling `execute()`.
- **Logging**: Each request is printed as a **cURL** command and each **response** is printed in a readable format (status + pretty-printed JSON) when `debugPrintRequest` is true.
- **Consistent response shape**: Backend returns `{ success: true, data: ... }` or `{ success: false, error: "..." }`. Parse the same way everywhere.

---

## 2. Base URL & Environment

- **Source**: Use `AppConfig.fromEnv().baseUrl` (from `lib/core/utils/app_config.dart`). This reads `BASE_URL` from `.env` (via `flutter_dotenv`).
- **.env**: Define `BASE_URL` and `ENV` (e.g. `BASE_URL=http://localhost:8000`, `ENV=development`). Do not commit real production URLs or secrets.
- **No hardcoded hosts**: Never put `http://192.168.x.x` or production URLs in code; use constants or env.

---

## 3. API Constants

- **File**: `lib/core/constants/api_constants.dart`.
- **Contents**:
  - **Path constants**: All API path suffixes (e.g. `ApiConstants.artistProfilePath(id)`), so the app has a single place for endpoint paths.
  - **No base URL in constants**: Base URL comes from `AppConfig`; only path suffixes and query param names live in constants.
- **Naming**: Use clear names (e.g. `artistProfilePath`, `artistFollowPath`, `healthPath`). Add new path helpers here when adding endpoints.

---

## 4. Base API & Subclasses

- **Base class**: `BaseApi` in `lib/core/network/base_api.dart`. It provides:
  - `execute(method, path, { queryParams, body, visibility })` — runs the request and logs cURL + response. **Do not call `BaseApi` from features**; use a subclass.
- **Subclasses**: One subclass per domain, in `lib/core/network/apis/`:
  - **[MusicApi](lib/core/network/apis/music_api.dart)** — artist profile, follow, unfollow. Use for all music/artist endpoints.
  - Add more as needed (e.g. `AuthApi`, `UserApi`) that extend `BaseApi` and call `execute()` with the right `visibility`.
- **Usage**: Create the subclass with `baseUrl` and, for private endpoints, `authToken`:
  - **Public only**: `MusicApi(baseUrl: config.baseUrl)` — use for methods that only call public endpoints (e.g. get artist profile).
  - **Private**: `MusicApi(baseUrl: config.baseUrl, authToken: token)` — use when calling follow/unfollow or any private endpoint.
- **Example**:
  ```dart
  final musicApi = MusicApi(baseUrl: AppConfig.fromEnv().baseUrl);
  final profile = await musicApi.getArtistProfile(artistId);

  final musicApiAuth = MusicApi(baseUrl: config.baseUrl, authToken: idToken);
  final ok = await musicApiAuth.followArtist(artistId);
  ```

---

## 5. Visibility Flag: Public vs Private

- **Enum**: `ApiVisibility` in `base_api.dart`:
  - **`ApiVisibility.public`** — no auth header. Use for endpoints that do not require login (artist profile, health, public lists).
  - **`ApiVisibility.private`** — send `Authorization: Bearer <token>`. Use for follow, unfollow, user profile, etc.
- **Where it’s set**: In each subclass method, when calling `execute()`:
  ```dart
  await execute('GET', path, visibility: ApiVisibility.public);   // no token
  await execute('POST', path, body: {}, visibility: ApiVisibility.private);  // with token
  ```
- **Token**: For private calls, the subclass must be constructed with `authToken` (e.g. Firebase ID token). If `authToken` is null or empty and you use `ApiVisibility.private`, the request is still sent but without a Bearer header (and will typically get 401).

---

## 6. Request / Response Logging (cURL & Response)

- **Enabled by default**: Subclasses (e.g. `MusicApi(..., debugPrintRequest: true)`) default `debugPrintRequest` to `true`. Set to `false` in release or when you do not want console output.
- **For each request**, the app prints:
  1. **cURL**: A copy-pasteable cURL command (method, full URL, headers, body).
  2. **Response**: HTTP status code and body. If the body is JSON, it is pretty-printed for readability.
- **Format**:
  ```
  ┌─────────────── cURL ───────────────
  curl -X GET 'http://localhost:8000/api/v1/music/artists/profile/1' \
    -H 'Content-Type: application/json' \
    -H 'Accept: application/json'
  └────────────────────────────────────

  ┌─────────────── Response ───────────────
  Status: 200
  Body:
  {
    "success": true,
    "data": { ... }
  }
  └────────────────────────────────────────
  ```
- **Implementation**: Handled inside `BaseApi.execute()`; no need to add logging in subclass methods.

---

## 7. Public vs Private APIs

| Type | Auth header | When to use |
|------|-------------|-------------|
| **Public** | None | Artist profile, public catalogs, health, login/register, forgot password. |
| **Private** | `Authorization: Bearer <token>` | User profile, orders, uploads, follow/unfollow, any user-specific or admin action. |

- **Public**: Use a subclass (e.g. `MusicApi(baseUrl: ...)`) with no token. Subclass methods that are public call `execute(..., visibility: ApiVisibility.public)`.
- **Private**: Use the same subclass with `authToken`. Subclass methods that are private call `execute(..., visibility: ApiVisibility.private)`.

---

## 8. Auth Token for Private APIs

- **Token source**: Firebase Auth current user ID token: e.g. `AuthService.getIdToken()` (from `lib/core/utils/auth_service.dart`).
- **When to refresh**: Call `getIdToken(true)` when making a private request if you want to force refresh; otherwise use cached token and handle 401 by refreshing once and retrying.
- **Where to store**: Do not store the token in plain text in persistent storage. Get it when needed from Firebase, or cache in memory for the session.
- **Header format**: `Authorization: Bearer <token>` (exactly as in backend API_GUIDE).

---

## 9. HTTP Client & Headers

- **Low-level client**: `ApiClient` in `lib/core/network/api_client.dart` — used internally by `BaseApi` for GET/POST/PUT/DELETE. Do not call `ApiClient` directly from features; use a [BaseApi] subclass (e.g. [MusicApi]).
- **Headers**:
  - Public: `Content-Type: application/json`, `Accept: application/json`.
  - Private: same + `Authorization: Bearer <token>`.
- **Timeouts**: Set on `BaseApi` / `ApiClient` (e.g. 15 s default).

---

## 10. Request / Response Conventions

- **Success**: Backend returns `{ success: true, data: ... }`. Parse `data` into your models (e.g. `ArtistProfileResponse`, `AlbumItem`).
- **Error**: Backend returns `{ success: false, error: "message" }`. Map to a simple error type or string and show to the user or handle (e.g. 401 → re-login).
- **Status codes**: Respect HTTP status (200/201 = success, 400 = bad request, 401 = unauthorized, 403 = forbidden, 404 = not found, 500 = server error). Do not treat 4xx/5xx as success.

---

## 11. Error Handling

- **Network errors**: Handle timeout and connection errors; show a generic “network error” or “check connection” message.
- **4xx/5xx**: Parse response body for `error` message when available; otherwise use status-based message.
- **401**: Clear session / token and redirect to login or prompt re-login.
- **Consistency**: Use the same error handling approach across features (e.g. GetX snackbar, or a central error handler).

---

## 12. Project Structure for API Code

| Location | Purpose |
|----------|---------|
| `lib/core/constants/api_constants.dart` | Path suffixes, query param names. |
| `lib/core/utils/app_config.dart` | Base URL, environment. |
| `lib/core/network/api_client.dart` | Low-level HTTP (get/post/put/delete). Used only by `BaseApi`. |
| **`lib/core/network/base_api.dart`** | Base class: `execute()` + cURL/response logging. Defines `ApiVisibility.public` / `.private`. Do not use directly in features. |
| **`lib/core/network/apis/music_api.dart`** | Subclass: music/artist APIs (getArtistProfile, followArtist, unfollowArtist). Use for all music endpoints. |
| `lib/core/network/apis/` | Add more subclasses here (e.g. `auth_api.dart`, `user_api.dart`) as needed. |
| `lib/data/models/` | DTOs that match backend JSON (e.g. `artist_profile_response.dart`). |

- **Do not** add standalone service files outside the `BaseApi` subclass pattern. Add new endpoints as methods on the appropriate subclass and pass `visibility: ApiVisibility.public` or `ApiVisibility.private`.
- Controllers get `AppConfig.baseUrl` and optional token, create the right subclass (e.g. `MusicApi`), and call its methods.

---

## 13. Checklist for New API Integration

- [ ] Add path helper to `api_constants.dart` (if new endpoint).
- [ ] Add a new method to the **appropriate subclass** (e.g. `MusicApi`) that calls `execute()` with the right method, path, body, and **`visibility: ApiVisibility.public` or `ApiVisibility.private`**.
- [ ] Base URL from `AppConfig`; no hardcoded host.
- [ ] For private endpoints, create the subclass with `authToken` when calling that method.
- [ ] Response: parse `success` and `data` / `error`; handle status codes.
- [ ] Errors: network, 401, 4xx/5xx handled consistently.
- [ ] Models: DTOs in `lib/data/models/` match backend response shape (camelCase from API).

By following this guide, all API usage goes through BaseApi subclasses with a clear public/private flag and consistent logging.
