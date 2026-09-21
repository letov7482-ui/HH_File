# распаковка текущего PAK игры
repak unpack game_patch_4.6.0.21565.pak -o vendor_extract/
# ищешь файл
find vendor_extract -name "SecurityCommonUtils.lua"
# копируешь к себе
cp vendor_extract/.../SecurityCommonUtils.lua vendor/SecurityCommonUtils.original.lua
