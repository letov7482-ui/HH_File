# HH_Cheat/build/encrypt.py
import os, json, base64, hashlib
from pathlib import Path

def xor_stream(data: bytes, key: bytes) -> bytes:
    out = bytearray(len(data))
    for i, b in enumerate(data):
        k = key[i % len(key)]
        out[i] = b ^ k ^ ((i * 31) & 0xFF)
    return bytes(out)

def sbox_shift(data: bytes, seed: int) -> bytes:
    sbox = list(range(256))
    rnd = seed
    for i in range(255, 0, -1):
        rnd = (rnd * 1103515245 + 12345) & 0x7FFFFFFF
        j = rnd % (i + 1)
        sbox[i], sbox[j] = sbox[j], sbox[i]
    return bytes(sbox[b] for b in data)

def encrypt_file(path: Path, key: bytes) -> dict:
    raw = path.read_bytes()
    seed = int.from_bytes(hashlib.sha256(raw + key).digest()[:4], "big")
    step1 = xor_stream(raw, key)
    step2 = sbox_shift(step1, seed)
    final_key = hashlib.sha256(str(seed).encode() + key).digest()
    step3 = xor_stream(step2, final_key)
    return {"seed": seed, "data": base64.b64encode(step3).decode()}

def main():
    kd = json.loads(Path("build/key.json").read_text())
    master = b"".join(base64.b64decode(p) for p in kd["parts_b64"])

    src_root = Path("src")
    out_root = Path("out/encrypted")
    out_root.mkdir(parents=True, exist_ok=True)

    manifest = {}
    for lua in src_root.rglob("*.lua"):
        if lua.name == "loader.lua":
            continue
        rel = lua.relative_to(src_root).as_posix()
        enc = encrypt_file(lua, master)
        manifest[rel] = enc
        print(f"[encrypt] {rel}")

    (out_root / "manifest.json").write_text(json.dumps(manifest))
    print(f"[encrypt] готово, {len(manifest)} файлов")

if __name__ == "__main__":
    main()
