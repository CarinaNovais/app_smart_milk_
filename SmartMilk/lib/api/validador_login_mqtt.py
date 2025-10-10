from calendar import c
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
        host="192.168.12.102", #ip computador joao
        user="root",
        password="root",
        database="mimosa"
    )

#celular ##arrumar ip
# def conectar_banco():
#     return mysql.connector.connect(
#         host="192.168.244.36", #ip computador joao
#         user="root",
#         password="root",
#         database="mimosa"
#     )



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
            consulta = "SELECT id, nome, senha, idtanque, idregiao, contato, foto FROM usuario WHERE nome = %s AND senha = %s AND cargo = %s"
            cursor.execute(consulta, (nome, senha, cargo))
            resultado = cursor.fetchone()
            conn.close()
            return resultado
        
        elif cargo == 2:
            consulta ="""SELECT usuario.id, usuario.nome, usuario.senha,usuario.idregiao, coletores.placa, usuario.contato, usuario.foto FROM usuario JOIN coletores ON coletores.coletor = usuario.nome WHERE usuario.nome = %s AND usuario.senha = %s AND usuario.cargo = %s"""
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
    
def atualizar_usuario(campo, valor, nome, cargo, id):
    try:
        conn = conectar_banco()
        cursor = conn.cursor()

        if cargo == 0:
            query = f"UPDATE usuario SET {campo} = %s WHERE nome = %s AND id = %s"
            cursor.execute(query, (valor, nome, id))
        
        elif cargo == 2:
            if campo == "placa":
                query = f"UPDATE coletores SET {campo} = %s WHERE coletor = %s AND id = %s"
                cursor.execute(query, (valor, nome, id))
            else:
                query = f"UPDATE usuario SET {campo} = %s WHERE nome = %s AND cargo = %s AND id = %s"
                cursor.execute(query, (valor, nome, cargo, id))

        else:
            return False, "Cargo não reconhecido"

        conn.commit()
        conn.close()
        return True, f"{campo} atualizado com sucesso"

    except Exception as erro:
        print(f"Erro ao atualizar {campo}:", erro)
        return False, f"Erro ao atualizar {campo}"

def atualizar_vaca(campo, valor, id, idVaca):
    try:
        conn = conectar_banco()
        cursor = conn.cursor()
        
        query = f"UPDATE vacas SET {campo} = %s WHERE vacas.usuario_id = %s AND vacas.id = %s"
        cursor.execute(query, (valor, id, idVaca))

        conn.commit()
        conn.close()
        return True, f"{campo} atualizado com sucesso"

    except Exception as erro:
        print(f"Erro ao atualizar {campo}:", erro)
        return False, f"Erro ao atualizar {campo}"

def deletar_vaca(usuario_id, vaca_id):
    try:
        conn = conectar_banco()
        cursor = conn.cursor()
        
        query = "DELETE FROM vacas WHERE vacas.usuario_id = %s AND vacas.id = %s"
        cursor.execute(query, (usuario_id, vaca_id))

        conn.commit()
        conn.close()
        return True, f"Vaca com ID {vaca_id} deletada com sucesso."

    except Exception as erro:
        print(f"Erro ao deletar vaca: {erro}")
        return False, f"Erro ao deletar vaca: {erro}"

#status- (a ser analisado)
def atualizar_status_tanque(idtanque, campo, valor):
    try:
        conn = conectar_banco()
        cursor = conn.cursor()

        query = f"UPDATE tanque SET {campo} = %s WHERE idtanque = %s"
        cursor.execute(query, (valor, idtanque))

        conn.commit()
        conn.close()
        return True, f"{campo} atualizado com sucesso"

    except Exception as erro:
        print(f"Erro ao atualizar {campo}:", erro)
        return False, f"Erro ao atualizar {campo}"

