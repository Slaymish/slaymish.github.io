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
SITE_URL="https://slaymish.github.io"
SITE_TITLE="My Learning Log"
AUTHOR_NAME="hamish"
AUTHOR_EMAIL="hamishapps@gmail.com"
FEED_FILE="atom.xml"

# --- OS Detection ---
OS_NAME=$(uname -s)
if [[ "$OS_NAME" == "Linux" ]]; then
  STAT_MOD_TIME_CMD="stat -c %Y"
  DATE_PARSE_CMD_PREFIX="date -u -d"
elif [[ "$OS_NAME" == "Darwin" ]]; then
  STAT_MOD_TIME_CMD="stat -f %m"
  DATE_PARSE_CMD_PREFIX="date -u -j -f"
else
  echo "Warning: Unsupported OS '$OS_NAME'. Using Linux defaults." >&2
  STAT_MOD_TIME_CMD="stat -c %Y"
  DATE_PARSE_CMD_PREFIX="date -u -d"
fi
DATE_FALLBACK_CMD_PREFIX="date -u -r"

set -e
echo "Starting blog build…"

# clean + recreate output dirs
rm -rf "$OUTPUT_DIR"
mkdir -p "$OUTPUT_DIR" "$OUTPUT_DIR/posts" "$OUTPUT_DIR/$JS_CONFIG_DIR"

# verify template
if [ ! -f "$TEMPLATE_FILE" ]; then
  echo "Error: template '$TEMPLATE_FILE' not found." >&2
  exit 1
fi

# bibliography flags
BIB_FLAGS=()
if [ -f "$BIB_FILE" ]; then
  echo "Using bibliography: $BIB_FILE"
  BIB_FLAGS+=(--bibliography="$BIB_FILE" --citeproc)
else
  echo "No bibliography; skipping citation processing."
fi

# 1) render each post
echo "Processing Markdown posts…"
while IFS= read -r md; do
  [[ -z "$md" ]] && continue
  slug=$(basename "$md" .md)
  out="$OUTPUT_DIR/posts/${slug}.html"
  echo "  $md → $out"
  pandoc "$md" \
    --standalone \
    --template="$TEMPLATE_FILE" \
    "${BIB_FLAGS[@]}" \
    --metadata title="$slug" \
    --metadata is_post=true \
    --from markdown+tex_math_dollars \
    --to html5 \
    -o "$out"
done < <(find "$POSTS_DIR" -maxdepth 1 -name "*.md")

# 2) copy static assets
cp -v "$CSS_FILE" "$OUTPUT_DIR/" 2>/dev/null || echo "Warning: no CSS to copy."
cp -v favicon.ico "$OUTPUT_DIR/" 2>/dev/null || true
cp -v "$POSTS_DIR"/*.{jpg,jpeg,png,gif} "$OUTPUT_DIR/posts/" 2>/dev/null || true
cp -v "$JS_CONFIG_DIR/$JS_CONFIG_FILE" "$OUTPUT_DIR/$JS_CONFIG_DIR/" 2>/dev/null || echo "Warning: no JS config to copy."

# 3) build index.html
INDEX="$OUTPUT_DIR/index.html"
echo "Building $INDEX"
BODY="<h1>Blog Posts</h1><ul class=\"post-list\">"
declare -A PD
while IFS= read -r html; do
  [[ -z "$html" ]] && continue
  name=$(basename "$html" .html)
  src="$POSTS_DIR/${name}.md"
  date=""
  mtime=0
  if [ -f "$src" ]; then
    date=$(grep -i '^date:' "$src" | sed -E 's/^date:[[:space:]]*["'\'']//;s/["'\'']$//' | head -1)
    mtime=$($STAT_MOD_TIME_CMD "$src")
  fi
  disp=""
  [ -n "$date" ] && disp="<span class=\"post-date\">($date)</span>"
  PD["$mtime-$name"]="<li><a href=\"posts/$name.html#disqus_thread\" data-disqus-identifier=\"$name\">$name</a> $disp</li>"
done < <(find "$OUTPUT_DIR/posts" -maxdepth 1 -name "*.html")

for key in $(printf "%s\n" "${!PD[@]}" | sort -nr); do
  BODY+="${PD[$key]}"
done
BODY+="</ul>"
# RSS subscribe button (unchanged)
BODY+="$(cat <<'EOF'
<div class="rss-subscribe">
  <a href="/atom.xml" title="Subscribe via RSS">
    <!-- your SVG + text -->
  </a>
</div>
EOF
)"

printf "%s" "$BODY" | pandoc \
  --standalone \
  --template="$TEMPLATE_FILE" \
  --from html \
  --to html5 \
  -o "$INDEX"


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


