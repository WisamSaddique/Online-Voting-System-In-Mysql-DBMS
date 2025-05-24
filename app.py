from flask import Flask, render_template, request, flash, redirect, url_for, jsonify
import mysql.connector
from mysql.connector import Error

app = Flask(__name__)
app.secret_key = 'your_secret_key'

db_config = {
    'host': '127.0.0.1',
    'port': 3306,
    'user': 'root',
    'password': 'admin',
    'database': 'pakistan_voting_system'
}

def get_db_connection():
    try:
        conn = mysql.connector.connect(**db_config)
        if conn.is_connected():
            print("Database connection successful")
            return conn
    except Error as e:
        print(f"Error connecting to database: {e}")
        return None
    return None

@app.route('/')
def index():
    provinces = []
    cities = []
    polling_stations = []
    elections = []
    conn = get_db_connection()
    if conn:
        try:
            cursor = conn.cursor()
            cursor.execute("SELECT province_id, province_name FROM provinces")
            provinces = cursor.fetchall()
            cursor.execute("SELECT city_id, city_name FROM cities")
            cities = cursor.fetchall()
            cursor.execute("SELECT station_id, station_name FROM polling_stations")
            polling_stations = cursor.fetchall()
            cursor.execute("SELECT election_id, election_name FROM elections")
            elections = cursor.fetchall()
        except Error as e:
            print(f"Error fetching data: {e}")
            flash("Error fetching data from database.", "error")
        finally:
            cursor.close()
            conn.close()
    
    return render_template('index.html', provinces=provinces, cities=cities, 
                         polling_stations=polling_stations, elections=elections)

@app.route('/api/vote_counts', methods=['GET'])
def get_vote_counts():
    conn = get_db_connection()
    party_votes = []
    if conn:
        try:
            cursor = conn.cursor()
            cursor.execute("""
                SELECT p.party_name, COUNT(v.vote_id) as vote_count
                FROM parties p
                LEFT JOIN votes v ON p.party_id = v.party_id
                GROUP BY p.party_id, p.party_name
                ORDER BY vote_count DESC
            """)
            party_votes = cursor.fetchall()
            print("Fetched vote counts:", party_votes)
            party_votes = [{'party_name': row[0], 'vote_count': row[1]} for row in party_votes]
        except Error as e:
            print(f"Error fetching vote counts: {e}")
            return jsonify({'error': 'Error fetching vote counts'}), 500
        finally:
            cursor.close()
            conn.close()
    return jsonify(party_votes)

@app.route('/search', methods=['POST'])
def search():
    first_name = request.form.get('first_name') or None
    last_name = request.form.get('last_name') or None
    father_name = request.form.get('father_name') or None
    city_id = request.form.get('city_id') or None
    has_voted = request.form.get('has_voted') or None
    gender = request.form.get('gender') or None
    province_id = request.form.get('province_id') or None
    polling_station_id = request.form.get('polling_station_id') or None
    id_number = request.form.get('id_number') or None
    election_id = request.form.get('election_id') or None
    
    if has_voted == 'true':
        has_voted = 1
    elif has_voted == 'false':
        has_voted = 0
    else:
        has_voted = None
    
    if city_id == '':
        city_id = None
    if province_id == '':
        province_id = None
    if polling_station_id == '':
        polling_station_id = None
    if election_id == '':
        election_id = None
    
    voters = []
    columns = []
    provinces = []
    cities = []
    polling_stations = []
    elections = []
    
    conn = get_db_connection()
    if conn:
        try:
            cursor = conn.cursor()
            cursor.execute("SELECT province_id, province_name FROM provinces")
            provinces = cursor.fetchall()
            cursor.execute("SELECT city_id, city_name FROM cities")
            cities = cursor.fetchall()
            cursor.execute("SELECT station_id, station_name FROM polling_stations")
            polling_stations = cursor.fetchall()
            cursor.execute("SELECT election_id, election_name FROM elections")
            elections = cursor.fetchall()
            
            query = "CALL search_voters(%s, %s, %s, %s, %s, %s, %s, %s, %s, %s)"
            params = (first_name, last_name, father_name, city_id, has_voted, gender, 
                     province_id, polling_station_id, id_number, election_id)
            cursor.execute(query, params)
            voters = cursor.fetchall()
            print("Search results:", voters)
            
            columns = [desc[0] for desc in cursor.description]
        except Error as e:
            print(f"Error executing query: {e}")
            flash(f"Error executing search: {e}", "error")
        finally:
            cursor.close()
            conn.close()
    
    return render_template('results_enhanced.html', voters=voters, columns=columns, 
                         provinces=provinces, cities=cities, 
                         polling_stations=polling_stations, elections=elections)

