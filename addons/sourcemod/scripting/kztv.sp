#include <sourcemod>

#include "sourcetvmanager"
#include <clientprefs>
#include <gokz/core>

#include <autoexecconfig>

#pragma semicolon 1
#pragma newdecls required

public Plugin myinfo = {
	name = "KZTV",
	author = "zer0.k",
	description = "GOTV integration for GOKZ",
	version = "1.1.2"
}

#define KZTV_CFG "sourcemod/kztv/kztv.cfg"
#define PREFIX " \x0CKZTV \x01| "
bool gB_EnablePostRunMenu[MAXPLAYERS + 1];
Handle gH_KZTVCookie;
ConVar gCV_KZTVAutoRecord;
int gI_StartTick[MAXPLAYERS + 1];
enum ActionType
{
	RESET_SAVE = 0,
	RESET,
	STOP_SAVE,
	STOP,
	START,
}
// ===================
// Plugin Events
// ===================

public void OnPluginStart()
{
	gH_KZTVCookie = RegClientCookie("KZTV-cookie", "cookie for KZTV", CookieAccess_Private);

	for (int client = 1; client <= MaxClients; client++)
	{
		if (IsClientInGame(client) && AreClientCookiesCached(client))
		{
        	OnClientCookiesCached(client);
		}
	}

	RegConsoleCmd("sm_kztv", Command_Menu_KZTV);
	RegConsoleCmd("sm_kztv_togglepostrunmenu", Command_KZTV_TogglePostRunMenu);
	RegConsoleCmd("sm_kztvpostrun", Command_KZTV_TogglePostRunMenu);
	CheckDemoDirectory();
	ExecGOTVConfig();
	CreateConVars();
}

// ===================
// Client Events
// ===================

public void OnClientPutInServer(int client)
{
	if (GetPlayerCount() == 1 && !IsFakeClient(client) && gCV_KZTVAutoRecord.IntValue)
	{
		StartDemo();
	}
}

public void OnClientDisconnect_Post(int client)
{
	if ((GetPlayerCount() == 0) && SourceTV_IsRecording())
	{
		StopDemo(client, false);
	}
}

public void OnClientCookiesCached(int client)
{
	char buffer[2];
	GetClientCookie(client, gH_KZTVCookie, buffer, sizeof(buffer));
	gB_EnablePostRunMenu[client] = !!buffer[0]; // "a hack to convert the char to boolean"
}

public void GOKZ_OnTimerStart_Post(int client, int course)
{
	gI_StartTick[client] = SourceTV_GetRecordingTick();
}

public void GOKZ_OnTimerEnd_Post(int client, int course, float time, int teleportsUsed)
{
	if (gB_EnablePostRunMenu[client])
	{
		Menu_KZTV_PostRun(client);
	}
}

// ===================
// Menu
// ===================

void Menu_KZTV_Confirm(int client, ActionType type, bool addTime = false)
{
	Menu menu = new Menu(Menu_KZTV_ConfirmHandler);

	switch (type)
	{
		case RESET:
		{
			menu.SetTitle("Warning: Resetting demo record will stop everyone's timer!");
			menu.AddItem("ResetDemo", "Yes");
		}
		case START:
		{
			menu.SetTitle("Warning: Starting demo record will stop everyone's timer!");
			menu.AddItem("StartDemo", "Yes");
		}
		case STOP_SAVE:
		{
			menu.SetTitle("Warning: This will stop recording for the entire server!");
			if (addTime)
			{
				menu.AddItem("StopDemo_Save_AddTime", "Yes");
			}
			else
			{
				menu.AddItem("StopDemo_Save", "Yes");
			}
		}
		case STOP:
		{
			menu.SetTitle("Warning: This will stop recording for the entire server without saving!");
			menu.AddItem("StopDemo", "Yes");
		}
		case RESET_SAVE:
		{
			menu.SetTitle("Warning: Resetting demo record will stop everyone's timer!");
			if (addTime)
			{
				menu.AddItem("ResetDemo_Save_AddTime", "Yes");
			}
			else
			{
				menu.AddItem("ResetDemo_Save", "Yes");
			}
		}
	}
	menu.AddItem("No", "No");
	menu.Display(client, MENU_TIME_FOREVER);
}

