#!/bin/bash

# --- Configuration ---
POSTS_DIR="posts"
OUTPUT_DIR="_site"
BIB_FILE="references.bib"
TEMPLATE_FILE="templates/basic_template.html"
CSS_FILE="style.css"

# --- Add JS Config File ---
JS_CONFIG_DIR="js"

# --- NEW Feed Configuration ---
SITE_URL="https://slaymish.github.io"
SITE_TITLE="My Learning Log"
AUTHOR_NAME="hamish"
AUTHOR_EMAIL="hamishapps@gmail.com"
FEED_FILE="atom.xml"

# --- OS Detection & Command Setup ---
OS_NAME="" # Will be set by determine_os_commands
STAT_MOD_TIME_CMD=""
DATE_PARSE_CMD_PREFIX=""
DATE_FALLBACK_CMD_PREFIX="date -u -r" # Common fallback

determine_os_commands() {
  OS_NAME=$(uname -s) # Set global OS_NAME
  echo "Determining OS-specific commands for $OS_NAME..."
  if [[ "$OS_NAME" == "Linux" ]]; then
    STAT_MOD_TIME_CMD="stat -c %Y"
    DATE_PARSE_CMD_PREFIX="date -u -d" # GNU date
  elif [[ "$OS_NAME" == "Darwin" ]]; then
    STAT_MOD_TIME_CMD="stat -f %m"
    DATE_PARSE_CMD_PREFIX="date -u -j -f" # macOS/BSD date
  else
    echo "Warning: Unsupported OS '$OS_NAME'. Using Linux defaults for stat and date commands." >&2
    # Default to GNU/Linux like commands
    STAT_MOD_TIME_CMD="stat -c %Y"
    DATE_PARSE_CMD_PREFIX="date -u -d"
  fi
  # Export for subshells if necessary, though direct use in functions is fine for now
  export OS_NAME STAT_MOD_TIME_CMD DATE_PARSE_CMD_PREFIX DATE_FALLBACK_CMD_PREFIX
}

setup_directories_and_template() {
  echo "Setting up output directories..."
  rm -rf "$OUTPUT_DIR"
  mkdir -p "$OUTPUT_DIR" "$OUTPUT_DIR/posts" "$OUTPUT_DIR/$JS_CONFIG_DIR"

  echo "Verifying template file..."
  if [ ! -f "$TEMPLATE_FILE" ]; then
    echo "Error: template '$TEMPLATE_FILE' not found." >&2
    exit 1
  fi
  echo "Template file verified."
}

# --- Helper function for bibliography ---
initialize_bibliography_flags() {
  BIB_FLAGS=() # Ensure it's an array
  if [ -f "$BIB_FILE" ]; then
    echo "Using bibliography: $BIB_FILE"
    BIB_FLAGS+=(--bibliography="$BIB_FILE" --citeproc)
  else
    echo "No bibliography file found at '$BIB_FILE'; skipping citation processing."
  fi
}

# --- Function to render markdown posts ---
process_markdown_posts() {
  echo "Processing Markdown posts from '$POSTS_DIR'..."
  local md_file slug output_html_path
  while IFS= read -r md_file; do
    [[ -z "$md_file" ]] && continue # Skip empty lines if any
    slug=$(basename "$md_file" .md)
    output_html_path="$OUTPUT_DIR/posts/${slug}.html"
    echo "  Rendering: $md_file → $output_html_path"
    pandoc "$md_file" \
      --standalone \
      --template="$TEMPLATE_FILE" \
      "${BIB_FLAGS[@]}" \
      --metadata title="$slug" \
      --metadata is_post=true \
      --from markdown+tex_math_dollars \
      --to html5 \
      -o "$output_html_path"
  done < <(find "$POSTS_DIR" -maxdepth 1 -name "*.md" -type f) # Ensure only files are processed
  echo "Markdown processing complete."
}

