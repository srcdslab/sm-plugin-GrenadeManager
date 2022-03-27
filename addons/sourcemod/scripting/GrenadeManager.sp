#include <sourcemod>
#include <sdktools>
#include <zombiereloaded>

#pragma tabsize 0

ConVar g_cvHePrice
ConVar g_cvSmokePrice;
ConVar g_cvExtraSmoke;
ConVar g_cvNadeEffect;

int g_iFireSprite;
int g_iLaserBeamSprite;
int g_LaserSprite;
int g_iHaloSprite;

bool g_bRoundEnd = false;

public Plugin myinfo =
{
    name = "[ZR] Grenades",
    author = "ire.",
	description = "Manage grenade cost, count on spawn, vip extras...",
	version = "1.2"
};

public void OnPluginStart()
{
    RegConsoleCmd("sm_he", BuyHe);
	RegConsoleCmd("sm_smoke", BuySmoke);
	
	HookEvent("player_spawn", Event_PlayerSpawn);
	HookEvent("round_end", Event_RoundEnd);
	HookEvent("round_start", Event_RoundStart);
	HookEvent("hegrenade_detonate", Event_HeGrenadeDetonate);
	HookEvent("smokegrenade_detonate", Event_SmokeGrenadeDetonate);
	
	g_cvHePrice = CreateConVar("sm_he_cost", "5000", "Price of He Grenade");
	g_cvSmokePrice = CreateConVar("sm_smoke_cost", "8000", "Price of Smoke Grenade");
	g_cvExtraSmoke = CreateConVar("sm_extra_smoke", "1", "Give VIP player a free Smoke Grenade on spawn");
	g_cvNadeEffect = CreateConVar("sm_nade_effect", "1", "Create a grenade effect on He Grenade and Smoke Grenade explosion");
	AutoExecConfig();
}

public void OnMapStart()
{
    PrecacheSound("items/medshot4.wav");
	g_iFireSprite = PrecacheModel("materials/sprites/xfireball3.vmt");
	g_iLaserBeamSprite = PrecacheModel("materials/sprites/laserbeam.vmt");
	g_LaserSprite = PrecacheModel("sprites/laser.vmt");
	g_iHaloSprite = PrecacheModel("sprites/halo.vmt");
}

public Action BuyHe(int client, int args)
{
	if(!IsValidClient(client) || g_bRoundEnd) 
	{
		return Plugin_Handled;
	}
	
	if(GetEntProp(client, Prop_Send, "m_iAccount") >= g_cvHePrice.IntValue)
	{
		if(GetEntProp(client, Prop_Send, "m_iAmmo", 4, 11) > 0)
		{
			PrintToChat(client, "[SM] You already have a HE Grenade.");
			return Plugin_Handled;
		}
		GivePlayerItem(client, "weapon_hegrenade");
		EmitSoundToClient(client, "items/medshot4.wav");
		SetEntProp(client, Prop_Send, "m_iAccount", GetEntProp(client, Prop_Send, "m_iAccount") - g_cvHePrice.IntValue);
		return Plugin_Handled;
	}
	
	else
	{
		PrintToChat(client, "[SM] You have insufficient funds (Price: $%d).", g_cvHePrice.IntValue);
		return Plugin_Handled;
	}
}

public Action BuySmoke(int client, int args)
{	
	if(!IsValidClient(client) || !HasAccess(client) || g_bRoundEnd) 
	{
		return Plugin_Handled;
	}
	
	if(GetEntProp(client, Prop_Send, "m_iAccount") >= g_cvSmokePrice.IntValue)
	{
		if(GetEntProp(client, Prop_Send, "m_iAmmo", 4, 13) > 0)
		{
			PrintToChat(client, "[SM] You already have a Smoke Grenade.");
			return Plugin_Handled;
		}
		GivePlayerItem(client, "weapon_smokegrenade");
		EmitSoundToClient(client, "items/medshot4.wav");
		SetEntProp(client, Prop_Send, "m_iAccount", GetEntProp(client, Prop_Send, "m_iAccount") - g_cvSmokePrice.IntValue);
		return Plugin_Handled;
	}
	
	else
	{
		PrintToChat(client, "[SM] You have insufficient funds (Price: $%d).", g_cvSmokePrice.IntValue);
		return Plugin_Handled;
	}
}

public void Event_PlayerSpawn(Event event, const char[] name, bool dontBroadcast)
{
	int client = GetClientOfUserId(event.GetInt("userid"));
	
	CreateTimer(0.1, GiveSmoke, client);
}

public Action GiveSmoke(Handle timer, int client)
{
	if(IsValidClient(client) && HasAccess(client) && g_cvExtraSmoke.BoolValue)
	{
		GivePlayerItem(client, "weapon_smokegrenade");
	}
}

public void Event_RoundEnd(Event event, const char[] name, bool dontBroadcast)
{
	g_bRoundEnd = true;
}

public void Event_RoundStart(Event event, const char[] name, bool dontBroadcast)
{
	g_bRoundEnd = false;
}

public void Event_HeGrenadeDetonate(Event event, const char[] name, bool dontBroadcast)
{
	int client = GetClientOfUserId(event.GetInt("userid"));
	
	CreateNadeEffect(event, client);
	
}

public void Event_SmokeGrenadeDetonate(Event event, const char[] name, bool dontBroadcast)
{
	int client = GetClientOfUserId(event.GetInt("userid"));
	
	CreateNadeEffect(event, client);
}

void CreateNadeEffect(Event event, int client)
{
	if(IsValidClient(client) && HasAccess(client) && g_cvNadeEffect.BoolValue)
	{
		float fLocation[3];
		fLocation[0] = event.GetFloat("x");
		fLocation[1] = event.GetFloat("y");
		fLocation[2] = event.GetFloat("z");
		
		int g_iColor[4];
		g_iColor[0] = GetRandomInt(1, 255);
		g_iColor[1] = GetRandomInt(1, 255);
		g_iColor[2] = GetRandomInt(1, 255);
		g_iColor[3] = 255;
		
		fLocation[2] += 7.5;
		
		TE_SetupBeamRingPoint(fLocation, 150.0, 300.0, g_iFireSprite, g_iLaserBeamSprite, 0, 15, 3.0, 15.0, 15.0, g_iColor, 5, 0);
		TE_SendToAll();
		
		TE_SetupBeamRingPoint(fLocation, 100.0, 200.0, g_LaserSprite, g_iHaloSprite, 0, 15, 3.0, 10.0, 10.0, g_iColor, 5, 0);
		TE_SendToAll();
	}
}

bool HasAccess(int client)
{
	return(CheckCommandAccess(client, "", ADMFLAG_CUSTOM1, true));
}

bool IsValidClient(int client)
{
	return(IsClientInGame(client) && IsPlayerAlive(client) && ZR_IsClientHuman(client));
}