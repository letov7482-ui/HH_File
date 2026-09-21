# HH_Cheat/build/keygen.py
import hashlib, secrets, json, base64
from pathlib import Path

SOURCES = {
    "s1": "30,3,20,666025,666026,180006,180007",
    "s2": "WatchGame_UIBP,Button_OpenHawkEyeReport,CanvasPanel_HawkImprison",
    "s3": "36661,36662,36664,36665,36666,49266,49267",
    "s4": base64.b64encode(secrets.token_bytes(32)).decode()
}

material = "|".join(SOURCES[k] for k in sorted(SOURCES)).encode()
MASTER = hashlib.sha256(material).digest()

parts = [MASTER[i*8:(i+1)*8] for i in range(4)]

out = {
    "parts_b64": [base64.b64encode(p).decode() for p in parts],
    "s4_salt":   SOURCES["s4"]
}
Path("build/key.json").write_text(json.dumps(out, indent=2))
print("[keygen] master key создан, разбит на 4 части")
print("[keygen] s4 salt:", SOURCES["s4"])
