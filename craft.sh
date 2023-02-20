#!/bin/bash

set -e

NGDP_BIN=$(realpath keg/bin/ngdp)
GREEN='\e[32m'
RED='\e[31m'
WHITE='\e[37m'

setup_keg() {
    cd keg
    pip install .
    cd ..
}

set_region() {
    if [ -f ".region" ]; then
        REGION=$(cat .region)
        return
    fi

    read -p "Which region do you wish to install? [eu/us/kr/cn]: " REGION
    if [ "${REGION}" != "eu" ] && [ "${REGION}" != "us" ] && [ "${REGION}" != "kr" ] && [ "${REGION}" != "cn" ]; then
        echo -e "${RED}Invalid Region. Exiting."
        exit 1
    fi
    echo $REGION >.region
}

set_locale() {
    if [ -f ".locale" ]; then
        LOCALE=$(cat .locale)
        return
    fi

    read -p "Which locale do you wish to install? [deDE/enGB/enUS/esES/esMX/frFR/itIT/jaJP/koKR/plPL/ptBR/ruRU/thTH/zhCN/zhTW]: " LOCALE
    if [ "${LOCALE}" != "deDE" ] && [ "${LOCALE}" != "enGB" ] && [ "${LOCALE}" != "enUS" ] && [ "${LOCALE}" != "esES" ] \
        && [ "${LOCALE}" != "esMX" ] && [ "${LOCALE}" != "frFR" ] && [ "${LOCALE}" != "itIT" ] && [ "${LOCALE}" != "jaJP" ] \
        && [ "${LOCALE}" != "koKR" ] && [ "${LOCALE}" != "plPL" ] && [ "${LOCALE}" != "ptBR" ] && [ "${LOCALE}" != "ruRU" ] \
        && [ "${LOCALE}" != "thTH" ] && [ "${LOCALE}" != "zhCN" ] && [ "${LOCALE}" != "zhTW" ]; then
        echo -e "${RED}Invalid Locale. Exiting."
        exit 1
    fi
    echo $LOCALE >.locale
}

init_hearthstone() {
    mkdir hearthstone && cd hearthstone
    set_region
    $NGDP_BIN init
    $NGDP_BIN remote add http://${REGION}.patch.battle.net:1119/hsb
}

