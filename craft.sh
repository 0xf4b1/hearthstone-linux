#!/bin/bash

set -e

TARGET_PATH=$(realpath $1)

UNITY_ENGINE=/Hub/Editor/2018.4.10f1/Editor/Data/PlaybackEngines/LinuxStandaloneSupport/Variations/linux64_withgfx_nondevelopment_mono

download_unity () {
    echo "Downloading Unity Hub"
    curl -O https://public-cdn.cloud.unity3d.com/hub/prod/UnityHub.AppImage
    chmod +x ./UnityHub.AppImage
    ./UnityHub.AppImage unityhub://2018.4.10f1/a0470569e97b
    [ ! -d ~/Unity$UNITY_ENGINE ] && echo "Required Unity Engine files not installed!" && exit 1
}

if [ -z $2 ]; then
    if [ ! -d ~/Unity$UNITY_ENGINE ]; then
        echo "Required Unity Engine files not found in default directory!"
        download_unity
    fi
    UNITY_PATH=~/Unity$UNITY_ENGINE
else
    UNITY_PATH=$2$UNITY_ENGINE
fi

echo "Rearrange game files ..."

mkdir $TARGET_PATH/Bin
mv $TARGET_PATH/Hearthstone.app/Contents/Resources/Data $TARGET_PATH/Bin/Hearthstone_Data
mv $TARGET_PATH/Hearthstone.app/Contents/Resources/'unity default resources' $TARGET_PATH/Bin/Hearthstone_Data/Resources
mv $TARGET_PATH/Hearthstone.app/Contents/Resources/PlayerIcon.icns $TARGET_PATH/Bin/Hearthstone_Data/Resources

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
