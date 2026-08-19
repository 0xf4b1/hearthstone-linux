#!/bin/bash

set -e

NGDP_BIN=$(realpath keg/bin/ngdp)
RED='\e[31m'
GREEN='\e[32m'
YELLOW='\e[33m'
WHITE='\e[37m'

print() {
    printf "$1$2\n${WHITE}"
}

info() {
    print $GREEN "$1"
}

warn() {
    print $YELLOW "$1"
}

error() {
    print $RED "$1"
}

create_venv() {
    info "Creating python venv for keg ..."
    python -m venv venv
    source venv/bin/activate
    pushd keg
    pip install .
    popd
}

check_keg()
{
    $NGDP_BIN --help >/dev/null
}

ensure_keg() {
    if [ ! -d venv ]; then
      create_venv
    fi
    source venv/bin/activate
    check_keg || (create_venv && check_keg) || (error "keg is not working" && exit 1)
}

set_region() {
    if [ -f ".region" ]; then
        REGION=$(cat .region)
        return
    fi

    read -p "Which region do you wish to install? [eu/us/kr/cn]: " REGION
    if [ "${REGION}" != "eu" ] && [ "${REGION}" != "us" ] && [ "${REGION}" != "kr" ] && [ "${REGION}" != "cn" ]; then
        error "Invalid Region. Exiting."
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
        error "Invalid Locale. Exiting."
        exit 1
    fi
    echo $LOCALE >.locale
}

init_hearthstone() {
    mkdir hearthstone && pushd hearthstone
    set_region
    $NGDP_BIN init
    $NGDP_BIN remote add http://${REGION}.patch.battle.net:1119/hsb
}

