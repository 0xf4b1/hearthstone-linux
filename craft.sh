#!/bin/bash

set -e

HS_PATH=$1
UNITY_PATH=$2/Hub/Editor/2018.4.10f1/Editor/Data/PlaybackEngines/LinuxStandaloneSupport/Variations/linux64_withgfx_nondevelopment_mono
TARGET_PATH=$(realpath $3)

mkdir -p $TARGET_PATH

echo "Copy game data files ..."

cp -r $HS_PATH/Data $TARGET_PATH
cp -r $HS_PATH/Strings $TARGET_PATH

mkdir $TARGET_PATH/Bin
cp -r $HS_PATH/Hearthstone.app/Contents/Resources/Data $TARGET_PATH/Bin/Hearthstone_Data
cp $HS_PATH/Hearthstone.app/Contents/Resources/'unity default resources' $TARGET_PATH/Bin/Hearthstone_Data/Resources
cp $HS_PATH/Hearthstone.app/Contents/Resources/PlayerIcon.icns $TARGET_PATH/Bin/Hearthstone_Data/Resources

echo "Copy engine files ..."

cp $UNITY_PATH/LinuxPlayer $TARGET_PATH/Bin/Hearthstone.x86_64
cp -r $UNITY_PATH/Data/MonoBleedingEdge $TARGET_PATH/Bin/Hearthstone_Data

echo "Creating stubs ..."

cp client.config $TARGET_PATH

mkdir -p $TARGET_PATH/Bin/Hearthstone_Data/Plugins/System/Library/Frameworks/CoreFoundation.framework

make -C stubs

cp stubs/CoreFoundation.so $TARGET_PATH/Bin/Hearthstone_Data/Plugins/System/Library/Frameworks/CoreFoundation.framework
cp stubs/libOSXWindowManagement.so $TARGET_PATH/Bin/Hearthstone_Data/Plugins

make -C token

cp token/Token.exe $TARGET_PATH

make -C login

cp login/login $TARGET_PATH

cat << EOF > ~/.local/share/applications/hearthstone.desktop
[Desktop Entry]
Type=Application
Name=Hearthstone
Exec=$TARGET_PATH/Bin/Hearthstone.x86_64
Icon=$TARGET_PATH/Bin/Hearthstone_Data/Resources/PlayerIcon.icns
Categories=Game;
EOF

echo "Done. Now generate your web token, before launching the game!"
