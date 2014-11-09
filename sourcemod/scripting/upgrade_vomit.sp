#include "upgrademod/interface"

public Plugin:myinfo = 
{
    name = "Upgrademod - Upgrade - Vomit",
    author = "Glider",
};

#define MAX_LEVEL 1
new upgrade_vomit;

static Handle:sdkCallVomitOnPlayer =    INVALID_HANDLE;
static Handle:sdkCallBileJarPlayer =    INVALID_HANDLE;
static Handle:sdkCallBileJarInfected =  INVALID_HANDLE;

new Float:fVomitCooldown[MAXPLAYERS];
new Handle:AttackTracerTimer[MAXPLAYERS] = INVALID_HANDLE;

#define VOMIT_SND "player/boomer/vomit/attack/bv1.wav"
#define VOMIT_PARTICLE "boomer_vomit"
#define VOMIT_RANGE 180.0

public OnMapStart()
{
    PrecacheParticle(VOMIT_PARTICLE);
    PrecacheSound(VOMIT_SND, true);
}

public OnPluginStart()
{
    PrepSDKCalls();
}

static PrepSDKCalls()
{
    new Handle:ConfigFile = LoadGameConfigFile("l4d2addresses");
    
    StartPrepSDKCall(SDKCall_Player);
    PrepSDKCall_SetFromConf(ConfigFile, SDKConf_Signature, "CTerrorPlayer_OnVomitedUpon");
    PrepSDKCall_AddParameter(SDKType_CBasePlayer, SDKPass_Pointer);
    PrepSDKCall_AddParameter(SDKType_PlainOldData, SDKPass_Plain);
    sdkCallVomitOnPlayer = EndPrepSDKCall();
    
    if (sdkCallVomitOnPlayer == INVALID_HANDLE)
    {
        SetFailState("Cant initialize OnVomitedUpon SDKCall");
        return;
    }

    StartPrepSDKCall(SDKCall_Player);
    PrepSDKCall_SetFromConf(ConfigFile, SDKConf_Signature, "CTerrorPlayer_OnHitByVomitJar");
    PrepSDKCall_AddParameter(SDKType_CBaseEntity, SDKPass_Pointer);
    sdkCallBileJarPlayer = EndPrepSDKCall();
    
    if (sdkCallBileJarPlayer == INVALID_HANDLE)
    {
        SetFailState("Cant initialize CTerrorPlayer_OnHitByVomitJar SDKCall");
        return;
    }
    
    StartPrepSDKCall(SDKCall_Entity);
    PrepSDKCall_SetFromConf(ConfigFile, SDKConf_Signature, "Infected_OnHitByVomitJar");
    PrepSDKCall_AddParameter(SDKType_CBaseEntity, SDKPass_Pointer);
    sdkCallBileJarInfected = EndPrepSDKCall();
    
    if (sdkCallBileJarInfected == INVALID_HANDLE)
    {
        SetFailState("Cant initialize Infected_OnHitByVomitJar SDKCall");
        return;
    }
    
    CloseHandle(ConfigFile);
}

public OnUpgrademodDatabaseLoaded(Handle:hDB)
{
    upgrade_vomit = RegisterUpgrade("vomit");
}

public Action:OnPlayerRunCmd(client, &buttons, &impulse, Float:vel[3], Float:angles[3], &weapon)
{
    if (!IsValidPlayer(client, true))
    {
        return Plugin_Continue;
    }
    
    if (buttons & IN_RELOAD)
    {
        ActivateVomit(client);
    }

    return Plugin_Continue;
}

ActivateVomit(client)
{
    if(IsValidPlayer(client, true) && !IsHelpless(client) && !IsPlayerIncapped(client))
    {   
        new iCurrentWeapon = GetEntPropEnt(client, Prop_Send, "m_hActiveWeapon");
        decl String:sWeaponName[WEAPON_NAME_MAXLENGTH];

        if (!IsValidEntity(iCurrentWeapon))
        {
            return;
        }
        
        GetEdictClassname(iCurrentWeapon, sWeaponName, sizeof(sWeaponName));
        if(!StrEqual(sWeaponName, "weapon_vomitjar", false))
        {
            return;
        }
        
        new level = GetUpgradeLevel(client, upgrade_vomit, sWeaponName);
        if (level == 0)
        {
            return;
        }
        
        Vomit(client);
    }
}

Vomit(client)
{
    // Toggling the button too fast!
    if(fVomitCooldown[client] > GetGameTime())
    {
        return;
    }

    SDKHooks_TakeDamage(client, client, client, 5.0);
    
    decl Float:z[3];
    GetClientEyePosition(client,z);
    z[2] = z[2]-2;
    
    AttachThrowAwayParticle(client, VOMIT_PARTICLE, NULL_VECTOR, "eyes", 5.0);
    EmitSoundToAll(VOMIT_SND, 0, SNDCHAN_WEAPON, SNDLEVEL_TRAFFIC, SND_NOFLAGS, SNDVOL_NORMAL, 100, _, z, NULL_VECTOR, false, 0.0);

    if (AttackTracerTimer[client] == INVALID_HANDLE)
    {
        AttackTracerTimer[client] = CreateTimer(0.1, TraceAttackTimer, client, TIMER_REPEAT);
    }
    else
    {
        CloseHandle(AttackTracerTimer[client]);
        AttackTracerTimer[client] = INVALID_HANDLE;
        AttackTracerTimer[client] = CreateTimer(0.1, TraceAttackTimer, client, TIMER_REPEAT);
    }

    CreateTimer(1.6, StopTimer, client);
    fVomitCooldown[client] = GetGameTime() + 2.0;
    //GotoThirdPersonVisible(client);
}

