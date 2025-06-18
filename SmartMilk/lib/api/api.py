from flask import Flask, request, jsonify
import paho.mqtt.publish as publish
import json 

app = Flask(__name__)

MQTT_BROKER = "192.168.66.50"
MQTT_PORT = 1883
MQTT_TOPIC = "login/entrada"
MQTT_USERNAME = "csilab"
MQTT_PASSWORD = "WhoAmI#2023"

@app.route('/login', methods=['POST'])
def login():
    dados = request.get_json()

    nome = dados.get("nome")
    senha = dados.get("senha")
    cargo = dados.get("cargo")

    if nome and senha and cargo is not None:
        publish.single(
            MQTT_TOPIC,
            json.dumps(dados),  # converte para JSON
            hostname=MQTT_BROKER,
            port=MQTT_PORT,
            auth={
                'username': MQTT_USERNAME,
                'password': MQTT_PASSWORD
            }
        )
        return jsonify({"status": "login publicado"}), 200
    return jsonify({"erro": "faltam dados obrigatórios"}), 400

if __name__ == "__main__":
    app.run(host="0.0.0.0", port=5000)