def cadastrar_historico_coleta(dados):
    conn = None
    cursor = None
    try:
        # validação mínima
        # required = ["nome","idtanque","idregiao","ph","temperatura","nivel",
        #             "amonia","carbono","metano","coletor","placa"]
        # faltando = [k for k in required if k not in dados]
        # if faltando:
        #     return False, f"Campos obrigatórios ausentes: {', '.join(faltando)}"

        conn = conectar_banco()
        cursor = conn.cursor()

        insert_sql = """
            INSERT INTO coleta_tanque
                (produtor, idtanque, idregiao, ph, temperatura, nivel,
                 amonia, carbono, metano, coletor, placa)
            VALUES (%s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s)
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
            dados["coletor"],
            dados["placa"],
        )
        cursor.execute(insert_sql, valores)

        update_sql = """
            UPDATE tanque
               SET status_tanque = %s
             WHERE idtanque = %s AND idregiao = %s
        """
        cursor.execute(update_sql, ('coletado', dados["idtanque"], dados["idregiao"]))

        # Se precisar zerar campos do tanque após coleta, descomente e mantenha padronização:
        # cursor.execute("""
        #     UPDATE tanque
        #        SET ph=NULL, temperatura=NULL, nivel=NULL, amonia=NULL,
        #            carbono=NULL, metano=NULL
        #      WHERE idtanque=%s AND idregiao=%s
        # """, (dados["idtanque"], dados["idregiao"]))

        conn.commit()
        return True, "Cadastro de coleta realizado com sucesso"

    except Exception as e:
        if conn:
            try:
                conn.rollback()
            except Exception:
                pass
        # Em prod, logue 'e' ao invés de expor:
        return False, f"Erro ao cadastrar coleta: {e}"

    finally:
        if cursor:
            try:
                cursor.close()
            except Exception:
                pass
        if conn:
            try:
                conn.close()
            except Exception:
                pass


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
def cadastrar_vaca(nome, brinco, crias, origem,estado,usuario_id):
    try:
        conn = conectar_banco()
        cursor = conn.cursor()

        # Verifica se já existe vaca com esse nome e nesse dono 
        cursor.execute("SELECT * FROM vacas WHERE nome = %s AND usuario_id = %s", (nome, usuario_id))
        if cursor.fetchone():
            conn.close()
            return False, "Nome de vaca já cadastrado com esse dono"

        # Insere nova vaca
        insert = """ INSERT INTO vacas (nome, brinco, crias, origem,estado, usuario_id) VALUES (%s, %s, %s, %s, %s,%s)"""
        cursor.execute(insert, (nome, brinco, crias, origem,estado,usuario_id))


        conn.commit()
        conn.close()
        return True, "Cadastro da vaca realizado com sucesso"
    except Exception as erro:
        print("Erro ao cadastrar vaca:", erro)
        return False, "Erro ao cadastrar vaca"

def buscarDevolutivas(idtanque):
    try:
        print("Id tanque recebido para busca:", idtanque)
        conn = conectar_banco()
        cursor = conn.cursor()
        
        query = """SELECT ld.*
            FROM lab_devolutiva AS ld
            JOIN coleta_tanque AS ct
            ON ct.id = ld.coleta_id
            WHERE ct.idTanque = %s;
            """

        cursor.execute(query, (idtanque,))
        resultado = cursor.fetchall()
        print(f"🔎 {len(resultado)} resultados encontrados.")
        conn.close()
        return resultado if resultado else None
    except Exception as erro:
        print("Erro ao buscar devolutivas:", erro)
        return None
    finally:
        try:
            cursor.close()
        except Exception:
            pass
        try:
            conn.close()
        except Exception:
            pass

def buscarVacas(usuario_id): 
    try:
        print("Id recebido para busca:", usuario_id)

        conn = conectar_banco()
        cursor = conn.cursor()
       
        query = """SELECT * FROM vacas WHERE usuario_id = %s"""
        cursor.execute(query, (usuario_id,))
        resultado = cursor.fetchall()
        print(f"🔎 {len(resultado)} resultados encontrados.")

        return resultado if resultado else None
    except Exception as erro:
        print("Erro ao buscar coletas:", erro)
        return None
    finally:
        conn.close()
