import sqlite3
from flask import Flask, g
from conf import shares_path

root_dir = "/data"
database = root_dir + "/unicloud.db"

sql_table_shares = f""" CREATE TABLE IF NOT EXISTS shares (
                         id INTEGER PRIMARY KEY,
                         size TEXT NOT NULL,
                         name TEXT NOT NULL,
                         description TEXT NOT NULL,
                         path TEXT NOT NULL);
                         """

sql_table_events = """ CREATE TABLE IF NOT EXISTS events (
                         id INTEGER PRIMARY KEY,
                         client TEXT NOT NULL,
                         share TEXT NOT NULL,
                         log TEXT,
                         start_ts   DATETIME,
                         end_ts   DATETIME,
                         duration INTEGER,
                         sync_status TEXT,
                         status TEXT); """

sql_table_clients = """ CREATE TABLE IF NOT EXISTS clients (
                         id INTEGER PRIMARY KEY,
                         name TEXT NOT NULL,
                         ssh_key TEXT NOT NULL,
                         status TEXT NOT NULL,
                         share TEXT NOT NULL,
                         threshold INTEGER NOT NULL,
                         sync_status TEXT,
                         lastseen DATETIME,
                         joindate DATETIME); """

backup_share = f""" INSERT OR IGNORE INTO shares 
                    (id,name,path,description,size) 
                    values ('0','unicloud_backup','{shares_path}/unicloud-backup','Unicloud Backuppp','None');"""

# Just for testing
share1 = f""" INSERT OR IGNORE INTO shares 
                    (id,name,path,description,size) 
                    values ('1','share1','{shares_path}/share1','testing','None');"""


def create_connection(db_file):
    """ create a database connection to a SQLite database """
    try:
        conn = sqlite3.connect(db_file)
        return conn
    except Error as e:
        print(e)


def create_table(conn, create_table_sql):
    """ create a table from the create_table_sql statement
    :param conn: Connection object
    :param create_table_sql: a CREATE TABLE statement
    :return:
    """
    try:
        c = conn.cursor()
        c.execute(create_table_sql)
    except Error as e:
        print(e)
#    conn.close()


def get_db():
    db = getattr(g, '_database', None)
    if db is None:
        db = g._database = sqlite3.connect(database)
        #db.row_factory = sqlite3.Row
    return db


def query_db(query, args=(), one=False):
    cur = get_db().execute(query, args)
    rv = cur.fetchall()
    cur.close()
    return (rv[0] if rv else None) if one else rv


### INIT DB AND TABLES

def init_db():
   conn = create_connection(database)
   if conn is not None:
      print("Create Database Schema")
      create_table(conn, sql_table_shares)
      create_table(conn, sql_table_events)
      create_table(conn, sql_table_clients)
      create_table(conn, backup_share)
      create_table(conn, share1)
      conn.commit()
      conn.close()
   else:
      print("Error! can't create database connection")
      #print(conn)
