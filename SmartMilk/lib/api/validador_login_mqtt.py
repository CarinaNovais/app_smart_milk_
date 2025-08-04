import paho.mqtt.client as mqtt
import mysql.connector
import json
import jwt
import datetime
import base64

#Configurações do JWT
JWT_SECRET = 'mimosa' #chave_secreta_aqui
JWT_ALGORITHM = 'HS256' #algoritmo de criptografia
JWT_EXPIRACAO_MINUTOS = 30 #tempo de expiração do token

# Função para conectar no banco de dados
def conectar_banco():
    return mysql.connector.connect(
        host="192.168.66.13", #ip computador joao
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
def verificar_login(nome, senha, cargo):
    try:
        conn = conectar_banco()
        cursor = conn.cursor()

        if cargo == 0:
            consulta = "SELECT id, nome, senha, idtanque, idregiao FROM usuario WHERE nome = %s AND senha = %s AND cargo = %s"
            cursor.execute(consulta, (nome, senha, cargo))
            resultado = cursor.fetchone()
            conn.close()
            return resultado
        
        elif cargo == 2:
            consulta ="""SELECT usuario.id, usuario.nome, usuario.senha, coletores.placa FROM usuario JOIN coletores ON coletores.coletor = usuario.nome WHERE usuario.nome = %s AND usuario.senha = %s AND usuario.cargo = %s"""
            cursor.execute(consulta, (nome, senha, cargo))
            resultado = cursor.fetchone()
            conn.close()
            return resultado
        else:
            conn.close()
            return None
        
    except Exception as erro:
        print("Erro ao acessar banco:", erro)
        return False
    
def atualizar_usuario(campo, valor, nome, idtanque, cargo):
    try:
        conn = conectar_banco()
        cursor = conn.cursor()

        if cargo == 0:
            query = f"UPDATE usuario SET {campo} = %s WHERE nome = %s AND idtanque = %s"
            cursor.execute(query, (valor, nome, idtanque))
        
        elif cargo == 2:
            if campo == "placa":
                query = f"UPDATE coletores SET {campo} = %s WHERE coletor = %s"
                cursor.execute(query, (valor, nome, cargo))
            else:
                query = f"UPDATE usuario SET {campo} = %s WHERE nome = %s AND cargo = %s"
                cursor.execute(query, (valor, nome, cargo))

        else:
            return False, "Cargo não reconhecido"

        conn.commit()
        conn.close()
        return True, f"{campo} atualizado com sucesso"

    except Exception as erro:
        print(f"Erro ao atualizar {campo}:", erro)
        return False, f"Erro ao atualizar {campo}"


def cadastrar_historico_coleta(dados):
    try:
        conn = conectar_banco()
        cursor = conn.cursor()

        insert = """
        INSERT INTO coleta_tanque
        (produtor, idTanque, idRegiao, ph, temperatura, nivel, amonia, carbono, metano, coletor, placa)
        VALUES (%s, %s, %s, %s, %s, %s, %s, %s, %s,%s,%s)
        """

        valores = (
            dados["nome"],
            dados["idtanque"],
            dados["idregiao"],
            dados["ph"],
            dados["temperatura"],
            dados["nivel"],
            dados["amonia"],
            dados["carbono"],
            dados["metano"],
            dados['coletor'],
            dados['placa'],
        )

        cursor.execute(insert, valores)

        #verifica se o nome do coletor corresponde
        consulta_nome = """SELECT nome FROM usuario
        WHERE idtanque = %s AND idregiao = %s"""
        cursor.execute(consulta_nome,(dados["idtanque"], dados["idregiao"]))
        resultado = cursor.fetchone()
        
        conn.commit()
        cursor.close()
        conn.close()
        return True, "Cadastro de coleta realizado com sucesso"
    
    except Exception as erro:
        print("Erro ao cadastrar coleta:", erro)
        return False, "Erro ao cadastrar coleta"

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
        insert = """ INSERT INTO usuario (nome, senha, idtanque, idregiao, cargo, saldo, litros, contato, foto) VALUES (%s, %s, %s, %s, %s, %s, %s, %s, %s)"""
        cursor.execute(insert, (nome, senha, idtanque, idregiao, cargo, None, None,contato, foto_bytes))


        conn.commit()
        conn.close()
        return True, "Cadastro realizado com sucesso"
    except Exception as erro:
        print("Erro ao cadastrar usuário:", erro)
        return False, "Erro ao cadastrar usuário"


def atualizarFoto(foto_bytes, nome, idusuario): #verificar se esta puxando id do usuario
    try:
        conn = conectar_banco()
        cursor = conn.cursor()

        update = """UPDATE usuario SET foto = %s WHERE nome = %s AND id = %s"""
        cursor.execute(update, (foto_bytes, nome, idusuario))

        conn.commit()
        conn.close()

        return True, "Foto Atualizada com sucesso"
    except Exception as erro:
        print("Erro ao atualizar foto:", erro)
        return False, "Erro ao atualizar foto"


def buscarDadosTanque(nome, idtanque, idregiao):
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
                u.nome = %s AND u.idtanque = %s AND u.idregiao = %s
        """
        cursor.execute(query, (nome, idtanque, idregiao))
        resultado = cursor.fetchone()
        return resultado if resultado else None
    except Exception as erro:
        print("Erro ao buscar dados do tanque:", erro)
        return None
    
def buscarColetas(nome): 
    try:
        nome = nome.strip()
        print("🔍 Nome recebido para busca:", nome)

        conn = conectar_banco()
        cursor = conn.cursor()
       

        query = """SELECT * FROM coleta_tanque WHERE coletor = %s"""
        cursor.execute(query, (nome,))
        resultado = cursor.fetchall()
        print(f"🔎 {len(resultado)} resultados encontrados.")

        return resultado if resultado else None
    except Exception as erro:
        print("Erro ao buscar coletas:", erro)
        return None
    finally:
        conn.close()
    
def formatar_coletas(dados, nome):
    return [
        {
            "produtor": str(linha[0]),
            "idTanque": str(linha[1]),
            "idRegiao": str(linha[2]),
            "ph": f"{linha[3]:.2f}",
            "temperatura": f"{linha[4]:.2f}",
            "nivel": f"{linha[5]:.2f}",
            "amonia": f"{linha[6]:.2f}",
            "carbono": f"{linha[7]:.2f}",
            "metano": f"{linha[8]:.2f}",
            "coletor": nome,
            "placa": str(linha[10]),
        }
        for linha in dados
    ]

def buscarDepositosProdutor(usuario_id):
    try:
        print("🔍 id_usuario recebido para busca:", usuario_id)

        conn = conectar_banco()
        cursor = conn.cursor()

        query = """
       SELECT 
  hdp.usuario_id,
  hdp.idTanque,
  hdp.idRegiao,
  hdp.ph,
  hdp.temperatura,
  hdp.nivel,
  hdp.amonia,
  hdp.carbono,
  hdp.metano,
  hdp.dataDeposito,
  u.nome
FROM historico_deposito_produtor hdp
INNER JOIN usuario u ON hdp.usuario_id = u.id
WHERE u.id = %s;

        """

        cursor.execute(query, (usuario_id,))
        resultado = cursor.fetchall()
        print(f"🔎 {len(resultado)} resultados encontrados.")

        return resultado if resultado else None
    except Exception as erro:
        print("Erro ao buscar depósitos:", erro)
        return None
    finally:
        conn.close()

def formatar_depositos(dados, usuario_id):
    return[
        {
            "usuario_id":usuario_id,
            "idTanque": str(linha[1]),
            "idRegiao": str(linha[2]),
            "ph": str(linha[3]),
            "temperatura": str(linha[4]),
            "nivel": str(linha[5]),
            "amonia": str(linha[6]),
            "carbono": str(linha[7]),
            "metano": str(linha[8]),
            "dataDeposito": str(linha[9]),
            "nome":str(linha[10]),

        }
        for linha in dados
    ]

#funcao que trata todas as mensagens recebidas
def on_message(client, userdata, msg):
    try:
        #extraindo dados para fazer a validação
        payload = json.loads(msg.payload.decode()) #transforma json em dicionario python
        topico = msg.topic

        if topico == "login/entrada":
            nome = payload.get("nome")
            senha = payload.get("senha")
            cargo = payload.get("cargo")
            resultado = verificar_login(nome, senha, cargo)
            print("🔍 Resultado do login:", resultado) 

            if resultado:
                token, expira_em = gerar_token(nome)

                if cargo == 0:
                    # produtor
                    resposta = {
                        "status": "aceito",
                        "token": token,
                        "expira_em": expira_em.isoformat(),
                        "id":resultado[0],
                        "nome": resultado[1],
                        "senha": resultado[2],
                        "idtanque": resultado[3],
                        "idregiao": resultado[4],
                        "cargo":cargo
                    }
                
                elif cargo == 2:
                    # coletor
                    resposta = {
                        "status": "aceito",
                        "token": token,
                        "expira_em": expira_em.isoformat(),
                        "id":resultado[0],
                        "nome": resultado[1],
                        "senha": resultado[2],
                        "placa": resultado[3],
                        "cargo":cargo
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
            foto_base64 = payload.get("foto")  # Pode ser None ou string base64

            if foto_base64:
                try:
                    foto_bytes = base64.b64decode(foto_base64)
                except Exception as e:
                    print("Erro ao decodificar foto:", e)
                    foto_bytes = None
            else:
                foto_bytes = None  # Aqui você define foto_bytes como None para foto null

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
            idtanque = payload.get("idtanque")
            idregiao = payload.get("idregiao")
            dados = buscarDadosTanque(nome, idtanque,idregiao)

            if dados:
                resposta = {
                    "status": "ok",
                    "dados": {
                        "nome": nome,
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
        
        elif topico == "fotoAtualizada/entrada":
            print(f"📨 Payload recebido: {payload}")
            print(f"📷 Base64 (início): {payload.get('foto', '')[:100]}")
            
            nome = payload.get("nome")
            idusuario = payload.get("id")
            foto_base64 = payload.get("foto")

            if not idusuario or not foto_base64 or not nome:
                resposta = {"status": "negado", "mensagem": "Dados incompletos para atualizar foto"}
                client.publish("fotoAtualizada/resultado", json.dumps(resposta))
                return

            try:
                foto_bytes = base64.b64decode(foto_base64, validate=True)
                print(f"🧪 Imagem decodificada com {len(foto_bytes)} bytes")

                if len(foto_bytes) > 16_777_215:  # limite mediumblob 16MB
                    resposta = {"status": "negado", "mensagem": "Imagem excede o limite de 16MB"}
                else:
                    sucesso, mensagem = atualizarFoto(foto_bytes, nome, idusuario)
                    resposta = {
                        "status": "aceito" if sucesso else "negado",
                        "mensagem": mensagem
                    }

            except Exception as erro:
                print("Erro na atualização da foto:", erro)
                resposta = {"status": "negado", "mensagem": "Erro ao decodificar ou atualizar foto"}
            
            client.publish("fotoAtualizada/resultado", json.dumps(resposta))
            print(f"📤 Resposta enviada ao app: {resposta}")


        elif topico == "editarUsuario/entrada":
            campo = payload.get("campo") 
            valor = payload.get("valor")
            nome = payload.get("nome")
            cargo = payload.get("cargo")
            idtanque = payload.get("idtanque")

            if not campo or not valor or not nome or cargo is None:
                resposta = {"status": "negado", "mensagem": "Dados incompletos"}

            elif cargo == 0 and not idtanque: #cargo 0 = produtor → precisa de idtanque
               resposta = {"status": "negado", "mensagem": "Produtor deve ter idtanque"}
            else:
                sucesso, mensagem = atualizar_usuario(campo, valor, nome, idtanque,cargo)
                resposta = {
                    "status": "aceito" if sucesso else "negado",
                    "mensagem": mensagem,
                    "campo":campo,
                    "valor":valor
                }

            client.publish("editarUsuario/resultado", json.dumps(resposta))
            print(f"[MQTT] Atualização de usuário enviada: {resposta}")
            
        elif topico == "cadastroHistoricoColeta/entrada":
            sucesso, mensagem = cadastrar_historico_coleta(payload)

            resposta = {
                "status": "aceito" if sucesso else "negado",
                "mensagem": mensagem
            }

            client.publish("cadastroHistoricoColeta/resultado", json.dumps(resposta))
            print(f"[MQTT] Resultado histórico enviado: {resposta}")
          
        elif topico == "tanqueIdentificado/entrada": #qrcode
            print("✅ Mensagem recebida no tópico tanqueIdentificado/entrada")
            nome = payload.get("nome")
            idregiao = payload.get("idregiao")
            idtanque = payload.get("idtanque")
            
            try:
                idtanque = int(idtanque)
                idregiao = int(idregiao)
            except (TypeError, ValueError):
                resposta = {"status": "negado", "mensagem": "ID inválido"}
                client.publish("tanqueIdentificado/resultado", json.dumps(resposta))
                return
    
            if not nome or not idtanque or not idregiao:
                resposta = {"status": "negado", "mensagem": "Dados incompletos"}
                client.publish("tanqueIdentificado/resultado", json.dumps(resposta))
                return
            
            dados = buscarDadosTanque(nome,idtanque,idregiao)

            if dados:
                resposta = {
                    "status": "ok",
                    "dados": {
                    "nome":nome,
                    "idtanque": str(dados[0]),
                    "idregiao": str(dados[1]),
                    "ph": f"{dados[2]:.2f}",      # formatado como string com 2 casas decimais
                    "temp": f"{dados[3]:.2f}",
                    "nivel": f"{dados[4]:.2f}",
                    "amonia": f"{dados[5]:.2f}",
                    "carbono": f"{dados[6]:.2f}",
                    "metano": f"{dados[7]:.2f}",
                    }
                }

            else:
                resposta = {
                    "status": "negado",
                    "mensagem": "Tanque não identificado"
                }

            client.publish("tanqueIdentificado/resultado", json.dumps(resposta))

        elif topico == "buscarColetas/entrada":
            print("✅ Mensagem recebida no tópico buscarColetas/entrada")
            nome = payload.get("nome")

            dados = buscarColetas(nome)

            if dados:
                resposta = {
                    "status": "ok",
                    "dados": formatar_coletas(dados, nome)
                }
            else:
                resposta = {
                    "status": "vazio",
                    "mensagem": f"Nenhuma coleta encontrada para o produtor '{nome}'."
                }

            client.publish("buscarColetas/resultado", json.dumps(resposta, default=str))
            print(f"[MQTT] Dados enviados para 'buscarColetas/resultado': {resposta}")
        
        elif topico == "buscarDepositosProdutor/entrada":

            print("✅ Mensagem recebida no tópico buscarDepositosProdutor/entrada")
            usuario_id = payload.get("usuario_id")

            dados = buscarDepositosProdutor(usuario_id)

            if dados:
                resposta = {
                    "status": "ok",
                    "dados": formatar_depositos(dados, usuario_id)
                }
            else:
                resposta = {
                    "status": "vazio",
                    "mensagem": f"Nenhum deposito encontrado para o produtor de id '{usuario_id}'."
                }
        else:
            print(f"[MQTT] Tópico desconhecido: {topico}")
        client.publish("buscarDepositosProdutor/resultado", json.dumps(resposta, default=str))
        print(f"[MQTT] Dados enviados para 'buscarDepositosProdutor/resultado': {resposta}")
        

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
client.subscribe("fotoAtualizada/entrada")
client.subscribe("editarUsuario/entrada")
client.subscribe("tanqueIdentificado/entrada")
client.subscribe("cadastroHistoricoColeta/entrada")
client.subscribe("buscarColetas/entrada")

client.subscribe("buscarDepositosProdutor/entrada")

print("🟢 Validador MQTT com sessão JWT rodando...")
client.loop_forever()