def buscarTanquesDisponiveis(idregiao):
    try:
        print("Id regiao do coletor recebido:", idregiao)

        conn = conectar_banco()
        cursor = conn.cursor()

        query ="""
        SELECT
            t.idtanque,
            t.idregiao,
            t.status_tanque,
            u.id   AS produtor_id,
            u.nome AS produtor
        FROM tanque AS t
        LEFT JOIN usuario AS u
               ON u.idregiao = t.idregiao
        WHERE t.idregiao = %s
          AND t.status_tanque = 'livre'
        """
        cursor.execute(query, (idregiao,))
        resultado = cursor.fetchall()
        print(f"🔎 {len(resultado)} resultados encontrados.")

        return resultado if resultado else None
    except Exception as erro:
        print("Erro ao buscar tanques disponiveis:", erro)
        return None
    finally:
        conn.close()

def formatar_lista_tanques_disponiveis(dados):
    if not dados:
        return []
    return[
        {
            "idtanque": str(linha[0]),
            "idregiao": str(linha[1]),
            "status_tanque": str(linha[2]),
            "produtor_id": str(linha[3]),
            "nome": str(linha[4]),
        
        }
        for linha in dados
    #quando ver q ta disponivel status'Livre' vai mudar para a ser coletado
    ]

def formatar_lista_vacas(dados, usuario_id):
    if not dados:
        return []
    
    return[
        {
            "usuario_id":usuario_id,
            "vaca_id":str(linha[0]),
            "nome": str(linha[1]),
            "brinco": str(linha[2]),
            "crias": str(linha[3]),
            "origem": str(linha[4]),
            "estado": str(linha[5]),

        }
        for linha in dados
    ]
def formatar_devolutivas(dados, idTanque):
    """
    Fun o que formata a lista de devolutivas recebida do banco de dados
    para o formato JSON esperado pela aplicacao.
    """
    if not dados:
        return []
    return[
        {
    "id": str(linha[0]),
    "coleta_id": str(linha[1]),
    "gordura": str(linha[2]),
    "proteina": str(linha[3]),
    "lactose": str(linha[4]),
    "solidos_totais": str(linha[5]),
    "solidos_nao_gord": str(linha[6]),
    "densidade": str(linha[7]),
    "crioscopia": str(linha[8]),
    "ph": str(linha[9]),
    "cbt": str(linha[10]),
    "ccs": str(linha[11]),
    "patogenos": str(linha[12]),
    "antibioticos_pos": str(linha[13]),
    "antibioticos_desc": str(linha[14]),
    "residuos_quimicos": str(linha[15]),
    "aflatoxina_m1": str(linha[16]),
    "estabilidade_alc": str(linha[17]),
    "indice_acidez": str(linha[18]),
    "tempo_reduc_azul": str(linha[19]),
    "valor_litro": str(linha[20]),
    "laboratorio": str(linha[21]),
    "laudo_data": str(linha[22]),
    "observacoes": str(linha[23]),
    "created_at": str(linha[24]),
    "updated_at": str(linha[25])
                }
        for linha in dados
    ]

def pegando_tanque_cad(idregiao, idtanque, produtor_id, nome, coletor_id):
    # 
    # Atualiza o tanque para 'a_ser_coletado' e cria um registro em tanque_selecionado.
    # Retorna (True, dados) em sucesso ou (False, mensagem) em erro.
    # 
    try:
        conn = conectar_banco()
        cursor = conn.cursor()

        # 1) Atualiza status do tanque
        cursor.execute("""
            UPDATE tanque
               SET status_tanque = %s
             WHERE idtanque = %s AND idregiao = %s
        """, ('a_ser_coletado', idtanque, idregiao))

        # 2) Registra em tanque_selecionado
        cursor.execute("""
            INSERT INTO tanque_selecionado
                (idregiao, idtanque, produtor_id, nome, created_at,coletor_id)
            VALUES
                (%s, %s, %s, %s, NOW(),%s)
        """, (idregiao, idtanque, produtor_id, nome,coletor_id))

        novo_id = cursor.lastrowid
        conn.commit()

        dados = {
            "registro_id": novo_id,
            "idregiao": int(idregiao) if idregiao is not None else None,
            "idtanque": int(idtanque) if idtanque is not None else None,
            "produtor_id": None if produtor_id is None else int(produtor_id),
            "nome": nome,
            "status_tanque": "a_ser_coletado",
            "coletor_id": None if coletor_id is None else int(coletor_id),
        }
        return True, dados

    except Exception as erro:
        try:
            if conn: conn.rollback()
        except: 
            pass
        return False, f"Erro ao reservar tanque: {erro}"

    finally:
        try:
            if cursor: cursor.close()
        except: 
            pass
        try:
            if conn: conn.close()
        except:  
            pass

