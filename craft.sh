#!/bin/bash

set -e

NGDP_BIN=$(realpath keg/bin/ngdp)
GREEN='\e[32m'
RED='\e[31m'
WHITE='\e[37m'

setup_keg() {
    cd keg
    ./setup.py build
    cd ..
}

set_region() {
    if [ -f ".region" ]; then
        REGION=$(cat .region)
    else
        read -p "Which region do you wish to install? [eu/us/kr/cn]: " REGION
        echo $REGION >.region
    fi
}

init_hearthstone() {
    mkdir hearthstone && cd hearthstone
    $NGDP_BIN init

    set_region

    if [ "${REGION^^}" = "EU" ] || [ "${REGION^^}" = "US" ] || [ "${REGION^^}" = "KR" ] || [ "${REGION^^}" = "CN" ]; then
        $NGDP_BIN remote add http://${REGION}.patch.battle.net:1119/hsb

    else
        echo -e "${RED}Invalid Region. Exiting."
        exit 1
    fi

    echo "Not installed" >.version
}

check_version() {
    set_region
    VERSION=$(curl http://${REGION}.patch.battle.net:1119/hsb/versions | grep $REGION)
    VERSION=${VERSION%|*}
    VERSION=${VERSION##*|}

    if [ -f ".version" ]; then
        INSTALLED=$(cat .version)
    else
        INSTALLED="Not installed"
    fi

    echo -e "${GREEN}Region: ${WHITE}$REGION"
    echo -e "${GREEN}Online version: ${WHITE}$VERSION"
    echo -e "${GREEN}Downloaded version: ${WHITE}$INSTALLED"
}

download_hearthstone() {
    echo -e "${GREEN}Downloading Hearthstone via keg ...${WHITE}\n"
    $NGDP_BIN --cdn "http://level3.blizzard.com/tpr/hs" fetch http://${REGION}.patch.battle.net:1119/hsb --tags OSX --tags enUS --tags Production
    $NGDP_BIN install http://${REGION}.patch.battle.net:1119/hsb $VERSION --tags OSX --tags enUS --tags Production
    echo $VERSION >.version
}

download_unity() {
    echo -e "${RED}Unity files not found.\n${GREEN}Downloading Unity 2018.4.10f1 (This is version is required for the game to run).${WHITE}\n"
    mkdir -p tmp
    [ ! -f "tmp/Unity.tar.xz" ] && wget -P tmp https://netstorage.unity3d.com/unity/a0470569e97b/LinuxEditorInstaller/Unity.tar.xz

    echo -e "${GREEN}Extracting Unity files....${WHITE}\n"
    tar -xf tmp/Unity.tar.xz -C tmp Editor/Data/PlaybackEngines/LinuxStandaloneSupport/Variations/linux64_withgfx_nondevelopment_mono/LinuxPlayer Editor/Data/PlaybackEngines/LinuxStandaloneSupport/Variations/linux64_withgfx_nondevelopment_mono/Data/MonoBleedingEdge/
    UNITY_PATH=tmp/Editor/Data/PlaybackEngines/LinuxStandaloneSupport/Variations/linux64_withgfx_nondevelopment_mono

    mkdir -p $TARGET_PATH/Bin
    mv $UNITY_PATH/LinuxPlayer $TARGET_PATH/Bin/Hearthstone.x86_64
    mv $UNITY_PATH/Data/MonoBleedingEdge $TARGET_PATH
    rm -rf tmp
    echo -e "${GREEN}Done!\n${WHITE}"
}

move_files_and_cleaup() {
    echo -e "${GREEN}Moving files & running cleanup ...\n${WHITE}"

    mv $TARGET_PATH/Hearthstone.app/Contents/Resources/Data $TARGET_PATH/Bin/Hearthstone_Data
    mv $TARGET_PATH/Hearthstone.app/Contents/Resources/'unity default resources' $TARGET_PATH/Bin/Hearthstone_Data/Resources
    mv $TARGET_PATH/Hearthstone.app/Contents/Resources/PlayerIcon.icns $TARGET_PATH/Bin/Hearthstone_Data/Resources
    mv $TARGET_PATH/MonoBleedingEdge $TARGET_PATH/Bin/Hearthstone_Data

    echo -e "${GREEN}Done!\n${WHITE}"

    echo -e "${GREEN}Cleaning up unecessary files.${WHITE}\n"
    rm -rf $TARGET_PATH/Hearthstone.app
    rm -rf $TARGET_PATH/'Hearthstone Beta Launcher.app'
}

gen_token_login() {
    make -C token
    cp token/Token.exe $TARGET_PATH
    make -C login
    cp login/login $TARGET_PATH
}

create_stubs() {
    cp client.config $TARGET_PATH
    mkdir -p $TARGET_PATH/Bin/Hearthstone_Data/Plugins/System/Library/Frameworks/CoreFoundation.framework
    make -C stubs
    cp stubs/CoreFoundation.so $TARGET_PATH/Bin/Hearthstone_Data/Plugins/System/Library/Frameworks/CoreFoundation.framework
    cp stubs/libOSXWindowManagement.so $TARGET_PATH/Bin/Hearthstone_Data/Plugins
}

check_directory() {
    if [ -z $1 ]; then
        if [ ! -d hearthstone ]; then
            echo -e "${RED}Hearthstone installation not found${WHITE}\n"
            setup_keg
            init_hearthstone
            check_version
            download_hearthstone
        else
            cd hearthstone
            check_version
            if [[ ! "$VERSION" = "$INSTALLED" ]]; then
                echo -e "${RED}Update required.${WHITE}\n"
                [ -d "Bin/Hearthstone_Data/MonoBleedingEdge" ] && mv Bin/Hearthstone_Data/MonoBleedingEdge .
                rm -rf Bin/Hearthstone_Data
                rm -rf Data
                rm -rf Hearthstone.app
                rm -rf 'Hearthstone Beta Launcher.app'
                rm -rf Strings
                rm -rf Logs
                download_hearthstone
            fi
        fi
        cd ..
        TARGET_PATH=$(realpath hearthstone)
    else
        # User-specified Hearthstone installation
        TARGET_PATH=$(realpath $1)
    fi
}

check_directory
if [ ! -f "$TARGET_PATH/Bin/Hearthstone.x86_64" ]; then
    download_unity
fi
move_files_and_cleaup
gen_token_login
create_stubs

cat <<EOF >~/.local/share/applications/hearthstone.desktop
[Desktop Entry]
Type=Application
Name=Hearthstone
Exec=$TARGET_PATH/Bin/Hearthstone.x86_64
Icon=$TARGET_PATH/Bin/Hearthstone_Data/Resources/PlayerIcon.icns
Categories=Game;
EOF

chmod +x $TARGET_PATH/login
chmod +x $TARGET_PATH/Bin/Hearthstone.x86_64
echo -e "\n${GREEN}Done. Now generate your web token, before launching the game!${WHITE}"
