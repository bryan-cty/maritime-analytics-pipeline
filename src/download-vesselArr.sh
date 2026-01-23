#!/bin/bash

# logging
exec > >(tee -a "$(dirname "$0")/../logs/script/download_vesselArr.log") 2>&1

# navigate to project root
cd "$(dirname "$0")/.." || exit 1

# Load API key
source "$(dirname "$0")/.env"

BASE_URL="https://oceans-x.mpa.gov.sg/api/v1/vessel/arrivals/1.0.0"
#START_DATE="$1"
#END_DATE="$2"
START_DATE="$(date -d "$GET_DATE -1 year" +%Y-%m-%d)"
END_DATE="$(date +%Y-%m-%d)"

# Create output directory
mkdir -p raw_data/arrivals

echo "======================================================================"
echo "Vessel Arrivals Download"
echo "======================================================================"
echo "Date range: $START_DATE to $END_DATE"
echo ""

# Convert dates to seconds
start_sec=$(date -d "$START_DATE" +%s)
end_sec=$(date -d "$END_DATE" +%s)
total_days=$(( (end_sec - start_sec) / 86400 + 1 ))

echo "Total days to download: $total_days"
echo ""

# Initialize
total_records=0
current_day=0
output_file="raw_data/arrivals/arrivals_${START_DATE}_${END_DATE}.json"

echo "[" > "$output_file"
first_record=true

# Loop through dates
current=$start_sec
while [ $current -le $end_sec ]; do
    date_str=$(date -d "@$current" +%Y-%m-%d)
    current_day=$((current_day + 1))
    
    echo -n "[$current_day/$total_days] $date_str ... "
    
    response=$(curl -s -X GET \
        "${BASE_URL}/date/${date_str}" \
        -H "accept: application/json" \
        -H "ApiKey: ${OCEANS_X_API_KEY}")
    
    if echo "$response" | jq empty 2>/dev/null; then
    record_count=$(echo "$response" | jq 'length' 2>/dev/null || echo "0")

    if [ "$record_count" != "null" ] && [ "$record_count" -gt 0 ]; then
        
        if [ "$first_record" = true ]; then
            # First batch: just write objects
            echo "$response" | jq -c '.[]' >> "$output_file"
            first_record=false
        else
            # Insert comma at end of file before appending
            sed -i '$ s/$/,/' "$output_file"
            echo "$response" | jq -c '.[]' >> "$output_file"
        fi
        
        total_records=$((total_records + record_count))
        echo "✓ $record_count records"
    else
        echo "⊘ No data"
    fi
else
    echo "✗ Failed"
    echo "$response" > "raw_data/arrivals/error_${date_str}.txt"
fi

echo "]" >> "$output_file"

echo ""
echo "======================================================================"
echo "Download Complete!"
echo "======================================================================"
echo "Output: $output_file"
echo "Total records: $total_records"
echo "File size: $(ls -lh "$output_file" | awk '{print $5}')"
echo ""

if jq empty "$output_file" 2>/dev/null; then
    echo "✓ JSON is valid"
    echo ""
    echo "Sample record:"
    jq '.[0]' "$output_file"
else
    echo "✗ JSON may be invalid"
fi

echo ""
echo "Finished at: $(date '+%Y-%m-%d %H:%M:%S')"
