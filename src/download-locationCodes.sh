#!/bin/bash

# ============================================================================
# Location Reference Download Script (Robust Version)
# ============================================================================

# Logging
exec > >(tee -a "$(dirname "$0")/../logs/script/download_locationCodes.log") 2>&1

# Go to project root
cd "$(dirname "$0")/.." || exit 1

# Load API key
source "$(dirname "$0")/.env"

BASE_URL="https://oceans-x.mpa.gov.sg/api/v1/mdhvessel/reference/locations/1.0.0/filetype/json"
OUTPUT_DIR="raw_data/locations"
OUTPUT_FILE="$OUTPUT_DIR/location_codes.json"

mkdir -p "$OUTPUT_DIR"

echo "======================================================================"
echo "Downloading Location Reference Data"
echo "======================================================================"
echo "Started at: $(date '+%Y-%m-%d %H:%M:%S')"
echo "Working directory: $(pwd)"
echo ""

echo "Downloading..."

curl --fail --silent --show-error --location --compressed \
  -H "accept: application/json" \
  -H "ApiKey: ${OCEANS_X_API_KEY}" \
  -H "User-Agent: Mozilla/5.0" \
  "$BASE_URL" \
  -o "$OUTPUT_FILE"

status=$?

if [ $status -ne 0 ]; then
    echo "✗ Download failed (curl exit code $status)"
    exit 1
fi

echo "✓ Download completed"
echo "Saved to: $(realpath "$OUTPUT_FILE")"
echo ""

# ============================================================================
# FILE DIAGNOSTICS
# ============================================================================

echo "File info:"
ls -lh "$OUTPUT_FILE"
file "$OUTPUT_FILE"
echo ""

echo "First 5 lines of file:"
head -n 5 "$OUTPUT_FILE"
echo ""

# ============================================================================
# If still gzipped, decompress manually
# ============================================================================

if file "$OUTPUT_FILE" | grep -q "gzip compressed"; then
    echo "Detected gzip file — decompressing..."
    gunzip -f "$OUTPUT_FILE"
    OUTPUT_FILE="${OUTPUT_FILE%.gz}"
fi

# ============================================================================
# JSON VALIDATION
# ============================================================================

echo "Validating JSON..."

if jq empty "$OUTPUT_FILE" 2>/dev/null; then
    echo "✓ JSON is valid"
    echo "Sample record:"
    jq '.[0]' "$OUTPUT_FILE"
else
    echo "✗ File is not valid JSON"
    echo "It may be an HTML error page or binary data."
fi

echo ""
echo "Finished at: $(date '+%Y-%m-%d %H:%M:%S')"
echo "======================================================================"
