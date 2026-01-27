#imports
import sqlite3, json
import pandas as pd

def get_conn():
    conn = sqlite3.connect("../maritime.db")
    conn.execute("PRAGMA foreign_key=ON;")
    return conn
