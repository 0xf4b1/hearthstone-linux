# hearthstone-linux

The files in this repository give you the power to craft a Linux-native Hearthstone client. The core game runs perfectly, but the in-game shop remains closed.

Hearthstone is based on the Unity engine, which allows the game to run on multiple platforms, including Linux.
The platform-specific engine files are mostly generic, so we take the official game files and run them with Unity's Linux binaries.
The macOS version of the game uses the OpenGLCore renderer, which we can use perfectly on Linux!

Even though we don't have to modify any of the game internals, please note that this is unofficial and you might risk a ban when using this method.

None of the proprietary files are distributed here, you can retrieve them from the official locations for free.

Hearthstone is ©2014 Blizzard Entertainment, Inc. All rights reserved. Heroes of Warcraft is a trademark, and Hearthstone is a registered trademark of Blizzard Entertainment, Inc. in the U.S. and/or other countries.

## Installation

### 1) Preparation

Install the required packages:

- Debian/Ubuntu

  ```
  sudo apt install build-essential libcrypto++-dev libwebkit2gtk-4.\*-dev git curl python3 python3-venv python-is-python3
  ```

- Arch Linux/Manjaro

  ```
  sudo pacman -S base-devel crypto++ webkit2gtk git curl python python-virtualenv
  ```
- Fedora Silverblue
  ```
  rpm-ostree install webkit2gtk3-devel cryptopp-devel gtk3-devel gcc-c++
  ```

Then clone the repository:

```
git clone --recursive https://github.com/0xf4b1/hearthstone-linux.git && cd hearthstone-linux
```

### 2) Hearthstone installation

Just execute the crafting script.

```
./craft.sh
```
<details>
  <summary>Have a Hearthstone installation from macOS handy?</summary>

If you have an up-to-date Hearthstone installation folder from your Mac `/Applications/Hearthstone` somewhere in place, you can specify the path as the first argument and skip the download. If you also have the needed Unity files, but not at the default location `~/Unity`, you can specify the path as second argument.

```
./craft.sh [<path of the MacOS installation>] [<Unity path>]
```
</details>

The script will download the game in the `hearthstone` directory, so change to this directory after the script succeeds.

```
cd hearthstone
```

### 3) Login

Use the login app inside the `hearthstone` directory to retrieve the authentication token for your account.

```
./login
```

If the login was successful, the app will create a `token` file in the current directory.

### 4) Launch the game!

Simply launch the game via the desktop entry :)

You can also run it from terminal directly via the executable from within the `hearthstone` directory. It is important that your current working directory is the `hearthstone` directory in which the `token` and `client.config` files are present, otherwise the login will not work!

```
Bin/Hearthstone.x86_64
```

Notice: There is an [issue](https://github.com/0xf4b1/hearthstone-linux/issues/7) if you have not completed the introductions for the different game modes with your account.
The animations/videos can't be played, but since newer game versions you don't get stuck anymore and can proceed into the game modes.

## Updating

When you start the game, you get a message that a newer version is available?

Just execute the crafting script again.

```
./craft.sh
```

## FAQ

> Closed
>
> The game was unable to log you in through the Blizzard services. Please wait a few minutes and try again.

> Closed
>
> Oops! Playful sprites have disrupted Hearthstone as it was connecting to our servers. Please wait a few minutes for them to disperse and try again later.

These two messages usually appear when something is wrong with your login token or the way you start the game.

- Did you forget to log in?

Please make sure the file `token` is present inside the `hearthstone` directory.

- Running from terminal?

Please make sure you are in the `hearthstone` directory in which the `token` and `client.config` files are present.

- Did you created the token with a different user?

The `token` is associated with the username that created it, so you will need to log in again with your new user.

> Updating to a newer version takes more time and bandwidth

To download the game files we use `keg`. It is not a full-fledged client and does not support actual patching of the game. Instead, it downloads each changed file again to bring the game up to date.

> The hearthstone directory consumes a lot of disk space

To download the game files, we use `keg`. It downloads all files in the `hearthstone/.ngdp` directory from which it creates the Hearthstone installation.
When updating, it downloads all changed files and reuses old files to bring the game to the latest state.
Since old files are never removed, it can consume a lot of space. However, if we would clean up the directory entirely, we would have to re-download the full game with every update.

If you have other issues, have a look through the [existing issues](https://github.com/0xf4b1/hearthstone-linux/issues?q=) and if that does not help create a [new issue](https://github.com/0xf4b1/hearthstone-linux/issues/new).
Don't forget to add logs from `Bin/Logs/` that might be helpful for troubleshooting.

## How does it work?

The `craft.sh` script copies and rearranges the needed files for your Linux client and additionally does the following tasks:

A file named `client.config` is used by the client for configuration. It will be added with some predefined values, including the option `Aurora.ClientCheck=false` to be able to run the client without the official launcher.

The macOS version has some platform-specific dependencies that we don't have on Linux and prevent the game from launching. The script builds some very simple stubs for the missing libraries, namely `CoreFoundation` and `OSXWindowManagement`.

When the game client is started without the launcher, the game hangs on the title screen and offers no login. This happens even on macOS with the normal installation. But since it tries to read an existing login token from the macOS registry, the `CoreFoundation` stub is used to provide our manually requested token.

The game tries to read the authentication token from the registry AES encrypted with some static parameters. Based on that logic, a small login tool will be built that encrypts and stores it in a file named `token` from which the `CoreFoundation` stub reads it.
