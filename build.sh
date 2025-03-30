#!/bin/bash

# --- Configuration ---
POSTS_DIR="posts"
OUTPUT_DIR="_site"
BIB_FILE="references.bib"
TEMPLATE_FILE="templates/basic_template.html"
CSS_FILE="style.css"
# --- Add JS Config File ---
JS_CONFIG_DIR="js"
JS_CONFIG_FILE="mathjax-config.js"

# --- Script Logic ---
set -e
echo "Starting blog build..."
echo "Cleaning output directory: $OUTPUT_DIR"
rm -rf "$OUTPUT_DIR"

echo "Creating output structure..."
mkdir -p "$OUTPUT_DIR/posts"
# --- Create JS output directory ---
mkdir -p "$OUTPUT_DIR/$JS_CONFIG_DIR"

# Check if template exists
if [ ! -f "$TEMPLATE_FILE" ]; then
  echo "Error: Template file '$TEMPLATE_FILE' not found." >&2
  exit 1
fi

# Check bibliography
BIB_FLAGS=()
if [ -f "$BIB_FILE" ]; then
  echo "Using bibliography: $BIB_FILE"
  BIB_FLAGS+=(--bibliography="$BIB_FILE" --citeproc)
else
  echo "No bibliography file found at '$BIB_FILE', skipping citation processing."
fi

# Process Markdown posts
echo "Processing Markdown posts..."
while IFS= read -r md_file; do
  if [ -z "$md_file" ]; then continue; fi
  base_name=$(basename "$md_file" .md)
  html_file="$OUTPUT_DIR/posts/${base_name}.html"
  echo "  Converting '$md_file' -> '$html_file'"

  # --- Pandoc command WITHOUT --mathjax ---
  pandoc "$md_file" \
    --standalone \
    --template="$TEMPLATE_FILE" \
    "${BIB_FLAGS[@]}" \
    --metadata pagetitle="$base_name" \
    --metadata is_post=true \
    --from markdown+tex_math_dollars \
    --to html5 \
    -o "$html_file"

  if [ $? -ne 0 ]; then
    echo "Error processing '$md_file'." >&2
    exit 1
  fi
done < <(find "$POSTS_DIR" -maxdepth 1 -name "*.md")

# Copy static files
if [ -f "$CSS_FILE" ]; then
  echo "Copying $CSS_FILE to $OUTPUT_DIR/"
  cp "$CSS_FILE" "$OUTPUT_DIR/"
else
  echo "Warning: CSS file '$CSS_FILE' not found, skipping copy."
fi

# --- Copy JS config file ---
if [ -f "$JS_CONFIG_DIR/$JS_CONFIG_FILE" ]; then
  echo "Copying $JS_CONFIG_DIR/$JS_CONFIG_FILE to $OUTPUT_DIR/$JS_CONFIG_DIR/"
  cp "$JS_CONFIG_DIR/$JS_CONFIG_FILE" "$OUTPUT_DIR/$JS_CONFIG_DIR/"
else
  echo "Warning: JS config file '$JS_CONFIG_DIR/$JS_CONFIG_FILE' not found, skipping copy."
fi

# Generate index page
INDEX_FILE="$OUTPUT_DIR/index.html"
echo "Generating index page: $INDEX_FILE"
BODY_CONTENT="<h1>Blog Posts</h1>\n<ul class=\"post-list\">\n"
while IFS= read -r html_file; do
  if [ -z "$html_file" ]; then continue; fi
  post_title=$(basename "$html_file" .html)
  md_source_file="$POSTS_DIR/${post_title}.md"
  post_date=""
  if [ -f "$md_source_file" ]; then
    post_date=$(grep '^date:' "$md_source_file" | sed -e 's/^date:[[:space:]]*//' -e 's/^["]//' -e 's/["]$//' -e 's/^['\'']//' -e 's/['\'']$//' | head -n 1)
  fi
  date_display=""
  if [ -n "$post_date" ]; then
    date_display="<span class=\"post-date\">($post_date)</span>"
  fi
  post_link="posts/${post_title}.html"
  BODY_CONTENT+="  <li><a href=\"$post_link\">$post_title</a> $date_display</li>\n"
done < <(find "$OUTPUT_DIR/posts" -name "*.html" | sort)
BODY_CONTENT+="</ul>"
echo "  Creating '$INDEX_FILE' using template..."
printf -- "$BODY_CONTENT" | pandoc \
  --standalone \
  --template="$TEMPLATE_FILE" \
  --metadata pagetitle="Blog Index" \
  --from html \
  --to html5 \
  -o "$INDEX_FILE"
if [ $? -ne 0 ]; then
  echo "Error generating index page '$INDEX_FILE'." >&2
  exit 1
fi

echo "Build finished"

