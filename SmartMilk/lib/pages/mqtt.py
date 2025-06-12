import json
import paho.mqtt.client as mqtt
import time

class MQTTService:
    def __init__(self, usuario="csilab", senha="WhoAmI#2023"):
        self.broker = '192.168.66.50'
        self.port = 1883
        self.client_id = 'python_client'
        self.topic_login = 'topico/login'
        
        self.client = mqtt.Client(self.client_id)

        # Se seu broker usa autenticação, passe aqui usuário e senha
        if usuario and senha:
            self.client.username_pw_set(usuario, senha)
        
        # Callbacks
        self.client.on_connect = self._on_connected
        self.client.on_disconnect = self._on_disconnected
        self.client.on_subscribe = self._on_subscribed
        
        self.connected = False

    def conectar_mqtt(self):
        try:
            self.client.connect(self.broker, self.port)
            self.client.loop_start()
        except Exception as e:
            print(f'⚠️ Exceção ao tentar conectar: {e}')

    def inscrever_no_login(self):
        if self.connected:
            self.client.subscribe(self.topic_login, qos=0)
            print(f'📡 Inscrito no tópico "{self.topic_login}"')
        else:
            print('❌ Não está conectado. Não pode se inscrever.')

    def testar_publicacao(self, nome, senha, id_cargo):
        if self.connected:
            mensagem = json.dumps({
                'tipo': 'login',
                'usuario': nome,
                'senha': senha,
                'idCargo': id_cargo,
            })
            self.client.publish(self.topic_login, mensagem, qos=0)
            print(f'📤 Mensagem publicada em "{self.topic_login}": {mensagem}')
        else:
            print('❌ Cliente MQTT NÃO está conectado. Não foi possível publicar login.')

    # Callbacks
    def _on_connected(self, client, userdata, flags, rc):
        if rc == 0:
            self.connected = True
            print('🔌 Conexão estabelecida com sucesso')
            self.inscrever_no_login()
        else:
            print(f'❌ Falha na conexão, código {rc}')
            # Opcional: tentar reconectar após um tempo
            # time.sleep(5)
            # self.conectar_mqtt()

    def _on_disconnected(self, client, userdata, rc):
        self.connected = False
        print('🔌 Desconectado do broker')
        if rc != 0:
            print(f'Reconectando devido a desconexão inesperada (rc={rc})...')
            try:
                self.client.reconnect()
            except Exception as e:
                print(f'⚠️ Falha ao tentar reconectar: {e}')

    def _on_subscribed(self, client, userdata, mid, granted_qos):
        print('📡 Inscrição confirmada no tópico')

if __name__ == '__main__':
    # Se seu broker precisa de usuário e senha, passe aqui
    mqtt_service = MQTTService(usuario='csilab', senha='WhoAmI#2023')
    mqtt_service.conectar_mqtt()

    # Aguarda conexão
    time.sleep(3)

    #simulação de inscricao
    #mqtt_service.testar_publicacao('carina', '222', 5)

    # Mantém o script rodando para callbacks
    time.sleep(5)
    mqtt_service.client.loop_stop()
    mqtt_service.client.disconnect()