check_version() {
    set_region
    set_locale
    VERSION=$(curl http://${REGION}.patch.battle.net:1119/hsb/versions | grep $REGION)
    VERSION=${VERSION%|*}
    VERSION=${VERSION##*|}

    INSTALLED="Not installed"
    if [ -f ".version" ]; then
        INSTALLED=$(cat .version)
    fi

    echo -e "${GREEN}Region: ${WHITE}$REGION"
    echo -e "${GREEN}Online version: ${WHITE}$VERSION"
    echo -e "${GREEN}Downloaded version: ${WHITE}$INSTALLED"
}

download_hearthstone() {
    echo -e "${GREEN}Downloading Hearthstone via keg ...${WHITE}\n"
    $NGDP_BIN --cdn "http://level3.blizzard.com/tpr/hs" fetch http://${REGION}.patch.battle.net:1119/hsb --tags OSX --tags ${LOCALE} --tags Production
    $NGDP_BIN install http://${REGION}.patch.battle.net:1119/hsb $VERSION --tags OSX --tags ${LOCALE} --tags Production
    echo $VERSION >.version
}

UNITY_ENGINE=Editor/Data/PlaybackEngines/LinuxStandaloneSupport/Variations/linux64_withgfx_nondevelopment_mono
UNITY_VER=2019.4.37f1
UNITY_INSTALLER_URL=https://download.unity3d.com/download_unity/019e31cfdb15/LinuxEditorInstaller/Unity.tar.xz
UNITY_HUB=/Hub/Editor/$UNITY_VER/$UNITY_ENGINE

check_unity() {
    if [ -f "$TARGET_PATH/Bin/Hearthstone.x86_64" ]; then
        # Unity files are present already in case of updating
        return
    fi

    if [ $1 ]; then
        # Unity files supplied via second argument
        UNITY_PATH=$1$UNITY_HUB
        copy_unity_files
    elif [ -d ~/Unity$UNITY_HUB ]; then
        # Check for unity files in default location
        UNITY_PATH=~/Unity$UNITY_HUB
        copy_unity_files
    else
        # Download unity files directly
        download_unity
    fi
}

download_unity() {
    echo -e "${RED}Unity files not found.\n${GREEN}Downloading Unity ${UNITY_VER} (This version is required for the game to run).${WHITE}\n"
    mkdir -p tmp
    [ ! -f "tmp/Unity.tar.xz" ] && wget -P tmp $UNITY_INSTALLER_URL

    echo -e "${GREEN}Extracting Unity files....${WHITE}\n"
    tar -xf tmp/Unity.tar.xz -C tmp $UNITY_ENGINE/LinuxPlayer $UNITY_ENGINE/UnityPlayer.so $UNITY_ENGINE/Data/MonoBleedingEdge/
    UNITY_PATH=tmp/$UNITY_ENGINE
    echo -e "${GREEN}Done!\n${WHITE}"

    copy_unity_files
    rm -rf tmp
}

copy_unity_files() {
    echo -e "${GREEN}Copy Unity files....${WHITE}\n"
    mkdir -p $TARGET_PATH/Bin
    cp $UNITY_PATH/LinuxPlayer $TARGET_PATH/Bin/Hearthstone.x86_64
    cp $UNITY_PATH/UnityPlayer.so $TARGET_PATH/Bin/
    cp -r $UNITY_PATH/Data/MonoBleedingEdge $TARGET_PATH
    echo -e "${GREEN}Done!\n${WHITE}"
}

move_files_and_cleanup() {
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
    make -C login
    cp login/login $TARGET_PATH
}

create_stubs() {
    sed -e "s/REGION/${REGION}/" -e "s/LOCALE/${LOCALE}/" client.config >$TARGET_PATH/client.config
    mkdir -p $TARGET_PATH/Bin/Hearthstone_Data/Plugins/System/Library/Frameworks/CoreFoundation.framework
    make -C stubs
    cp stubs/CoreFoundation.so $TARGET_PATH/Bin/Hearthstone_Data/Plugins/System/Library/Frameworks/CoreFoundation.framework
    cp stubs/libOSXWindowManagement.so $TARGET_PATH/Bin/Hearthstone_Data/Plugins
    cp stubs/libblz_commerce_sdk_plugin.so $TARGET_PATH/Bin/Hearthstone_Data/Plugins
}

check_directory() {
    if [ $1 ]; then
        # User-specified Hearthstone installation
        set_region
        TARGET_PATH=$(realpath $1)
        return
    fi

    # Managed Hearthstone installation via keg
    if [ ! -d hearthstone ]; then
        echo -e "${RED}Hearthstone installation not found${WHITE}\n"
        setup_keg
        init_hearthstone
    else
        cd hearthstone
    fi

    # Update procedure
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

    cd ..
    TARGET_PATH=$(realpath hearthstone)
}

check_directory $1
check_unity $2
move_files_and_cleanup
gen_token_login
create_stubs

cat <<EOF >~/.local/share/applications/hearthstone.desktop
[Desktop Entry]
Type=Application
Name=Hearthstone
Exec=sh -c "cd $TARGET_PATH && ./Bin/Hearthstone.x86_64 -launch"
Icon=$TARGET_PATH/Bin/Hearthstone_Data/Resources/PlayerIcon.icns
Categories=Game;
StartupWMClass=Hearthstone.x86_64
EOF

chmod +x $TARGET_PATH/login
chmod +x $TARGET_PATH/Bin/Hearthstone.x86_64
echo -e "\n${GREEN}Done. Now generate your web token, before launching the game!${WHITE}"