check_version() {
    set_region
    set_locale
    VERSION=$(curl -sL http://${REGION}.patch.battle.net:1119/hsb/versions | grep $REGION)
    VERSION=${VERSION%|*}
    VERSION=${VERSION##*|}

    INSTALLED="Not installed"
    if [ -f ".version" ]; then
        INSTALLED=$(cat .version)
    fi

    info "Region: $REGION"
    info "Online version: $VERSION"
    info "Installed version: $INSTALLED"
}

download_hearthstone() {
    info "Downloading Hearthstone via keg ..."
    CDN_DOMAIN="http://level3.blizzard.com/tpr/hs"
    if [ "${REGION}" == "cn" ]; then
        # China mainland region uses different CDN from blizzard
        CDN_DOMAIN="https://blzdist-hs.necdn.leihuo.netease.com/tpr/hs"
        info "Using CN CDN from netease: $CDN_DOMAIN"
    fi
    $NGDP_BIN --cdn "${CDN_DOMAIN}" fetch http://${REGION}.patch.battle.net:1119/hsb --tags OSX --tags ${LOCALE} --tags Production
    $NGDP_BIN install http://${REGION}.patch.battle.net:1119/hsb $VERSION --tags OSX --tags ${LOCALE} --tags Production
    echo $VERSION >.version
}

UNITY_ENGINE=Editor/Data/PlaybackEngines/LinuxStandaloneSupport/Variations/linux64_player_nondevelopment_mono

check_unity() {
    UNITY_VER=`strings "Bin/Hearthstone_Data/level0" | head -n 1`
    [ -z "$UNITY_VER" ] && error "Can not determine required Unity version!" && exit 1
    UNITY_INSTALLED="Not installed"
    if [ -f ".unity" ]; then
        UNITY_INSTALLED=$(cat .unity)
    fi

    info "Required Unity version: $UNITY_VER"
    info "Installed Unity version: $UNITY_INSTALLED"

    if [[ "$UNITY_VER" = "$UNITY_INSTALLED" ]]; then
        # Unity files are present already in case of updating
        [ -d "MonoBleedingEdge" ] && mv MonoBleedingEdge Bin/Hearthstone_Data
        return
    fi

    warn "Update required."
    rm -rf MonoBleedingEdge
    UNITY_HUB=/Hub/Editor/$UNITY_VER/$UNITY_ENGINE
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
    mkdir -p tmp
    pushd tmp

    info "Fetching Unity archive ..."

    # Use Unity Hub release API to retrieve archive hash
    curl --silent "https://services.api.unity.com/unity/editor/release/v1/releases?version=$UNITY_VER&limit=5" \
        -o archive \
        || (error "Could not fetch Unity archive" && exit 1)

    HASH=`grep -oE "unityhub://$UNITY_VER/\w+" archive | cut -d/ -f4` || (error "Unity version not found in archive" && exit 1)
    URL="https://download.unity3d.com/download_unity/$HASH/LinuxEditorInstaller/Unity.tar.xz"

    info "Downloading Unity from $URL ..."
    curl $URL -o Unity.tar.xz || (error "Could not download Unity" && exit 1)

    info "Extracting Unity ..."
    tar -xf Unity.tar.xz $UNITY_ENGINE/LinuxPlayer $UNITY_ENGINE/UnityPlayer.so $UNITY_ENGINE/Data/MonoBleedingEdge/
    UNITY_PATH=$PWD/$UNITY_ENGINE

    popd
    copy_unity_files
    rm -rf tmp
}

copy_unity_files() {
    info "Copy Unity files ..."
    cp $UNITY_PATH/LinuxPlayer Bin/Hearthstone.x86_64
    cp $UNITY_PATH/UnityPlayer.so Bin/
    cp -r $UNITY_PATH/Data/MonoBleedingEdge Bin/Hearthstone_Data
    echo $UNITY_VER >.unity
}

transform_installation() {
    if [ ! -d Hearthstone.app ]; then
        # Installation already transformed
        return
    fi
    info "Transform installation ..."

    # Move the game's Unity data bundle (level0, globalgamemanagers,
    # resources.assets, Managed, ...) into Bin/Hearthstone_Data. Drop any stale
    # target so the move renames Data into place instead of nesting inside it.
    mkdir -p Bin
    rm -rf Bin/Hearthstone_Data
    mv Hearthstone.app/Contents/Resources/Data Bin/Hearthstone_Data

    mkdir -p Bin/Hearthstone_Data/Resources
    # In some game builds the Unity built-in resources live outside Data/
    if [ -f "Hearthstone.app/Contents/Resources/unity default resources" ]; then
        mv Hearthstone.app/Contents/Resources/'unity default resources' Bin/Hearthstone_Data/Resources
    fi
    mv Hearthstone.app/Contents/Resources/PlayerIcon.icns Bin/Hearthstone_Data/Resources

    rm -rf Hearthstone.app
    rm -rf 'Hearthstone Beta Launcher.app'
}

create_compatibility_files() {
    info "Create compatibility files ..."

    sed -e "s/REGION/${REGION}/" -e "s/LOCALE/${LOCALE}/" client.config >$TARGET_PATH/client.config

    mkdir -p $TARGET_PATH/Bin/Hearthstone_Data/Plugins/System/Library/Frameworks/CoreFoundation.framework
    make -C stubs
    cp stubs/CoreFoundation.so $TARGET_PATH/Bin/Hearthstone_Data/Plugins/System/Library/Frameworks/CoreFoundation.framework
    cp stubs/libOSXWindowManagement.so $TARGET_PATH/Bin/Hearthstone_Data/Plugins
    cp stubs/libblz_commerce_sdk_plugin.so $TARGET_PATH/Bin/Hearthstone_Data/Plugins

    # The game P/Invokes CoreFoundation via the macOS absolute path, which Mono
    # can't find on Linux. Map it to the stub.
    MONO_CONFIG=$TARGET_PATH/Bin/Hearthstone_Data/MonoBleedingEdge/etc/mono/config
    if [ -f $MONO_CONFIG ] && ! grep -q 'dll="/System/Library/Frameworks/CoreFoundation.framework/CoreFoundation"' $MONO_CONFIG; then
        sed -i "s|</configuration>|    <dllmap dll=\"/System/Library/Frameworks/CoreFoundation.framework/CoreFoundation\" target=\"$TARGET_PATH/Bin/Hearthstone_Data/Plugins/System/Library/Frameworks/CoreFoundation.framework/CoreFoundation.so\" os=\"!osx\"/>\n</configuration>|" $MONO_CONFIG
    fi

    make -C login
    cp login/login $TARGET_PATH
}

check_directory() {
    if [ $1 ]; then
        # User-specified Hearthstone installation
        set_region
        pushd $1
        TARGET_PATH=$PWD
        return
    fi

    ensure_keg

    # Managed Hearthstone installation via keg
    if [ ! -d hearthstone ]; then
        warn "Hearthstone installation not found"
        init_hearthstone
    else
        pushd hearthstone
        # Reinitialize ngdp if db is corrupt/empty
        if [ ! -s .ngdp/keg.db ] || ! $NGDP_BIN fsck >/dev/null 2>&1; then
            warn "keg database is empty or corrupt, reinitializing ..."
            set_region
            $NGDP_BIN init
            $NGDP_BIN remote add http://${REGION}.patch.battle.net:1119/hsb
        fi
    fi

    # Update procedure
    check_version
    if [[ ! "$VERSION" = "$INSTALLED" ]]; then
        warn "Update required."
        [ -d "Bin/Hearthstone_Data/MonoBleedingEdge" ] && mv Bin/Hearthstone_Data/MonoBleedingEdge .
        rm -rf Bin/Hearthstone_Data
        rm -rf Data
        rm -rf Strings
        rm -rf Logs
        rm -rf BlizzardBrowser
        download_hearthstone
    fi

    TARGET_PATH=$PWD
}

check_directory $1
transform_installation
check_unity $2
popd
create_compatibility_files

mkdir -p ~/.local/share/applications

cat <<EOF >~/.local/share/applications/hearthstone.desktop
[Desktop Entry]
Type=Application
Name=Hearthstone
Path=$TARGET_PATH
Exec=Bin/Hearthstone.x86_64
Icon=$TARGET_PATH/Bin/Hearthstone_Data/Resources/PlayerIcon.icns
Categories=Game;
StartupWMClass=Hearthstone.x86_64
EOF

info "Done."
[ -f "$TARGET_PATH/token" ] || (warn "Please create your login token before launching the game!" && $TARGET_PATH/login)
