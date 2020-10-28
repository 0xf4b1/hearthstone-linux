# hearthstone-linux

Craft your own linux native Hearthstone client

*Tested with client version 17.4.0.49534*

Hearthstone is based on the Unity engine, that allows to deploy to multiple platforms, including linux. The platform specific engine files are mostly generic, so let's take the game files and run them with Unity's linux binaries. Taking the windows version does not work, since it was exported only with Direct3D renderer enabled, but the MacOS version uses the OpenGLCore renderer, that we can perfectly use on linux!

Even though we don't have to modify any of the game internals, please note that this is unofficial and you might risk a ban when using this method.

None of the proprietary files are distributed here, you can retrieve them from the official locations for free.

Hearthstone is ©2014 Blizzard Entertainment, Inc. All rights reserved. Heroes of Warcraft is a trademark, and Hearthstone is a registered trademark of Blizzard Entertainment, Inc. in the U.S. and/or other countries.

## Installation

1) Hearthstone installation from MacOS

Have an up-to-date Hearthstone installation folder from your Mac `/Applications/Hearthstone` somewhere in place.

2) Unity Engine files version 2018.4.10f1

Install Unity Hub from [here](https://store.unity.com/download?ref=personal) and afterwards use this link to install the engine files:

[unityhub://2018.4.10f1/a0470569e97b](unityhub://2018.4.10f1/a0470569e97b)

3) Execute the crafting script in the following way:

```
$ craft.sh <path of the MacOS installation> <Unity path> <target path>
```

4) Login

Visit the website https://eu.battle.net/login/en/?app=wtcg, enter your account credentials and you will get the authentication token in the browser's address bar via redirection, similarly to this:

```
http://localhost:0/?ST=XX-XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX-XXXXXXXXX
```

Store the token:

```
$ mono token.exe XX-XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX-XXXXXXXXX
```

5) Launch the game!

```
$ Bin/Hearthstone.x86_64
```

The game runs perfectly besides some features, like the in-game shop, due to missing libraries.

If you are interested what's going on behind the scenes, you can continue reading.

## Crafting

The `craft.sh` script copies and rearranges the needed files for your linux client and additionally does the following tasks:

A file named `client.config` is used by the client for configuration. It will be added with some predefined values, including the option `Aurora.ClientCheck=false` to be able to run the client without the Launcher.

Since we use the MacOS version, it has some platform specific dependencies we don't have on linux, that prevent the game from launching. The script builds some very simple stubs for the missing libraries, that are `CoreFoundation` and `OSXWindowManagement`.

When starting the game client without the Launcher, the game is stuck on the title screen and does not offer something like a login. This happens even on MacOS with the normal installation. But since it tries to read an existing login token from the MacOS registry, the `CoreFoundation` stub is used to provide our manually requested token.

The game tries to read the authentication token from the registry AES encrypted with some static parameters. Based on that logic, a small token tool will be built that encrypts a provided webtoken and stores it in a file named `token`, where the `CoreFoundation` stub reads it from.
