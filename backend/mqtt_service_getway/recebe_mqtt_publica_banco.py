import os
from typing import Dict, Optional
import json

import mysql.connector
import paho.mqtt.client as mqtt

MQTT_HOST = os.getenv("MQTT_HOST", "192.168.66.11") # colocar ip broker
MQTT_PORT = int(os.getenv("MQTT_PORT", "1883"))
MQTT_USER = os.getenv("MQTT_USER", "csilab")
MQTT_PASS = os.getenv("MQTT_PASS", "WhoAmI#2024")

MQTT_TOPIC = os.getenv("MQTT_TOPIC", "regiao/+/tanque/+/sensores")

DB_HOST = os.getenv("DB_HOST", "127.0.0.1")
DB_PORT = int(os.getenv("DB_PORT", "3306"))
DB_USER = os.getenv("DB_USER", "root")
DB_PASS = os.getenv("DB_PASS", "root")
DB_NAME = os.getenv("DB_NAME", "mimosa")

FIELDS = ["ph", "temp", "nivel", "amonia", "metano", "condutividade", "turbidez", "co2"]
DEFAULT_STATUS = "a_ser_coletado"

def parse_payload(payload: str) -> Dict[str, str]:
    payload = payload.strip().replace("\r", "").replace("\n", "")

    # 1) JSON
    if payload.startswith("{") and payload.endswith("}"):
        try:
            obj = json.loads(payload)
            return {str(k).strip().lower(): str(v).strip() for k, v in obj.items()}
        except Exception:
            pass

    # 2) chave:valor;chave:valor
    out: Dict[str, str] = {}
    for part in payload.split(";"):
        part = part.strip()
        if not part or ":" not in part:
            continue
        k, v = part.split(":", 1)
        out[k.strip().lower()] = v.strip()
    return out

def to_float(v: Optional[str]) -> Optional[float]:
    if v is None:
        return None
    try:
        return float(v.replace(",", "."))
    except Exception:
        return None

def db_connect():
    return mysql.connector.connect(
        host=DB_HOST,
        port=DB_PORT,
        user=DB_USER,
        password=DB_PASS,
        database=DB_NAME,
        autocommit=False,
    )

def ensure_row_exists(cur, idtanque: int, idregiao: int):
    cur.execute(
        "SELECT 1 FROM tanque WHERE idtanque=%s AND idregiao=%s LIMIT 1",
        (idtanque, idregiao),
    )
    if cur.fetchone() is None:
        # cria já com status padrão
        cur.execute(
            "INSERT INTO tanque (idtanque, idregiao, status_tanque) VALUES (%s, %s, %s)",
            (idtanque, idregiao, DEFAULT_STATUS),
        )

def update_tanque(cur, idtanque: int, idregiao: int, values: Dict[str, Optional[float]]):
    set_parts = []
    params = []

    # sempre publica status_tanque
    set_parts.append("status_tanque=%s")
    params.append(DEFAULT_STATUS)

    # publica os sensores que vierem não-nulos
    for f in FIELDS:
        if values.get(f) is not None:
            set_parts.append(f"{f}=%s")
            params.append(values[f])

    if not set_parts:
        return

    sql = f"UPDATE tanque SET {', '.join(set_parts)} WHERE idtanque=%s AND idregiao=%s"
    cur.execute(sql, params + [idtanque, idregiao])

def parse_ids_from_topic(topic: str) -> Optional[tuple[int, int]]:
    # regiao/<r>/tanque/<t>/sensores
    parts = topic.split("/")
    if len(parts) < 5:
        return None
    try:
        regiao = int(parts[1])
        tanque = int(parts[3])
        return tanque, regiao
    except Exception:
        return None

def on_connect(client, userdata, flags, rc):
    if rc == 0:
        print("[MQTT] conectado")
        client.subscribe(MQTT_TOPIC)
        print("[MQTT] subscribed:", MQTT_TOPIC)
    else:
        print("[MQTT] erro rc=", rc)

def on_message(client, userdata, msg):
    ids = parse_ids_from_topic(msg.topic)
    if not ids:
        print("[WARN] topico invalido:", msg.topic)
        return

    idtanque, idregiao = ids
    payload = msg.payload.decode("utf-8", errors="ignore")

    data = parse_payload(payload)
    values = {f: to_float(data.get(f)) for f in FIELDS}

    conn = None
    cur = None
    try:
        conn = db_connect()
        cur = conn.cursor()

        ensure_row_exists(cur, idtanque, idregiao)
        update_tanque(cur, idtanque, idregiao, values)

        conn.commit()
        print(f"[OK] tanque={idtanque} regiao={idregiao} atualizado (status='{DEFAULT_STATUS}')")
    except Exception as e:
        print("[ERRO] DB:", e)
        try:
            if conn:
                conn.rollback()
        except Exception:
            pass
    finally:
        try:
            if cur:
                cur.close()
            if conn:
                conn.close()
        except Exception:
            pass

def main():
    c = mqtt.Client(client_id="smartmilk_live_writer")
    c.username_pw_set(MQTT_USER, MQTT_PASS)
    c.on_connect = on_connect
    c.on_message = on_message

    print(f"[MQTT] conectando {MQTT_HOST}:{MQTT_PORT} ...")
    c.connect(MQTT_HOST, MQTT_PORT, 60)
    c.loop_forever()

if __name__ == "__main__":
    main()
