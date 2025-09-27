# 🐄 SMARTMILK – Sistema de Monitoramento e Controle de Leite

**SMARTMILK** é um aplicativo desenvolvido para conectar produtores de leite aos coletores, oferecendo uma plataforma integrada de **monitoramento, controle e rastreabilidade** dos tanques unitários de leite.

## 📱 Sobre o Aplicativo

O SMARTMILK foi criado para facilitar o acompanhamento da produção e coleta de leite em tempo real, promovendo maior transparência, qualidade e eficiência em todo o processo.

### 👥 Usuários

- **Produtores**: acompanham o volume, temperatura, pH e histórico do leite armazenado em seus tanques.
- **Coletores**: visualizam rotas, dados dos tanques a serem coletados e registram coletas diretamente pelo app.

## 🔧 Funcionalidades

- 📊 Monitoramento dos tanques em tempo real (temperatura, volume, pH etc.)
- 🔒 Acesso individualizado para produtor e coletor
- 📅 Histórico de coletas e registros por tanque
- 🌐 Integração com sistema IoT para dados em tempo real
- 🔔 Comunicação do contratante e produtor
- 📍 Localização dos tanques vinculados ao usuário

## 🚀 Tecnologias Utilizadas

- **Flutter** – desenvolvimento do aplicativo mobile
- **Python + MySQL** – backend e banco de dados
- **MQTT (Paho)** – comunicação em tempo real com os dispositivos de coleta
- **ESP32** – hardware para sensores nos tanques

## 📦 Instalação e Uso

```bash
# Clone o repositório
git clone https://github.com/seu-usuario/smartmilk.git

# Acesse o diretório do projeto
cd smartmilk

# Instale as dependências do Flutter
flutter pub get

# Execute o aplicativo
flutter run
```
⚠️ Certifique-se de configurar corretamente o backend e o broker MQTT antes de executar.

📚 Documentação
A documentação detalhada do projeto está disponível na pasta /docs, com diagramas, estrutura do banco de dados e fluxos de tela.

🤝 Contribuições
Contribuições são bem-vindas!
Caso queira sugerir melhorias ou corrigir bugs, abra uma issue ou envie um pull request.

📫 Contato
Projeto desenvolvido por João Gabriel Marcelino e Carina Pereira
