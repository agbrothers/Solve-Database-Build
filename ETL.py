import pandas as pd
import numpy as np
import argparse
import pymysql
import sys
import os
from tqdm import tqdm
from dateutil.parser import parse
pd.options.display.max_columns = 4



class DB:

    def __init__(self, host, user, password, database):
        self.host = host
        self.user = user
        self.pw = password
        self.db = database
    
    def get_tables(self):
        self.tables = read('show tables;', self)
        print(self.tables)



# QUERY BUILDING UTILS
        
def add_cols(query, cols, as_str=False):  
    # add a list of cols/values to a query string
    for i,item in enumerate(cols):
        query += str(item) if as_str==False or type(item)!=str or item=='null' else f"'{item}'"
        query += ', ' if i < len(cols)-1 else ''
    return query


def build_where(query, cols, values):
    for i,col in enumerate(cols):
        query += str(col) +'='+str(values[i]) if type(values[i]) != str or values[i]=='null' else str(col) +"='"+str(values[i])+"'"
        query +=' and ' if i < len(cols)-1 else ''
    return query


def build_row(cols, values):
    row = []
    for key in cols:
        if key in values.keys(): 
            row.append(values[key])
        else:
             row.append('null')                
    return row

def none_to_null(values):
    nulls = pd.isnull(values)
    for i,item in enumerate(nulls):
        values[i] = 'null' if item == True else values[i]
    return values



# CRUD UTILS

def read(query, db):
    try:
        con = pymysql.connect(host=db.host, user=db.user, password=db.pw, database=db.db)
        df = pd.read_sql(query, con)
        con.close()
        return df
    except Exception as e:
        print(f'Query Failed: \n{e}')


def update(query, db):
    try:
        con = pymysql.connect(host=db.host, user=db.user, password=db.pw, database=db.db, autocommit=True)
        cursor = con.cursor()
        cursor.execute(query)
        con.close()
    except Exception as e:
        print(f'Update Error: {e}')
        
        
def insert(cols, values, table, db):
    values = none_to_null(values)
    query = add_cols(f'insert into {table}(', cols) + ') ' + add_cols('values(', values, as_str=True) + ');'
    try:
        con = pymysql.connect(host=db.host, user=db.user, password=db.pw, database=db.db, autocommit=True)
        cursor = con.cursor()
        cursor.execute(query)
        ID = pd.read_sql('SELECT LAST_INSERT_ID();', con)
        con.close()
        return ID.values[0][0]
    except Exception as e:
        print(f'Insert Error: {e}')
        

def autofill(cols, values, table, db):
    query = build_where(f'select id from {table} where ', cols, values) +';'
    result = read(query, db)
    if len(result) == 0: 
        return insert(cols, values, table, db)
    return result.iloc[0][0]


def check_props(cols, row):
    try:
        return [row[col] for col in cols]
    except Exception as e:
        return None
        
    
    
# TRANSFORM UTIL - Partition raw event data to fit into the database schema
        
