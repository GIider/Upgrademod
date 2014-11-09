#include "upgrademod/interface"

public Plugin:myinfo = 
{
    name = "Upgrademod - Upgrade - Suicide Bomb",
    author = "Glider",
};

#define MAX_LEVEL 1
#define SUICIDE_BOMB_TIMER 1.0
#define SUICIDE_DAMAGE_MODIFIER 400.0
#define SUICIDE_BEEPS 6

new upgrade_suicidebomb;
new Float:fExplosionTime[MAXPLAYERS];
new gSuicideBombBeeps[MAXPLAYERS];
new bool:bSuicideBombActivated[MAXPLAYERS];
new Float:fSuicideCooldown[MAXPLAYERS];
new Handle:hSuicideTimer[MAXPLAYERS];
new iSuicideEntity[MAXPLAYERS];

static const String:CLASSNAME_INFECTED[]    = "infected";
static const String:CLASSNAME_WITCH[]       = "witch";

#define PIPEBOMB_BEEP_SND "weapons/hegrenade/beep.wav"

public OnMapStart()
{
    PrecacheSound(PIPEBOMB_BEEP_SND, true);
}

public OnUpgrademodDatabaseLoaded(Handle:hDB)
{
    upgrade_suicidebomb = RegisterUpgrade("suicidebomb");
}

public Action:OnPlayerRunCmd(client, &buttons, &impulse, Float:vel[3], Float:angles[3], &weapon)
{
    if (!IsValidPlayer(client, true))
    {
        return Plugin_Continue;
    }
    
    if (buttons & IN_RELOAD)
    {
        ActivateSuicideBomb(client);
    }

    return Plugin_Continue;
}

ActivateSuicideBomb(client)
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
        if(!StrEqual(sWeaponName, "weapon_pipe_bomb", false))
        {
            return;
        }
        
        new level = GetUpgradeLevel(client, upgrade_suicidebomb, sWeaponName);
        if (level == 0)
        {
            return;
        }
        
        ToggleSuicideBomb(client);
    }
}

ToggleSuicideBomb(client)
{
    // Toggling the button too fast!
    if(fSuicideCooldown[client] > GetGameTime())
    {
        return;
    }
    
    if(bSuicideBombActivated[client])
    {
        GotoFirstPerson(client);
        KillTimer(hSuicideTimer[client]);

        Upgrade_ChatMessage(0, "{olive}{client %d}{blue} decided against blowing himself up!", client);
    }
    else
    {
        gSuicideBombBeeps[client] = 0;

        GotoThirdPersonVisible(client);
        PerformSceneEx(client, "PlayerYellRun", "PlayerYellRun", 0.0, DEFAULT_SCENE_PITCH);
        
        hSuicideTimer[client] = CreateTimer(SUICIDE_BOMB_TIMER, BeepSuicideBomb, EntIndexToEntRef(client));
        
        Upgrade_ChatMessage(0, "{olive}{client %d}{blue} will blow himself up! GET AWAY!", client);
    }

    bSuicideBombActivated[client] = !bSuicideBombActivated[client];
    fSuicideCooldown[client] = GetGameTime() + 0.25;
}


public Action:BeepSuicideBomb(Handle:timer, any:client)
{
    client = EntRefToEntIndex(client);
    
    if(IsValidPlayer(client, true) && bSuicideBombActivated[client])
    {
        gSuicideBombBeeps[client] += 1;
        new seconds_left = SUICIDE_BEEPS - gSuicideBombBeeps[client];
        
        if(seconds_left == 0)
        {
            ExplodeSuicideBomb(client);
        }
        else
        {
            EmitSoundToAll(PIPEBOMB_BEEP_SND, client);
            if(seconds_left == 1)
            {
                Upgrade_ChatMessage(0, "1 second until {olive}{client %d}{blue} explodes!", client);
            }
            else
            {
                Upgrade_ChatMessage(0, "%d seconds until {olive}{client %d}{blue} explodes!", seconds_left, client);
            }
            
            hSuicideTimer[client] = CreateTimer(SUICIDE_BOMB_TIMER, BeepSuicideBomb, EntIndexToEntRef(client));
        }
    }
    
    return Plugin_Continue;
}

