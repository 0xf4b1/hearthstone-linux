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
    VERSION=$(curl -s http://${REGION}.patch.battle.net:1119/hsb/versions | grep $REGION)
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

    # Start downloading in the background
    $NGDP_BIN --cdn "http://level3.blizzard.com/tpr/hs" fetch http://${REGION}.patch.battle.net:1119/hsb --tags OSX --tags ${LOCALE} --tags Production &

    DOWNLOAD_PID=$!

    # Start installation in the background
    $NGDP_BIN install http://${REGION}.patch.battle.net:1119/hsb $VERSION --tags OSX --tags ${LOCALE} --tags Production &

    INSTALL_PID=$!

    # Wait for both processes to complete
    wait $DOWNLOAD_PID $INSTALL_PID

    echo $VERSION >.version
}


UNITY_ENGINE=Editor/Data/PlaybackEngines/LinuxStandaloneSupport/Variations/linux64_player_nondevelopment_mono
UNITY_VER=2021.3.25f1
UNITY_INSTALLER_URL=https://download.unity3d.com/download_unity/68ef2c4f8861/LinuxEditorInstaller/Unity.tar.xz
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
    [ ! -f "tmp/Unity.tar.xz" ] && wget -P tmp $UNITY_INSTALLER_URL &     
    UNITY_DOWNLOAD_PID=$!     
    echo -e "${GREEN}Extracting Unity files....${WHITE}\n"     
    wait $UNITY_DOWNLOAD_PID && tar -xf tmp/Unity.tar.xz -C tmp $UNITY_ENGINE/LinuxPlayer $UNITY_ENGINE/UnityPlayer.so $UNITY_ENGINE/Data/MonoBleedingEdge/ &     
    UNITY_EXTRACT_PID=$!     
    wait $UNITY_EXTRACT_PID     
    UNITY_PATH=tmp/$UNITY_ENGINE     
    echo -e "${GREEN}Done!\n${WHITE}"      
    copy_unity_files     
    rm -rf tmp 
}


copy_unity_files() {
    local unity_files=(
        "LinuxPlayer"
        "UnityPlayer.so"
        "Data/MonoBleedingEdge"
    )

    echo -e "${GREEN}Copy Unity files....${WHITE}\n"
    mkdir -p $TARGET_PATH/Bin

    for file in ${unity_files[@]}; do
        cp "$UNITY_PATH/$file" "$TARGET_PATH/Bin/"
    done

    echo -e "${GREEN}Done!\n${WHITE}"
}

move_files_and_cleanup() {
    local files_to_move=(
        "Hearthstone.app/Contents/Resources/Data"
        "Hearthstone.app/Contents/Resources/'unity default resources'"
        "Hearthstone.app/Contents/Resources/PlayerIcon.icns"
        "MonoBleedingEdge"
    )

    echo -e "${GREEN}Moving files & running cleanup ...\n${WHITE}"

    for file in ${files_to_move[@]}; do
        mv "$TARGET_PATH/$file" "$TARGET_PATH/Bin/Hearthstone_Data"
    done

    echo -e "${GREEN}Done!\n${WHITE}"

    echo -e "${GREEN}Cleaning up unecessary files.${WHITE}\n"

    rm -rf $TARGET_PATH/{Hearthstone.app,'Hearthstone Beta Launcher.app'}
}

gen_token_login() {
    make -C login
    cp login/login $TARGET_PATH
}

create_stubs() {
    local files_to_copy=(
        "stubs/CoreFoundation.so"
        "stubs/libOSXWindowManagement.so"
        "stubs/libblz_commerce_sdk_plugin.so"
    )

    sed -e "s/REGION/${REGION}/" -e "s/LOCALE/${LOCALE}/" client.config >$TARGET_PATH/client.config
    mkdir -p $TARGET_PATH/Bin/Hearthstone_Data/Plugins/System/Library/Frameworks/CoreFoundation.framework
    make -C stubs

    for file in ${files_to_copy[@]}; do
        cp "$file" "$TARGET_PATH/Bin/Hearthstone_Data/Plugins"
    done
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

        directories_to_remove=("Bin/Hearthstone_Data" "Data" "Hearthstone.app" "'Hearthstone Beta Launcher.app'" "Strings" "Logs")
        for dir in ${directories_to_remove[@]}; do
            rm -rf $dir
        done

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
Exec=sh -c "cd $TARGET_PATH && ./Bin/Hearthstone.x86_64"
Icon=$TARGET_PATH/Bin/Hearthstone_Data/Resources/PlayerIcon.icns
Categories=Game;
StartupWMClass=Hearthstone.x86_64
EOF

chmod +x $TARGET_PATH/login
chmod +x $TARGET_PATH/Bin/Hearthstone.x86_64
echo -e "\n${GREEN}Done. Now generate your web token, before launching the game!${WHITE}"
