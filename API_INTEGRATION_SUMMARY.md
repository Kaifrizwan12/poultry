# API Integration Summary

## Overview
Frontend and backend are **fully integrated** with comprehensive logging for debugging and monitoring.

---

## Backend API Endpoints

**Base URL:** `http://localhost:3000/api/v1/auth`

### 1. **POST /register**
Register a new user account.
- **Request Body:**
  ```json
  {
    "name": "John Doe",
    "email": "john@example.com",
    "password": "SecurePass123",
    "farmType": "poultry" | "chicken"
  }
  ```
- **Response:**
  ```json
  {
    "token": "jwt_token_string",
    "expiresAt": "2026-05-12T...",
    "user": {
      "uid": "firebase_uid",
      "name": "John Doe",
      "email": "john@example.com",
      "farmType": "poultry"
    }
  }
  ```
- **Status Codes:** 200 (success), 400 (missing fields), 500 (server error)

### 2. **POST /login**
Authenticate user and receive JWT token.
- **Request Body:**
  ```json
  {
    "email": "john@example.com",
    "password": "SecurePass123"
  }
  ```
- **Response:** Same structure as `/register`
- **Status Codes:** 200 (success), 400 (missing fields), 401 (invalid credentials), 500 (server error)

### 3. **GET /me**
Fetch current authenticated user profile.
- **Headers:**
  ```
  Authorization: Bearer {token}
  ```
- **Response:**
  ```json
  {
    "user": {
      "uid": "firebase_uid",
      "name": "John Doe",
      "email": "john@example.com",
      "farmType": "poultry",
      "createdAt": "2026-05-05T..."
    }
  }
  ```
- **Status Codes:** 200 (success), 401 (unauthorized), 404 (user not found)

### 4. **POST /logout**
Logout user (client removes token; optional server-side invalidation).
- **Response:**
  ```json
  {
    "ok": true
  }
  ```
- **Status Codes:** 200 (success)

### 5. **POST /forgot**
Request password reset token.
- **Request Body:**
  ```json
  {
    "email": "john@example.com"
  }
  ```
- **Response:**
  ```json
  {
    "ok": true,
    "token": "reset_token_hex_string"
  }
  ```
- **Status Codes:** 200 (success), 400 (missing email), 500 (user not found/error)

### 6. **POST /reset**
Reset password using reset token.
- **Request Body:**
  ```json
  {
    "token": "reset_token_hex_string",
    "newPassword": "NewSecurePass456"
  }
  ```
- **Response:**
  ```json
  {
    "ok": true
  }
  ```
- **Status Codes:** 200 (success), 400 (invalid/expired token), 500 (server error)

### 7. **POST /change**
Change password for authenticated user.
- **Headers:**
  ```
  Authorization: Bearer {token}
  ```
- **Request Body:**
  ```json
  {
    "oldPassword": "SecurePass123",
    "newPassword": "NewSecurePass456"
  }
  ```
- **Response:**
  ```json
  {
    "ok": true
  }
  ```
- **Status Codes:** 200 (success), 400 (missing fields), 401 (unauthorized/invalid password), 404 (user not found)

---

## Frontend Integration

### API Service (`lib/services/api_service.dart`)
Provides HTTP client with **detailed logging**:
- **POST requests** with body logging
- **GET requests** with header logging
- **Response status and body logging**
- **Error logging** with stack traces
- Timestamps on all log entries

**Key Methods:**
- `post(String path, Map<String, dynamic> body)` — Send POST request
- `get(String path, {Map<String, String>? headers})` — Send GET request with optional headers

### Auth Service (`lib/services/auth_service.dart`)
Higher-level auth API wrapper:
- `login(email, password)` → POST /login
- `register(payload)` → POST /register
- `me(token)` → GET /me (with Authorization header)
- `forgot(email)` → POST /forgot
- `reset(token, newPassword)` → POST /reset
- `changePassword(token, oldPassword, newPassword)` → POST /change

### Auth Controller (`lib/controllers/auth_controller.dart`)
Business logic layer:
- Validates email, password, name
- Manages loading state
- Handles token & user persistence via `LocalStorageService`
- Provides `login()`, `register()`, `forgotPassword()`, `resetPassword()`, `changePassword()` methods

---

## Backend Logging

### Log Format
```
[ISO_TIMESTAMP] [LEVEL] MESSAGE
{detailed_data_as_json}
```

### Log Levels
- **INFO** — Normal operations (request received, user created, token verified)
- **WARN** — Validation failures, missing fields, auth failures
- **ERROR** — Exceptions, Firebase errors

### Examples
```
[2026-05-05T10:30:45.123Z] [INFO] POST /register received
{"name": "John Doe", "email": "john@example.com", "farmType": "poultry"}

[2026-05-05T10:30:46.456Z] [INFO] Firebase user created
{"uid": "abc123xyz", "email": "john@example.com"}

[2026-05-05T10:30:47.789Z] [ERROR] Login failed
{"error": "Mismatch in stored password hash"}
```

---

## Frontend Logging

### Log Format
Logged via `dart:developer` and `print()`:
```
[ISO_TIMESTAMP] [LEVEL] MESSAGE
{detailed_data_as_json}
```

### Examples
```
[2026-05-05T10:30:45.123Z] [INFO] POST request
{"url": "http://localhost:3000/api/v1/auth/login", "body": {"email": "john@example.com"}}

[2026-05-05T10:30:45.456Z] [INFO] Response received
{"statusCode": 200, "url": "http://localhost:3000/api/v1/auth/login"}

[2026-05-05T10:30:45.789Z] [INFO] Response body decoded
{"token": "jwt_...", "expiresAt": "...", "user": {...}}
```

---

## Testing the Integration

### Using cURL (Backend)

```bash
# Register
curl -X POST http://localhost:3000/api/v1/auth/register \
  -H "Content-Type: application/json" \
  -d '{"name":"John","email":"john@test.com","password":"Pass123","farmType":"poultry"}'

# Login
curl -X POST http://localhost:3000/api/v1/auth/login \
  -H "Content-Type: application/json" \
  -d '{"email":"john@test.com","password":"Pass123"}'

# Get current user (replace TOKEN with actual JWT)
curl -X GET http://localhost:3000/api/v1/auth/me \
  -H "Authorization: Bearer TOKEN"
```

### Via Flutter (Frontend)
1. Use the `AuthController` in widgets
2. Check **Dart DevTools console** for detailed API logs
3. Check **Terminal/IDE output** for print logs
4. Monitor backend logs in Node.js terminal

---

## Integration Status

✅ **Frontend → Backend:** Fully connected  
✅ **Token-based auth:** Implemented (JWT)  
✅ **Firebase Auth:** Integrated (user creation)  
✅ **Firestore:** Used for user storage  
✅ **Password hashing:** bcrypt (backend)  
✅ **Logging:** Comprehensive on both sides  
✅ **Error handling:** Proper error responses  

---

## Next Steps

1. Test all endpoints via cURL or Postman
2. Run Flutter app and monitor console logs
3. Verify tokens are stored/retrieved correctly in local storage
4. Test password reset flow end-to-end
5. Implement rate limiting on backend (optional)
6. Add request validation middleware (optional)
