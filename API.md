# API Documentation

## Overview

This documents all API endpoints. Authentication uses JWT tokens obtained via the login endpoint.

---

## Table of Contents

- [Authentication](#authentication)
- [Auth API](#auth-api)
  - [Login](#login)
- [Admin API](#admin-api)
  - [Change Password](#change-password)
  - [Update About Info](#update-about-info)
  - [List All Banners](#list-all-banners)
  - [Create Banner](#create-banner)
  - [Update Banner](#update-banner)
  - [Delete Banner](#delete-banner)
- [Blog API](#blog-api)
  - [Get All Blog Metadata](#get-all-blog-metadata)
  - [Get Specific Blog Post](#get-specific-blog-post)
  - [Create Blog Post](#create-blog-post)
  - [Update Blog Post](#update-blog-post)
  - [Delete Blog Post](#delete-blog-post)
- [Public API](#public-api)
  - [Get About Info](#get-about-info)
  - [Get Active Banners](#get-active-banners)
- [Internal API](#internal-api)
  - [Upload CV](#upload-cv)
  - [Upload Avatar](#upload-avatar)
  - [Upload Favicon](#upload-favicon)
- [Error Responses](#error-responses)

---

## Authentication

Protected endpoints require a JWT token obtained from the login endpoint:

```
Authorization: Bearer <jwt-token>
```

Tokens expire after 24 hours.

**Environment variables:**
- `ADMIN_USERNAME` — admin username (default: `admin`)
- `ADMIN_PASSWORD` — admin password (default: `changeme`)
- `JWT_SECRET` — JWT signing secret (auto-generated if unset)

---

## Auth API

Base path: `/auth_api`

### Login

Authenticate and receive a JWT token.

**Endpoint:** `POST /auth_api/login`

**Authentication:** None

**Request Body:**
```json
{
  "loginRequest": {
    "username": "admin",
    "password": "changeme"
  }
}
```

**Response:**
```json
{
  "success": true,
  "message": "Login successful.",
  "data": {
    "token": "eyJ..."
  }
}
```

**cURL Example:**
```bash
curl -X POST http://localhost:8081/auth_api/login \
  -H "Content-Type: application/json" \
  -d '{"loginRequest": {"username": "admin", "password": "changeme"}}'
```

---

## Admin API

Base path: `/admin_api`

All admin endpoints require JWT authentication.

### Change Password

**Endpoint:** `POST /admin_api/password`

**Request Body:**
```json
{
  "passwordChangeRequest": {
    "currentPassword": "changeme",
    "newPassword": "newsecurepassword"
  }
}
```

**cURL Example:**
```bash
curl -X POST http://localhost:8081/admin_api/password \
  -H "Authorization: Bearer $TOKEN" \
  -H "Content-Type: application/json" \
  -d '{"passwordChangeRequest": {"currentPassword": "changeme", "newPassword": "newsecurepassword"}}'
```

---

### Update About Info

**Endpoint:** `PUT /admin_api/about`

**Request Body:**
```json
{
  "aboutRequest": {
    "name": "Kirill Saidov",
    "bio": ["First paragraph.", "Second paragraph."],
    "social": {
      "email-user": "user",
      "email-domain": "gmail.com",
      "linkedin": "https://linkedin.com/in/username",
      "github_ks": "https://github.com/username",
      "github_rk": "https://github.com/username2",
      "youtube": "https://youtube.com/@channel"
    }
  }
}
```

**cURL Example:**
```bash
curl -X PUT http://localhost:8081/admin_api/about \
  -H "Authorization: Bearer $TOKEN" \
  -H "Content-Type: application/json" \
  -d '{"aboutRequest": {"name": "Kirill Saidov", "bio": ["Bio paragraph."]}}'
```

---

### List All Banners

**Endpoint:** `GET /admin_api/banners`

**Response:**
```json
[
  {
    "id": "...",
    "message": "Site maintenance tonight",
    "type": "warning",
    "startDate": "2025-01-01T00:00:00Z",
    "endDate": "2025-01-02T00:00:00Z",
    "active": true,
    "createdAt": "2024-12-30T10:00:00Z"
  }
]
```

---

### Create Banner

**Endpoint:** `POST /admin_api/banners`

**Request Body:**
```json
{
  "bannerRequest": {
    "message": "Welcome to the new site!",
    "type": "info",
    "startDate": "2025-01-01T00:00:00Z",
    "endDate": "2025-12-31T23:59:59Z",
    "active": true
  }
}
```

---

### Update Banner

**Endpoint:** `PUT /admin_api/banners/:id`

**Request Body:** Same as create (all fields optional).

---

### Delete Banner

**Endpoint:** `DELETE /admin_api/banners/:id`

---

## Blog API

Base path: `/blog_api`

### Get All Blog Metadata

**Endpoint:** `GET /blog_api/posts`
**Authentication:** None

```bash
curl http://localhost:8081/blog_api/posts
```

---

### Get Specific Blog Post

**Endpoint:** `GET /blog_api/posts/:title`
**Authentication:** None

```bash
curl http://localhost:8081/blog_api/posts/My%20First%20Post
```

---

### Create Blog Post

**Endpoint:** `POST /blog_api/posts`
**Authentication:** Required

```bash
curl -X POST http://localhost:8081/blog_api/posts \
  -H "Authorization: Bearer $TOKEN" \
  -H "Content-Type: application/json" \
  -d '{
    "blogPost": {
      "title": "My New Post",
      "description": "A short description",
      "tags": ["tutorial"],
      "content": "# Title\n\nContent here..."
    }
  }'
```

---

### Update Blog Post

**Endpoint:** `PUT /blog_api/posts/:title`
**Authentication:** Required

```bash
curl -X PUT http://localhost:8081/blog_api/posts/My%20New%20Post \
  -H "Authorization: Bearer $TOKEN" \
  -H "Content-Type: application/json" \
  -d '{"blogPost": {"content": "# Updated Content"}}'
```

---

### Delete Blog Post

**Endpoint:** `DELETE /blog_api/posts/:title`
**Authentication:** Required

```bash
curl -X DELETE http://localhost:8081/blog_api/posts/My%20New%20Post \
  -H "Authorization: Bearer $TOKEN"
```

---

## Public API

Base path: `/public_api`

### Get About Info

**Endpoint:** `GET /public_api/about`
**Authentication:** None

Returns about info from MongoDB (seeded from `config/config.json` on first startup).

```bash
curl http://localhost:8081/public_api/about
```

---

### Get Active Banners

**Endpoint:** `GET /public_api/banners`
**Authentication:** None

Returns banners where `active=true` and current time is within start/end date range.

```bash
curl http://localhost:8081/public_api/banners
```

---

## Internal API

Base path: `/internal_api`

All internal endpoints require JWT authentication.

### Upload CV

**Endpoint:** `POST /internal_api/cv`

```bash
curl -X POST http://localhost:8081/internal_api/cv \
  -H "Authorization: Bearer $TOKEN" \
  -F "file=@/path/to/cv.pdf"
```

---

### Upload Avatar

**Endpoint:** `POST /internal_api/avatar`

Auto-resized to 512px width, saved as PNG.

```bash
curl -X POST http://localhost:8081/internal_api/avatar \
  -H "Authorization: Bearer $TOKEN" \
  -F "file=@/path/to/photo.jpg"
```

---

### Upload Favicon

**Endpoint:** `POST /internal_api/favicon`

```bash
curl -X POST http://localhost:8081/internal_api/favicon \
  -H "Authorization: Bearer $TOKEN" \
  -F "file=@/path/to/favicon.ico"
```

---

## API Summary

| Method | Path | Auth | Description |
|--------|------|------|-------------|
| POST | /auth_api/login | No | Login, returns JWT |
| POST | /admin_api/password | JWT | Change password |
| PUT | /admin_api/about | JWT | Update about info |
| GET | /admin_api/banners | JWT | List all banners |
| POST | /admin_api/banners | JWT | Create banner |
| PUT | /admin_api/banners/:id | JWT | Update banner |
| DELETE | /admin_api/banners/:id | JWT | Delete banner |
| GET | /public_api/about | No | Get about info |
| GET | /public_api/banners | No | Get active banners |
| GET | /blog_api/posts | No | List blog metadata |
| GET | /blog_api/posts/:title | No | Get full blog post |
| POST | /blog_api/posts | JWT | Create blog post |
| PUT | /blog_api/posts/:title | JWT | Update blog post |
| DELETE | /blog_api/posts/:title | JWT | Delete blog post |
| POST | /internal_api/cv | JWT | Upload CV PDF |
| POST | /internal_api/avatar | JWT | Upload avatar |
| POST | /internal_api/favicon | JWT | Upload favicon |

---

## Error Responses

**401 Unauthorized:**
```json
{"success": false, "error": "Missing Authorization header"}
{"success": false, "error": "Invalid or expired token"}
```

**404 Not Found:**
```json
{"success": false, "error": "Blog post not found: title"}
```
