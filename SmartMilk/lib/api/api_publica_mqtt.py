from flask import Flask, request, jsonify
from werkzeug.exceptions import RequestEntityTooLarge
import paho.mqtt.publish as publish
import json 
import base64

app = Flask(__name__)

MQTT_BROKER = "192.168.66.50"
MQTT_PORT = 1883
MQTT_USERNAME = "csilab"
MQTT_PASSWORD = "WhoAmI#2023"

# Limite máximo para o corpo da requisição (exemplo: 20MB)
app.config['MAX_CONTENT_LENGTH'] = 20 * 1024 * 1024  # 20 megabytes

# Tratamento do erro 413
@app.errorhandler(RequestEntityTooLarge)
def handle_file_too_large(e):
    return jsonify({"erro": "Arquivo muito grande. Tamanho máximo permitido é 20MB."}), 413

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
    try:
        dados = request.get_json()

        nome = dados.get("nome")
        foto_base64 = dados.get("foto")
        # idtanque = dados.get("idtanque")
        idusuario = dados.get("id")

        if not all(k is not None for k in[nome, foto_base64, idusuario]):
            return jsonify({"erro": "faltam dados obrigatórios"}),400

        #log do tamanho da imagem recebida
        print(f"Tamanho da imagem recebida: {len(foto_base64)} caracteres")

        # Verificar tamanho da imagem (base64 é ~33% maior que bytes)
        max_base64_length = int(20 * 1024 * 1024 * 4 / 3)  # 20 MB em base64
        if len(foto_base64) > max_base64_length:
            return jsonify({"erro": "Imagem muito grande. Limite: 20MB"}), 413

        #print(f"📷 Base64 (início): {foto[:100]}")
        try:
            imagem_bytes = base64.b64decode(foto_base64)
        except Exception as erro_decodificacao:
            print(f"❌ Erro ao decodificar imagem: {erro_decodificacao}")
            return jsonify({"status": "negado", "mensagem": "Erro ao processar imagem"}), 400

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
    except Exception as e:
        print(f"Erro ao processar /fotoAtualizada: {e}")
        return jsonify({"erro": "Erro interno no servidor"}), 500

@app.route('/editarUsuario', methods=['POST'])
def editar_usuario():
    dados = request.get_json()

    nome = dados.get("nome")
    idtanque = dados.get("idtanque")
    cargo = dados.get("cargo")
    campo = dados.get("campo")     # exemplo: "senha"
    valor = dados.get("valor")     # novo valor para o campo

    print("📥 Dados recebidos:", dados)
    
    if nome is None or campo is None or valor is None or cargo is None:
        return jsonify({"erro": "Faltam dados obrigatórios"}), 400

    # Produtor precisa de idtanque
    if cargo == 0 and not idtanque:
        return jsonify({"erro": "Produtor deve ter um idtanque"}), 400
    
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


@app.route('/qrCode', methods=['POST'])
def qrCode():
    dados = request.get_json()
    try:
        id_tanque = int(dados.get("idtanque",0))
        id_regiao =int(dados.get("idregiao",0))
        dono = str(dados.get("nome","")).strip()

        if id_tanque is None or dono is None or id_regiao is None:
            return jsonify({"erro": "Faltam dados obrigatórios: idtanque ou nome"}), 400

        payload = {
            "idtanque": id_tanque,
            "idregiao": id_regiao,
            "nome": dono
        }

        publish.single(
            "tanqueIdentificado/entrada",
            json.dumps(payload), 
            hostname=MQTT_BROKER,
            port=MQTT_PORT,
            auth={
                'username': MQTT_USERNAME,
                'password': MQTT_PASSWORD
            }
        )
        print(f"✅ QR Code publicado no tópico MQTT: tanque/identificado -> {dados}")
        return jsonify({"status": "QR Code publicado com sucesso"}), 200

    except Exception as e:
        print(f"❌ Erro ao publicar MQTT: {e}")
        return jsonify({"erro": "Erro ao publicar no MQTT"}), 500

@app.route('/cadastroHistoricoColeta', methods=['POST'])
def historico_coleta():
    try:
        dados = request.get_json()

        campos_necessarios = [
            "nome", "idtanque", "idregiao", "ph",
            "temperatura", "nivel", "amonia", "carbono", "metano","coletor","placa"
        ]

        for campo in campos_necessarios:
            if campo not in dados:
                return jsonify({"erro": f"Campo '{campo}' ausente."}), 400
            
        publish.single(
            "cadastroHistoricoColeta/entrada",
                json.dumps(dados),
                hostname=MQTT_BROKER,
                port=MQTT_PORT,
                auth={
                    'username': MQTT_USERNAME,
                    'password': MQTT_PASSWORD
                }  
        )

        return jsonify({"status": "coleta publicada"}), 200
    except Exception as e:
        print(f"❌ Erro ao publicar coleta: {e}")
        return jsonify({"erro": "Erro ao publicar a coleta"}), 500

    
if __name__ == "__main__":
    app.run(host="0.0.0.0", port=5000)