ExplodeSuicideBomb(client)
{
    // Detonate!
    new Float:CasterPosition[3];
    GetClientAbsOrigin(client, CasterPosition);
    
    // Remember the explosion time so we can up the damage
    // for the next few ticks of damage that were caused
    // by this player. This should get almost all the damage
    // caused by the ultimate. It might be that similiar damage
    // like propane next to your tnt might also get enhanced
    RemovePlayerItem(client, GetPlayerWeaponSlot(client, 2));
    iSuicideEntity[client] = L4D_Explode(client, CasterPosition, 1);
    
    fExplosionTime[client] = GetEngineTime() + 0.5;
    
    // You dead :(
    ForcePlayerSuicide(client);
    bSuicideBombActivated[client] = false;

    // Debug
    GotoFirstPerson(client);
}

public OnClientPutInServer(client)
{
    SDKHook(client, SDKHook_OnTakeDamage, SDK_Forwarded_OnTakeDamage);
}

public OnClientDisconnect(client)
{
    SDKUnhook(client, SDKHook_OnTakeDamage, SDK_Forwarded_OnTakeDamage); 
}

public OnEntityCreated(entity, const String:classname[])
{
    if (StrEqual(classname, CLASSNAME_INFECTED, false) || StrEqual(classname, CLASSNAME_WITCH, false))
    {
        SDKHook(entity, SDKHook_OnTakeDamage, SDK_Forwarded_OnTakeDamage);
    }
}

public Action:SDK_Forwarded_OnTakeDamage(victim, &attacker, &inflictor, &Float:damage, &damagetype)
{
    if(IsValidPlayer(attacker))
    {
        if (fExplosionTime[attacker] > GetEngineTime())
        {
            if (inflictor != attacker) // && ((IsL4DZombieEntity(victim)) || (IsValidPlayer(victim) && GetClientTeam(victim) == TEAM_INFECTED)))
            {
                damage *= SUICIDE_DAMAGE_MODIFIER;

                return Plugin_Changed;
            }
        }
    }

    return Plugin_Continue;
}

public bool:OnIsUpgradeAvailableForWeapon(upgrade, String:sWeaponName[WEAPON_NAME_MAXLENGTH], &bool:result)
{
    if (upgrade == upgrade_suicidebomb)
    {
        result = StrEqual(sWeaponName, "weapon_pipe_bomb", false);
    }
}

public OnUpgradeDescriptionRequested(upgrade, String:sWeaponName[WEAPON_NAME_MAXLENGTH], level, String:sUpgradeDescription[UPGRADE_DESCRIPTION_MAXLENGTH])
{
    if (upgrade == upgrade_suicidebomb)
    {
        Format(sUpgradeDescription, UPGRADE_DESCRIPTION_MAXLENGTH, "Blow yourself up");
    }
}

public OnUpgradeNameRequested(upgrade, String:sWeaponName[WEAPON_NAME_MAXLENGTH], String:sUpgradeName[UPGRADE_NAME_MAXLENGTH])
{
    if (upgrade == upgrade_suicidebomb)
    {
        Format(sUpgradeName, UPGRADE_NAME_MAXLENGTH, "Suicide Bomb (+reload)");
    }
}

public OnUpgradeMaxLevelRequested(upgrade, String:sWeaponName[WEAPON_NAME_MAXLENGTH], &maxlevel)
{
    if (upgrade == upgrade_suicidebomb)
    {
        maxlevel = MAX_LEVEL;
    }
}

public OnUpgradeExperienceRequiredRequested(upgrade, String:sWeaponName[WEAPON_NAME_MAXLENGTH], level, &experience)
{
    if (upgrade == upgrade_suicidebomb)
    {
        experience = 500;
    }
}