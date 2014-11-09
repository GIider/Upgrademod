#include "upgrademod/interface"

public Plugin:myinfo = 
{
    name = "Upgrademod - Engine - Experience",
    author = "Glider",
    description = "Engine responsible for awarding players with Weapon Experience"
};

#define COMMON_INFECTED_EXPERIENCE  10
#define WITCH_EXPERIENCE            5
#define SPECIAL_INFECTED_EXPERIENCE 15

#define UPGRADE_PACK_USED_EXPERIENCE 50
#define PLAYER_REVIVED_EXPERIENCE   100

#define KILL_WEAPON_XP_RATIO  0.5
#define SUPPORT_ITEM_XP_RATIO 0.3
#define TEAM_XP_RATIO         0.2

/**
 * THE EXP ALGORITHM OF UPGRADEMOD:
 * 
 * Experience is awarded when a player kills something.
 * The base experience is split up as follows:
 * 
 * 50% is given to the player that made the kill on the weapon that made the kill.
 * 30% is given to all other items of the killer.
 * 
 * The remaining 20% are shared among all players that are alive, including the killer.
 * 
 * With these rates: 0.5 / 0.3 / 0.2 
 * 
 * A 10 exp reward gets split up as follows:
 * 
 * Killer Weapon: 5 (+2) exp
 * Killer support items: 1 (+2) exp
 * Everyone: 2 exp
 * 
 * Note: EXP is always rounded up!
 */

// Maybe we should randomzie the support exp? GetRandomInt(0.0, support_exp)?

public OnPluginStart()
{
    if(!HookEventEx("player_death", PlayerDeathEvent, EventHookMode_Pre))
    {
        Upgrademod_LogCritical("Could not hook player_death event!");
    }
    if(!HookEventEx("heal_success", PlayerHealSuccessEvent, EventHookMode_Pre))
    {
        Upgrademod_LogCritical("Could not hook heal_success event!");
    }
    if(!HookEventEx("defibrillator_used", PlayerRevivedEvent, EventHookMode_Pre))
    {
        Upgrademod_LogCritical("Could not hook defibrillator_used event!");
    }
    if(!HookEventEx("upgrade_pack_used", UpgradePackUsedEvent, EventHookMode_Pre))
    {
        Upgrademod_LogCritical("Could not hook upgrade_pack_used event!");
    }
}

public Action:PlayerDeathEvent(Handle:event, const String:name[], bool:dontBroadcast)
{
    new iVictim = GetEventInt(event, "userid");
    new iAttacker = GetEventInt(event, "attacker");
    new iEntity = GetEventInt(event, "entityid");
    
    new victimIndex = 0;
    new attackerIndex = 0;
    
    if(iAttacker > 0)
    {
        attackerIndex = GetClientOfUserId(iAttacker);
    }
    if(iVictim > 0)
    {
        victimIndex = GetClientOfUserId(iVictim);
    }
    
    if(!IsValidPlayer(attackerIndex) || GetClientTeam(attackerIndex) != TEAM_SURVIVORS)
    {
        return Plugin_Continue;
    }
    
    if (IsCommonInfected(iEntity))
    {
        decl String:sWeaponName[WEAPON_NAME_MAXLENGTH];
        GetEventString(event, "weapon", sWeaponName, sizeof(sWeaponName));
        
        Format(sWeaponName, sizeof(sWeaponName), "weapon_%s", sWeaponName);
        
        AwardExperience(attackerIndex, sWeaponName, COMMON_INFECTED_EXPERIENCE);
    }
    else if (IsWitch(iEntity))
    {
        decl String:sWeaponName[WEAPON_NAME_MAXLENGTH];
        GetEventString(event, "weapon", sWeaponName, sizeof(sWeaponName));
        
        Format(sWeaponName, sizeof(sWeaponName), "weapon_%s", sWeaponName);
        
        AwardExperience(attackerIndex, sWeaponName, WITCH_EXPERIENCE);
    }
    else if (GetClientTeam(attackerIndex) != GetClientTeam(victimIndex))
    {
        decl String:sWeaponName[WEAPON_NAME_MAXLENGTH];
        GetEventString(event, "weapon", sWeaponName, sizeof(sWeaponName));
        
        Format(sWeaponName, sizeof(sWeaponName), "weapon_%s", sWeaponName);
        
        AwardExperience(attackerIndex, sWeaponName, SPECIAL_INFECTED_EXPERIENCE);
    }
   
    return Plugin_Continue;
}

