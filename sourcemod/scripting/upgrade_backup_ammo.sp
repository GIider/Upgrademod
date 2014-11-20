#include "upgrademod/interface"

public Plugin:myinfo = 
{
    name = "Upgrademod - Upgrade - Backup Ammo",
    author = "Glider",
};

new backupAmmo;

public OnPluginStart()
{
    HookEvent("player_use", Event_PlayerUse);
    HookEvent("ammo_pickup", Event_AmmoPickup);
}

public OnUpgrademodDatabaseLoaded(Handle:hDB)
{
    backupAmmo = RegisterUpgrade("backup_ammo");
}

public bool:OnIsUpgradeAvailableForWeapon(upgrade, String:sWeaponName[WEAPON_NAME_MAXLENGTH], &bool:result)
{
    if (upgrade == backupAmmo)
    {
        if(IsPrimaryWeapon(sWeaponName) && !IsSpecialWeapon(sWeaponName))
        {
            result = true;
        }
    }
}

public OnUpgradeDescriptionRequested(upgrade, String:sWeaponName[WEAPON_NAME_MAXLENGTH], level, String:sUpgradeDescription[UPGRADE_DESCRIPTION_MAXLENGTH])
{
    if(upgrade == backupAmmo)
    {
        new percentage = RoundToFloor(GetPercentage(level, sWeaponName) * 100) - 100;
        Format(sUpgradeDescription, UPGRADE_DESCRIPTION_MAXLENGTH, "Upgrades the amount of backup ammo you can carry.\n\nYou are currently carrying %d %% more ammo", percentage);
    }
}

public OnUpgradeNameRequested(upgrade, String:sWeaponName[WEAPON_NAME_MAXLENGTH], String:sUpgradeName[UPGRADE_NAME_MAXLENGTH])
{
    if(upgrade == backupAmmo)
    {
        Format(sUpgradeName, UPGRADE_NAME_MAXLENGTH, "Increased backup ammo");
    }
}

public OnUpgradeMaxLevelRequested(upgrade, String:sWeaponName[WEAPON_NAME_MAXLENGTH], &maxlevel)
{
    if(upgrade == backupAmmo)
    {
        if(IsTierOneWeapon(sWeaponName))
        {
            maxlevel = 10;
        }
        else
        {
            maxlevel = 5;
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
            SetMaxBackupAmmoForPrimaryWeapon(client);
        }
    }
}

public Event_AmmoPickup(Handle:event, const String:name[], bool:dontBroadcast)
{
    new client = GetClientOfUserId(GetEventInt(event, "userid"));
    
    SetMaxBackupAmmoForPrimaryWeapon(client);
}

Float:GetPercentage(level, String:sWeaponName[WEAPON_NAME_MAXLENGTH])
{
    new Float:percentage;
    if(IsTierOneWeapon(sWeaponName))
    {
        percentage= 1 + (level * 0.1);
    }
    else
    {
        percentage= 1 + (level * 0.05);
    }
    
    return percentage;
}

GetMaxBackupAmmoPerked(client, String:sWeaponName[WEAPON_NAME_MAXLENGTH])
{
    new iMaxBackupAmmo = GetMaxBackupAmmo(sWeaponName);
    new level = GetUpgradeLevel(client, backupAmmo, sWeaponName);

    new iPerkedBackupAmmo = RoundToCeil(iMaxBackupAmmo * GetPercentage(level, sWeaponName));
    
    return iPerkedBackupAmmo;
}

SetMaxBackupAmmoForPrimaryWeapon(client)
{
    decl String:sPrimaryWeaponName[64];
    GetPrimaryWeaponName(client, sPrimaryWeaponName);

    new iNewBackupAmmo = GetMaxBackupAmmoPerked(client, sPrimaryWeaponName);
    if (iNewBackupAmmo != 0)
    {
        SetBackupAmmo(client, iNewBackupAmmo);
    }
}