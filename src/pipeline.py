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

# Transform



# Load