@app.route('/insert', methods=['GET', 'POST'])
def insert():
    cities = []
    polling_stations = []
    message = None
    
    conn = get_db_connection()
    if conn:
        try:
            cursor = conn.cursor()
            cursor.execute("SELECT city_id, city_name FROM cities")
            cities = cursor.fetchall()
            cursor.execute("SELECT station_id, station_name FROM polling_stations")
            polling_stations = cursor.fetchall()
            
            if request.method == 'POST':
                id_number = request.form['id_number']
                first_name = request.form['first_name']
                last_name = request.form['last_name']
                father_name = request.form['father_name']
                gender = request.form['gender']
                address = request.form['address']
                city_id = request.form['city_id']
                polling_station_id = request.form['polling_station_id']
                
                if not all([id_number, first_name, last_name, father_name, gender, address, city_id, polling_station_id]):
                    message = "All fields are required."
                else:
                    query = "CALL insert_voter(%s, %s, %s, %s, %s, %s, %s, %s)"
                    params = (id_number, first_name, last_name, father_name, gender, address, city_id, polling_station_id)
                    cursor.execute(query, params)
                    conn.commit()
                    print("Voter inserted:", id_number)
                    flash("Voter added successfully!", "success")
                    return redirect(url_for('index'))
                    
        except Error as e:
            print(f"Error inserting voter: {e}")
            if e.errno == 1062:
                message = "Error: ID number already exists."
            elif e.errno == 1305:
                message = "Error: Database procedure not found. Please contact the administrator."
            else:
                message = f"Error adding voter: {e}"
        finally:
            cursor.close()
            conn.close()
    
    return render_template('insert.html', cities=cities, polling_stations=polling_stations, message=message)

@app.route('/add_vote', methods=['GET', 'POST'])
def add_vote():
    cities = []
    polling_stations = []
    elections = []
    parties = []
    message = None
    
    conn = get_db_connection()
    if conn:
        try:
            cursor = conn.cursor()
            cursor.execute("SELECT city_id, city_name FROM cities")
            cities = cursor.fetchall()
            cursor.execute("SELECT station_id, station_name FROM polling_stations")
            polling_stations = cursor.fetchall()
            cursor.execute("SELECT election_id, election_name FROM elections WHERE status IN ('Active', 'Upcoming')")
            elections = cursor.fetchall()
            cursor.execute("SELECT party_id, party_name FROM parties")
            parties = cursor.fetchall()
            
            if request.method == 'POST':
                id_number = request.form.get('id_number')
                election_id = request.form.get('election_id')
                polling_station_id = request.form.get('polling_station_id')
                party_id = request.form.get('party_id')
                
                if not all([id_number, election_id, polling_station_id, party_id]):
                    message = "All fields are required."
                    print("Missing form fields:", {
                        'id_number': id_number,
                        'election_id': election_id,
                        'polling_station_id': polling_station_id,
                        'party_id': party_id
                    })
                else:
                    try:
                        query = "CALL insert_vote(%s, %s, %s, %s)"
                        params = (id_number, election_id, polling_station_id, party_id)
                        print("Executing insert_vote with params:", params)
                        cursor.execute(query, params)
                        conn.commit()
                        print(f"Vote added successfully: voter_id={id_number}, election_id={election_id}, party_id={party_id}")
                        flash("Vote added successfully!", "success")
                        return redirect(url_for('index'))
                    except Error as e:
                        conn.rollback()
                        print(f"Error adding vote: {e}")
                        if e.errno == 1062:
                            message = "Error: This voter has already voted in this election."
                        elif e.sqlstate == '45000':
                            message = "Error: Voter not found."
                        elif e.errno == 1305:
                            message = "Error: Database procedure not found. Please contact the administrator."
                        else:
                            message = f"Error recording vote: {e}"
                    
        except Error as e:
            print(f"Error fetching form data: {e}")
            message = f"Error loading form data: {e}"
        finally:
            cursor.close()
            conn.close()
    
    return render_template('add_vote.html', cities=cities, polling_stations=polling_stations, 
                         elections=elections, parties=parties, message=message)

if __name__ == '__main__':
    app.run(debug=True, host='0.0.0.0', port=5000)