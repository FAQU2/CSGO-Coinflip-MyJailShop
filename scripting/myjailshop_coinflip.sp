#include <sourcemod>
#include <sdktools>
#include <cstrike>
#include <myjailshop>
#include <kento_csgocolors>

#pragma semicolon 1
#pragma newdecls required

ConVar gc_iMinAmount;
ConVar gc_iMaxAmount;
ConVar gc_iWinChance;

bool g_bCoinflipLimit[MAXPLAYERS + 1] = false;

public Plugin myinfo = 
{
	name = "Coinflip for MyJailShop",
	author = "FAQU",
	description = "Coinflip system for MyJailShop",
	version = "1.0"
};

public void OnPluginStart()
{
	LoadTranslations("MyJailShop.phrases");
	LoadTranslations("MyJailShop.Coinflip.phrases");
	
	HookEvent("round_start", Event_RoundStart);
	
	RegConsoleCmd("sm_coinflip", Command_Coinflip);
	
	gc_iMinAmount = CreateConVar("sm_coinflip_minamount", "10", "Minimum amount of credits needed for coinflip");
	gc_iMaxAmount = CreateConVar("sm_coinflip_maxamount", "100", "Maximum amount of credits allowed for coinflip");
	gc_iWinChance = CreateConVar("sm_coinflip_winchance", "50", "% - Winning chance for coinflip");
	
	AutoExecConfig(true, "Coinflip", "MyJailShop");
}

public void OnClientPutInServer(int client)
{
	ResetLimit(client);
}

public void OnClientDisconnect(int client)
{
	ResetLimit(client);
}

public Action Event_RoundStart(Handle event, const char[] name, bool dontBroadcast)
{
	for (int i = 1; i <= MaxClients; i++)
	{
		if (IsClientInGame(i) && g_bCoinflipLimit[i])
		{
			ResetLimit(i);
		}
	}
}

public Action Command_Coinflip(int client, int args)
{
	if (args != 1)
	{
		ReplyToCommand(client, "[SM] Usage: sm_coinflip <credits>");
		return Plugin_Handled;
	}
	if (GetClientTeam(client) == CS_TEAM_SPECTATOR)
	{
		CPrintToChat(client, "%t %t", "shop_tag", "coin_spectators");
		return Plugin_Handled;
	}
	if (g_bCoinflipLimit[client])
	{
		CPrintToChat(client, "%t %t", "shop_tag", "coin_roundlimit");
		return Plugin_Handled;
	}
	
	char arg1[32];
	GetCmdArg(1, arg1, sizeof(arg1));
	int amount = StringToInt(arg1);
	int currentcredits = MyJailShop_GetCredits(client);
	
	if (amount > currentcredits)
	{
		CPrintToChat(client, "%t %t", "shop_tag", "coin_notenough");
		return Plugin_Handled;
	}
	if(amount < gc_iMinAmount.IntValue)
	{
		CPrintToChat(client, "%t %t", "shop_tag", "coin_minimum", gc_iMinAmount.IntValue);
		return Plugin_Handled;
	}
	if(amount > gc_iMaxAmount.IntValue)
	{
		CPrintToChat(client, "%t %t", "shop_tag", "coin_maximum", gc_iMaxAmount.IntValue);
		return Plugin_Handled;
	}
	
	int random = GetRandomInt(1, 100);
	
	if (random > gc_iWinChance.IntValue)
	{
		MyJailShop_SetCredits(client, currentcredits - amount);
		CPrintToChat(client, "%t %t", "shop_tag", "coin_lost", amount);
		g_bCoinflipLimit[client] = true;
		return Plugin_Handled;
	}
	if (random < gc_iWinChance.IntValue)
	{
		MyJailShop_SetCredits(client, currentcredits + amount);
		CPrintToChat(client, "%t %t", "shop_tag", "coin_won", amount);
		g_bCoinflipLimit[client] = true;
		return Plugin_Handled;
	}
	return Plugin_Handled;
}

void ResetLimit(int client)
{
	g_bCoinflipLimit[client] = false;
}