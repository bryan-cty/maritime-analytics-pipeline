-- ============================================================================
-- MARITIME ANALYTICS DATABASE SCHEMA
-- ============================================================================

-- Drop existing tables (for clean restart)
DROP TABLE IF EXISTS voyage_analytics;
DROP TABLE IF EXISTS port_visits;
DROP TABLE IF EXISTS departures;
DROP TABLE IF EXISTS arrivals;
DROP TABLE IF EXISTS vessel_positions;
DROP TABLE IF EXISTS locations;
DROP TABLE IF EXISTS vessels;

-- ============================================================================
-- VESSELS TABLE
-- ============================================================================
CREATE TABLE vessels (
    imo_number TEXT PRIMARY KEY,
    vessel_name TEXT,
    call_sign TEXT,
    mmsi_number TEXT,
    flag TEXT,
    vessel_type TEXT,
    vessel_type_name TEXT,
    vessel_length INTEGER,
    vessel_breadth INTEGER,
    gross_tonnage INTEGER,
    net_tonnage INTEGER,
    deadweight INTEGER,
    estimated_dwt INTEGER,
    year_built INTEGER,
    last_updated TEXT
);

-- ============================================================================
-- LOCATIONS TABLE
-- ============================================================================
CREATE TABLE locations (
    location_name TEXT PRIMARY KEY,
    latitude REAL,
    longitude REAL,
    location_type TEXT,
    country TEXT
);

-- ============================================================================
-- ARRIVALS TABLE
-- ============================================================================
CREATE TABLE arrivals (
    arrival_id INTEGER PRIMARY KEY AUTOINCREMENT,
    imo_number TEXT,
    vessel_name TEXT,
    arrived_time TEXT,
    origin_location TEXT,           -- Where vessel came from
    destination_location TEXT,      -- Singapore berth/terminal
    FOREIGN KEY (imo_number) REFERENCES vessels(imo_number)
);

CREATE INDEX idx_arrivals_imo ON arrivals(imo_number);
CREATE INDEX idx_arrivals_time ON arrivals(arrived_time);

-- ============================================================================
-- DEPARTURES TABLE
-- ============================================================================
CREATE TABLE departures (
    departure_id INTEGER PRIMARY KEY AUTOINCREMENT,
    imo_number TEXT,
    vessel_name TEXT,
    departed_time TEXT,
    origin_location TEXT,           -- Singapore berth/terminal
    destination_location TEXT,      -- Where vessel is going
    FOREIGN KEY (imo_number) REFERENCES vessels(imo_number)
);

CREATE INDEX idx_departures_imo ON departures(imo_number);
CREATE INDEX idx_departures_time ON departures(departed_time);

-- ============================================================================
-- VESSEL POSITIONS TABLE
-- ============================================================================
CREATE TABLE vessel_positions (
    position_id INTEGER PRIMARY KEY AUTOINCREMENT,
    imo_number TEXT,
    timestamp TEXT,
    latitude REAL,
    longitude REAL,
    speed REAL,
    course REAL,
    heading REAL,
    FOREIGN KEY (imo_number) REFERENCES vessels(imo_number)
);

CREATE INDEX idx_positions_imo ON vessel_positions(imo_number);

-- ============================================================================
-- PORT VISITS TABLE (Analytical view joining arrivals + departures)
-- ============================================================================
CREATE TABLE port_visits (
    visit_id INTEGER PRIMARY KEY AUTOINCREMENT,
    imo_number TEXT,
    vessel_name TEXT,
    
    arrival_id INTEGER,
    arrived_time TEXT,
    arrived_from TEXT,
    
    departure_id INTEGER,
    departed_time TEXT,
    departed_to TEXT,
    
    berth_location TEXT,
    port_dwell_hours REAL,
    
    FOREIGN KEY (arrival_id) REFERENCES arrivals(arrival_id),
    FOREIGN KEY (departure_id) REFERENCES departures(departure_id),
    FOREIGN KEY (imo_number) REFERENCES vessels(imo_number)
);

-- ============================================================================
-- VOYAGE ANALYTICS TABLE
-- ============================================================================
CREATE TABLE voyage_analytics (
    visit_id INTEGER PRIMARY KEY,
    imo_number TEXT,
    vessel_type TEXT,
    estimated_dwt INTEGER,
    year_built INTEGER,
    
    origin TEXT,
    destination TEXT,
    distance_nm REAL,
    
    voyage_hours REAL,
    port_dwell_hours REAL,
    average_speed_knots REAL,
    
    fuel_consumed_tons REAL,
    co2_emissions_tons REAL,
    
    FOREIGN KEY (visit_id) REFERENCES port_visits(visit_id)
);
