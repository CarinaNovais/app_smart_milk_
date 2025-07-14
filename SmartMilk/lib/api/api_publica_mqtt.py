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

@app.route('/fotoAtualizada', methods=['POST'])
def fotoAtualizada():
    dados = request.get_json()
    
    nome = dados.get("nome")
    foto = dados.get("foto")

    print(f"📷 Base64 (início): {foto[:100]}")


    if all(k is not None for k in[nome,foto]):
        publish.single(
            "fotoAtualizada/entrada",
            json.dumps(dados),  # converte para JSON
            hostname=MQTT_BROKER,
            port=MQTT_PORT,
            auth={
                'username': MQTT_USERNAME,
                'password': MQTT_PASSWORD
            }
        )
        return jsonify({"status": "foto publicada"}), 200
    return jsonify({"erro": "faltam dados obrigatórios"}), 400

@app.route('/editarUsuario', methods=['POST'])
def editar_usuario():
    dados = request.get_json()

    nome = dados.get("nome")
    idtanque = dados.get("idtanque")
    campo = dados.get("campo")     # exemplo: "senha"
    valor = dados.get("valor")     # novo valor para o campo

    if all(x is not None for x in [nome, idtanque, campo, valor]):
        publish.single(
            "editarUsuario/entrada",
            json.dumps(dados),  # envia tudo como está
            hostname=MQTT_BROKER,
            port=MQTT_PORT,
            auth={
                'username': MQTT_USERNAME,
                'password': MQTT_PASSWORD
            }
        )
        return jsonify({"status": "atualização publicada"}), 200

    return jsonify({"erro": "faltam dados obrigatórios"}), 400


if __name__ == "__main__":
    app.run(host="0.0.0.0", port=5000)