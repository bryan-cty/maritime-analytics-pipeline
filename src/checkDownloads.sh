cd ~/maritime-project/maritime-analytics-pipeline

# Check what files you downloaded
echo "=== Arrivals ==="
ls -lh raw_data/arrivals/

echo ""
echo "=== Departures ==="
ls -lh raw_data/departures/

echo ""
echo "=== Positions ==="
ls -lh raw_data/positions/

# Quick data preview
echo ""
echo "=== Sample Arrival Record ==="
jq '.[0]' raw_data/arrivals/arrivals_*.json | head -50

echo ""
echo "=== Sample Departure Record ==="
jq '.[0]' raw_data/departures/departures_*.json | head -50

echo ""
echo "=== Sample Position Record ==="
jq '.[0]' raw_data/positions/snapshot_*.json | head -50

# Count records
echo ""
echo "=== Record Counts ==="
echo "Arrivals: $(jq 'length' raw_data/arrivals/arrivals_*.json)"
echo "Departures: $(jq 'length' raw_data/departures/departures_*.json)"
echo "Positions: $(jq 'length' raw_data/positions/snapshot_*.json)"

