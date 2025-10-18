#!/usr/bin/env bash

# Default values
API_URL="http://localhost:8081/blog_api/posts"
FILE=""
TITLE=""
DESCRIPTION=""
TAGS=""

# Parse command line arguments
while [[ $# -gt 0 ]]; do
  case $1 in
    --file)
      FILE="$2"
      shift 2
      ;;
    --title)
      TITLE="$2"
      shift 2
      ;;
    --description)
      DESCRIPTION="$2"
      shift 2
      ;;
    --tags)
      TAGS="$2"
      shift 2
      ;;
    --url)
      API_URL="$2"
      shift 2
      ;;
    -h|--help)
      echo "Usage: $0 --file <markdown-file> --title <title> --description <description> --tags <tag1,tag2,...>"
      echo ""
      echo "Options:"
      echo "  --file         Path to markdown file (required)"
      echo "  --title        Blog post title (required)"
      echo "  --description  Blog post description (required)"
      echo "  --tags         Comma-separated tags (required)"
      echo "  --url          API URL (default: http://localhost:8081/blog_api/posts)"
      echo "  -h, --help     Show this help message"
      echo ""
      echo "Environment variables:"
      echo "  API_KEY        API key for authentication (required)"
      echo ""
      echo "Example:"
      echo "  export API_KEY=123"
      echo "  $0 --file post.md --title \"My Post\" --description \"My description\" --tags \"tutorial,programming\""
      exit 0
      ;;
    *)
      echo "Unknown option: $1"
      echo "Use --help for usage information"
      exit 1
      ;;
  esac
done

# Validate required arguments
if [[ -z "$FILE" ]]; then
  echo "Error: --file is required"
  exit 1
fi

if [[ -z "$TITLE" ]]; then
  echo "Error: --title is required"
  exit 1
fi

if [[ -z "$DESCRIPTION" ]]; then
  echo "Error: --description is required"
  exit 1
fi

if [[ -z "$TAGS" ]]; then
  echo "Error: --tags is required"
  exit 1
fi

if [[ -z "$API_KEY" ]]; then
  echo "Error: API_KEY environment variable is not set"
  echo "Export it with: export API_KEY=your-api-key"
  exit 1
fi

# Check if file exists
if [[ ! -f "$FILE" ]]; then
  echo "Error: File '$FILE' not found"
  exit 1
fi

# Convert comma-separated tags to JSON array
IFS=',' read -ra TAG_ARRAY <<< "$TAGS"
TAGS_JSON=$(printf '%s\n' "${TAG_ARRAY[@]}" | jq -R . | jq -s .)

# Read content and create JSON payload
CONTENT=$(cat "$FILE")

echo "Creating blog post..."
echo -e "  Title:       $TITLE"
echo -e "  Description: $DESCRIPTION"
echo -e "  Tags:        ${TAG_ARRAY[*]}"
echo -e "  File:        $FILE"
echo ""

# Create and send request
jq -n \
  --arg title "$TITLE" \
  --arg description "$DESCRIPTION" \
  --argjson tags "$TAGS_JSON" \
  --arg content "$CONTENT" \
  '{blogPost:{title:$title,description:$description,tags:$tags,content:$content}}' \
| curl -X POST "$API_URL" \
    -H "Authorization: Bearer $API_KEY" \
    -H "Content-Type: application/json" \
    -d @- \
    -w "\n\nHTTP Status: %{http_code}\n"

echo ""