public Action:PlayerHealSuccessEvent(Handle:event, const String:name[], bool:dontBroadcast)
{
    new iHealthRestored = GetEventInt(event, "health_restored");
    new iUserId = GetEventInt(event, "userid");
    new iHealer = GetClientOfUserId(iUserId);
    
    AwardTeam(iHealthRestored);
    GiveWeaponExperience(iHealer, "weapon_first_aid_kit", iHealthRestored * 2);
}

public Action:PlayerRevivedEvent(Handle:event, const String:name[], bool:dontBroadcast)
{
    new iUserId = GetEventInt(event, "userid");
    new iHealer = GetClientOfUserId(iUserId);
    
    AwardTeam(PLAYER_REVIVED_EXPERIENCE);
    GiveWeaponExperience(iHealer, "weapon_first_aid_kit", PLAYER_REVIVED_EXPERIENCE * 2);
}

public Action:UpgradePackUsedEvent(Handle:event, const String:name[], bool:dontBroadcast)
{
    new iUserId = GetEventInt(event, "userid");
    new iDeployer = GetClientOfUserId(iUserId);
    new iUpgradeID = GetEventInt(event, "upgradeid");
    
    decl String:sWeaponName[WEAPON_NAME_MAXLENGTH];
    GetEdictClassname(iUpgradeID, sWeaponName, sizeof(sWeaponName));

    if(StrEqual(sWeaponName, "upgrade_ammo_explosive"))
    {
        GiveWeaponExperience(iDeployer, "weapon_upgradepack_explosive", UPGRADE_PACK_USED_EXPERIENCE * 2);
    }
    else if(StrEqual(sWeaponName, "upgrade_ammo_incendiary"))
    {
        GiveWeaponExperience(iDeployer, "weapon_upgradepack_incendiary", UPGRADE_PACK_USED_EXPERIENCE * 2);
    }
    else
    {
        Upgrademod_LogError("Invalid upgrade pack with name \"%s\" deployed", sWeaponName);
    }
    
    AwardTeam(UPGRADE_PACK_USED_EXPERIENCE);
}

AwardExperience(client, String:sWeaponName[WEAPON_NAME_MAXLENGTH], amount)
{
    AwardKillExperience(client, sWeaponName, amount);
    AwardTeam(RoundToCeil(amount * TEAM_XP_RATIO));
}

AwardTeam(amount)
{
    for(new client=1; client <= MaxClients; client++)
    {
        if(IsValidPlayer(client, true) && GetClientTeam(client) == TEAM_SURVIVORS)
        {
            AwardSupportExperience(client, amount);
        }
    }
}

AwardKillExperience(client, String:sKillWeaponName[WEAPON_NAME_MAXLENGTH], amount)
{
    decl String:sWeaponName[WEAPON_NAME_MAXLENGTH];
    new weapon_experience = RoundToCeil(amount * KILL_WEAPON_XP_RATIO);
    new support_experience = RoundToCeil(amount * SUPPORT_ITEM_XP_RATIO);

    GiveWeaponExperience(client, sKillWeaponName, weapon_experience);
    //Upgrade_ChatMessage(client, "You received %d exp for your %s (Kill)", weapon_experience, sKillWeaponName);
    
    new weapon = -1;
    
    for(new slot=-1; slot < 6; slot++)
    {
        weapon = GetPlayerWeaponSlot(client, slot);
        if(IsValidEdict(weapon))
        {
            GetEdictClassname(weapon, sWeaponName, sizeof(sWeaponName));
            
            if(!StrEqual(sWeaponName, sKillWeaponName, false))
            {
                GiveWeaponExperience(client, sWeaponName, support_experience);

                //Upgrade_ChatMessage(client, "You received %d exp for your %s (Kill-Support)", support_experience, sWeaponName);
            }
        }
    }
}

AwardSupportExperience(client, amount)
{
    decl String:sWeaponName[WEAPON_NAME_MAXLENGTH];
    new weapon = -1;
    
    for(new slot=-1; slot < 6; slot++)
    {
        weapon = GetPlayerWeaponSlot(client, slot);
        if(IsValidEdict(weapon))
        {
            GetEdictClassname(weapon, sWeaponName, sizeof(sWeaponName));
            GiveWeaponExperience(client, sWeaponName, amount);
            
            //Upgrade_ChatMessage(client, "You received %d exp for your %s (Support)", amount, sWeaponName);
        }
    }
}