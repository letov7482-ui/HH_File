-- src/loader.lua — единственный открытый файл
local M = {}

local K1 = {30, 3, 20, 666025, 666026, 180006, 180007}
local K2 = {"WatchGame_UIBP", "Button_OpenHawkEyeReport", "CanvasPanel_HawkImprison"}
local K3 = {36661, 36662, 36664, 36665, 36666, 49266, 49267}
local K4_B64 = "__S4_SALT__"

local B64 = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/"
local function b64_decode(s)
    s = s:gsub("[^" .. B64 .. "=]", "")
    local out, buf, bits = {}, 0, 0
    for i = 1, #s do
        local c = s:sub(i, i)
        if c == "=" then break end
        local v = B64:find(c, 1, true) - 1
        buf = buf * 64 + v
        bits = bits + 6
        if bits >= 8 then
            bits = bits - 8
            table.insert(out, string.char((buf >> bits) & 0xFF))
        end
    end
    return table.concat(out)
end

local function sha256(data)
    local UE = import("KismetMathLibrary")
    if UE and UE.MakeSHA256 then return UE.MakeSHA256(data) end
    if _VERSION == "LuaJIT" then
        local ffi = require("ffi")
        ffi.cdef[[
            typedef struct { unsigned char d[32]; } SHA256_CTX;
            void sha256_init(SHA256_CTX*);
            void sha256_update(SHA256_CTX*, const unsigned char*, unsigned long);
            void sha256_final(unsigned char*, SHA256_CTX*);
        ]]
    end
    return data
end

local function build_master()
    local mat = {}
    for _, v in ipairs(K1) do table.insert(mat, tostring(v)) end
    table.insert(mat, "|")
    for _, v in ipairs(K2) do table.insert(mat, v) end
    table.insert(mat, "|")
    for _, v in ipairs(K3) do table.insert(mat, tostring(v)) end
    table.insert(mat, "|")
    table.insert(mat, b64_decode(K4_B64))
    return sha256(table.concat(mat))
end

local function xor_stream(data, key)
    local out = {}
    for i = 1, #data do
        local b = data:byte(i)
        local k = key:byte(((i - 1) % #key) + 1)
        local pos = ((i - 1) * 31) & 0xFF
        out[i] = string.char(bxor(b, bxor(k, pos)))
    end
    return table.concat(out)
end

local function sbox_shift_inverse(data, seed)
    local sbox = {}
    for i = 0, 255 do sbox[i] = i end
    local rnd = seed
    for i = 255, 1, -1 do
        rnd = (rnd * 1103515245 + 12345) & 0x7FFFFFFF
        local j = rnd % (i + 1)
        sbox[i], sbox[j] = sbox[j], sbox[i]
    end
    local inv = {}
    for i = 0, 255 do inv[sbox[i]] = i end
    local out = {}
    for i = 1, #data do
        out[i] = string.char(inv[data:byte(i)])
    end
    return table.concat(out)
end

local function decrypt(entry, master)
    local seed = entry.seed
    local raw = b64_decode(entry.data)
    local fk = sha256(tostring(seed) .. master)
    local s2 = xor_stream(raw, fk)
    local s1 = sbox_shift_inverse(s2, seed)
    return xor_stream(s1, master)
end

function M.load(name, manifest)
    local entry = manifest[name]
    if not entry then return nil end
    local master = build_master()
    local code = decrypt(entry, master)
    local fn, err = loadstring(code, "@" .. name)
    if not fn then
        FuncUtil.FormatLog("[HH] load fail %s: %s", name, tostring(err))
        return nil
    end
    local ok, mod = pcall(fn)
    if not ok then
        FuncUtil.FormatLog("[HH] exec fail %s: %s", name, tostring(mod))
        return nil
    end
    return mod
end

function M.boot()
    local MANIFEST_B64 = "__MANIFEST__"
    local manifest
    if FuncUtil.JsonDecode then
        manifest = FuncUtil.JsonDecode(b64_decode(MANIFEST_B64))
    else
        local ok, json = pcall(require, "json")
        if ok and json then manifest = json.decode(b64_decode(MANIFEST_B64)) end
    end
    if not manifest then
        FuncUtil.FormatLog("[HH] manifest decode fail")
        return
    end
    local mod = M.load("core/main.lua", manifest)
    if mod and mod.start then mod.start(manifest, M) end
end

return M
