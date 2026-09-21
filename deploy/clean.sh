#!/bin/bash
# HH_Cheat/deploy/clean.sh
PATCH="game_patch_4.6.0.21565"
PKG="com.tencent.ig"
adb shell "run-as $PKG rm -f files/UE4Game/ShadowTrackerExtra/ShadowTrackerExtra/Saved/Paks/puffer_temp/${PATCH}.pak"
adb shell "run-as $PKG rm -f files/UE4Game/ShadowTrackerExtra/ShadowTrackerExtra/Saved/Paks/puffer_temp/${PATCH}.sig"