# --- Function to copy static assets ---
copy_static_assets() {
  echo "Copying static assets..."
  # Copy CSS
  if [ -f "$CSS_FILE" ]; then
    cp -v "$CSS_FILE" "$OUTPUT_DIR/"
  else
    echo "Warning: CSS file '$CSS_FILE' not found. Skipping."
  fi

  # Copy favicon
  if [ -f "favicon.ico" ]; then
    cp -v "favicon.ico" "$OUTPUT_DIR/"
  else
    echo "Warning: favicon.ico not found. Skipping."
  fi

  # Copy post images (if any)
  # Check if pattern matches any files to avoid error if no images exist
  shopt -s nullglob
  local images=("$POSTS_DIR"/*.{jpg,jpeg,png,gif})
  if [ ${#images[@]} -gt 0 ]; then
    echo "Copying images from $POSTS_DIR to $OUTPUT_DIR/posts/"
    cp -v "${images[@]}" "$OUTPUT_DIR/posts/"
  else
    echo "No images found in $POSTS_DIR to copy."
  fi
  shopt -u nullglob # Reset nullglob

  # Copy JS files from JS_CONFIG_DIR
  if [ -d "$JS_CONFIG_DIR" ]; then
    echo "Copying JavaScript files from $JS_CONFIG_DIR to $OUTPUT_DIR/$JS_CONFIG_DIR/"
    # Ensure the target directory exists
    mkdir -p "$OUTPUT_DIR/$JS_CONFIG_DIR"
    # Copy all .js files
    local js_file
    for js_file in "$JS_CONFIG_DIR"/*.js; do
      if [ -f "$js_file" ]; then
        cp -v "$js_file" "$OUTPUT_DIR/$JS_CONFIG_DIR/"
      fi
    done
  else
    echo "Warning: JavaScript directory '$JS_CONFIG_DIR' not found. Skipping JS files."
  fi
  echo "Static assets copying complete."
}

# --- Function to build the index HTML page ---
build_index_page() {
  local index_html_path="$OUTPUT_DIR/index.html"
  local body_content="<section class=\"hero text-center\"><h1 class=\"text-4xl font-bold mb-3\">Welcome to $SITE_TITLE</h1><p class=\"text-lg mb-4\">Documenting my learning journey one post at a time.</p><a href=\"#posts\" class=\"inline-block bg-purple-700 text-white px-5 py-2 rounded hover:bg-purple-800\">Read Latest Posts</a></section><h2 id=\"posts\" class=\"text-2xl font-semibold mt-10\">Recent Posts</h2><ul class=\"post-list\">"
  declare -A post_metadata_map # Renamed from PD for clarity

  # Temporary array to hold sortable keys
  local sortable_keys=()

  # Loop through generated HTML files to gather metadata
  local html_file post_name source_md_path post_date post_mtime
  for html_file in "$OUTPUT_DIR/posts"/*.html; do
    [[ -e "$html_file" ]] || continue # Skip if no html files found
    post_name=$(basename "$html_file" .html)
    source_md_path="$POSTS_DIR/${post_name}.md"
    post_date=""
    post_mtime=0

    if [ -f "$source_md_path" ]; then
      # Extract date from frontmatter (case-insensitive)
      post_date=$(grep -i '^date:' "$source_md_path" | sed -E 's/^date:[[:space:]]*["'\'']?//i;s/["'\'']?$//' | head -1)
      post_mtime=$($STAT_MOD_TIME_CMD "$source_md_path")
    else
      echo "Warning: Source markdown file '$source_md_path' not found for html file '$html_file'."
      # Use html file mtime as a fallback, though less ideal
      post_mtime=$($STAT_MOD_TIME_CMD "$html_file")
    fi

    # Use date for sorting if available, otherwise mtime.
    # Prepending a sort key prefix to ensure dates are sorted before mtime-only entries if mixed.
    local sort_key
    if [ -n "$post_date" ]; then
      # Use date for sorting and include mtime and post name to ensure uniqueness
      # Combining these prevents duplicate keys when multiple posts share the same
      # date and file modification time (e.g., when checked into git together).
      sort_key="date_${post_date}_${post_mtime}_${post_name}"
    else
      # When no date is provided, fall back to modification time plus the post
      # name so each entry has a unique sort key.
      sort_key="mtime_${post_mtime}_${post_name}"
    fi

    local display_date_span=""
    [ -n "$post_date" ] && display_date_span="<span class=\"post-date\">($post_date)</span>"

    post_metadata_map["$sort_key"]="<li><a href=\"posts/$post_name.html#disqus_thread\" data-disqus-identifier=\"$post_name\">$post_name</a> $display_date_span</li>"
    sortable_keys+=("$sort_key")
  done

  # Sort keys: numerically if mtime, lexicographically if date.
  # Using process substitution with sort.
  # Sorting in reverse order (newest first).
  local sorted_keys
  mapfile -t sorted_keys < <(printf '%s\n' "${sortable_keys[@]}" | sort -r)

  for key in "${sorted_keys[@]}"; do
    body_content+="${post_metadata_map[$key]}"
  done
  body_content+="</ul>"


  # Use printf for the body content to avoid issues with special characters
  printf "%s" "$body_content" | pandoc \
    --standalone \
    --template="$TEMPLATE_FILE" \
    --metadata title="$SITE_TITLE" \
    --metadata is_index=true \
    --from html \
    --to html5 \
    -o "$index_html_path"
  echo "Index page built successfully."
}

# --- Helper function to extract metadata from a markdown file ---
# Arguments: $1 = file_path, $2 = field_name (e.g., "title", "date")
get_metadata_value() {
  local file_path="$1"
  local field_name_lower
  field_name_lower=$(echo "$2" | tr '[:upper:]' '[:lower:]') # Ensure lowercase for case-insensitive grep
  local value
  # Regex:
  # - (?i): case-insensitive match for field_name
  # - ^${field_name_lower}: field name at the beginning of the line
  # - :[[:space:]]*: colon followed by optional whitespace
  # - ["']?: optional quote (single or double)
  # - (.*?)["']?$: capture content (non-greedy) until optional closing quote at end of line
  # Using perl for non-greedy match and better handling of quotes.
  # Fallback to grep/sed if perl is not available or fails.
  if command -v perl >/dev/null; then
    value=$(perl -ne "print \$1 if /^(?i)${field_name_lower}:[[:space:]]*[\"']?(.*?)[\"']?\$/" "$file_path" | head -n 1)
  else
    # Fallback to grep/sed. grep -i handles case-insensitivity for matching the line.
    # sed then removes the prefix (everything up to the first colon and subsequent whitespace/quote) and trailing quote.
    # This is more portable than using 'i' flag in sed for substitution.
    line_content=$(grep -i "^${field_name_lower}:" "$file_path" | head -n 1)
    if [ -n "$line_content" ]; then
      # Strip leading part (e.g., "date: ", "Title: ") and then strip optional quotes around the value.
      # The (.*) captures the value between the optional quotes.
      value=$(echo "$line_content" | sed -E 's/^[^:]+:[[:space:]]*["'\'']?(.*)["'\'']?$/\1/')
    else
      value=""
    fi
  fi
  echo "$value"
}


# --- Function to generate Atom feed ---
generate_atom_feed() {
  echo "Generating Atom feed: $OUTPUT_DIR/$FEED_FILE..."
  local feed_output_file="$OUTPUT_DIR/$FEED_FILE"
  local feed_updated_time
  feed_updated_time=$(date -u +"%Y-%m-%dT%H:%M:%SZ") # Overall feed update time

  # Start Atom feed structure
  {
    printf '<?xml version="1.0" encoding="utf-8"?>\n'
    printf '<feed xmlns="http://www.w3.org/2005/Atom">\n'
    printf '  <title>%s</title>\n' "$SITE_TITLE"
    printf '  <link href="%s/%s" rel="self"/>\n' "$SITE_URL" "$FEED_FILE"
    printf '  <link href="%s/"/>\n' "$SITE_URL"
    printf '  <updated>%s</updated>\n' "$feed_updated_time"
    printf '  <id>%s/</id>\n' "$SITE_URL"
    printf '  <author>\n'
    printf '    <name>%s</name>\n' "$AUTHOR_NAME"
    if [ -n "$AUTHOR_EMAIL" ]; then
      printf '    <email>%s</email>\n' "$AUTHOR_EMAIL"
    fi
    printf '  </author>\n'
  } > "$feed_output_file" # Overwrite or create the file

  echo "  Adding feed entries..."

  # --- OS-Specific Sorting for Feed Entries ---
  # Create a temporary file to store md file paths sorted by modification date
  local temp_sorted_md_files
  temp_sorted_md_files=$(mktemp)
  # Ensure cleanup of temp file on script exit or interrupt
  trap 'rm -f "$temp_sorted_md_files"' EXIT SIGINT SIGTERM


  # Populate temp file with "mtime filepath"
  local md_file mod_time
  # Using find -type f to ensure we only process files
  find "$POSTS_DIR" -maxdepth 1 -name "*.md" -type f | while IFS= read -r md_file; do
    mod_time=$($STAT_MOD_TIME_CMD "$md_file")
    printf "%s %s\n" "$mod_time" "$md_file" >> "$temp_sorted_md_files"
  done

  # Sort the temporary file numerically in reverse order (newest first)
  # and then extract just the filepath
  # Using process substitution to feed `sort` output to `while read` loop
  # This avoids issues with subshells if we piped directly to `while`
  local sorted_file_list
  sorted_file_list=$(sort -k1,1nr -k2 "$temp_sorted_md_files" | cut -d' ' -f2-)

  # Read the sorted list of markdown files
  echo "$sorted_file_list" | while IFS= read -r md_source_file; do
    [[ -z "$md_source_file" ]] && continue # Skip empty lines

    local post_basename post_title post_url post_id
    post_basename=$(basename "$md_source_file" .md)

    # Extract title using helper function
    post_title=$(get_metadata_value "$md_source_file" "title")
    if [ -z "$post_title" ]; then
        echo "    Info: No title found in frontmatter for '$md_source_file'. Using filename as title." >&2
        post_title="$post_basename"
    fi

    post_url="$SITE_URL/posts/${post_basename}.html"
    post_id="$post_url" # Unique ID for the entry, typically the URL

    # Date handling for feed entries
    local post_date_raw post_date_rfc3339
    post_date_raw=$(get_metadata_value "$md_source_file" "date")

    if [ -n "$post_date_raw" ]; then
      # Attempt to parse the extracted date string
      if [[ "$OS_NAME" == "Linux" ]] || [[ "$OS_NAME" != "Darwin" ]]; then # Linux or other (defaulting to GNU date syntax)
        # For Linux, DATE_PARSE_CMD_PREFIX is "date -u -d"
        # Input date format for -d is quite flexible on GNU date
        post_date_rfc3339=$($DATE_PARSE_CMD_PREFIX "$post_date_raw" +"%Y-%m-%dT00:00:00Z" 2>/dev/null)
      elif [[ "$OS_NAME" == "Darwin" ]]; then
        # For Darwin, DATE_PARSE_CMD_PREFIX is "date -u -j -f"
        # Try a sequence of common formats for macOS/BSD date's -f flag
        # The first one that successfully parses will set post_date_rfc3339
        post_date_rfc3339=$($DATE_PARSE_CMD_PREFIX "%Y-%m-%d" "$post_date_raw" +"%Y-%m-%dT00:00:00Z" 2>/dev/null) || \
        post_date_rfc3339=$($DATE_PARSE_CMD_PREFIX "%Y/%m/%d" "$post_date_raw" +"%Y-%m-%dT00:00:00Z" 2>/dev/null) || \
        post_date_rfc3339=$($DATE_PARSE_CMD_PREFIX "%d %b %Y" "$post_date_raw" +"%Y-%m-%dT00:00:00Z" 2>/dev/null) || \
        post_date_rfc3339=$($DATE_PARSE_CMD_PREFIX "%B %d, %Y" "$post_date_raw" +"%Y-%m-%dT00:00:00Z" 2>/dev/null) || \
        post_date_rfc3339=$($DATE_PARSE_CMD_PREFIX "%a, %d %b %Y %H:%M:%S %z" "$post_date_raw" +"%Y-%m-%dT00:00:00Z" 2>/dev/null) # RFC 822/2822 like
        # Add more formats here if needed
      fi
    fi

      # If date parsing failed (empty post_date_rfc3339) or no raw date extracted, use file modification time
    if [ -z "$post_date_rfc3339" ]; then
      if [ -n "$post_date_raw" ]; then # Only log if we attempted to parse a date
        echo "    Info: Could not parse date string '$post_date_raw' for '$md_source_file'. Using file modification time." >&2
      else
        echo "    Info: No date found in frontmatter for '$md_source_file'. Using file modification time." >&2
      fi
      local mod_time_secs
      mod_time_secs=$($STAT_MOD_TIME_CMD "$md_source_file")
      post_date_rfc3339=$($DATE_FALLBACK_CMD_PREFIX "$mod_time_secs" +"%Y-%m-%dT%H:%M:%SZ")
    fi

    echo "    Adding entry for '$post_title' (Timestamp: $post_date_rfc3339)"

    # Generate HTML content for the feed entry (actual post content)
    local post_html_content
    # Pandoc converts markdown to HTML body content
    if ! post_html_content=$(pandoc "$md_source_file" \
                              "${BIB_FLAGS[@]}" \
                              --from markdown+tex_math_dollars \
                              --to html5); then
      echo "      Warning: Failed to generate HTML content for feed entry '$post_title'. Using placeholder." >&2
      post_html_content="<p>Error generating content for this post. Please visit the website to read.</p>"
    fi

    # Append entry to feed
    {
      printf '  <entry>\n'
      printf '    <title>%s</title>\n' "$post_title"
      printf '    <link href="%s"/>\n' "$post_url"
      printf '    <id>%s</id>\n' "$post_id"
      printf '    <updated>%s</updated>\n' "$post_date_rfc3339"
      # Basic summary, could be improved by extracting from markdown
      printf '    <summary>Post: %s</summary>\n' "$post_title"
      printf '    <content type="html"><![CDATA[\n'
      # Ensure post_html_content is properly placed within CDATA
      printf '%s\n' "$post_html_content"
      printf '    ]]></content>\n'
      printf '  </entry>\n'
    } >> "$feed_output_file"
  done

  printf '</feed>\n' >> "$feed_output_file"
  # No need to explicitly rm $temp_sorted_md_files due to trap
  echo "Atom feed generated successfully at $feed_output_file"
}


# --- Main script execution ---
main() {
  set -e # Exit immediately if a command exits with a non-zero status.
  echo "Starting blog build process..."

  determine_os_commands
  setup_directories_and_template
  initialize_bibliography_flags # Initialize BIB_FLAGS global array
  process_markdown_posts
  copy_static_assets
  build_index_page
  generate_atom_feed

  echo "Build finished successfully."
}


# Execute main function
main