def buscarTanquesSelecionados(coletor_id):
    try:
        print("Id recebido para busca de tanques selecionados para ROTAS:", coletor_id)

        conn = conectar_banco()
        cursor = conn.cursor()
       
        query = """
SELECT
            ts.id, ts.idregiao, ts.idtanque, ts.produtor_id, ts.nome, ts.created_at, ts.coletor_id
        FROM tanque_selecionado AS ts
        JOIN tanque AS t
          ON t.idtanque = ts.idtanque
         AND t.idregiao = ts.idregiao
        WHERE ts.coletor_id = %s
          AND t.status_tanque = 'a_ser_coletado'"""
        cursor.execute(query, (coletor_id,))
        resultado = cursor.fetchall()
        print(f"🔎 {len(resultado)} resultados encontrados.")

        return resultado if resultado else None
    except Exception as erro:
        print("Erro ao buscar tanques selecionados:", erro)
        return None
    finally:
        conn.close()

def formatar_lista_tanques_selecionados(dados, coletor_id):
    if not dados:
        return []
    return[
        {
            "id": str(linha[0]),
            "idregiao": str(linha[1]),
            "idtanque": str(linha[2]),
            "produtor_id": str(linha[3]),
            "nome": str(linha[4]),
            "created_at": str(linha[5]),
            "coletor_id": coletor_id,
        
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
                    foto_bytes = resultado[6]

                    if foto_bytes:
                        foto_base64 = base64.b64encode(foto_bytes).decode('utf-8')
                    else:
                        foto_base64 = None
                    
                    resposta = {
                        "status": "aceito",
                        "token": token,
                        "expira_em": expira_em.isoformat(),
                        "id":resultado[0],
                        "nome": resultado[1],
                        "senha": resultado[2],
                        "idtanque": resultado[3],
                        "idregiao": resultado[4],
                        "contato":resultado[5],
                        "foto":foto_base64,
                        "cargo":cargo
                    }
                
                elif cargo == 2:
                    # coletor
                    foto_bytes = resultado[6]
                    if foto_bytes:
                        foto_base64 = base64.b64encode(foto_bytes).decode('utf-8')
                    else:
                        foto_base64 = None

                    resposta = {
                        "status": "aceito",
                        "token": token,
                        "expira_em": expira_em.isoformat(),
                        "id":resultado[0],
                        "nome": resultado[1],
                        "senha": resultado[2],
                        "idregiao": resultado[3],
                        "placa": resultado[4],
                        "contato":resultado[5],
                        "foto":foto_base64,
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
                foto_bytes = None  #foto_bytes como None para foto null

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
            dados = buscarDadosTanque(nome,idtanque,idregiao)

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
                    
                    # Garante que mensagem é string para json.dumps
                    if isinstance(mensagem, bytes):
                        mensagem = mensagem.decode('utf-8', errors='ignore')
                    
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
            id = payload.get("id")
            campo = payload.get("campo") 
            valor = payload.get("valor")
            nome = payload.get("nome")
            cargo = payload.get("cargo")

            if not campo or not valor or not nome or cargo is None or id is None:
                resposta = {"status": "negado", "mensagem": "Dados incompletos"}
            else:
                sucesso, mensagem = atualizar_usuario(campo, valor, nome,cargo,id)
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

            client.publish("buscarDepositosProdutor/resultado", json.dumps(resposta, default=str))
            print(f"[MQTT] Dados enviados para 'buscarDepositosProdutor/resultado': {resposta}")

        elif topico == "cadastroVaca/entrada":
            usuario_id = payload.get("usuario_id")
            nome = payload.get("nome")
            brinco = int(payload.get("brinco"))
            crias = int(payload.get("crias"))
            origem = payload.get("origem")
            estado = payload.get("estado")  

            sucesso, mensagem = cadastrar_vaca(nome, brinco, crias, origem,estado, usuario_id)

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

            client.publish("cadastroVaca/resultado", json.dumps(resposta))
            print(f"[MQTT] Resultado CADASTRO VACA enviado: {resposta}")

        elif topico == "buscarVacas/entrada":
            print("✅ Mensagem recebida no tópico buscarVacas/entrada")
            usuario_id = payload.get("usuario_id")

            dados = buscarVacas(usuario_id)

            # sempre retorna uma lista, mesmo que vazia
            resposta = {
            "status": "ok",
            "dados": formatar_lista_vacas(dados, usuario_id) if dados else []
            }

            client.publish("buscarVacas/resultado", json.dumps(resposta, default=str))
            print(f"[MQTT] Dados enviados para 'buscarVacas/resultado': {resposta}")


        elif topico == "editarVaca/entrada":
            usuario_id = payload.get("usuario_id")
            vaca_id = payload.get("vaca_id")
            campo = payload.get("campo") 
            valor = payload.get("valor")

            if not campo or not valor or usuario_id is None or vaca_id is None:
                resposta = {"status": "negado", "mensagem": "Dados incompletos"}
            else:
                sucesso, mensagem = atualizar_vaca(campo, valor, usuario_id, vaca_id)
                resposta = {
                    "status": "aceito" if sucesso else "negado",
                    "mensagem": mensagem,
                    "campo":campo,
                    "valor":valor
                }

            client.publish("editarVaca/resultado", json.dumps(resposta))
            print(f"[MQTT] Atualização da vaca enviada: {resposta}")

        elif topico == "deletarVaca/entrada":
            usuario_id = payload.get("usuario_id")
            vaca_id = payload.get("vaca_id")
            if usuario_id is None or vaca_id is None:
                resposta = {"status": "negado", "mensagem": "Dados incompletos"}
            else:
                sucesso, mensagem = deletar_vaca(usuario_id, vaca_id)
                resposta = {
                    "status": "aceito" if sucesso else "negado",
                    "mensagem": mensagem,
                }
                client.publish("deletarVaca/resultado", json.dumps(resposta))
                print(f"[MQTT] Solicitacao de exclusao enviada: {resposta}")

        elif topico == "buscarDevolutivas/entrada":
            idtanque = payload.get("idtanque")
            dados = buscarDevolutivas(idtanque)
            if dados:
                resposta = {
                    "status": "ok",
                    "dados": formatar_devolutivas(dados, idtanque) if dados else []
                }
            else:
                resposta = {
                    "status": "vazio",
                    "mensagem": "Nenhuma devolutiva encontrada"
                }

            client.publish("buscarDevolutivas/resultado", json.dumps(resposta, default=str))
            print(f"[MQTT] Dados enviados para 'buscarDevolutivas/resultado': {resposta}")
            
        elif topico == "atualizarStatusTanque/entrada":
            idtanque = payload.get("idtanque")
            campo = payload.get("campo")
            valor = payload.get("valor")
            sucesso, mensagem = atualizar_status_tanque(idtanque, campo, valor)
            resposta = {
                "status": "aceito" if sucesso else "negado",
                "mensagem": mensagem,
                "campo": campo,
                "valor": valor
            }
            client.publish("atualizarStatusTanque/resultado", json.dumps(resposta))
            print(f"[MQTT] Atualização de status do tanque enviada: {resposta}")

        elif topico == "buscarTanquesDisponiveis/entrada":
            idregiao = payload.get("idregiao")
            dados = buscarTanquesDisponiveis(idregiao)
            if dados:
                resposta = {
                    "status": "ok",
                    "dados": formatar_lista_tanques_disponiveis(dados) if dados else []
                }
            else:
                resposta = {
                    "status": "vazio",
                    "mensagem": "Nenhum tanque disponivel"
                }

            client.publish("buscarTanquesDisponiveis/resultado", json.dumps(resposta, default=str))
            print(f"[MQTT] Dados enviados para 'buscarTanquesDisponiveis/resultado': {resposta}")
        elif topico == "pegandoTanque/entrada":
          
            idregiao = payload.get("idregiao")
            idtanque = payload.get("idtanque")
            produtor_id = payload.get("produtor_id")
            nome = payload.get("nome")
            coletor_id = payload.get("coletor_id")

            try:
                idregiao = int(idregiao)
                idtanque = int(idtanque)

                if produtor_id in (None, "", "None"):
                    produtor_id = None
                else:
                    produtor_id = int(produtor_id)

                if coletor_id in (None, "", "None"):
                    coletor_id = None
                else:
                    coletor_id = int(coletor_id)

            except (TypeError, ValueError):
                resposta = {"status": "negado", "mensagem": "IDs inválidos"}
                client.publish("pegandoTanque/resultado", json.dumps(resposta))
                print(f"[MQTT] pegandoTanque/resultado: {resposta}")
                return

            ok, out = pegando_tanque_cad(idregiao, idtanque, produtor_id, nome, coletor_id)

            if ok:
                resposta = {"status": "ok", "mensagem": "Coleta selecionada", "dados": out}
            else:
                resposta = {"status": "negado", "mensagem": out}

            client.publish("pegandoTanque/resultado", json.dumps(resposta))
            print(f"[MQTT] pegandoTanque/resultado: {resposta}")

        elif topico == "buscarTanquesSelecionados/entrada":
            coletor_id = payload.get("coletor_id")
            dados = buscarTanquesSelecionados(coletor_id)
            if dados:
                resposta = {
                    "status": "ok",
                    "dados": formatar_lista_tanques_selecionados(dados, coletor_id) if dados else []
                }
            else:
                resposta = {
                    "status": "vazio",
                    "mensagem": "Nenhum tanque selecionado"
                }

            client.publish("buscarTanquesSelecionados/resultado", json.dumps(resposta, default=str))
            print(f"[MQTT] Dados enviados para 'buscarTanquesSelecionados/resultado': {resposta}")

    except Exception as e:
        print("❌ Erro ao processar mensagem:", e)


# Configurando MQTT
# Isso conecta no broker MQTT e fica escutando o tempo todo
client = mqtt.Client()
#arrumar
# client.username_pw_set("csilab", "WhoAmI#2023")
client.username_pw_set("admin", "admin")
client.on_message = on_message

#arrumar
# client.connect("192.168.244.220", 1883)

#ip broker
client.connect("192.168.12.103", 1883)

client.subscribe("login/entrada")
client.subscribe("cadastro/entrada")
client.subscribe("tanque/buscar")
client.subscribe("fotoAtualizada/entrada")
client.subscribe("editarUsuario/entrada")
client.subscribe("tanqueIdentificado/entrada")
client.subscribe("cadastroHistoricoColeta/entrada")
client.subscribe("buscarColetas/entrada")
client.subscribe("buscarDepositosProdutor/entrada")
client.subscribe("cadastroVaca/entrada")
client.subscribe("buscarVacas/entrada")
client.subscribe("editarVaca/entrada")
client.subscribe("deletarVaca/entrada")
client.subscribe("atualizarStatusTanque/entrada")
client.subscribe("buscarDevolutivas/entrada")
client.subscribe("buscarTanquesDisponiveis/entrada")


client.subscribe("pegandoTanque/entrada")
client.subscribe("buscarTanquesSelecionados/entrada")

print("🟢 Validador MQTT com sessão JWT rodando...")
client.loop_forever()