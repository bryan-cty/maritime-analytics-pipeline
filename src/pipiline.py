#!/usr/bin/env python3
"""
ETL Pipeline: Load JSON data into SQLite for Maritime Analytics
"""

import json
import sqlite3
import glob
from datetime import datetime

# -------------------------------
# DB Connection
# -------------------------------
def get_conn(db_path="../maritime_analytics.db"):
    conn = sqlite3.connect(db_path)
    conn.execute("PRAGMA foreign_keys = ON;")  # enforce FKs
    return conn

# -------------------------------
# VESSEL TYPE MAPPING
# -------------------------------
VESSEL_TYPE_NAMES = {
    'BC': 'Bulk Carrier',
    'CT': 'Container Ship',
    'OT': 'Oil Tanker',
    'GT': 'Gas Tanker',
    'CC': 'Chemical Carrier',
    'GC': 'General Cargo',
    'RR': 'Ro-Ro Cargo',
    'RF': 'Refrigerated Cargo',
    'PC': 'Passenger',
    'PF': 'Passenger/Ferry',
    'YC': 'Yacht',
    'TU': 'Tug',
    'OF': 'Offshore Vessel',
    'SV': 'Service Vessel',
    'FB': 'Fishing Vessel',
    'DR': 'Dredger',
}

def estimate_dwt(vessel_type, gross_tonnage):
    ratios = {'BC': 1.7, 'OT': 1.8, 'GT': 1.5, 'CC': 1.4,
              'CT': 0.9, 'GC': 1.3, 'RR': 0.7, 'SV': 0.5}
    if gross_tonnage == 0:
        return 0
    return int(gross_tonnage * ratios.get(vessel_type, 1.5))

# -------------------------------
# EXTRACT FUNCTIONS
# -------------------------------
def extract_json(path_pattern):
    all_data = []
    for file in glob.glob(path_pattern):
        with open(file, 'r') as f:
            data = json.load(f)
            all_data.extend(data)
    return all_data

# -------------------------------
# TRANSFORM FUNCTIONS
# -------------------------------
def transform_vessels(positions_data):
    print("Transforming vessels data...")
    vessels = []
    processed_imos = set()

    for record in positions_data:
        particulars = record.get('vesselParticulars', {})
        imo = particulars.get('imoNumber')
        if not imo or imo in processed_imos:
            continue
        processed_imos.add(imo)

        vessel_type = particulars.get('vesselType', '')
        gross_tonnage = particulars.get('grossTonnage', 0)
        deadweight = particulars.get('deadweight', 0)

        estimated_dwt = estimate_dwt(vessel_type, gross_tonnage)
        vessel_type_name = VESSEL_TYPE_NAMES.get(vessel_type, '')

        vessels.append({
            'imo_number': imo,
            'vessel_name': particulars.get('vesselName'),
            'call_sign': particulars.get('callSign'),
            'mmsi_number': particulars.get('mmsiNumber'),
            'flag': particulars.get('flag'),
            'vessel_type': vessel_type,
            'vessel_type_name': vessel_type_name,
            'vessel_length': particulars.get('vesselLength'),
            'vessel_breadth': particulars.get('vesselBreadth'),
            'vessel_depth': particulars.get('vesselDepth'),
            'gross_tonnage': gross_tonnage,
            'net_tonnage': particulars.get('netTonnage'),
            'deadweight': deadweight,
            'estimated_dwt': estimated_dwt,
            'year_built': particulars.get('yearBuilt'),
            'last_updated': datetime.now().isoformat()
        })
    print(f"Extracted {len(vessels)} unique vessels")
    return vessels

def transform_arrivals(arrivals_data):
    print("Transforming arrivals data...")
    arrivals = []
    for record in arrivals_data:
        particulars = record.get('vesselParticulars', {})
        arrivals.append({
            'imo_number': particulars.get('imoNumber'),
            'vessel_name': particulars.get('vesselName'),
            'call_sign': particulars.get('callSign'),
            'flag': particulars.get('flag'),
            'arrived_time': record.get('arrivedTime'),
            'location_from_code': record.get('locationFrom'),
            'location_to_code': record.get('locationTo'),
        })
    print(f"Transformed {len(arrivals)} arrivals")
    return arrivals

def transform_departures(departures_data):
    print("Transforming departures data...")
    departures = []
    for record in departures_data:
        particulars = record.get('vesselParticulars', {})
        departures.append({
            'imo_number': particulars.get('imoNumber'),
            'vessel_name': particulars.get('vesselName'),
            'call_sign': particulars.get('callSign'),
            'flag': particulars.get('flag'),
            'departed_time': record.get('departedTime'),
            'location_from_code': record.get('locationFrom'),
            'location_to_code': record.get('locationTo'),
        })
    print(f"Transformed {len(departures)} departures")
    return departures

def transform_locations(location_codes_data):
    print("Transforming location code data...")
    location_codes = []
    for record in location_codes_data:
        location_codes.append({
            'location_code': record.get('locationCode'),
            'location_description': record.get('locationDescription'),
            'latitude': record.get('latitude', None),
            'longitude': record.get('longitude', None),
            'location_type': record.get('locationType', None),
            'timestamp': record.get('timeStamp')
        })
    print(f"Transformed {len(location_codes)} location codes")
    return location_codes

# -------------------------------
# LOAD FUNCTIONS
# -------------------------------
def load_table(conn, table_name, data, columns):
    print(f"Loading {table_name}...")
    cursor = conn.cursor()
    placeholders = ', '.join(['?'] * len(columns))
    cols_str = ', '.join(columns)
    inserted = 0

    for row in data:
        try:
            cursor.execute(f"INSERT OR IGNORE INTO {table_name} ({cols_str}) VALUES ({placeholders})",
                           [row[col] for col in columns])
            inserted += 1
        except Exception as e:
            print(f"Error inserting into {table_name}: {e}")

    conn.commit()
    print(f"Loaded {inserted} rows into {table_name}\n")


# -------------------------------
# RUN ETL
# -------------------------------
if __name__ == "__main__":
    conn = get_conn()

    # Extract
    arrivals_raw = extract_json('../raw_data/arrivals_cleaned/*.json')
    departures_raw = extract_json('../raw_data/departures_cleaned/*.json')
    positions_raw = extract_json('../raw_data/positions/*.json')
    locations_raw = extract_json('../raw_data/locations/*.json')

    # Transform
    vessels_data = transform_vessels(positions_raw)
    arrivals_data = transform_arrivals(arrivals_raw)
    departures_data = transform_departures(departures_raw)
    location_codes_data = transform_locations(locations_raw)

    # Load
    load_table(conn, 'vessels', vessels_data, [
        'imo_number','vessel_name','call_sign','mmsi_number','flag','vessel_type',
        'vessel_type_name','vessel_length','vessel_breadth','vessel_depth',
        'gross_tonnage','net_tonnage','deadweight','estimated_dwt','year_built','last_updated'
    ])
    
    load_table(conn, 'location_codes', location_codes_data, [
        'location_code','location_description','latitude','longitude','location_type','timestamp'
    ])

    load_table(conn, 'arrivals', arrivals_data, [
        'imo_number','vessel_name','call_sign','flag','arrived_time','location_from_code','location_to_code'
    ])

    load_table(conn, 'departures', departures_data, [
        'imo_number','vessel_name','call_sign','flag','departed_time','location_from_code','location_to_code'
    ])


    conn.close()
    print("ETL completed successfully!")
