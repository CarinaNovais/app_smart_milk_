import paho.mqtt.client as mqtt
import mysql.connector
import json
import jwt
import datetime

#Configurações do JWT
JWT_SECRET = 'mimosa' #chave_secreta_aqui
JWT_ALGORITHM = 'HS256' #algoritmo de criptografia
JWT_EXPIRACAO_MINUTOS = 30 #tempo de expiração do token

# Função para conectar no banco de dados
def conectar_banco():
    return mysql.connector.connect(
        host="192.168.66.17", #ip computador joao
        user="root",
        password="root",
        database="mimosa"
    )

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
#banco ipJoao
def verificar_login(nome, senha):
    try:
        conn = conectar_banco()
        cursor = conn.cursor()
        consulta = "SELECT nome, senha, idtanque, idregiao FROM usuario WHERE nome = %s AND senha = %s"
        cursor.execute(consulta, (nome, senha))
        resultado = cursor.fetchone()
        conn.close()
        return resultado
    except Exception as erro:
        print("Erro ao acessar banco:", erro)
        return False
    
def cadastrar_usuario(nome, senha, idtanque, idregiao,  cargo, contato, foto_bytes=None):
    try:
        conn = conectar_banco()
        cursor = conn.cursor()

        # Verifica se já existe usuário com esse nome
        cursor.execute("SELECT * FROM usuario WHERE nome = %s", (nome,))
        if cursor.fetchone():
            conn.close()
            return False, "Nome de usuário já cadastrado"
        
         # Verifica se o par (idTanque, idRegiao) existe na tabela 'id'
        verifica_ids = "SELECT 1 FROM id WHERE idtanque = %s AND idregiao = %s"
        cursor.execute(verifica_ids, (idtanque, idregiao))
        if not cursor.fetchone():
            conn.close()
            return False, "Tanque e/ou região inválidos"

        # Insere novo usuário
        insert = """ INSERT INTO usuario (nome, senha, idtanque, idregiao, cargo, saldo, litros, contato, foto) VALUES (%s, %s, %s, %s, %s, NULL, NULL, %s, %s)"""
        cursor.execute(insert, (nome, senha, idtanque, idregiao, cargo, contato, foto_bytes))



        conn.commit()
        conn.close()
        return True, "Cadastro realizado com sucesso"
    except Exception as erro:
        print("Erro ao cadastrar usuário:", erro)
        return False, "Erro ao cadastrar usuário"

        

def buscarDadosTanque(nome):
    try:
        conn = conectar_banco()
        cursor = conn.cursor()
        query = """
            SELECT 
                t.idtanque,
                t.idregiao,
                t.ph,
                t.temp,
                t.nivel,  
                t.amonia,
                t.carbono,                       
                t.metano
            FROM 
                usuario u
            JOIN 
                tanque t ON u.idtanque = t.idtanque AND u.idregiao = t.idregiao
            WHERE 
                u.nome = %s
        """
        cursor.execute(query,(nome,))
        resultado = cursor.fetchone()
        return resultado if resultado else None
    except Exception as erro:
            print("Erro ao buscar dados do tanque:", erro)
            return None

#funcao que trata todas as mensagens recebidas
def on_message(client, userdata, msg):
    try:
        #extraindo dados para fazer a validação
        payload = json.loads(msg.payload.decode()) #transforma json em dicionario python
        topico = msg.topic

        if topico == "login/entrada":
            nome = payload.get("nome")
            senha = payload.get("senha")
           # cargo = payload.get("cargo")
            resultado = verificar_login(nome,senha)
            print("🔍 Resultado do login:", resultado)  # 👈 AQUI

            if resultado:
                token, expira_em = gerar_token(nome)
                resposta = {
                    "status": "aceito",
                    "token": token,
                    "expira_em": expira_em.isoformat(),
                    "nome": resultado[0],
                    "idtanque": resultado[2],
                    "idregiao": resultado[3],
                    "senha": resultado[1]
                }
            else:
                resposta = {
                "status": "negado",
                "mensagem": "Credenciais inválidas"
            }

            client.publish("login/resultado", json.dumps(resposta))
            print(f"[MQTT] Resultado enviado: {resposta}")

        elif topico == "cadastro/entrada":

            nome = payload.get("nome")
            senha = payload.get("senha")
            cargo = payload.get("cargo")
            idtanque = int(payload.get("idtanque"))
            idregiao = int(payload.get("idregiao"))
            contato = payload.get("contato")
            foto_base64 = payload.get("foto")

            if foto_base64:
                import base64
                try:
                    foto_bytes = base64.b64decode(foto_base64)
                except Exception as e:
                        print("Erro ao decodificar foto:", e)
                        foto_bytes = None
            else:
                foto_bytes = None

            sucesso, mensagem = cadastrar_usuario(nome, senha, idtanque, idregiao, cargo, contato, foto_bytes)


            if sucesso:
                resposta = {
                    "status": "aceito",
                    "mensagem": mensagem
                }
            else:
                resposta = {
                    "status": "negado",
                    "mensagem": mensagem
                }

            client.publish("cadastro/resultado", json.dumps(resposta))
            print(f"[MQTT] Resultado CADASTRO enviado: {resposta}")

        elif topico == "tanque/buscar":
            nome = payload.get("nome")
            dados = buscarDadosTanque(nome)

            if dados:
                resposta = {
                    "status": "ok",
                    "dados": {
                        "idtanque": dados[0],
                        "idregiao": dados[1],
                        "ph": dados[2],
                        "temp": dados[3],
                        "nivel": dados[4],
                        "amonia": dados[5],
                        "carbono": dados[6],
                        "metano": dados[7]
                    }
                }
            else: 
                resposta = {
                    "status": "erro",
                    "mensagem": "Usuário ou tanque não encontrado"
                }
            client.publish("tanque/resposta", json.dumps(resposta))
            print(f"[MQTT] Dados do tanque enviados para 'tanque/resposta': {resposta}")

        else:
            print(f"[MQTT] Tópico desconhecido: {topico}")

    except Exception as e:
        print("❌ Erro ao processar mensagem:", e)


# Configurando MQTT
# Isso conecta no broker MQTT e fica escutando o tempo todo
client = mqtt.Client()
client.username_pw_set("csilab", "WhoAmI#2023")
client.on_message = on_message

client.connect("192.168.66.50", 1883)
client.subscribe("login/entrada")
client.subscribe("cadastro/entrada")
client.subscribe("tanque/buscar")


print("🟢 Validador MQTT com sessão JWT rodando...")
client.loop_forever()