public Action:TraceAttackTimer(Handle:timer, any:client)
{
    if (IsValidPlayer(client, true)) 
    {
        TraceAttack(client, true);
    }
}
public Action:StopTimer(Handle:timer, any:client)
{
    if (AttackTracerTimer[client] != INVALID_HANDLE)
    {
        CloseHandle(AttackTracerTimer[client]);
        AttackTracerTimer[client] = INVALID_HANDLE;
        
        //GotoFirstPerson(client);
    }
}

TraceAttack(client, bool:bHullTrace)
{
    decl Float:vPos[3], Float:vAng[3], Float:vEnd[3];

    GetClientEyePosition(client, vPos);
    GetClientEyeAngles(client, vAng);

    new Handle:trace = TR_TraceRayFilterEx(vPos, vAng, MASK_SHOT, RayType_Infinite, ExcludeSelf_Filter, client);
    if( TR_DidHit(trace) )
    {
        TR_GetEndPosition(vEnd, trace);
    }
    else
    {
        CloseHandle(trace);
        return;
    }

    if( bHullTrace )
    {
        CloseHandle(trace);
        decl Float:vMins[3], Float:vMaxs[3];
        vMins = Float: { -15.0, -15.0, -15.0 };
        vMaxs = Float: { 15.0, 15.0, 15.0 };
        trace = TR_TraceHullFilterEx(vPos, vEnd, vMins, vMaxs, MASK_SHOT, ExcludeSelf_Filter, client);
        
        if( !TR_DidHit(trace) )
        {
            CloseHandle(trace);
            return;
        }
    }

    TR_GetEndPosition(vEnd, trace);
    if(GetVectorDistance(vPos, vEnd) > VOMIT_RANGE)
    {
        CloseHandle(trace);
        return;
    }

    new entity = TR_GetEntityIndex(trace);
    CloseHandle(trace);

    if(IsValidPlayer(entity, true) && GetClientTeam(entity) == TEAM_INFECTED )
    {
        VomitPlayer(entity, client);
    }
    else
    {
    
        if (IsZombieEntity(entity))
        {
            VomitEntity(entity, client);
        }
    }
}


public bool:ExcludeSelf_Filter(entity, contentsMask, any:client)
{
    // ignore player aswell as biled entitys
    if( entity == client || (GetEntProp(entity, Prop_Send, "m_glowColorOverride") == -4713783))
    {
        return false;
    }
    
    return true;
}

VomitPlayer(target, sender)
{
    if (!IsPlayerGhost(target))
    {
        SDKCall(sdkCallBileJarPlayer, target, sender, true);
    }
}

VomitEntity(entity, sender)
{
    SDKCall(sdkCallBileJarInfected, entity, sender, true);
}

public bool:OnIsUpgradeAvailableForWeapon(upgrade, String:sWeaponName[WEAPON_NAME_MAXLENGTH], &bool:result)
{
    if (upgrade == upgrade_vomit)
    {
        result = StrEqual(sWeaponName, "weapon_vomitjar", false);
    }
}

public OnUpgradeDescriptionRequested(upgrade, String:sWeaponName[WEAPON_NAME_MAXLENGTH], level, String:sUpgradeDescription[UPGRADE_DESCRIPTION_MAXLENGTH])
{
    if (upgrade == upgrade_vomit)
    {
        Format(sUpgradeDescription, UPGRADE_DESCRIPTION_MAXLENGTH, "You vomit at your foes like a Boomer.\nCosts 5 health points to use.");
    }
}

public OnUpgradeNameRequested(upgrade, String:sWeaponName[WEAPON_NAME_MAXLENGTH], String:sUpgradeName[UPGRADE_NAME_MAXLENGTH])
{
    if (upgrade == upgrade_vomit)
    {
        Format(sUpgradeName, UPGRADE_NAME_MAXLENGTH, "Chug (+reload)");
    }
}

public OnUpgradeMaxLevelRequested(upgrade, String:sWeaponName[WEAPON_NAME_MAXLENGTH], &maxlevel)
{
    if (upgrade == upgrade_vomit)
    {
        maxlevel = MAX_LEVEL;
    }
}

public OnUpgradeExperienceRequiredRequested(upgrade, String:sWeaponName[WEAPON_NAME_MAXLENGTH], level, &experience)
{
    if (upgrade == upgrade_vomit)
    {
        experience = 500;
    }
}