#!/bin/bash

# logging
exec > >(tee -a "$(dirname "$0")/../logs/script/download_vesselPos.log") 2>&1

# navigate to project root
cd "$(dirname "$0")/.." || exit 1

# Load API key
source "$(dirname "$0")/.env"

BASE_URL="https://oceans-x.mpa.gov.sg/api/v1/vessel/positions/1.0.0"
#START_DATE="$1"
#END_DATE="$2"
START_DATE="$(date -d "$GET_DATE -1 year" +%Y-%m-%d)"
END_DATE="$(date +%Y-%m-%d)"

# Create output directory
mkdir -p raw_data/positions

TIMESTAMP=$(date +%Y%m%d_%H%M%S)
OUTPUT_FILE="raw_data/positions/snapshot_${TIMESTAMP}.json"

echo "======================================================================"
echo "Vessel Positions Snapshot Download"
echo "======================================================================"
echo "Timestamp: $TIMESTAMP"
echo ""

curl -s -X GET \
    "${BASE_URL}/snapshot" \
    -H "accept: application/json" \
    -H "ApiKey: ${OCEANS_X_API_KEY}" \
    -o "$OUTPUT_FILE"

if [ $? -eq 0 ] && [ -f "$OUTPUT_FILE" ]; then
    echo "✓ Download successful"
    echo ""
    
    vessel_count=$(jq 'length' "$OUTPUT_FILE")
    file_size=$(ls -lh "$OUTPUT_FILE" | awk '{print $5}')
    
    echo "File: $OUTPUT_FILE"
    echo "Vessels: $vessel_count"
    echo "Size: $file_size"
    echo ""
    
    echo "Vessel types in snapshot:"
    jq -r '.[].vesselParticulars.vesselType' "$OUTPUT_FILE" | sort | uniq -c | sort -rn
    
    echo ""
    echo "Vessels by status:"
    moving=$(jq -r '.[] | select(.speed > 0.5) | .speed' "$OUTPUT_FILE" | wc -l)
    stationary=$(jq -r '.[] | select(.speed <= 0.5) | .speed' "$OUTPUT_FILE" | wc -l)
    echo "  Moving (>0.5 knots): $moving"
    echo "  Stationary (≤0.5 knots): $stationary"
    
    echo ""
    echo "✓ JSON is valid"
    echo ""
    echo "Sample vessel:"
    jq '.[0]' "$OUTPUT_FILE"
else
    echo "✗ Download failed"
    exit 1
fi

echo ""
echo "Finished at: $(date '+%Y-%m-%d %H:%M:%S')"
