#include "upgrademod/interface"

public Plugin:myinfo = 
{
    name = "Upgrademod - Engine - Ammo Control",
    author = "Glider",
};

new laserSight;

public OnPluginStart()
{
    HookEvent("player_use", Event_PlayerUse);
    HookEvent("ammo_pickup", Event_AmmoPickup);
}

public OnUpgrademodDatabaseLoaded(Handle:hDB)
{
    laserSight = RegisterUpgrade("laser_sight");
}

public bool:OnIsUpgradeAvailableForWeapon(upgrade, String:sWeaponName[WEAPON_NAME_MAXLENGTH], &bool:result)
{
    if (upgrade == laserSight)
    {
        if(IsPrimaryWeapon(sWeaponName) && !IsSpecialWeapon(sWeaponName))
        {
            result = true;
        }
    }
}

public OnUpgradeDescriptionRequested(upgrade, String:sWeaponName[WEAPON_NAME_MAXLENGTH], level, String:sUpgradeDescription[UPGRADE_DESCRIPTION_MAXLENGTH])
{
    if(upgrade == laserSight)
    {
        Format(sUpgradeDescription, UPGRADE_DESCRIPTION_MAXLENGTH, "Gives you the laser sight upgrade when refilling your ammo.");
    }
}

public OnUpgradeNameRequested(upgrade, String:sWeaponName[WEAPON_NAME_MAXLENGTH], String:sUpgradeName[UPGRADE_NAME_MAXLENGTH])
{
    if(upgrade == laserSight)
    {
        Format(sUpgradeName, UPGRADE_NAME_MAXLENGTH, "Laser Sight");
    }
}

public OnUpgradeMaxLevelRequested(upgrade, String:sWeaponName[WEAPON_NAME_MAXLENGTH], &maxlevel)
{
    if(upgrade == laserSight)
    {
        maxlevel = 1;
    }
}

public OnUpgradeExperienceRequiredRequested(upgrade, String:sWeaponName[WEAPON_NAME_MAXLENGTH], level, &experience)
{
    if(upgrade == laserSight)
    {
        if(IsTierOneWeapon(sWeaponName))
        {
            experience = 25000;
        }
        else
        {
            experience = 50000;
        }
    }
}

public Event_PlayerUse(Handle:event, const String:name[], bool:dontBroadcast)
{
    new client = GetClientOfUserId(GetEventInt(event, "userid"));
    new iEntity = GetEventInt(event, "targetid");

    if (IsValidEntity(iEntity))
    {
        decl String:entityName[64];
        GetEdictClassname(iEntity, entityName, sizeof(entityName));

        if (StrEqual(entityName, "weapon_ammo_spawn"))
        {
            GiveLaserSight(client);
        }
    }
}

public Event_AmmoPickup(Handle:event, const String:name[], bool:dontBroadcast)
{
    new client = GetClientOfUserId(GetEventInt(event, "userid"));
    
    GiveLaserSight(client);
}

GiveLaserSight(client)
{
    decl String:sWeaponName[64];
    GetPrimaryWeaponName(client, sWeaponName);
    
    new level = GetUpgradeLevel(client, laserSight, sWeaponName);
    if (level == 1)
    {
        new primary = GetPlayerWeaponSlot(client, 0);
        new upgrades = L4D2_GetWeaponUpgrades(primary);
        
        L4D2_SetWeaponUpgrades(primary, L4D2_WEPUPGFLAG_LASER + upgrades);
    }
}