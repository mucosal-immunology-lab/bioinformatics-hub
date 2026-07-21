#!/bin/bash

# verify_checksums.sh
# Recursively verifies SHA256 checksums for all files in each directory.
# For each directory containing a SHA256SUMS file:
#   - Recomputes SHA256 checksums for all files except SHA256SUMS.
#   - Compares the newly generated checksums with the existing SHA256SUMS.
#   - Reports whether the verification passed or failed.

set -euo pipefail

# Function to display usage information
usage() {
    echo "Usage: $0 [BASE_FOLDER] [GNU Parallel options]"
    echo "  BASE_FOLDER: The base directory to start verification (default: current directory)."
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

# Function to verify checksums in a single directory
verify_checksums_in_dir() {
    local checksum_file="$1"

    # Extract directory path
    local dir
    dir=$(dirname "$checksum_file")

    # Navigate to the directory
    (
        cd "$dir" || { echo "Error: Cannot change to directory $dir"; exit 1; }

        # Ensure SHA256SUMS exists
        if [[ ! -f "SHA256SUMS" ]]; then
            echo "Error: SHA256SUMS file not found in $dir"
            exit 1
        fi

        # Create a unique temporary file for new checksums
        temp_checksum=$(mktemp)

        # Ensure the temporary file is deleted on exit, regardless of success or failure
        trap 'rm -f "$temp_checksum"' EXIT

        # Find all regular files excluding SHA256SUMS, handle spaces and special chars
        # Use -printf '%f\0' to get filenames without the leading './'
        find . -maxdepth 1 -type f ! -name 'SHA256SUMS' -printf '%f\0' | \
            parallel -0 $PARALLEL_OPTS sha256sum | sort > "$temp_checksum"

        # Sort the existing SHA256SUMS for accurate comparison
        sort "SHA256SUMS" > "SHA256SUMS.sorted"

        # Compare the newly generated checksums with the existing ones
        if diff -q "SHA256SUMS.sorted" "$temp_checksum" > /dev/null; then
            echo "Verification PASSED in directory: $dir"
        else
            echo "Verification FAILED in directory: $dir"
            echo "Differences found between existing SHA256SUMS and current files."
            diff "SHA256SUMS.sorted" "$temp_checksum"
            exit 1
        fi

        # Clean up the sorted existing SHA256SUMS
        rm "SHA256SUMS.sorted"
    )
}

export -f verify_checksums_in_dir

# Find all SHA256SUMS files and verify them in parallel
find "$BASE_FOLDER" -type f -name "SHA256SUMS" -print0 | \
    parallel -0 $PARALLEL_OPTS verify_checksums_in_dir {}

echo "All SHA256 checksums have been verified successfully."

