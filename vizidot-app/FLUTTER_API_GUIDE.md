# Vizidot Flutter API Guide

This document defines **structure, constants, and rules** for all API usage in the Vizidot Flutter app. Every API call must follow this guide. It covers **public** and **private** APIs, auth tokens, and consistency with the backend [API_GUIDE](../vizidot-api/API_GUIDE.md).

---

## Table of Contents

1. [Overview](#1-overview)
2. [Base URL & Environment](#2-base-url--environment)
3. [API Constants](#3-api-constants)
4. [Public vs Private APIs](#4-public-vs-private-apis)
5. [Auth Token for Private APIs](#5-auth-token-for-private-apis)
6. [HTTP Client & Headers](#6-http-client--headers)
7. [Request / Response Conventions](#7-request--response-conventions)
8. [Error Handling](#8-error-handling)
9. [Project Structure for API Code](#9-project-structure-for-api-code)
10. [Checklist for New API Integration](#10-checklist-for-new-api-integration)

---

## 1. Overview

- **Single base URL**: All API requests go to one base URL (from env / `AppConfig`). No hardcoded host URLs in feature code.
- **Consistent response shape**: Backend returns `{ success: true, data: ... }` or `{ success: false, error: "..." }`. Parse the same way everywhere.
- **Public vs private**: Public endpoints need no token; private endpoints require `Authorization: Bearer <token>` (Firebase ID token).

---

## 2. Base URL & Environment

- **Source**: Use `AppConfig.fromEnv().baseUrl` (from `lib/core/utils/app_config.dart`). This reads `BASE_URL` from `.env` (via `flutter_dotenv`).
- **.env**: Define `BASE_URL` and `ENV` (e.g. `BASE_URL=http://localhost:8000`, `ENV=development`). Do not commit real production URLs or secrets.
- **No hardcoded hosts**: Never put `http://192.168.x.x` or production URLs in code; use constants or env.

---

## 3. API Constants

- **File**: `lib/core/constants/api_constants.dart`.
- **Contents**:
  - **Path constants**: All API path suffixes (e.g. `ApiPaths.artistProfile(id)`), so the app has a single place for endpoint paths.
  - **No base URL in constants**: Base URL comes from `AppConfig`; only path suffixes and query param names live in constants.
- **Naming**: Use clear names (e.g. `artistProfile`, `authLogin`, `health`). Keep path constants next to the client that uses them or in one shared file.

---

## 4. Public vs Private APIs

| Type | Auth header | When to use |
|------|-------------|-------------|
| **Public** | None | Artist profile, public catalogs, health, login/register, forgot password. |
| **Private** | `Authorization: Bearer <idToken>` | User profile, orders, uploads, follow, any user-specific or admin action. |

- **Public**: Do not attach an auth header. Backend does not require identity.
- **Private**: Always attach the current Firebase ID token. If token is missing or expired, get a new one or prompt re-login; do not send expired tokens.

---

## 5. Auth Token for Private APIs

- **Token source**: Firebase Auth current user ID token: `User.getIdToken()` (from `firebase_auth`).
- **When to refresh**: Call `getIdToken(true)` when making a private request if you want to force refresh; otherwise use cached token and handle 401 by refreshing once and retrying.
- **Where to store**: Do not store the token in plain text in persistent storage. Get it when needed from Firebase, or cache in memory for the session.
- **Header format**: `Authorization: Bearer <idToken>` (exactly as in backend API_GUIDE).

---

## 6. HTTP Client & Headers

- **Client**: Use a single HTTP client (e.g. `ApiClient` or `http` wrapper) that:
  - Prepends `AppConfig.baseUrl` to path constants.
  - Sets `Content-Type: application/json` for JSON body.
  - Optionally attaches `Authorization: Bearer <token>` for private requests (via a method or parameter).
- **Headers**:
  - Public: `Content-Type: application/json` when sending body.
  - Private: `Content-Type: application/json` + `Authorization: Bearer <token>`.
- **Timeouts**: Set a reasonable connect/read timeout (e.g. 10–30 s) in the client.

---

## 7. Request / Response Conventions

- **Success**: Backend returns `{ success: true, data: ... }`. Parse `data` into your models (e.g. `ArtistProfile`, `AlbumItem`).
- **Error**: Backend returns `{ success: false, error: "message" }`. Map to a simple error type or string and show to the user or handle (e.g. 401 → re-login).
- **Status codes**: Respect HTTP status (200/201 = success, 400 = bad request, 401 = unauthorized, 403 = forbidden, 404 = not found, 500 = server error). Do not treat 4xx/5xx as success.

---

## 8. Error Handling

- **Network errors**: Handle timeout and connection errors; show a generic “network error” or “check connection” message.
- **4xx/5xx**: Parse response body for `error` message when available; otherwise use status-based message.
- **401**: Clear session / token and redirect to login or prompt re-login.
- **Consistency**: Use the same error handling approach across features (e.g. GetX snackbar, or a central error handler).

---

## 9. Project Structure for API Code

- **Constants**: `lib/core/constants/api_constants.dart` – path suffixes, query param names.
- **Config**: `lib/core/utils/app_config.dart` – base URL, environment.
- **Client**: `lib/core/network/api_client.dart` (or `lib/data/remote/api_client.dart`) – base URL, headers, get/post, optional auth.
- **Services / Repositories**: e.g. `lib/data/services/artist_api_service.dart` – methods that call endpoints and return domain models (e.g. `ArtistProfile`).
- **Models**: `lib/data/models/` or feature-level `lib/modules/.../models/` – DTOs that match backend JSON (e.g. `artist_profile_response.dart`).

Do not scatter raw URLs or auth header logic across widgets; keep them in client and services.

---

## 10. Checklist for New API Integration

- [ ] Endpoint path added to `api_constants.dart` (or equivalent).
- [ ] Base URL from `AppConfig`; no hardcoded host.
- [ ] Public vs private decided; if private, attach Bearer token from Firebase.
- [ ] Request: correct method (GET/POST/PUT/DELETE), JSON body when needed.
- [ ] Response: parse `success` and `data` / `error`; handle status codes.
- [ ] Errors: network, 401, 4xx/5xx handled consistently.
- [ ] Models: DTOs match backend response shape (camelCase from API).

By following this guide, all API usage in the Flutter app stays consistent, secure, and easy to maintain.
