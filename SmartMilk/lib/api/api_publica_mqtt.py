from flask import Flask, request, jsonify, Response
from werkzeug.exceptions import RequestEntityTooLarge
from flask_cors import CORS
import mysql.connector
import paho.mqtt.publish as publish
import json
import base64
import os

app = Flask(__name__)
CORS(app)

API_BASE_URL = os.getenv("API_BASE_URL", "http://localhost:5000")

def conectar_banco():
    return mysql.connector.connect(
        host="192.168.66.13", #ip computador joao
        user="root",
        password="root",
        database="mimosa"
    )

MQTT_BROKER = "192.168.66.50"
MQTT_PORT = 1883
MQTT_USERNAME = "csilab"
MQTT_PASSWORD = "WhoAmI#2023"

# Limite máximo para o corpo da requisição (20MB)
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
        idusuario = dados.get("id")

        if not all(k for k in [nome, foto_base64, idusuario]):
            return jsonify({"erro": "faltam dados obrigatórios"}), 400


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

    id = dados.get("id")
    nome = dados.get("nome")
    # idtanque = dados.get("idtanque")
    cargo = dados.get("cargo")
    campo = dados.get("campo")     # exemplo: "senha"
    valor = dados.get("valor")     # novo valor para o campo

    print("📥 Dados recebidos:", dados)
    
    if nome is None or campo is None or valor is None or cargo is None or id is None:
        return jsonify({"erro": "Faltam dados obrigatórios"}), 400

    # Produtor precisa de idtanque
    # if cargo == 0 and not idtanque:
    #     return jsonify({"erro": "Produtor deve ter um idtanque"}), 400
    
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

