# API Documentation

## Overview

The file documents all API endpoints of this project.

---

## Table of Contents

- [Authentication](#authentication)
- [Blog API](#blog-api)
  - [Get All Blog Metadata](#get-all-blog-metadata)
  - [Get Specific Blog Post](#get-specific-blog-post)
  - [Create Blog Post](#create-blog-post)
  - [Update Blog Post](#update-blog-post)
  - [Delete Blog Post](#delete-blog-post)
- [Internal API](#internal-api)
  - [Upload CV](#upload-cv)
  - [Upload Avatar](#upload-avatar)
  - [Upload Favicon](#upload-favicon)
- [Error Responses](#error-responses)

---

## Authentication

Protected endpoints require authentication via the `Authorization` header:

```
Authorization: Bearer your-api-key-here
```

Set your API key as an environment variable:

```bash
export API_KEY="your-secret-api-key"
```

---

## Blog API

Base path: `/blog_api`

### Get All Blog Metadata

Retrieve metadata for all blog posts (without content).

**Endpoint:** `GET /blog_api/posts`

**Authentication:** None required

**Response:**
```json
[
  {
    "title": "My First Post",
    "description": "This is my first blog post",
    "tags": ["tutorial", "d-lang"],
    "createdAt": "2025-01-15T10:30:00Z",
    "modifiedAt": "2025-01-15T10:30:00Z"
  },
  {
    "title": "Another Post",
    "description": "My second post",
    "tags": ["programming"],
    "createdAt": "2025-01-16T14:20:00Z",
    "modifiedAt": "2025-01-17T09:15:00Z"
  }
]
```

**cURL Example:**
```bash
curl http://localhost:8081/blog_api/posts
```

---

### Get Specific Blog Post

Retrieve a complete blog post including content.

**Endpoint:** `GET /blog_api/posts/:title`

**Authentication:** None required

**Parameters:**
- `title` (path parameter) - The exact title of the blog post

**Response:**
```json
{
  "metadata": {
    "title": "My First Post",
    "description": "This is my first blog post",
    "tags": ["tutorial", "d-lang"],
    "createdAt": "2025-01-15T10:30:00Z",
    "modifiedAt": "2025-01-15T10:30:00Z"
  },
  "content": "# Hello World\n\nThis is the **markdown** content of my post."
}
```

**cURL Example:**
```bash
curl http://localhost:8081/blog_api/posts/My%20First%20Post
```

**Error Response (404):**
```json
{
  "statusMessage": "Blog post not found: My First Post",
  "statusCode": 404
}
```

---

### Create Blog Post

Create a new blog post.

**Endpoint:** `POST /blog_api/posts`

**Authentication:** Required

**Request Body:**
```json
{
  "blogPost": {
    "title": "My New Post",
    "description": "A short description",
    "tags": ["tutorial", "programming"],
    "content": "# Title\n\nMarkdown content here..."
  }
}
```

**Required Fields:**
- `title` (string) - Post title
- `description` (string) - Short description
- `tags` (array of strings) - List of tags
- `content` (string) - Markdown content

**Response:**
```json
{
  "success": true,
  "message": "Blog post created successfully!",
  "data": {
    "metadata": {
      "title": "My New Post",
      "description": "A short description",
      "tags": ["tutorial", "programming"],
      "createdAt": "2025-01-18T10:30:00Z",
      "modifiedAt": "2025-01-18T10:30:00Z"
    }
  }
}
```

**cURL Example:**
```bash
curl -X POST http://localhost:8081/blog_api/posts \
  -H "Authorization: Bearer $API_KEY" \
  -H "Content-Type: application/json" \
  -d '{
    "blogPost": {
      "title": "My New Post",
      "description": "A short description",
      "tags": ["tutorial", "programming"],
      "content": "# Title\n\nMarkdown content here..."
    }
  }'
```

**Error Response (Missing Fields):**
```json
{
  "success": false,
  "message": "All fields (title, description, tags, content) are required when creating a post!",
  "data": {}
}
```

**Error Response (Duplicate):**
```json
{
  "success": false,
  "message": "Blog post already exists!",
  "data": {}
}
```

---

### Update Blog Post

Update an existing blog post. All fields are optional - only provided fields will be updated.

**Endpoint:** `PUT /blog_api/posts/:title`

**Authentication:** Required

**Parameters:**
- `title` (path parameter) - The exact title of the post to update

**Request Body (all fields optional):**
```json
{
  "blogPost": {
    "title": "Updated Title",
    "description": "Updated description",
    "tags": ["updated", "tags"],
    "content": "# Updated\n\nNew content..."
  }
}
```

**Note:** You can send only the fields you want to update. Omitted fields will keep their existing values.

**Response:**
```json
{
  "success": true,
  "message": "Blog post updated successfully!",
  "data": {
    "metadata": {
      "title": "Updated Title",
      "description": "Updated description",
      "tags": ["updated", "tags"],
      "createdAt": "2025-01-15T10:30:00Z",
      "modifiedAt": "2025-01-18T15:45:00Z"
    },
    "content": "# Updated\n\nNew content..."
  }
}
```

**cURL Examples:**

Update all fields:
```bash
curl -X PUT http://localhost:8081/blog_api/posts/My%20New%20Post \
  -H "Authorization: Bearer $API_KEY" \
  -H "Content-Type: application/json" \
  -d '{
    "blogPost": {
      "title": "Updated Title",
      "description": "Updated description",
      "tags": ["updated"],
      "content": "# Updated Content"
    }
  }'
```

Update only content:
```bash
curl -X PUT http://localhost:8081/blog_api/posts/My%20New%20Post \
  -H "Authorization: Bearer $API_KEY" \
  -H "Content-Type: application/json" \
  -d '{
    "content": "# Just updating the content"
  }'
```

Update only tags:
```bash
curl -X PUT http://localhost:8081/blog_api/posts/My%20New%20Post \
  -H "Authorization: Bearer $API_KEY" \
  -H "Content-Type: application/json" \
  -d '{
    "tags": ["new-tag", "another-tag"]
  }'
```

**Error Response (Not Found):**
```json
{
  "success": false,
  "message": "Blog post not found: My New Post",
  "data": {}
}
```

---

### Delete Blog Post

Permanently delete a blog post.

**Endpoint:** `DELETE /blog_api/posts/:title`

**Authentication:** Required

**Parameters:**
- `title` (path parameter) - The exact title of the post to delete

**Response:**
```json
{
  "success": true,
  "message": "Blog post deleted successfully!",
  "data": {}
}
```

**cURL Example:**
```bash
curl -X DELETE http://localhost:8081/blog_api/posts/My%20New%20Post \
  -H "Authorization: Bearer $API_KEY"
```

**Error Response (404):**
```json
{
  "statusMessage": "Blog post not found: My New Post",
  "statusCode": 404
}
```

---

## Internal API

Base path: `/internal_api`

These endpoints handle file uploads for CV and avatar.

### Upload CV

Upload a new CV PDF file. File will be saved to `public/cv.pdf`.

**Endpoint:** `POST /internal_api/cv`

**Authentication:** Required

**Content-Type:** `multipart/form-data`

**Form Fields:**
- `file` - The PDF file to upload

**Validation:**
- File extension must be `.pdf`
- Maximum file size: 10MB

**Response:**
```json
{
  "success": true,
  "message": "CV updated!",
  "data": {}
}
```

**cURL Example:**
```bash
curl -X POST http://localhost:8081/internal_api/cv \
  -H "Authorization: Bearer $API_KEY" \
  -F "file=@/path/to/your/cv.pdf"
```

**Error Responses:**

Missing file:
```json
{
  "success": false,
  "message": "No file provided. Use 'file' as the field name.",
  "data": {}
}
```

Invalid file type:
```json
{
  "success": false,
  "message": "Invalid file type. Only PDF files are allowed.",
  "data": {}
}
```

Invalid PDF (magic bytes check):
```json
{
  "success": false,
  "message": "Invalid file. File is not a valid PDF.",
  "data": {}
}
```

File too large:
```json
{
  "success": false,
  "message": "File too large. Maximum size is 10MB.",
  "data": {}
}
```

---

### Upload Avatar

Upload a new avatar image. Image will be automatically resized to 512px width (maintaining aspect ratio) and saved as `public/avatar.png`.

**Endpoint:** `POST /internal_api/avatar`

**Authentication:** Required

**Content-Type:** `multipart/form-data`

**Form Fields:**
- `file` - The image file to upload

**Validation:**
- File extension must be `.jpg`, `.jpeg`, or `.png`
- Maximum file size: 5MB (configurable)
- Image will be resized to 512px width

**Response:**
```json
{
  "success": true,
  "message": "Avatar updated!",
  "data": {}
}
```

**cURL Example:**
```bash
curl -X POST http://localhost:8081/internal_api/avatar \
  -H "Authorization: Bearer $API_KEY" \
  -F "file=@/path/to/your/photo.jpg"
```

**Error Responses:**

Missing file:
```json
{
  "success": false,
  "message": "No file provided. Use 'file' as the field name.",
  "data": {}
}
```

Invalid file type:
```json
{
  "success": false,
  "message": "Invalid file type. Only JPEG and PNG images are allowed.",
  "data": {}
}
```

Invalid image (magic bytes check):
```json
{
  "success": false,
  "message": "Invalid file. File is not a valid JPEG or PNG image.",
  "data": {}
}
```

File too large:
```json
{
  "success": false,
  "message": "File too large. Maximum size is 5MB.",
  "data": {}
}
```

---

### Upload Favicon

Upload a new favicon ICO file. File will be saved to `public/favicon.ico`.

**Endpoint:** `POST /internal_api/favicon`

**Authentication:** Required

**Content-Type:** `multipart/form-data`

**Form Fields:**
- `file` - The ICO file to upload

**Validation:**
- File extension must be `.ico`
- Maximum file size: 1MB

**Response:**
```json
{
  "success": true,
  "message": "Favicon updated!",
  "data": {}
}
```

**cURL Example:**
```bash
curl -X POST http://localhost:8081/internal_api/favicon \
  -H "Authorization: Bearer $API_KEY" \
  -F "file=@/path/to/your/favicon.ico"
```

**Error Responses:**

Missing file:
```json
{
  "success": false,
  "message": "No file provided. Use 'file' as the field name.",
  "data": {}
}
```

Invalid file type:
```json
{
  "success": false,
  "message": "Invalid file type. Only .ico files are allowed.",
  "data": {}
}
```

Invalid ICO (magic bytes check):
```json
{
  "success": false,
  "message": "Invalid file. File is not a valid ICO file.",
  "data": {}
}
```

File too large:
```json
{
  "success": false,
  "message": "File too large. Maximum size is 1MB.",
  "data": {}
}
```

---

## Error Responses

### Authentication Errors

**401 Unauthorized - Missing Header:**
```json
{
  "statusMessage": "Missing Authorization header",
  "statusCode": 401
}
```

**401 Unauthorized - Invalid Format:**
```json
{
  "statusMessage": "Invalid Authorization header format. Expected: Bearer <api-key>",
  "statusCode": 401
}
```

**401 Unauthorized - Invalid Key:**
```json
{
  "statusMessage": "Invalid API key",
  "statusCode": 401
}
```

### General Errors

**404 Not Found:**
```json
{
  "statusMessage": "Resource not found",
  "statusCode": 404
}
```

**500 Internal Server Error:**
```json
{
  "statusMessage": "Internal server error",
  "statusCode": 500
}
```

---

## Complete Usage Examples

### Workflow: Create, Update, Read, Delete Blog Post

```bash
# Set API key
export API_KEY="your-secret-key"

# 1. Create a new post
curl -X POST http://localhost:8081/blog_api/posts \
  -H "Authorization: Bearer $API_KEY" \
  -H "Content-Type: application/json" \
  -d '{
    "blogPost": {
      "title": "Getting Started with D",
      "description": "Learn D programming basics",
      "tags": ["d-lang", "tutorial", "beginner"],
      "content": "# Getting Started\n\nD is awesome!"
    }
  }'

# 2. Get all posts
curl http://localhost:8081/blog_api/posts

# 3. Get specific post
curl http://localhost:8081/blog_api/posts/Getting%20Started%20with%20D

# 4. Update the post
curl -X PUT http://localhost:8081/blog_api/posts/Getting%20Started%20with%20D \
  -H "Authorization: Bearer $API_KEY" \
  -H "Content-Type: application/json" \
  -d '{
    "blogPost": {
      "content": "# Getting Started (Updated)\n\nD is really awesome!",
      "tags": ["d-lang", "tutorial", "beginner", "updated"]
    }
  }'

# 5. Delete the post
curl -X DELETE http://localhost:8081/blog_api/posts/Getting%20Started%20with%20D \
  -H "Authorization: Bearer $API_KEY"
```

### Workflow: Upload CV, Avatar, and Favicon
```bash
# Set API key
export API_KEY="your-secret-key"

# Upload CV
curl -X POST http://localhost:8081/internal_api/cv \
  -H "Authorization: Bearer $API_KEY" \
  -F "file=@./documents/my-cv.pdf"

# Upload Avatar
curl -X POST http://localhost:8081/internal_api/avatar \
  -H "Authorization: Bearer $API_KEY" \
  -F "file=@./photos/profile-pic.jpg"

# Upload Favicon
curl -X POST http://localhost:8081/internal_api/favicon \
  -H "Authorization: Bearer $API_KEY" \
  -F "file=@./images/favicon.ico"
```



