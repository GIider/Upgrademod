#include "upgrademod/interface"

public Plugin:myinfo = 
{
    name = "Upgrademod - Upgrade - Block",
    author = "Glider",
};

new block;

public OnUpgrademodDatabaseLoaded(Handle:hDB)
{
    block = RegisterUpgrade("block");
}

public OnClientPutInServer(client)
{
    SDKHook(client, SDKHook_OnTakeDamage, SDK_Forwarded_OnTakeDamage);
}
public OnClientDisconnect(client)
{
    SDKUnhook(client, SDKHook_OnTakeDamage, SDK_Forwarded_OnTakeDamage); 
}

public Action:SDK_Forwarded_OnTakeDamage(victim, &attacker, &inflictor, &Float:damage, &damagetype)
{
    if(IsValidPlayer(victim, true))
    {
        new iCurrentWeapon = GetEntPropEnt(victim, Prop_Send, "m_hActiveWeapon");
        decl String:sWeaponName[WEAPON_NAME_MAXLENGTH];

        if (IsValidEntity(iCurrentWeapon))
        {
            GetEdictClassname(iCurrentWeapon, sWeaponName, sizeof(sWeaponName));
        }
        else
        {
            return Plugin_Continue;
        }
        
        if (!IsMeleeWeapon(sWeaponName))
        {
            return Plugin_Continue;
        }
        
        new level = GetUpgradeLevel(victim, block, sWeaponName);
        if (level == 0)
        {
            return Plugin_Continue;
        }
       
        if ((damage > 0.0) && !IsHelpless(victim) && !IsPlayerIncapped(victim) && GetRandomFloat(0.0, 1.0) <= (level * 0.03))
        {
            damage = 0.0;
            Upgrade_ChatMessage(victim, "You blocked the damage!");
            
            return Plugin_Changed;
        }
    }

    return Plugin_Continue;
}

public bool:OnIsUpgradeAvailableForWeapon(upgrade, String:sWeaponName[WEAPON_NAME_MAXLENGTH], &bool:result)
{
    if (upgrade == block)
    {
        if(IsMeleeWeapon(sWeaponName))
        {
            result = true;
        }
    }
}

public OnUpgradeDescriptionRequested(upgrade, String:sWeaponName[WEAPON_NAME_MAXLENGTH], level, String:sUpgradeDescription[UPGRADE_DESCRIPTION_MAXLENGTH])
{
    if(upgrade == block)
    {
        if(IsMeleeWeapon(sWeaponName))
        {
            new chance = level * 3;
            Format(sUpgradeDescription, UPGRADE_DESCRIPTION_MAXLENGTH, "You have a %d %% chance to block damage", chance);
        }
    }
}

public OnUpgradeNameRequested(upgrade, String:sWeaponName[WEAPON_NAME_MAXLENGTH], String:sUpgradeName[UPGRADE_NAME_MAXLENGTH])
{
    if(upgrade == block)
    {
        Format(sUpgradeName, UPGRADE_NAME_MAXLENGTH, "Block");
    }
}

public OnUpgradeMaxLevelRequested(upgrade, String:sWeaponName[WEAPON_NAME_MAXLENGTH], &maxlevel)
{
    if(upgrade == block)
    {
        maxlevel = 5;
    }
}

public OnUpgradeExperienceRequiredRequested(upgrade, String:sWeaponName[WEAPON_NAME_MAXLENGTH], level, &experience)
{
    if(upgrade == block)
    {
        experience = level * 2500;
    }
}