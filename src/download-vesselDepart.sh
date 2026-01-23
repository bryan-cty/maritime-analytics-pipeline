#!/bin/bash

# logging
exec > >(tee -a "$(dirname "$0")/../logs/script/download_vesselDepart.log") 2>&1

# navigate to project root
cd "$(dirname "$0")/.." || exit 1

# Load API key
source "$(dirname "$0")/.env"

# Configs
BASE_URL="https://oceans-x.mpa.gov.sg/api/v1/vessel/departure/1.0.0"
START_DATE="$(date -d "$GET_DATE -1 year" +%Y-%m-%d)"
END_DATE="$(date +%Y-%m-%d)"

# Create output directory
mkdir -p raw_data/departures

# Print header
echo "======================================================================"
echo "Vessel Departures Download"
echo "======================================================================"
echo "Date range: $START_DATE to $END_DATE"
echo ""

# Calculate date range
start_sec=$(date -d "$START_DATE" +%s)
end_sec=$(date -d "$END_DATE" +%s)
total_days=$(( (end_sec - start_sec) / 86400 + 1 ))

echo "Total days to download: $total_days"
echo ""

# Initialize variables
total_records=0
current_day=0
output_file="raw_data/departures/departures_${START_DATE}_${END_DATE}.json"

# Start JSON array
echo "[" > "$output_file"
first_record=true

# Loop through each date
current=$start_sec
while [ $current -le $end_sec ]; do
    date_str=$(date -d "@$current" +%Y-%m-%d)
    current_day=$((current_day + 1))
    
    echo -n "[$current_day/$total_days] $date_str ... "
    
    # Fetch data for current date
    response=$(curl -s -X GET \
        "${BASE_URL}/date/${date_str}" \
        -H "accept: application/json" \
        -H "ApiKey: ${OCEANS_X_API_KEY}")
    
    # Validate and process response
    if echo "$response" | jq empty 2>/dev/null; then
        record_count=$(echo "$response" | jq 'length' 2>/dev/null || echo "0")
        
        if [ "$record_count" != "null" ] && [ "$record_count" -gt 0 ]; then
            
            if [ "$first_record" = true ]; then
                # First batch: write objects as-is
                echo "$response" | jq -c '.[]' >> "$output_file"
                first_record=false
            else
                # Add comma to the current last line in file
                sed -i '$ s/$/,/' "$output_file"
                
                # Then append new objects normally
                echo "$response" | jq -c '.[]' >> "$output_file"
            fi
            
            total_records=$((total_records + record_count))
            echo "✓ $record_count records"
        else
            echo "⊘ No data"
        fi
    else
        echo "✗ Failed"
        echo "$response" > "raw_data/departures/error_${date_str}.txt"
    fi
    
    # Move to next day
    current=$((current + 86400))
    
    # Progress update every 10 days
    if [ $((current_day % 10)) -eq 0 ]; then
        echo "  → Progress: $current_day/$total_days days, $total_records records so far"
    fi
    
    # Rate limiting
    sleep 0.5
done

# Close JSON array
echo "]" >> "$output_file"

# Print summary
echo ""
echo "======================================================================"
echo "Download Complete!"
echo "======================================================================"
echo "Output: $output_file"
echo "Total records: $total_records"
echo "File size: $(ls -lh "$output_file" | awk '{print $5}')"
echo ""

# Validate JSON output
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