int Menu_KZTV_ConfirmHandler(Menu menu, MenuAction action, int param1, int param2)
{
	if (action == MenuAction_Select)
	{
		char info[32];
		menu.GetItem(param2, info, sizeof(info));
		if (StrEqual(info, "StartDemo"))
		{
			StartDemo();
		}
		else if (StrEqual(info, "ResetDemo"))
		{
			ResetDemo(param1, false);
		}
		else if (StrEqual(info, "StopDemo_Save"))
		{
			StopDemo(param1, true);
		}
		else if (StrEqual(info, "StopDemo"))
		{
			StopDemo(param1, false);
		}
		else if (StrEqual(info, "ResetDemo_Save"))
		{
			ResetDemo(param1, true);
		}
		else if (StrEqual(info, "StopDemo_Save_AddTime"))
		{
			StopDemo(param1, true, true);
		}
		else if (StrEqual(info, "ResetDemo_Save_AddTime"))
		{
			ResetDemo(param1, true, true);
		}
	}
	else if (action == MenuAction_End)
	{
		delete menu;
	}
}

void Menu_KZTV(int client)
{
	Menu menu = new Menu(Menu_KZTVHandler);
	menu.SetTitle("KZTV Menu");
	if (!SourceTV_IsRecording())
	{
		menu.AddItem("Start Demo", "Start Demo");
		menu.AddItem("Stop Demo", "Stop Demo", ITEMDRAW_DISABLED);
		menu.AddItem("Stop & Save Demo", "Stop & Save Demo", ITEMDRAW_DISABLED);
		menu.AddItem("Reset Demo", "Reset Demo", ITEMDRAW_DISABLED);
		menu.AddItem("Save & Reset Demo", "Save & Reset Demo", ITEMDRAW_DISABLED);
	}
	else
	{
		menu.AddItem("Start Demo", "Start Demo", ITEMDRAW_DISABLED);
		menu.AddItem("Stop Demo", "Stop Demo");
		menu.AddItem("Save & Stop Demo", "Save & Stop Demo");
		menu.AddItem("Reset Demo", "Reset Demo");
		menu.AddItem("Save & Reset Demo", "Save & Reset Demo");
	}
	menu.ExitButton = true;
	menu.Display(client, MENU_TIME_FOREVER);
}

int Menu_KZTVHandler(Menu menu, MenuAction action, int param1, int param2)
{
	if (action == MenuAction_Select)
	{
		char info[32];
		menu.GetItem(param2, info, sizeof(info));
		if (StrEqual(info, "Start Demo"))
		{
			Menu_KZTV_Confirm(param1, START);
		}
		else if (StrEqual(info, "Stop Demo"))
		{
			Menu_KZTV_Confirm(param1, STOP);
		}
		else if (StrEqual(info, "Save & Stop Demo"))
		{
			Menu_KZTV_Confirm(param1, STOP_SAVE);
		}
		else if (StrEqual(info, "Reset Demo"))
		{
			Menu_KZTV_Confirm(param1, RESET);
		}
		else if (StrEqual(info, "Save & Reset Demo"))
		{
			Menu_KZTV_Confirm(param1, RESET_SAVE);
		}
	}
	else if (action == MenuAction_End)
	{
		delete menu;
	}
}

void Menu_KZTV_PostRun(int client)
{
	Menu menu = new Menu(Menu_KZTV_PostRunHandler);
	menu.SetTitle("KZTV Finish Menu");
	if (SourceTV_IsRecording())
	{
		menu.AddItem("Save Demo", "Save this demo");
		menu.AddItem("Save & Start Demo", "Save this demo and start a new one");
		menu.AddItem("Reset Demo", "Start new demo");
	}
	menu.ExitButton = true;
	menu.Display(client, MENU_TIME_FOREVER);
}

int Menu_KZTV_PostRunHandler(Menu menu, MenuAction action, int param1, int param2)
{
	if (action == MenuAction_Select)
	{
		char info[32];
		menu.GetItem(param2, info, sizeof(info));
		if (StrEqual(info, "Save Demo"))
		{
			Menu_KZTV_Confirm(param1, STOP_SAVE, true);
		}
		else if (StrEqual(info, "Save & Start Demo"))
		{
			Menu_KZTV_Confirm(param1, RESET_SAVE, true);
		}
		else if (StrEqual(info, "Reset Demo"))
		{
			Menu_KZTV_Confirm(param1, RESET);
		}
	}
	else if (action == MenuAction_End)
	{
		delete menu;
	}
}
// ===================
// Commands
// ===================

