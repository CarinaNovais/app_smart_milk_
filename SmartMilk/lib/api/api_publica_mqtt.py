from flask import Flask, request, jsonify
import paho.mqtt.publish as publish
import json 
import base64

app = Flask(__name__)

MQTT_BROKER = "192.168.66.50"
MQTT_PORT = 1883
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
            "login/entrada",
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

@app.route('/cadastro', methods=['POST'])
def cadastro():
    dados = request.get_json()

    nome = dados.get("nome")
    senha = dados.get("senha")
    #cargo = dados.get("cargo")
    idregiao = dados.get("idregiao")
    idtanque = dados.get("idtanque")
    contato = dados.get("contato")
    #foto = dados.get("foto")

    if all(x is not None for x in [nome, senha, idregiao, idtanque, contato]):
    # cargo pode ser None, não verificamos aqui

        publish.single(
            "cadastro/entrada",
            json.dumps(dados),  # converte para JSON
            hostname=MQTT_BROKER,
            port=MQTT_PORT,
            auth={
                'username': MQTT_USERNAME,
                'password': MQTT_PASSWORD
            }
        )
        return jsonify({"status": "cadastro publicado"}), 200
    return jsonify({"erro": "faltam dados obrigatórios"}), 400

@app.route('/perfil/editar_foto', methods=['POST'])
def editar_foto():
    dados = request.get_json()

    nome = dados.get('nome')
    idtanque = dados.get('idtanque')
    foto_base64 = dados.get('foto')

    if not nome or not idtanque or not foto_base64:
        return jsonify({"status": "erro", "mensagem": "Parâmetros insuficientes"}), 400
    
    try:
        publish.single(
            topic="perfil/editar_foto/entrada",  # Tópico correto para a foto
            payload=json.dumps(dados),  # Converte para JSON
            hostname=MQTT_BROKER,
            port=MQTT_PORT,
            auth={
                'username': MQTT_USERNAME,
                'password': MQTT_PASSWORD
            }
        )
        return jsonify({"status": "sucesso", "mensagem": "Foto publicada no MQTT"}), 200
    except Exception as e:
        return jsonify({"status": "erro", "mensagem": f"Erro ao publicar MQTT: {e}"}), 500




if __name__ == "__main__":
    app.run(host="0.0.0.0", port=5000)