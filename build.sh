#!/bin/bash

# --- Configuration ---
POSTS_DIR="posts"
OUTPUT_DIR="_site"
BIB_FILE="references.bib"
TEMPLATE_FILE="templates/basic_template.html"
# Optional: CSS file to copy
CSS_FILE="style.css"

# --- Script Logic ---
# Exit immediately if a command exits with a non-zero status.
set -e

echo "Starting blog build..."

# Clean up previous build (optional but recommended)
echo "Cleaning output directory: $OUTPUT_DIR"
rm -rf "$OUTPUT_DIR"

# Create output directories
echo "Creating output structure..."
mkdir -p "$OUTPUT_DIR/posts" # Create posts subdirectory within output

# Check if template exists
if [ ! -f "$TEMPLATE_FILE" ]; then
  echo "Error: Template file '$TEMPLATE_FILE' not found." >&2
  exit 1
fi

# Check if bibliography exists (only add flags if it does)
BIB_FLAGS=() # Use an array for flags
if [ -f "$BIB_FILE" ]; then
  echo "Using bibliography: $BIB_FILE"
  # Add bib flags to the array
  BIB_FLAGS+=(--bibliography="$BIB_FILE" --citeproc)
else
  echo "No bibliography file found at '$BIB_FILE', skipping citation processing."
fi

# Find all Markdown files in the posts directory and process them
echo "Processing Markdown posts..."
# --- Use Process Substitution for the loop ---
while IFS= read -r md_file; do
  if [ -z "$md_file" ]; then continue; fi # Skip empty lines if find returns any

  # Get the base filename without the .md extension
  base_name=$(basename "$md_file" .md)

  # Define the output HTML filename
  html_file="$OUTPUT_DIR/posts/${base_name}.html"

  echo "  Converting '$md_file' -> '$html_file'"

  # Run Pandoc, expanding the BIB_FLAGS array safely
  # --- NO --mathjax flag here ---
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
    # Exit if one file fails
    exit 1
  fi
done < <(find "$POSTS_DIR" -maxdepth 1 -name "*.md")

# Optional: Copy static files like CSS
if [ -f "$CSS_FILE" ]; then
  echo "Copying $CSS_FILE to $OUTPUT_DIR/"
  cp "$CSS_FILE" "$OUTPUT_DIR/"
else
  echo "Warning: CSS file '$CSS_FILE' not found, skipping copy."
fi

# --- Generate a simple index page (Revised to include Date) ---
INDEX_FILE="$OUTPUT_DIR/index.html"
echo "Generating index page: $INDEX_FILE"

# Start building the HTML content for the body
BODY_CONTENT="<h1>Blog Posts</h1>\n<ul class=\"post-list\">\n" # Added class to UL

# Use process substitution to read file list without a subshell for the loop
while IFS= read -r html_file; do
  if [ -z "$html_file" ]; then # Skip empty lines if any
      continue
  fi
  post_title=$(basename "$html_file" .html)

  # Construct the path to the original Markdown file
  md_source_file="$POSTS_DIR/${post_title}.md"
  post_date="" # Initialize date variable

  # Check if the source MD file exists
  if [ -f "$md_source_file" ]; then
    # Extract the date from YAML front matter (handles quotes)
    # Looks for lines starting with 'date:', trims whitespace, removes quotes
    post_date=$(grep '^date:' "$md_source_file" | sed -e 's/^date:[[:space:]]*//' -e 's/^["]//' -e 's/["]$//' -e 's/^['\'']//' -e 's/['\'']$//' | head -n 1)
  fi

  # Format the date string (add parentheses or similar)
  date_display=""
  if [ -n "$post_date" ]; then
    # Add some formatting, e.g., wrap in a span with a class for styling
    date_display="<span class=\"post-date\">($post_date)</span>"
  fi

  # Make link relative to the index file
  post_link="posts/${post_title}.html"

  # Append list item HTML including the date
  BODY_CONTENT+="  <li><a href=\"$post_link\">$post_title</a> $date_display</li>\n" # Added $date_display
done < <(find "$OUTPUT_DIR/posts" -name "*.html" | sort) # <<< Process substitution

# Close the unordered list
BODY_CONTENT+="</ul>"

# Now, run Pandoc ONCE to insert the generated HTML list into the template
echo "  Creating '$INDEX_FILE' using template..."
# Use printf to handle the multi-line string potentially containing special chars
printf -- "$BODY_CONTENT" | pandoc \
  --standalone \
  --template="$TEMPLATE_FILE" \
  --metadata pagetitle="Blog Index" \
  --from html \
  --to html5 \
  -o "$INDEX_FILE" # Read from stdin (piped from printf)

if [ $? -ne 0 ]; then
  echo "Error generating index page '$INDEX_FILE'." >&2
  exit 1
fi
# --- End of Revised Index Generation ---

echo "Build finished"

