#!/usr/bin/env python3
"""
ETL Pipeline: Loading JSON data into SQLite database
"""

# imports
import json
import sqlite3
import pandas as pd
from datetime import datetime
import glob

def get_conn():
    conn = sqlite3.connect("../maritime_analytics.db")
    conn.execute("PRAGMA foreign_key=ON;")
    return conn

# Vessel type code mapping
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
    """Estimate DWT from gross tonnage when missing"""
    ratios = {
        'BC': 1.7, 'OT': 1.8, 'GT': 1.5, 'CC': 1.4,
        'CT': 0.9, 'GC': 1.3, 'RR': 0.7, 'SV': 0.5
    }
    if gross_tonnage == 0:
        return 0
    return int(gross_tonnage * ratios.get(vessel_type, 1.5))



# Extract
def extract_arrivals():
    """ Load arrivals from json files """
    print("Extracting data...")
    files = glob.glob('../raw_data/arrivals_cleaned/*.json')

    all_data = []
    for file in files:
        with open(file , 'r') as f:
            data = json.load(f)
            all_data.extend(data)
    print(f"  ✓ Loaded {len(all_data)} arrival records")
    return all_data

def extract_departures():
    """ Load departures from json files """
    print("Extracting data...")
    files = glob.glob('../raw_data/departures_cleaned/*.json')

    all_data = []
    for file in files:
        with open(file , 'r') as f:
            data = json.load(f)
            all_data.extend(data)
    print(f"  ✓ Loaded {len(all_data)} arrival records")
    return all_data

def extract_vessel_position():
    """ Load vessel positions from json files """
    print("Extracting data...")
    files = glob.glob('../raw_data/positions/*.json')

    all_data = []
    for file in files:
        with open(file , 'r') as f:
            data = json.load(f)
            all_data.extend(data)
    print(f"  ✓ Loaded {len(all_data)} arrival records")
    return all_data

def extract_location():
    """ Load location from json files """
    print("Extracting data...")
    files = glob.glob('../raw_data/locations/*.json')

    all_data = []
    for file in files:
        with open(file , 'r') as f:
            data = json.load(f)
            all_data.extend(data)
    print(f"  ✓ Loaded {len(all_data)} arrival records")
    return all_data

# Transform: Clean and prepare data (continuing from jupyter data discovery step)

def transform_vessels(positions_data):
    """Extract vessel master data from positions"""
    print("Transforming vessels data...")
    
    vessels = []
    processed_imos = set()

    for record in positions_data:
        particulars = record.get('vesselParticulars', {})
        imo = particulars.get('imoNumber')
    
        if not imo or imo in processed_imos:
            continue
    
        processed_imos.add(imo)
        
        # Estimate DWT if missing/wrong
        vessel_type = particulars.get('vesselType', '')
        gross_tonnage = particulars.get('grossTonnage', 0)
        deadweight = particulars.get('deadweight', 0)
        
        # DWT estimation ratios by vessel type (DWT = Deadweight Tonnage (Max Weight))
        dwt_ratios = {'BC': 1.7, 'OT': 1.8, 'CT': 0.9} # OT = Oil Tanker CT = Chemical Tanker BC = Bulk Carrier
        estimated_dwt = int(gross_tonnage * dwt_ratios.get(vessel_type, 1.5))
        
        vessels.append({
            'imo_number': imo,
            'vessel_name': particulars.get('vesselName'),
            'call_sign': particulars.get('callSign'),
            'mmsi_number': particulars.get('mmsiNumber'),
            'flag': particulars.get('flag'),
            'vessel_type': vessel_type,
            'vessel_length': particulars.get('vesselLength'),
            'vessel_breadth': particulars.get('vesselBreadth'),
            'gross_tonnage': gross_tonnage,
            'net_tonnage': particulars.get('netTonnage'),
            'deadweight': deadweight,
            'estimated_dwt': estimated_dwt,
            'year_built': particulars.get('yearBuilt'),
            'last_updated': datetime.now().isoformat()
        })
    
    print(f"  ✓ Extracted {len(vessels)} unique vessels")
    return vessels

def transform_arrivals(arrivals_data):
    """Extract arrivals data from arrivals"""
    print("Transforming arrivals data...")

    arrivals = []

    for record in arrivals_data:
        particulars = record.get('vesselParticulars',{})


    return

def transform_departures(departures_data):
    """Extract depatures data from departuress"""
    print("Transforming departures data...")

    departures = []
    for record in departures_data:
        particulars = record.get('vesselParticulars', {})
    return

def transform_locations(location_codes_data):
    """Extract location codes data from locations"""
    print("Transforming location code data...")

    location_codes = []

    for record in location_codes_data:
        locationDetails = record.get('',{})

    return

# Load


