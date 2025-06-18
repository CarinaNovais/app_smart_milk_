import paho.mqtt.client as mqtt
import mysql.connector
import json
import jwt
import datetime

#Configurações do JWT
JWT_SECRET = 'mimosa' #chave_secreta_aqui
JWT_ALGORITHM = 'HS256' #algoritmo de criptografia
JWT_EXPIRACAO_MINUTOS = 30 #tempo de expiração do token

#função gerar token JWT
def gerar_token(usuario):
    exp = datetime.datetime.utcnow() + datetime.timedelta(minutes=JWT_EXPIRACAO_MINUTOS)
    payload = {
        'sub': usuario, #quem ta logado
        'exp': exp, #expiraçao do token
        'iat': datetime.datetime.utcnow() #quando foi gerado
    }
    token = jwt.encode(payload, JWT_SECRET, algorithm=JWT_ALGORITHM)
    return token, exp

#funcao verificar se login esta correto no MyQL
def verificar_login(nome, senha, cargo):
    try:
        conn = mysql.connector.connect(
            host="192.168.66.11",
            user="root",
            password="root",
            database="mimosa"
        )
        cursor = conn.cursor()
        consulta = "SELECT * FROM usuario WHERE nome = %s AND senha = %s AND cargo = %s"
        cursor.execute(consulta, (nome, senha, cargo))
        resultado = cursor.fetchone()
        conn.close()
        return resultado is not None
    except Exception as erro:
        print("Erro ao acessar banco:", erro)
        return False

def on_message(client, userdata, msg):
    try:
        #extraindo dados para fazer a validação
        payload = json.loads(msg.payload.decode()) #transforma json em dicionario python
        nome = payload.get("nome")
        senha = payload.get("senha")
        cargo = payload.get("cargo")

        if verificar_login(nome, senha, cargo):
            token, expira_em = gerar_token(nome)
            resposta = {
                "status": "aceito",
                "token": token,
                "expira_em": expira_em.isoformat(),
                "nome": nome
            }
        else:
            resposta = {
                "status": "negado",
                "mensagem": "Credenciais inválidas"
            }

        client.publish("login/resultado", json.dumps(resposta))
        print(f"[MQTT] Resultado enviado: {resposta}")

    except Exception as e:
        print("Erro ao processar login:", e)

# Configurando MQTT
# Isso conecta no broker MQTT e fica escutando o tempo todo por novos logins.
client = mqtt.Client()
client.username_pw_set("csilab", "WhoAmI#2023")
client.on_message = on_message

client.connect("192.168.66.50", 1883)
client.subscribe("login/entrada")

print("🟢 Validador MQTT com sessão JWT rodando...")
client.loop_forever()
