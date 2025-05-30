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

# --- NEW Feed Configuration ---
SITE_URL="https://slaymish.github.io" # IMPORTANT: Change if you use a custom domain
SITE_TITLE="My Learning Log"          # Your Blog's Title
AUTHOR_NAME="hamish"                  # Your Name
AUTHOR_EMAIL="hamishapps@gmail.com"
FEED_FILE="atom.xml"                  # Output filename for the feed

# --- OS Detection ---
OS_NAME=$(uname -s)
STAT_MOD_TIME_CMD=""
DATE_PARSE_CMD_PREFIX=""
DATE_FALLBACK_CMD_PREFIX="date -u -r" # Works on both GNU and BSD date for timestamp input

echo "Detected OS: $OS_NAME"

if [[ "$OS_NAME" == "Linux" ]]; then
  STAT_MOD_TIME_CMD="stat -c %Y"
  # GNU date uses -d for parsing strings
  DATE_PARSE_CMD_PREFIX="date -u -d"
elif [[ "$OS_NAME" == "Darwin" ]]; then
  STAT_MOD_TIME_CMD="stat -f %m"
  # macOS/BSD date uses -j -f <format> for parsing strings
  DATE_PARSE_CMD_PREFIX="date -u -j -f"
else
  echo "Warning: Unsupported OS '$OS_NAME'. Using Linux defaults, but might fail." >&2
  STAT_MOD_TIME_CMD="stat -c %Y"
  DATE_PARSE_CMD_PREFIX="date -u -d"
fi

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

# Copy favicon
if [ -f "favicon.ico" ]; then
  cp favicon.ico "$OUTPUT_DIR/"
fi


# Copy post images
echo "Copying post images..."
cp "$POSTS_DIR"/*.{jpg,jpeg,png,gif} "$OUTPUT_DIR/posts/" 2>/dev/null || true


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

# Use associative array for sorting index page entries by mod time
declare -A post_data

while IFS= read -r html_file; do
  if [ -z "$html_file" ]; then continue; fi
  post_title=$(basename "$html_file" .html)
  md_source_file="$POSTS_DIR/${post_title}.md"
  post_date=""
  mod_time=0 # Default modification time

  if [ -f "$md_source_file" ]; then
    # Get date from metadata first
    post_date=$(grep -i '^date:' "$md_source_file" | sed -e 's/^date:[[:space:]]*//i' -e 's/^["]//' -e 's/["]$//' -e "s/^[']//" -e "s/[']$//" | head -n 1)
    # Get file modification time using OS-specific command
    mod_time=$($STAT_MOD_TIME_CMD "$md_source_file")
  fi

  date_display=""
  if [ -n "$post_date" ]; then
    date_display="<span class=\"post-date\">($post_date)</span>"
  fi
  post_link="posts/${post_title}.html"

  # Store data using modification time as key
  post_data["$mod_time-$post_title"]="  <li><a href=\"$post_link\">$post_title</a> $date_display</li>\n"

done < <(find "$OUTPUT_DIR/posts" -maxdepth 1 -name "*.html")

# Sort posts by modification time (descending) and add to BODY_CONTENT
for key in $(printf "%s\n" "${!post_data[@]}" | sort -nr); do
    BODY_CONTENT+="${post_data[$key]}"
done

BODY_CONTENT+="</ul>"

