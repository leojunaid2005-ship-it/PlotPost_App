# PlotPost API

Express API for PlotPost. MongoDB stores accounts, listings, conversations,
messages, and notifications. Listing images are uploaded to Cloudinary; password
reset email uses SMTP.

## Requirements

- Node.js 20+
- MongoDB
- Cloudinary account (for listing image uploads)
- SMTP account (for password reset email)

## Run locally

```powershell
cd backend
Copy-Item .env.example .env
npm install
```

Set `MONGODB_URI` and a random `JWT_SECRET` of at least 32 characters in `.env`.
Fill in Cloudinary credentials to enable photo uploads and SMTP credentials to
enable password reset emails. Set `CORS_ORIGINS` to the exact web app origins
that should be allowed.

```powershell
npm run dev
```

The health endpoint is `GET http://localhost:3000/api/health`.

For Flutter, the Android emulator uses the default API URL. For web, use:

```powershell
flutter run -d chrome --web-port=5000 --dart-define=API_BASE_URL=http://localhost:3000/api
```

For a physical device, set `API_BASE_URL` to the computer's LAN IP and allow
that device through the local firewall. Use HTTPS for deployed environments.

## API

All responses use JSON except `204 No Content` on listing deletion. Protected
routes require `Authorization: Bearer <token>`.

| Method | Route | Auth | Purpose |
|---|---|---:|---|
| GET | `/api/health` | No | Health check |
| POST | `/api/auth/register` | No | Create account and receive JWT |
| POST | `/api/auth/login` | No | Sign in and receive JWT |
| GET | `/api/auth/me` | Yes | Current account |
| POST | `/api/auth/forgot-password` | No | Send expiring reset link by email |
| POST | `/api/auth/reset-password` | No | Set password using reset token |
| GET | `/api/listings` | No | Browse/filter listings (`q`, `type`, `deal`, `page`, `limit`) |
| GET | `/api/listings/mine` | Yes | Current user's listings |
| POST | `/api/listings` | Yes | Create listing; multipart image field `images`, up to 8 |
| PATCH | `/api/listings/:id` | Yes | Update owned listing and its images |
| DELETE | `/api/listings/:id` | Yes | Delete owned listing |
| GET | `/api/messages/users?q=...` | Yes | Find message recipients |
| GET | `/api/messages/conversations` | Yes | List current user's conversations |
| POST | `/api/messages/conversations` | Yes | Start/reuse a conversation |
| GET | `/api/messages/conversations/:id/messages` | Yes | Read conversation messages |
| POST | `/api/messages/conversations/:id/messages` | Yes | Send message and notify recipient |
| GET | `/api/notifications` | Yes | List current user's notifications |
| PATCH | `/api/notifications/:id/read` | Yes | Mark notification read |
| PATCH | `/api/notifications/read-all` | Yes | Mark all notifications read |

Reset email links use `APP_RESET_URL` (defaults to `plotpost://reset-password`).
The app's reset form accepts the token from that email link and submits it to
`/api/auth/reset-password`.
