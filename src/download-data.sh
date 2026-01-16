#!/bin/bash

# Load API key
source ../.env

BASE_URL="https://oceans-x.mpa.gov.sg/api/v1/vessel/arrivals/1.0.0"

# Define months to download (adjust as needed)
YEAR=2025
MONTHS=(01 02)

mkdir -p ../raw_data/monthly

echo "Downloading data by month for year $YEAR"
echo ""

for MONTH in "${MONTHS[@]}"; do
    # Get first and last day of month
    START_DATE="${YEAR}-${MONTH}-01"
    LAST_DAY=$(date -d "${START_DATE} +1 month -1 day" +%d)
    END_DATE="${YEAR}-${MONTH}-${LAST_DAY}"
    
    OUTPUT_FILE="../raw_data/monthly/arrivals_${YEAR}_${MONTH}.json"
    
    echo "================================================================"
    echo "Downloading: $START_DATE to $END_DATE"
    echo "================================================================"
    
    # Start JSON array
    echo "[" > "$OUTPUT_FILE"
    
    total_records=0
    first_record=true
    
    # Convert to seconds
    start_sec=$(date -d "$START_DATE" +%s)
    end_sec=$(date -d "$END_DATE" +%s)
    current=$start_sec
    
    while [ $current -le $end_sec ]; do
        date_str=$(date -d "@$current" +%Y-%m-%d)
        
        echo -n "$date_str ... "
        
        response=$(curl -s -X GET \
            "${BASE_URL}/date/${date_str}" \
            -H "accept: application/json" \
            -H "ApiKey: ${OCEANS_X_API_KEY}")
        
        if echo "$response" | jq empty 2>/dev/null; then
            record_count=$(echo "$response" | jq 'length' 2>/dev/null || echo "0")
            
            if [ "$record_count" -gt 0 ]; then
                if [ "$first_record" = true ]; then
                    echo "$response" | jq -c '.[]' >> "$OUTPUT_FILE"
                    first_record=false
                else
                    echo "$response" | jq -c '.[]' | sed 's/^/,/' >> "$OUTPUT_FILE"
                fi
                
                total_records=$((total_records + record_count))
                echo "✓ $record_count records"
            else
                echo "⊘ No data"
            fi
        else
            echo "✗ Failed"
        fi
        
        current=$((current + 86400))
        sleep 0.5
    done
    
    # Close JSON array
    echo "]" >> "$OUTPUT_FILE"
    
    echo ""
    echo "Month $MONTH complete: $total_records records"
    echo "File: $OUTPUT_FILE ($(ls -lh "$OUTPUT_FILE" | awk '{print $5}'))"
    echo ""
done

echo "All months downloaded!"
echo ""
echo "Summary:"
ls -lh ../raw_data/monthly/
