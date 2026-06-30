# Rafiq Auth Backend

Production-ready **Authentication REST API** built with **Node.js**, **Express.js**, and **PostgreSQL**.

## 🚀 Features

- ✅ JWT Access Tokens (15-minute expiry) + Refresh Token rotation
- ✅ bcrypt password hashing (12 salt rounds)
- ✅ PostgreSQL with connection pooling (pg-pool)
- ✅ CORS with configurable origins
- ✅ Input validation via `express-validator`
- ✅ Rate limiting (general + strict auth limiter)
- ✅ Security headers (helmet-equivalent, zero deps)
- ✅ Graceful shutdown
- ✅ Centralized error handling with production-safe messages
- ✅ Soft-delete users
- ✅ Logout from all devices (token revocation)
- ✅ Health check endpoints
- ✅ Database seeder for dev/testing

---

## 📁 Project Structure

```
backend/
├── src/
│   ├── server.js              # Entry point
│   ├── app.js                 # Express setup
│   ├── database/
│   │   ├── connection.js      # pg Pool
│   │   ├── schema.sql         # Full SQL schema
│   │   ├── migrate.js         # Migration runner
│   │   └── seed.js            # Dev seeder
│   ├── models/
│   │   ├── user.model.js
│   │   └── refreshToken.model.js
│   ├── services/
│   │   └── auth.service.js    # Business logic
│   ├── controllers/
│   │   ├── auth.controller.js
│   │   └── user.controller.js
│   ├── routes/
│   │   ├── auth.routes.js
│   │   ├── user.routes.js
│   │   └── health.routes.js
│   ├── middleware/
│   │   ├── authenticate.js    # JWT verification
│   │   ├── validate.js        # express-validator runner
│   │   ├── rateLimiter.js
│   │   ├── securityHeaders.js
│   │   ├── requestLogger.js
│   │   └── errorHandler.js
│   ├── validators/
│   │   └── auth.validator.js
│   └── utils/
│       ├── AppError.js
│       └── logger.js
├── .env.example
├── .gitignore
└── package.json
```

---

## ⚙️ Setup

### 1. Prerequisites

- Node.js ≥ 18
- PostgreSQL ≥ 14

### 2. Install Dependencies

```bash
cd backend
npm install
```

### 3. Configure Environment

In Command Prompt (cmd.exe):
```cmd
copy .env.example .env
```

In PowerShell:
```powershell
Copy-Item .env.example .env
```

Edit `.env` and fill in your database credentials and JWT secrets:

```env
DB_HOST=localhost
DB_PORT=5432
DB_NAME=rafiq_db
DB_USER=postgres
DB_PASSWORD=your_password

JWT_SECRET=your_secret_min_32_chars
JWT_REFRESH_SECRET=another_secret_min_32_chars
```

### 4. Create the Database

```bash
psql -U postgres -c "CREATE DATABASE rafiq_db;"
```

### 5. Run Migrations

```bash
npm run db:migrate
```

### 6. (Optional) Seed Dev Data

```bash
npm run db:seed
# Creates: admin / Admin@123456  and  testuser / Test@123456
```

### 7. Start the Server

```bash
npm run dev     # Development (nodemon)
npm start       # Production
```

---

## 📡 API Reference

### Auth Endpoints — `/api/auth`

| Method | Endpoint | Auth | Description |
|--------|----------|------|-------------|
| `POST` | `/register` | ❌ | Register a new user |
| `POST` | `/login` | ❌ | Login, receive tokens |
| `POST` | `/refresh` | ❌ | Rotate refresh token |
| `POST` | `/logout` | ❌ | Revoke refresh token |
| `POST` | `/logout-all` | ✅ | Revoke all sessions |
| `GET`  | `/me` | ✅ | Current user info |
| `PATCH` | `/change-password` | ✅ | Change password |

### User Endpoints — `/api/users`

| Method | Endpoint | Auth | Description |
|--------|----------|------|-------------|
| `GET`  | `/profile` | ✅ | Get full profile |
| `PATCH` | `/profile` | ✅ | Update profile |
| `DELETE` | `/account` | ✅ | Delete account |

### Health Endpoints — `/api/health`

| Method | Endpoint | Description |
|--------|----------|-------------|
| `GET`  | `/` | Server liveness |
| `GET`  | `/db` | Database connectivity |

---

## 📝 Request / Response Examples

### Register

```http
POST /api/auth/register
Content-Type: application/json

{
  "full_name": "Ahmed Youssef",
  "username": "ahmed_y",
  "email": "ahmed@example.com",
  "password": "Secure@1234",
  "confirm_password": "Secure@1234"
}
```

**Response 201:**
```json
{
  "success": true,
  "message": "Account created successfully",
  "data": {
    "user": {
      "id": "uuid...",
      "full_name": "Ahmed Youssef",
      "username": "ahmed_y",
      "email": "ahmed@example.com",
      "status": "active",
      "is_verified": false,
      "created_at": "2026-06-19T..."
    }
  }
}
```

### Login

```http
POST /api/auth/login
Content-Type: application/json

{
  "identifier": "ahmed_y",
  "password": "Secure@1234"
}
```

**Response 200:**
```json
{
  "success": true,
  "message": "Logged in successfully",
  "data": {
    "accessToken": "eyJ...",
    "refreshToken": "a3f9...",
    "expiresIn": "15m",
    "user": { ... }
  }
}
```

---

## 🔐 Security Practices

- Passwords hashed with **bcrypt** (12 rounds)
- Refresh tokens stored as **SHA-256 hashes**
- Access tokens expire in **15 minutes**
- Refresh tokens expire in **7 days** and are **rotated** on every use
- Rate limiting: **5 attempts / 15 min** on auth routes
- All SQL uses **parameterized queries** (no SQL injection)
- Account status validated on **every authenticated request**
- Security headers: `X-Content-Type-Options`, `X-Frame-Options`, `HSTS`, etc.