@app.route('/deletarVaca', methods=['POST'])
def deletar_vaca():
    dados = request.get_json()

    usuario_id= dados.get("usuario_id")
    vaca_id = dados.get("vaca_id")

    print("📥 Dados recebidos:", dados)
    
    if vaca_id is None or usuario_id is None:
        return jsonify({"erro": "Faltam dados obrigatórios"}), 400
    
    publish.single(
        "deletarVaca/entrada",
        json.dumps(dados), 
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
    
@app.route('/cadastroVaca', methods=['POST'])
def cadastroVacas():
    dados = request.get_json()
    
    usuario_id = dados.get("usuario_id")
    nome = dados.get("nome", "").strip()
    brinco = dados.get("brinco")
    crias = dados.get("crias")
    origem = dados.get("origem", "").strip()
    estado = dados.get("estado", "").strip()

    if all(x is not None for x in [nome, brinco, crias, origem, estado, usuario_id]):

        publish.single(
            "cadastroVaca/entrada",
            json.dumps(dados),  # converte para JSON
            hostname=MQTT_BROKER,
            port=MQTT_PORT,
            auth={
                'username': MQTT_USERNAME,
                'password': MQTT_PASSWORD
            }
        )
        return jsonify({"status": "cadastro de vaca publicado"}), 200
    return jsonify({"erro": "faltam dados obrigatórios"}), 400

@app.route('/editarVaca', methods=['POST'])
def editar_vaca():
    dados = request.get_json()

    usuario_id = dados.get("usuario_id") #id do produtor
    vaca_id = dados.get("vaca_id")
    campo = dados.get("campo")     # exemplo: "senha"
    valor = dados.get("valor")     # novo valor para o campo

    print("📥 Dados recebidos:", dados)
    
    if not campo or not valor or not usuario_id or not vaca_id:
        return jsonify({"erro": "Faltam dados obrigatórios"}), 400

    try:
        publish.single(
            "editarVaca/entrada",
            json.dumps(dados),  # envia tudo como está
            hostname=MQTT_BROKER,
            port=MQTT_PORT,
            auth={
                'username': MQTT_USERNAME,
                'password': MQTT_PASSWORD
            }
        )
    except Exception as e:
        return jsonify({"erro": f"Falha ao publicar MQTT: {e}"}), 500
        # return jsonify({"status": "atualização da vaca publicada"}), 200

#atualizar status do tanque
@app.route('/atualizarStatusTanque', methods=['POST'])
def atualizar_status_tanque():
    dados = request.get_json()
    idtanque = dados.get("idtanque")
    campo = dados.get("campo")
    valor = dados.get("valor")

    if not idtanque or not campo or not valor:
        return jsonify({"erro": "Faltam dados obrigatórios"}), 400
    
    publish.single(
        "atualizarStatusTanque/entrada",
        json.dumps(dados),
        hostname=MQTT_BROKER,
        port=MQTT_PORT,
        auth={
            'username': MQTT_USERNAME,
            'password': MQTT_PASSWORD
        }
    )
    return jsonify({"status": "atualização do status do tanque publicada"}), 200    
@app.route('/pegandoTanque', methods=['POST'])
def pegando_tanque():
    dados = request.get_json()
    idregiao = dados.get("idregiao")
    idtanque = dados.get("idtanque")
    produtor_id = dados.get("produtor_id")
    nome = dados.get("nome")
    coletor_id = dados.get("coletor_id")

    if  not idtanque or not idregiao or not produtor_id or not nome or not coletor_id:
        return jsonify({"erro": "Faltam dados obrigatórios"}), 400

    publish.single(
        "pegandoTanque/entrada",
        json.dumps(dados),
        hostname=MQTT_BROKER,
        port=MQTT_PORT,
        auth={'username': MQTT_USERNAME,'password': MQTT_PASSWORD}
    )
    return jsonify({"status": "pegando tanque publicada"}), 200


# =========================
# HTTP direto p/ Avisos (sem MQTT)
# =========================


# @app.route("/aviso")
# def aviso_unico():
#     idtanque = request.args.get("idtanque", type=int)
#     idregiao = request.args.get("idregiao", type=int)

#     if idtanque is None or idregiao is None:
#         return jsonify({"erro": "informe idtanque e idregiao"}), 400

#     cn = cur = None
#     try:
#         cn = conectar_banco()
#         cur = cn.cursor()
#         # pega o primeiro que encontrar 
#         cur.execute("""
#             SELECT publicacao
#             FROM `id`
#             WHERE idtanque=%s OR idregiao=%s
#             LIMIT 1
#         """, (idtanque, idregiao))
#         row = cur.fetchone()
#         if not row or not row[0]:
#             return jsonify({"erro": "nenhuma imagem encontrada"}), 404

#         blob = row[0]
#         # troque para "image/jpeg" se as imagens forem JPEG e etc
#         return Response(blob, mimetype="image/png")
#     except Exception as e:
#         print("erro /aviso:", e)
#         return jsonify({"erro": "falha interna"}), 500
#     finally:
#         if cur: cur.close()
#         if cn: cn.close()
@app.route("/aviso")
def aviso_unico():
    idtanque = request.args.get("idtanque", type=int)
    idregiao = request.args.get("idregiao", type=int)
    if idtanque is None or idregiao is None:
        return jsonify({"erro": "informe idtanque e idregiao"}), 400

    cn = cur = None
    try:
        cn = conectar_banco()
        # BLOB em bytes puros
        cur = cn.cursor(raw=True)

        cur.execute("""
            SELECT publicacao
            FROM `id`
            WHERE idtanque = %s AND idregiao = %s
            LIMIT 1
        """, (idtanque, idregiao))
        row = cur.fetchone()

        if not row or not row[0]:
            return jsonify({"erro": "nenhuma imagem encontrada"}), 404

        blob = row[0]
        # força tipo bytes (caso venha memoryview/bytearray)
        try:
            blob = bytes(blob)
        except Exception as conv_err:
            print("[/aviso] erro convertendo blob para bytes:", conv_err)
            return jsonify({"erro": "imagem inválida no banco"}), 500

        resp = Response(blob, mimetype="image/png")  # PNG
        resp.headers["Content-Length"] = str(len(blob))
        resp.headers["Cache-Control"] = "no-store, no-cache, must-revalidate, max-age=0"
        resp.headers["Pragma"] = "no-cache"
        return resp

    except Exception as e:
        print("erro /aviso:", repr(e))
        return jsonify({"erro": "falha interna"}), 500
    finally:
        if cur: cur.close()
        if cn: cn.close()

if __name__ == "__main__":
    app.run(host="0.0.0.0", port=5000)