# --- Add RSS Subscribe Link ---
read -r -d '' RSS_LINK_HTML << EOM || true
<div class="rss-subscribe" style="margin-top: 2em; text-align: center;">
  <a href="/${FEED_FILE}" title="Subscribe to ${SITE_TITLE} via RSS/Atom Feed" style="display: inline-flex; align-items: center; text-decoration: none; color: #333; background-color: #f0f0f0; padding: 8px 15px; border-radius: 5px; border: 1px solid #ccc; font-size: 0.9em;">
    <svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 8 8" width="16" height="16" style="margin-right: 8px;">
      <title>RSS feed icon</title>
      <!-- Orange color for the icon -->
      <style>path, circle { fill: #f26522; }</style>
      <!-- Standard RSS icon paths -->
      <path d="M1.1 0C.5 0 0 .5 0 1.1v1.2C.1 4.1 1.3 5.8 3 7.1 4.2 8 5.9 8 7.3 7.3c.1-.1.2-.2.3-.3.6-.6.7-1.5.1-2.1-.6-.6-1.5-.5-2.1.1-.8.6-1.6.6-2.5 0C1.9 4.3 1.2 3 1.1 1.7V1.1z"/>
      <path d="M1.1 3.5c2.5 0 4.4 1.9 4.4 4.4v.1c0 .6-.5 1.1-1.1 1.1-.6 0-1.1-.5-1.1-1.1 0-1.4-.9-2.6-2.2-2.6-.6 0-1.1-.5-1.1-1.1V3.5z"/>
      <circle cx="1.7" cy="6.3" r="1.7"/>
    </svg>
    <span>Subscribe via RSS</span>
  </a>
</div>
EOM
BODY_CONTENT+="$RSS_LINK_HTML"
# --- End of RSS Subscribe Link ---

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

# --- Generate Atom Feed ---
echo "Generating Atom feed: $OUTPUT_DIR/$FEED_FILE"
FEED_OUTPUT_FILE="$OUTPUT_DIR/$FEED_FILE"
FEED_UPDATED_TIME=$(date -u +"%Y-%m-%dT%H:%M:%SZ")

# Start Atom feed structure
printf '<?xml version="1.0" encoding="utf-8"?>\n' > "$FEED_OUTPUT_FILE"
printf '<feed xmlns="http://www.w3.org/2005/Atom">\n' >> "$FEED_OUTPUT_FILE"
printf '  <title>%s</title>\n' "$SITE_TITLE" >> "$FEED_OUTPUT_FILE"
printf '  <link href="%s/%s" rel="self"/>\n' "$SITE_URL" "$FEED_FILE" >> "$FEED_OUTPUT_FILE"
printf '  <link href="%s/"/>\n' "$SITE_URL" >> "$FEED_OUTPUT_FILE"
printf '  <updated>%s</updated>\n' "$FEED_UPDATED_TIME" >> "$FEED_OUTPUT_FILE"
printf '  <id>%s/</id>\n' "$SITE_URL" >> "$FEED_OUTPUT_FILE"
printf '  <author>\n' >> "$FEED_OUTPUT_FILE"
printf '    <name>%s</name>\n' "$AUTHOR_NAME" >> "$FEED_OUTPUT_FILE"
if [ -n "$AUTHOR_EMAIL" ]; then
  printf '    <email>%s</email>\n' "$AUTHOR_EMAIL" >> "$FEED_OUTPUT_FILE"
fi
printf '  </author>\n' >> "$FEED_OUTPUT_FILE"

echo "  Adding entries..."

# --- OS-Specific Sorting for Feed Entries ---
TMP_SORT_FILE=$(mktemp)
if [[ "$OS_NAME" == "Linux" ]]; then
  # Use GNU find's -printf for efficiency
  find "$POSTS_DIR" -maxdepth 1 -name "*.md" -printf "%T@ %p\n" | sort -nr > "$TMP_SORT_FILE"
elif [[ "$OS_NAME" == "Darwin" ]]; then
  # Use stat loop for macOS/BSD
  find "$POSTS_DIR" -maxdepth 1 -name "*.md" | while IFS= read -r md_file; do
    mod_time=$($STAT_MOD_TIME_CMD "$md_file")
    printf "%s %s\n" "$mod_time" "$md_file" >> "$TMP_SORT_FILE"
  done
  sort -nr "$TMP_SORT_FILE" -o "$TMP_SORT_FILE" # Sort the temp file in place
else
  # Fallback: simple alphabetical sort if OS unknown (less ideal)
  find "$POSTS_DIR" -maxdepth 1 -name "*.md" | sort > "$TMP_SORT_FILE"
fi
# --- End OS-Specific Sorting ---

# Process sorted list from temporary file
cut -d' ' -f2- "$TMP_SORT_FILE" | while IFS= read -r md_source_file; do
  if [ -z "$md_source_file" ]; then continue; fi

  post_basename=$(basename "$md_source_file" .md)
  post_title="$post_basename" # Use basename as title, adjust if needed
  post_url="$SITE_URL/posts/${post_basename}.html"
  post_id="$post_url" # Use URL as unique ID for the entry

  # Attempt to get the date from the source MD file again
  post_date_raw=""
  post_date_rfc3339=""
  if [ -f "$md_source_file" ]; then
    post_date_raw=$(grep -i '^date:' "$md_source_file" | sed -e 's/^date:[[:space:]]*//i' -e 's/^["]//' -e 's/["]$//' -e "s/^[']//" -e "s/[']$//" | head -n 1)
    if [ -n "$post_date_raw" ]; then
      # Attempt to convert to RFC 3339 format using OS-specific date command
      if [[ "$OS_NAME" == "Linux" ]]; then
        post_date_rfc3339=$($DATE_PARSE_CMD_PREFIX "$post_date_raw" +"%Y-%m-%dT00:00:00Z" 2>/dev/null)
      elif [[ "$OS_NAME" == "Darwin" ]]; then
        # Try multiple common formats for macOS/BSD date
        post_date_rfc3339=$($DATE_PARSE_CMD_PREFIX "%Y-%m-%d" "$post_date_raw" +"%Y-%m-%dT00:00:00Z" 2>/dev/null) || \
        post_date_rfc3339=$($DATE_PARSE_CMD_PREFIX "%Y/%m/%d" "$post_date_raw" +"%Y-%m-%dT00:00:00Z" 2>/dev/null) || \
        post_date_rfc3339=$($DATE_PARSE_CMD_PREFIX "%d %b %Y" "$post_date_raw" +"%Y-%m-%dT00:00:00Z" 2>/dev/null)
      else
         # Fallback attempt if OS unknown
         post_date_rfc3339=$($DATE_PARSE_CMD_PREFIX "$post_date_raw" +"%Y-%m-%dT00:00:00Z" 2>/dev/null)
      fi

      # If parsing failed OR date was empty, use file modification time
      if [ -z "$post_date_rfc3339" ]; then
         mod_time_secs=$($STAT_MOD_TIME_CMD "$md_source_file")
         post_date_rfc3339=$($DATE_FALLBACK_CMD_PREFIX "$mod_time_secs" +"%Y-%m-%dT%H:%M:%SZ")
      fi
    else
       # If no date metadata, use file modification time
       mod_time_secs=$($STAT_MOD_TIME_CMD "$md_source_file")
       post_date_rfc3339=$($DATE_FALLBACK_CMD_PREFIX "$mod_time_secs" +"%Y-%m-%dT%H:%M:%SZ")
    fi
  else
    # Fallback if md file somehow missing (shouldn't happen with find)
    post_date_rfc3339=$(date -u +"%Y-%m-%dT%H:%M:%SZ")
  fi

  echo "    Adding entry for $post_title (Date: $post_date_rfc3339)"

  # --- Generate HTML content fragment for the feed ---
  post_html_content=""
  # Run pandoc again, but without standalone/template to get just the body HTML
  # Capture output into variable; handle potential errors
  if post_html_content=$(pandoc "$md_source_file" \
                            "${BIB_FLAGS[@]}" \
                            --from markdown+tex_math_dollars \
                            --to html5); then
    : # Command succeeded, content is in variable
  else
    echo "      Warning: Failed to generate HTML content for feed entry '$post_title'. Skipping content." >&2
    post_html_content="[Content generation failed]" # Add placeholder or leave empty
  fi
  # --- End of HTML content generation ---


  # Add entry to feed
  printf '  <entry>\n' >> "$FEED_OUTPUT_FILE"
  printf '    <title>%s</title>\n' "$post_title" >> "$FEED_OUTPUT_FILE"
  printf '    <link href="%s"/>\n' "$post_url" >> "$FEED_OUTPUT_FILE"
  printf '    <id>%s</id>\n' "$post_id" >> "$FEED_OUTPUT_FILE"
  printf '    <updated>%s</updated>\n' "$post_date_rfc3339" >> "$FEED_OUTPUT_FILE"

  # Add summary (optional, could be complex to extract, using title for now)
  summary_text="New post: $post_title" # Basic summary
  printf '    <summary>%s</summary>\n' "$summary_text" >> "$FEED_OUTPUT_FILE"

  # --- Add full HTML content ---
  # Use CDATA section to embed HTML without needing to escape <, >, &
  printf '    <content type="html"><![CDATA[\n' >> "$FEED_OUTPUT_FILE"
  printf '%s\n' "$post_html_content" >> "$FEED_OUTPUT_FILE"
  printf '    ]]></content>\n' >> "$FEED_OUTPUT_FILE"
  # --- End of full HTML content ---

  printf '  </entry>\n' >> "$FEED_OUTPUT_FILE"

done

# Clean up temporary file
rm "$TMP_SORT_FILE"

# Close the feed tag
printf '</feed>\n' >> "$FEED_OUTPUT_FILE"
echo "  Atom feed generated successfully."
# --- End of Feed Generation ---

echo "Build finished"


