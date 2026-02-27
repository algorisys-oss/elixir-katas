# Kata 07: JWT Authentication

## What is a JWT?

A **JSON Web Token** (JWT, pronounced "jot") is a compact, URL-safe token format defined in [RFC 7519](https://tools.ietf.org/html/rfc7519).

```
eyJhbGciOiJIUzI1NiJ9.eyJzdWIiOiI0MiJ9.SflKxwRJSMeKKF2QT4fwpM
└──── header ────┘ └──── payload ────┘ └──── signature ────┘
```

### Three Parts, Dot-Separated

1. **Header**: Algorithm and token type
2. **Payload**: Claims (data about the user/session)
3. **Signature**: Cryptographic verification

Each part is **Base64url-encoded** (URL-safe Base64, no padding).

---

## JWT Header

```json
{
  "alg": "HS256",
  "typ": "JWT"
}
```

- `alg`: The signing algorithm (HS256 = HMAC-SHA256)
- `typ`: Token type (always "JWT")

### Common Algorithms

| Algorithm | Type      | Key       | Use Case                       |
|-----------|-----------|-----------|--------------------------------|
| HS256     | Symmetric | Shared secret | Simple apps, same server signs & verifies |
| RS256     | Asymmetric | RSA key pair | Microservices, third-party verification |
| ES256     | Asymmetric | EC key pair  | Modern, smaller keys           |
| none      | None       | None         | NEVER use in production!       |

---

## JWT Claims

Claims are key-value pairs in the payload. RFC 7519 defines **registered claims**:

```json
{
  "sub": "user_42",
  "iat": 1700000000,
  "exp": 1700086400,
  "iss": "my_app",
  "aud": "my_app_web",
  "nbf": 1700000000,
  "jti": "unique-id-123"
}
```

| Claim | Name        | Purpose                                      |
|-------|-------------|----------------------------------------------|
| `sub` | Subject     | Who the token represents (user ID)            |
| `iat` | Issued At   | When the token was created (Unix timestamp)   |
| `exp` | Expiration  | When the token expires (Unix timestamp)       |
| `iss` | Issuer      | Who created the token (your app name)         |
| `aud` | Audience    | Who should accept the token                   |
| `nbf` | Not Before  | Token is not valid before this time           |
| `jti` | JWT ID      | Unique ID to prevent replay attacks           |

You can also add **custom claims** (role, email, permissions, etc.).

---

## Signing with HMAC in Elixir

Elixir's `:crypto` module provides HMAC directly — no external library needed:

```elixir
# Signing
signing_input = header_b64 <> "." <> payload_b64
signature = :crypto.mac(:hmac, :sha256, secret, signing_input)
signature_b64 = Base.url_encode64(signature, padding: false)

jwt = signing_input <> "." <> signature_b64
```

### Verification

```elixir
# Split the token
[header_b64, payload_b64, signature_b64] = String.split(jwt, ".")

# Recompute the expected signature
expected = :crypto.mac(:hmac, :sha256, secret, header_b64 <> "." <> payload_b64)

# Decode the provided signature
{:ok, actual} = Base.url_decode64(signature_b64, padding: false)

# Constant-time comparison (prevents timing attacks)
:crypto.hash_equals(expected, actual)
```

### Why `hash_equals` Instead of `==`?

The `==` operator short-circuits: it returns `false` as soon as bytes differ. An attacker can measure response time to guess the signature byte by byte. `hash_equals` always compares all bytes in constant time.

---

## Token Generation Module

```elixir
defmodule MyApp.Token do
  @secret Application.compile_env!(:my_app, :jwt_secret)
  @expiry 86_400  # 24 hours

  def generate(user) do
    header = %{"alg" => "HS256", "typ" => "JWT"}
    payload = %{
      "sub" => to_string(user.id),
      "email" => user.email,
      "role" => user.role,
      "iat" => System.system_time(:second),
      "exp" => System.system_time(:second) + @expiry
    }

    h = Base.url_encode64(Jason.encode!(header), padding: false)
    p = Base.url_encode64(Jason.encode!(payload), padding: false)
    s = :crypto.mac(:hmac, :sha256, @secret, h <> "." <> p)
    h <> "." <> p <> "." <> Base.url_encode64(s, padding: false)
  end

  def verify(token) do
    with [h, p, s] <- String.split(token, "."),
         {:ok, sig} <- Base.url_decode64(s, padding: false),
         true <- :crypto.hash_equals(
           :crypto.mac(:hmac, :sha256, @secret, h <> "." <> p), sig
         ),
         {:ok, json} <- Base.url_decode64(p, padding: false),
         {:ok, claims} <- Jason.decode(json),
         true <- System.system_time(:second) < claims["exp"] do
      {:ok, claims}
    else
      _ -> {:error, :invalid_token}
    end
  end
end
```

---

## Refresh Tokens

JWTs are stateless — you cannot revoke them once issued. The solution:

1. **Access token**: Short-lived JWT (15 min - 1 hour)
2. **Refresh token**: Long-lived, stored in database (7-30 days)

### Flow

```
1. Client logs in → server returns {access_token, refresh_token}
2. Client uses access_token for API calls
3. Access token expires → client sends refresh_token to /auth/refresh
4. Server verifies refresh_token in DB → issues new access_token
5. To revoke: delete the refresh_token from the DB
```

### Implementation

```elixir
# Refresh token is a random string stored in DB
def generate_refresh_token(user) do
  token = :crypto.strong_rand_bytes(32) |> Base.url_encode64(padding: false)

  %RefreshToken{}
  |> RefreshToken.changeset(%{
    token: token,
    user_id: user.id,
    expires_at: DateTime.add(DateTime.utc_now(), 30, :day)
  })
  |> Repo.insert!()

  token
end

# Refresh endpoint
def refresh(conn, %{"refresh_token" => token}) do
  case Repo.get_by(RefreshToken, token: token) do
    %{expires_at: exp, user_id: uid} when exp > DateTime.utc_now() ->
      user = Repo.get!(User, uid)
      access_token = Token.generate(user)
      json(conn, %{access_token: access_token})

    _ ->
      conn |> put_status(:unauthorized) |> json(%{error: "Invalid refresh token"})
  end
end
```

---

## Token Expiry Best Practices

| Token Type     | Expiry       | Storage                        |
|----------------|-------------|--------------------------------|
| Access token   | 15 min - 1h | Client memory (NOT localStorage) |
| Refresh token  | 7 - 30 days | httpOnly cookie or secure storage |
| Password reset | 1 hour      | Database                        |
| Email verify   | 24 hours    | Database                        |

### Why Short Access Token Expiry?

- If an access token is stolen, the damage window is small
- Combined with refresh tokens, the user experience is seamless
- Server doesn't need to check a revocation list for every API call

---

## Phoenix.Token (Built-in Alternative)

Phoenix includes a simpler signed token system:

```elixir
# Generate
token = Phoenix.Token.sign(MyAppWeb.Endpoint, "user_auth", user_id)

# Verify (max age in seconds)
case Phoenix.Token.verify(MyAppWeb.Endpoint, "user_auth", token, max_age: 86400) do
  {:ok, user_id} -> # valid
  {:error, :expired} -> # too old
  {:error, :invalid} -> # tampered or wrong salt
end
```

This is simpler than raw JWT but not interoperable with other services. Use it for internal tokens (email verification, websocket auth, etc.).
