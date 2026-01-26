-- ============================================================================
-- MARITIME ANALYTICS DATABASE SCHEMA (NORMALIZED VERSION)
-- ============================================================================

DROP TABLE IF EXISTS voyage_analytics;
DROP TABLE IF EXISTS port_visits;
DROP TABLE IF EXISTS departures;
DROP TABLE IF EXISTS arrivals;
DROP TABLE IF EXISTS vessel_positions;
DROP TABLE IF EXISTS locations;
DROP TABLE IF EXISTS vessels;

-- ============================================================================
-- VESSELS
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
-- LOCATIONS (DIMENSION TABLE)
-- ============================================================================
CREATE TABLE locations (
    location_id INTEGER PRIMARY KEY AUTOINCREMENT,
    location_name TEXT UNIQUE,
    latitude REAL,
    longitude REAL,
    location_type TEXT,   -- PORT / BERTH / TERMINAL / ANCHORAGE
    country TEXT
);

-- ============================================================================
-- ARRIVALS
-- ============================================================================
CREATE TABLE arrivals (
    arrival_id INTEGER PRIMARY KEY AUTOINCREMENT,
    imo_number TEXT NOT NULL,
    arrived_time TEXT,
    
    origin_location_id INTEGER,       -- Where vessel came from
    destination_location_id INTEGER,  -- Local berth/terminal
    
    FOREIGN KEY (imo_number) REFERENCES vessels(imo_number),
    FOREIGN KEY (origin_location_id) REFERENCES locations(location_id),
    FOREIGN KEY (destination_location_id) REFERENCES locations(location_id)
);

CREATE INDEX idx_arrivals_imo ON arrivals(imo_number);
CREATE INDEX idx_arrivals_time ON arrivals(arrived_time);

-- ============================================================================
-- DEPARTURES
-- ============================================================================
CREATE TABLE departures (
    departure_id INTEGER PRIMARY KEY AUTOINCREMENT,
    imo_number TEXT NOT NULL,
    departed_time TEXT,
    
    origin_location_id INTEGER,       -- Local berth/terminal
    destination_location_id INTEGER,  -- Next port
    
    FOREIGN KEY (imo_number) REFERENCES vessels(imo_number),
    FOREIGN KEY (origin_location_id) REFERENCES locations(location_id),
    FOREIGN KEY (destination_location_id) REFERENCES locations(location_id)
);

CREATE INDEX idx_departures_imo ON departures(imo_number);
CREATE INDEX idx_departures_time ON departures(departed_time);

-- ============================================================================
-- VESSEL POSITIONS (AIS TRACKING)
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
-- PORT VISITS (EVENT AGGREGATION LAYER)
-- ============================================================================
CREATE TABLE port_visits (
    visit_id INTEGER PRIMARY KEY AUTOINCREMENT,
    imo_number TEXT,
    
    arrival_id INTEGER,
    departure_id INTEGER,
    
    arrived_time TEXT,
    departed_time TEXT,
    
    arrived_from_location_id INTEGER,
    departed_to_location_id INTEGER,
    berth_location_id INTEGER,
    
    port_dwell_hours REAL,
    
    FOREIGN KEY (imo_number) REFERENCES vessels(imo_number),
    FOREIGN KEY (arrival_id) REFERENCES arrivals(arrival_id),
    FOREIGN KEY (departure_id) REFERENCES departures(departure_id),
    FOREIGN KEY (arrived_from_location_id) REFERENCES locations(location_id),
    FOREIGN KEY (departed_to_location_id) REFERENCES locations(location_id),
    FOREIGN KEY (berth_location_id) REFERENCES locations(location_id)
);

-- ============================================================================
-- VOYAGE ANALYTICS (DERIVED FACT TABLE)
-- ============================================================================
CREATE TABLE voyage_analytics (
    visit_id INTEGER PRIMARY KEY,
    imo_number TEXT,
    
    vessel_type TEXT,
    estimated_dwt INTEGER,
    year_built INTEGER,
    
    origin_location_id INTEGER,
    destination_location_id INTEGER,
    
    distance_nm REAL,
    voyage_hours REAL,
    port_dwell_hours REAL,
    average_speed_knots REAL,
    
    fuel_consumed_tons REAL,
    co2_emissions_tons REAL,
    
    FOREIGN KEY (visit_id) REFERENCES port_visits(visit_id),
    FOREIGN KEY (origin_location_id) REFERENCES locations(location_id),
    FOREIGN KEY (destination_location_id) REFERENCES locations(location_id)
);
