from flask import Flask, jsonify
from pymongo import MongoClient
import os

app = Flask(__name__)

# Conexión a MongoDB usando las variables de entorno
mongo_uri = os.getenv("MONGO_URI")
client = MongoClient(mongo_uri)
db = client.testdb

@app.route('/')
def hello():
    return "¡Hola desde el contenedor Flask!"

@app.route('/users')
def get_users():
    users = list(db.users.find({}, {'_id': 0}))
    return jsonify(users)

@app.route('/add/<name>')
def add_user(name):
    db.users.insert_one({"name": name})
    return f"Usuario {name} añadido"

if __name__ == '__main__':
    app.run(host='0.0.0.0', port=5000)