def load_events(events, db):
    # GET COLUMN NAMES FOR EACH TABLE
    user_cols = list(read('desc users;', solveDB)['Field'])
    user_properties = list(read('desc user_properties;', solveDB)['Field'].iloc[1:])
    event_properties = list(read('desc event_properties;', solveDB)['Field'].iloc[1:])
    appsflyer_properties = list(read('desc appsflyer_properties;', solveDB)['Field'].iloc[1:])
    location_cols = list(read('desc locations;', solveDB)['Field'].iloc[1:])
    device_cols =  list(read('desc devices;', solveDB)['Field'].iloc[1:])
    retention_cols =  list(read('desc retention;', solveDB)['Field'].iloc[1:])
    ab_cols =  list(read('desc ab_tests;', solveDB)['Field'].iloc[1:])

    for i,ev in tqdm(events.iterrows()):
        # CHECK IF EXISTING USER
        user = read(f"select user_id from users where user_id='{ev.user_id}'", db).shape[0] == 0
        appsflyer = read(f"select user_id from appsflyer_properties where user_id='{ev.user_id}'", db).shape[0] == 0
        
        # FILL USER TABLE - if the user is not in the database
        if user:  
            user_values = list(ev.loc[['user_id','user_creation_time','language']]) + [None, None, None, None, None]    
            user_values[1] = parse(user_values[1]).strftime('%Y-%m-%d %H:%M:%S')
            user_id = insert(cols=user_cols, values=user_values, table='users', db=db)            
            location_id = autofill(location_cols, ev[location_cols], 'locations', db)            
            device_id = autofill(device_cols, ev[device_cols], 'devices', db)
            try:
                gender_id = autofill(['gender'], [ev.user_properties['appsflyer_gender']], 'genders', db)
            except Exception:
                gender_id = 'null'
            update_query = f"update users set location_id={location_id}, device_id={device_id}, gender_id={gender_id} where user_id='{ev.user_id}';"
            update(update_query, db)


        # FILL EVENT PROPERTY TABLES
        event_id = insert(cols=['user_id','time'], values=list(ev[['user_id','event_time']]), table='events', db=db)
        user_property_values = [ev.user_id, event_id] + build_row(user_properties[2:], ev.user_properties)
        user_property_id = insert(cols=user_properties, values=user_property_values, table='user_properties', db=db)
        event_property_values = [ev.user_id, event_id] + build_row(event_properties[2:], ev.event_properties)
        event_property_id = insert(cols=event_properties, values=event_property_values, table='event_properties', db=db)

                                           
        # FILL APPSFLYER TABLE
        if appsflyer and ev.event_type == 'appsflyer_attribution':
            appsflyer_values = [ev.user_id, event_id] + build_row(appsflyer_properties, ev.user_properties)
            insert(cols=appsflyer_properties, values=appsflyer_values, table='appsflyer_properties', db=db)


        # AUTOFILL LOOKUP + JUNCTION TABLES
        retention_values = check_props(['current_dn'], ev.user_properties)
        if retention_values:
            retention_values[0] = 'D' + str(retention_values[0])
            retention_id = autofill(retention_cols, retention_values, 'retention', db)
            update_query = f"update users set retention_id={retention_id} where user_id='{ev.user_id}';"
            update(update_query, db)
            if read(f"select retention_id from users where user_id='{ev.user_id}';", db).iloc[0][0] != retention_id:
                insert(cols=['user_id','retention_id'], values=[ev.user_id,retention_id], table='UserRetention', db=db)


        ab_values = check_props(['current_ab_test','current_ab_test_group'], ev.user_properties)
        if ab_values:
            ab_id = autofill(ab_cols, ab_values, 'ab_tests', db)
            update_query = f"update users set ab_test_id={ab_id} where user_id='{ev.user_id}';"
            update(update_query, db)
            if read(f"select ab_test_id from users where user_id='{ev.user_id}';", db).iloc[0][0] != ab_id:
                insert(cols=['user_id','ab_id'], values=[ev.user_id,ab_id], table='UserTests', db=db)



if __name__ == "__main__":
    #  '/Users/greysonbrothers/Desktop/ /work/SOLVE/data/etl_tests/etl_test.csv'
    
    parser = argparse.ArgumentParser(description='Solve Database ETL Script')
    parser.add_argument('--src_dir',  '-s',  type=str, default='events', help='Source directory for event data to be uploaded.')
    parser.add_argument('--host',     '-host',  type=str, default='localhost', help='MySQL Server Host Name')
    parser.add_argument('--user',     '-u',  type=str, default='root', help='MySQL Server User Name')
    parser.add_argument('--password', '-pw', type=str, default='sonny_crocket_84', help='MySQL Server Password')
    parser.add_argument('--database', '-db', type=str, default='solve', help='Database to load values into')
    args, _ = parser.parse_known_args()    
    
    solveDB = DB(host=args.host, user=args.user, password=args.password, database=args.database)
    db = DB(host=args.host, user=args.user, password=args.password, database=args.database)


    for file in os.listdir(args.src_dir):
        if file.split('.')[-1] == 'csv':
            events = pd.read_csv('/Users/greysonbrothers/Desktop/ /work/SOLVE/data/events/dump 2020-07-05/267117_2020-07-05_0#264.json.csv')
            events['user_properties'] = events['user_properties'].apply(eval)
            events['event_properties'] = events['event_properties'].apply(eval)
            load_events(events, solveDB)
    
            test = pd.read_csv('/Users/greysonbrothers/Desktop/ /work/SOLVE/data/etl_tests/etl_test.csv')
            test['user_properties'] = test['user_properties'].apply(eval)
            test['event_properties'] = test['event_properties'].apply(eval)
            load_events(test, solveDB)
    

    tables = read('show tables;', db)
    for table in tables['Tables_in_solve']:
        print(f'\n{table}')
        print(read(f'select * from {table};', db).head())


    
    # Execution Example
    # load_sql = 
    """
    LOAD DATA LOCAL INFILE '/tmp/city.csv' 
    INTO TABLE usermanaged.city\
    cols TERMINATED BY ',' 
    ENCLOSED BY '"' 
    IGNORE 1 LINES;
    
    
    # Execution Example
    query = 'Select * From world.city'
    file_path = '/tmp/city.csv'
    host = 'host url'
    user = 'username'
    password = 'password'
    mysql_to_csv(query, file_path, host, user, password)
    """   
    
    
    """
    LOAD DATA LOCAL 
    INFILE '/Users/miguelgomez/Desktop/mock_data.csv' 
    INTO TABLE users 
    cols TERMINATED BY ',' 
    LINES TERMINATED BY '\n' 
    IGNORE 1 ROWS 
    (id, first_name, last_name, email, transactions, @account_creation)
    SET account_creation  = STR_TO_DATE(@account_creation, '%m/%d/%y');
    """


# str(cols).replace('[','').replace(']','')



















