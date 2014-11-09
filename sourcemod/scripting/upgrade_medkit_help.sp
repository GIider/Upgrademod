#include "upgrademod/interface"

public Plugin:myinfo = 
{
    name = "Upgrademod - Upgrade - Helping Hand",
    author = "Glider",
};

#define MAX_LEVEL 8

new helping_hand;
new Float:g_flReviveTime = -1.0;
new Float:fHelpingHandMultiplier[MAX_LEVEL + 1] = {1.0, 0.95, 0.9, 0.85, 0.8, 0.75, 0.7, 0.65, 0.6};

public OnPluginStart()
{
    HookEvent("revive_begin", Event_ReviveBeginPre, EventHookMode_Pre);
    g_flReviveTime = GetConVarFloat(FindConVar("survivor_revive_duration"));
}

public OnUpgrademodDatabaseLoaded(Handle:hDB)
{
    helping_hand = RegisterUpgrade("helping_hand");
}

public bool:OnIsUpgradeAvailableForWeapon(upgrade, String:sWeaponName[WEAPON_NAME_MAXLENGTH], &bool:result)
{
    if (upgrade == helping_hand)
    {
        result = IsFirstAid(sWeaponName);
    }
}

public OnUpgradeDescriptionRequested(upgrade, String:sWeaponName[WEAPON_NAME_MAXLENGTH], level, String:sUpgradeDescription[UPGRADE_DESCRIPTION_MAXLENGTH])
{
    if(upgrade == helping_hand)
    {
        Format(sUpgradeDescription, UPGRADE_DESCRIPTION_MAXLENGTH, "Allows you to pick up teammates faster.\nOnly active while you have a first aid kit.");
    }
}

public OnUpgradeNameRequested(upgrade, String:sWeaponName[WEAPON_NAME_MAXLENGTH], String:sUpgradeName[UPGRADE_NAME_MAXLENGTH])
{
    if(upgrade == helping_hand)
    {
        Format(sUpgradeName, UPGRADE_NAME_MAXLENGTH, "Helping Hand");
    }
}

public OnUpgradeMaxLevelRequested(upgrade, String:sWeaponName[WEAPON_NAME_MAXLENGTH], &maxlevel)
{
    if(upgrade == helping_hand)
    {
        maxlevel = MAX_LEVEL;
    }
}

public OnUpgradeExperienceRequiredRequested(upgrade, String:sWeaponName[WEAPON_NAME_MAXLENGTH], level, &experience)
{
    if(upgrade == helping_hand)
    {
        experience = level * 1500;
    }
}

public Action:Event_ReviveBeginPre (Handle:event, const String:name[], bool:dontBroadcast)
{
    new client = GetClientOfUserId(GetEventInt(event, "userid"));

    if(IsValidPlayer(client, true))
    {
        decl String:sWeaponName[64];
        new first_aid_kit = GetPlayerWeaponSlot(client, 3);
        if(IsValidEdict(first_aid_kit))
        {
            GetEdictClassname(first_aid_kit, sWeaponName, sizeof(sWeaponName));
    
            new level = GetUpgradeLevel(client, helping_hand, sWeaponName);
            SetConVarFloat(FindConVar("survivor_revive_duration"), g_flReviveTime * fHelpingHandMultiplier[level], false, false);
        }
    }
    
    return Plugin_Continue;
}