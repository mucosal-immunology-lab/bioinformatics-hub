#!/bin/bash

# generate_checksums.sh
# Recursively generates SHA256 checksums for all files in each directory.
# Stores checksums in a SHA256SUMS file within each respective directory.
# Removes existing SHA256SUMS files before generating new ones to ensure consistency.

set -euo pipefail

# Function to display usage information
usage() {
    echo "Usage: $0 [BASE_FOLDER] [GNU Parallel options]"
    echo "  BASE_FOLDER: The base directory to start checksum generation (default: current directory)."
    echo "  GNU Parallel options: Additional options for GNU Parallel (e.g., -j 8)."
    echo "Example:"
    echo "  $0 /path/to/base_folder -j 8"
    exit 1
}

# Check for help flag
if [[ "${1:-}" == "-h" || "${1:-}" == "--help" ]]; then
    usage
fi

# Parse arguments
BASE_FOLDER="${1:-.}"
shift || true  # Shift if BASE_FOLDER is provided
PARALLEL_OPTS="${@}"

# Check if GNU Parallel is installed
if ! command -v parallel &> /dev/null; then
    echo "Error: GNU Parallel is not installed. Please install it and retry."
    exit 1
fi

# Function to generate checksums in a single directory
generate_checksums_in_dir() {
    local dir="$1"
    local checksum_file="SHA256SUMS"  # Use relative path inside the directory

    # Navigate to the directory
    (
        cd "$dir" || { echo "Error: Cannot change to directory $dir"; exit 1; }

        # Remove existing SHA256SUMS file if it exists
        if [[ -f "$checksum_file" ]]; then
            rm -f "$checksum_file"
            echo "Existing SHA256SUMS removed in directory: $(pwd)"
        fi

        # Find all regular files excluding SHA256SUMS, handle spaces and special chars
        # Use -printf '%f\0' to get filenames without the leading './'
        find . -maxdepth 1 -type f ! -name 'SHA256SUMS' -printf '%f\0' | \
            parallel -0 $PARALLEL_OPTS sha256sum | sort > "$checksum_file"

        # Echo the absolute path of the newly created checksum file
        echo "Checksum file created: $(pwd)/$checksum_file"
    )
}

export -f generate_checksums_in_dir

# Find all directories and process them in parallel
find "$BASE_FOLDER" -type d -print0 | \
    parallel -0 $PARALLEL_OPTS generate_checksums_in_dir {}

echo "All SHA256 checksums have been generated successfully."

