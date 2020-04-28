# hearthstone-linux

Craft your own linux native Hearthstone client

Hearthstone is based on the Unity engine, that allows to deploy to multiple platforms, including linux. The platform specific engine files are mostly generic, so let's take the game files and run them with Unity's linux binaries. Taking the windows version does not work, since it was exported only with Direct3D renderer enabled, but the MacOS version uses the OpenGLCore renderer, that we can perfectly use on linux!

Even though we don't have to modify any of the game internals, please note that this is unofficial and you might risk a ban when using this method.

None of the proprietary files are distributed here, you can retrieve them from the official locations for free.

Hearthstone is ©2014 Blizzard Entertainment, Inc. All rights reserved. Heroes of Warcraft is a trademark, and Hearthstone is a registered trademark of Blizzard Entertainment, Inc. in the U.S. and/or other countries.

## What you need

1) Hearthstone installation from MacOS

Have an up-to-date Hearthstone installation folder from your Mac `/Applications/Hearthstone` somewhere in place.

2) Unity Engine files version 2018.4.10f1

Install Unity Hub from [here](https://store.unity.com/download?ref=personal) and afterwards use this link to install the engine files:

[unityhub://2018.4.10f1/a0470569e97b](unityhub://2018.4.10f1/a0470569e97b)

## Crafting

When you have the files in place, use the `craft.sh` script, that copies and rearranges the needed files for your linux client and additionally does the following tasks:

A file named `client.config` is used by the client for configuration. It will be added with some predefined values, including the option `Aurora.ClientCheck=false` to be able to run the client without the Launcher.

Since we use the MacOS version, it has some platform specific dependencies we don't have on linux, that prevent the game from launching. So let's use some very simple stubs for the missing libraries, that are `CoreFoundation` and `OSXWindowManagement`. `CoreFoundation` is used to read configuration values from the MacOS registry, that additionally allows our stub to provide the game our authentication token.

The game tries to read the authentication token from the registry AES encrypted with some static parameters. Based on that logic, there is a small token tool included that will encrypt a provided webtoken and store it in a file named `token`, where the `CoreFoundation` stub reads it from.

Use the script in the following way:

	$ craft.sh <path of the MacOS installation> <Unity path> <target path>

When the script succeeded, navigate to the target path and continue with requesting a login token for your account. If not, some files may not be in place as expected or you are missing build tools, just check the script and you will see how it is intended.

## Login

When starting the game client without the Launcher, the game is stuck on the title screen and does not offer something like a login. This happens even on MacOS with the normal installation. But since it tries to read an existing token from the registry, we let our stub provide our manually requested token.

Visit the website https://eu.battle.net/login/en/?app=wtcg, enter your account credentials and you will get the webtoken in the browser's address bar via redirection:

	http://localhost:0/?ST=XX-XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX-XXXXXXXXX

Then use the token tool to store the webtoken:

	$ mono token.exe XX-XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX-XXXXXXXXX

Now you should be ready to go, so fingers crossed that the game launches:

	$ Bin/Hearthstone.x86_64