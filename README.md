# KZTV

![Downloads](https://img.shields.io/github/downloads/zer0k-z/kztv/total?style=flat-square) ![Last commit](https://img.shields.io/github/last-commit/zer0k-z/kztv?style=flat-square) ![Open issues](https://img.shields.io/github/issues/zer0k-z/kztv?style=flat-square) ![Closed issues](https://img.shields.io/github/issues-closed/zer0k-z/kztv?style=flat-square) ![Size](https://img.shields.io/github/repo-size/zer0k-z/kztv?style=flat-square) ![GitHub Workflow Status](https://img.shields.io/github/workflow/status/zer0k-z/kztv/Compile%20with%20SourceMod?style=flat-square)

## Description ##

GOTV demo integration for GOKZ.

***Warning!*** 
1. Everyone has access to these commands. 
2. Starting a demo record will stop **ALL** running timers! This should change after GOKZ v2.11.4.

Therefore it is not recommended to run the plugin in public servers. Enabling the GOTV recordings is ideal for small, private and tournament servers.

### **GOTV demos vs POV demos vs GOKZ replays** ###

Unlike GOKZ replays, demos can be played directly by the game client without the need of a LAN/listen server. Demos have more accurate sounds compared to GOKZ replays. 

GOTV demos allow for the most flexibility with moviemaking as campaths can be done alongside the actual run to create more interesting edits. Furthermore, GOKZ player models are currently broken with no player animation, making GOTV demos the better choice for video editors.

GOTV demos are not affected by latency like POV demos are.

Furthermore, POV demos can also be corrupted without a map restart, and cannot be recorded midgame due to a recent update, though this can be fixed by [this plugin](https://github.com/zer0k-z/demo-record-fix).

There are downsides to GOTV demos compared to GOKZ replays. As demos save the state of the entire game (compared to player info only in GOKZ replays), demos can be 10x the size of a replay file. Furthermore, as demos record everything since the start of the map and not just one run, its size can be significantly bigger than GOKZ replay files.

## Requirements ##
- Sourcemod and Metamod
- GOKZ (and its dependencies)
- SourceTVManager extension (already included)

## Installation ##
1. Grab the latest release from the release page and unzip it in your sourcemod folder.
2. Restart the server or type `sm plugins load kztv` in the console to load the plugin.
3. The config file will be automatically generated in ``cfg/sourcemod/kztv``.

## Configuration ##
- You can modify GOTV convars in ``cfg/sourcemod/kztv/kztv.cfg``.
- Autorecord convar can be found in ``cfg/sourcemod/kztv/kztv-cvars.cfg``.

## Commands ##
- ``!kztv`` - Display KZTV menu
- ``!kztv_togglepostrunmenu`` / ``!kztvpostrun`` - Toggle GOKZ post-run menu.

## Issues/Bugs ##
- There is no chat log in demos. This is caused by GOKZ not sending messages to chat. A [pull request](https://bitbucket.org/kztimerglobalteam/gokz/pull-requests/179) to GOKZ has been made to address the problem.
- Server crashes after waking up from hibernate. This is an issue of the game itself, currently there's no known fix for this.

## Todo
- Add a way to manage demos
- FTP upload demos upon requests
