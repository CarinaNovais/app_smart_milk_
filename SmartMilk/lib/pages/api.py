from flask import Flask, request, jsonify
from mqtt import MQTTService

app = Flask(__name__)
mqtt_service = MQTTService(usuario='csilab', senha='WhoAmI#2023')
mqtt_service.conectar_mqtt()

@app.route("/login", methods=["POST"])
def login():
    dados = request.get_json()

    # Validação simples
    if not dados:
        return jsonify({"erro": "Requisição sem dados"}), 400

    usuario = dados.get("usuario")
    senha = dados.get("senha")
    idCargo = dados.get("idCargo")

    if not all([usuario, senha, idCargo]):
        return jsonify({"erro": "Campos incompletos"}), 400

    mqtt_service.testar_publicacao(usuario, senha, idCargo)

    return jsonify({"mensagem": "Login enviado para o MQTT"}), 200

if __name__ == "__main__":
    app.run(host="0.0.0.0", port=5000)
