#!/bin/bash

# This script builds the site using build.sh and then serves it
# using Python's built-in HTTP server.

# Define the output directory (should match the one in build.sh)
OUTPUT_DIR="_site"
# Define the port for the server
PORT=8000

# --- Build Step ---
echo ">>> Running build script..."
# Execute build.sh located in the same directory as this script
./build.sh

# Check the exit code of the build script
BUILD_EXIT_CODE=$?
if [ $BUILD_EXIT_CODE -ne 0 ]; then
  echo ">>> Build script failed with exit code $BUILD_EXIT_CODE. Aborting."
  exit $BUILD_EXIT_CODE
fi

echo ">>> Build successful."
echo "" # Add a blank line for readability

# --- Serve Step ---

# Check if the output directory exists before trying to cd into it
if [ ! -d "$OUTPUT_DIR" ]; then
    echo ">>> Error: Output directory '$OUTPUT_DIR' not found after build."
    exit 1
fi

echo ">>> Changing to output directory: $OUTPUT_DIR"
cd "$OUTPUT_DIR" || exit # Use || exit to stop if cd fails

echo ">>> Starting Python HTTP server on port $PORT..."
echo "    Access your site at: http://localhost:$PORT or http://127.0.0.1:$PORT"
echo "    Press Ctrl+C to stop the server."
echo ""

# Start Python's simple HTTP server in the current directory (_site)
# Use python3. If this fails, you might need 'python -m SimpleHTTPServer $PORT' for Python 2
python3 -m http.server $PORT

# The script will stay here until the server is stopped (e.g., with Ctrl+C)

echo ""
echo ">>> Server stopped."

exit 0

