#!/bin/bash
# HH_Cheat/deploy/push.sh
set -e

PATCH="game_patch_4.6.0.21565"   # ← то же что в pack.py
PKG="com.tencent.ig"              # BGMI: com.rekoo.pubgm

LOCAL_PAK="../out/${PATCH}.pak"
DEVICE_TMP="/sdcard/${PATCH}.pak"
DEVICE_DST="files/UE4Game/ShadowTrackerExtra/ShadowTrackerExtra/Saved/Paks/puffer_temp/"

adb push "$LOCAL_PAK" "$DEVICE_TMP"
adb shell "run-as $PKG mkdir -p $DEVICE_DST"
adb shell "run-as $PKG cp $DEVICE_TMP $DEVICE_DST"
adb shell "run-as $PKG ls -la $DEVICE_DST"
adb shell "am force-stop $PKG"
adb shell "monkey -p $PKG -c android.intent.category.LAUNCHER 1"