public Action Command_KZTV_TogglePostRunMenu(int client, int args)
{
	gB_EnablePostRunMenu[client] = !gB_EnablePostRunMenu[client];
	if (gB_EnablePostRunMenu[client])
	{
		PrintToChat(client, "%s\8Post-run KZTV Menu enabled.", PREFIX);
	}
	else
	{
		PrintToChat(client, "%s\8Post-run KZTV Menu disabled.", PREFIX);
	}
	if (AreClientCookiesCached(client))
	{
		char buffer[2];
		IntToString(gB_EnablePostRunMenu[client], buffer, sizeof(buffer));
		SetClientCookie(client, gH_KZTVCookie, buffer);
	}
	return Plugin_Handled;
}

public Action Command_Menu_KZTV(int client, int args)
{
	Menu_KZTV(client);
	return Plugin_Handled;
}

// ===================
// Timers
// ===================


static Action Timer_StartWarmup(Handle timer)
{
	ServerCommand("mp_warmup_start");
}

static Action Timer_StartRecording(Handle timer)
{
	RecordDemo();
}

static Action Timer_StopWarmup(Handle timer)
{
	ServerCommand("mp_warmup_end");
	return Plugin_Handled;
}

// ===================
// Demo functions
// ===================

void RecordDemo()
{
	FindConVar("tv_delay").IntValue = 0;

	char demoName[PLATFORM_MAX_PATH];
	char timestamp[11];
	char map[PLATFORM_MAX_PATH];
	char demoPath[PLATFORM_MAX_PATH];

	IntToString(GetTime(), timestamp, sizeof(timestamp));
	GetCurrentMap(map, sizeof(map));
	GetMapDisplayName(map, demoName, sizeof(demoName));

	StrCat(demoName, sizeof(demoName), "_");
	StrCat(demoName, sizeof(demoName), timestamp);
	Format(demoPath, sizeof(demoPath), "demos/%s", demoName);
	SourceTV_StartRecording(demoPath);
}

void StartDemo()
{
	if (SourceTV_IsActive() && !SourceTV_IsRecording())
	{
		PrintToChatAll("%sRecording Demo...", PREFIX);
		// Making sure that the replay does not get corrupted and the server does not crash
		FindConVar("mp_restartgame").IntValue = 1;
		CreateTimer(1.1, Timer_StartWarmup);
		CreateTimer(1.2, Timer_StartRecording);
		CreateTimer(1.3, Timer_StopWarmup);
	}
}

void StopDemo(int client, bool save, bool addTime = false)
{
	char fileName[64];
	SourceTV_GetDemoFileName(fileName, sizeof(fileName));
	if (!save)
	{
		PrintToChatAll("%sStopping demo record...", PREFIX);
		SourceTV_StopRecording();
		DeleteFile(fileName);
	}
	else
	{
		SourceTV_StopRecording();
		if (addTime)
		{
			char buffer[2][64];
			char demoPath[PLATFORM_MAX_PATH];
			ExplodeString(fileName,".dem", buffer, 2, 64);
			Format(demoPath, sizeof(demoPath), "%s_%i.dem", buffer[0], gI_StartTick[client]);
			RenameFile(demoPath, fileName);
			PrintToChatAll("%sDemo saved as %s.", PREFIX, demoPath);
		}
		else
		{
			PrintToChatAll("%sDemo saved as %s.", PREFIX, fileName);
		}
	}
}

void ResetDemo(int client, bool save, bool addTime = false)
{
	StopDemo(client, save, addTime);
	StartDemo();
}

// ===================
// Misc.
// ===================

void ExecGOTVConfig()
{
	char gotvCfgPath[PLATFORM_MAX_PATH];
	FormatEx(gotvCfgPath, sizeof(gotvCfgPath), "cfg/%s", KZTV_CFG);
	if (FileExists(gotvCfgPath))
	{
		ServerCommand("exec %s", KZTV_CFG);
	}
	else
	{
		SetFailState("Failed to load file: \"%s\". Check that it exists.", gotvCfgPath);
	}
}

int GetPlayerCount()
{
	int PlayerNumb = 0;
	for (int x = 1; x <= MaxClients; x++)
	{
		if(IsClientInGame(x) && !IsFakeClient(x))
		{
			PlayerNumb++;
		}
	}
	return PlayerNumb;
}

void CheckDemoDirectory()
{
	if (!DirExists("demos"))
	{
		CreateDirectory("demos", 511);
	}
}

void CreateConVars()
{
	AutoExecConfig_SetFile("kztv-cvars", "sourcemod/kztv");
	AutoExecConfig_SetCreateFile(true);

	gCV_KZTVAutoRecord = AutoExecConfig_CreateConVar("kztv_autorecord", "1", "Enable KZTV autorecording.", _, true, 0.0, true, 1.0);

	AutoExecConfig_ExecuteFile();
	AutoExecConfig_CleanFile();
}
