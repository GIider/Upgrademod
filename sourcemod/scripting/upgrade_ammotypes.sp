#include "upgrademod/interface"

public Plugin:myinfo = 
{
    name = "Upgrademod - Upgrade - Ammo Types",
    author = "Glider",
};

new special_ammo_incendiary;
new special_ammo_explosive;

public OnPluginStart()
{
    HookEvent("player_use", Event_PlayerUse);
    HookEvent("ammo_pickup", Event_AmmoPickup);
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
            GiveSpecialAmmo(client);
        }
    }
}

public Event_AmmoPickup(Handle:event, const String:name[], bool:dontBroadcast)
{
    new client = GetClientOfUserId(GetEventInt(event, "userid"));
    
    GiveSpecialAmmo(client);
}

GiveSpecialAmmo(client)
{
    new primary = GetPlayerWeaponSlot(client, 0);
    if (!IsValidEntity(primary))
    {
        return;
    }
    
    new ammo = GetEntProp(primary, Prop_Send, "m_nUpgradedPrimaryAmmoLoaded");
    if (ammo == 0)
    {   
        decl String:sWeaponName[64];
        new upgrade_kit = GetPlayerWeaponSlot(client, 3);
        if(!IsValidEdict(upgrade_kit))
        {
            return;
        }
        GetEdictClassname(upgrade_kit, sWeaponName, sizeof(sWeaponName));

        new incendiary_level = GetUpgradeLevel(client, special_ammo_incendiary, sWeaponName);
        if (incendiary_level > 0)
        {
            new Float:percentage = 0.1 * incendiary_level;
            SetIncendiaryAmmoInMagazine(client, RoundToCeil(percentage * GetMaxMagSize(sWeaponName)));
        }
        
        new explosive_level = GetUpgradeLevel(client, special_ammo_explosive, sWeaponName);
        if (explosive_level > 0)
        {
            new Float:percentage = 0.1 * explosive_level;
            SetExplosiveAmmoInMagazine(client, RoundToCeil(percentage * GetMaxMagSize(sWeaponName)));
        }
    }
}

public OnUpgrademodDatabaseLoaded(Handle:hDB)
{
    special_ammo_incendiary = RegisterUpgrade("special_ammo_incendiary");
    special_ammo_explosive = RegisterUpgrade("special_ammo_explosive");
}

public bool:OnIsUpgradeAvailableForWeapon(upgrade, String:sWeaponName[WEAPON_NAME_MAXLENGTH], &bool:result)
{
    if (upgrade == special_ammo_incendiary)
    {
        result = StrEqual(sWeaponName, "weapon_upgradepack_incendiary", false);
    }
    else if (upgrade == special_ammo_explosive)
    {
        result = StrEqual(sWeaponName, "weapon_upgradepack_explosive", false);
    }
}

public OnUpgradeDescriptionRequested(upgrade, String:sWeaponName[WEAPON_NAME_MAXLENGTH], level, String:sUpgradeDescription[UPGRADE_DESCRIPTION_MAXLENGTH])
{
    new percentage = level * 10;

    if(upgrade == special_ammo_incendiary)
    {
        Format(sUpgradeDescription, UPGRADE_DESCRIPTION_MAXLENGTH, "When you refill ammo you receive %d %% of your magazine as incendiary ammo", percentage);
    }
    else if (upgrade == special_ammo_explosive)
    {
        Format(sUpgradeDescription, UPGRADE_DESCRIPTION_MAXLENGTH, "When you refill ammo you receive %d %% of your magazine as explosive ammo", percentage);
    }
}

public OnUpgradeNameRequested(upgrade, String:sWeaponName[WEAPON_NAME_MAXLENGTH], String:sUpgradeName[UPGRADE_NAME_MAXLENGTH])
{
    if(upgrade == special_ammo_incendiary)
    {
        Format(sUpgradeName, UPGRADE_NAME_MAXLENGTH, "Permanent Incendiary Ammo");
    }
    else if (upgrade == special_ammo_explosive)
    {
        Format(sUpgradeName, UPGRADE_NAME_MAXLENGTH, "Permanent Explosive Ammo");
    }
}

public OnUpgradeMaxLevelRequested(upgrade, String:sWeaponName[WEAPON_NAME_MAXLENGTH], &maxlevel)
{
    if(upgrade == special_ammo_incendiary || upgrade == special_ammo_explosive)
    {
        maxlevel = 10;
    }
}

public OnUpgradeExperienceRequiredRequested(upgrade, String:sWeaponName[WEAPON_NAME_MAXLENGTH], level, &experience)
{
    if(upgrade == special_ammo_incendiary || upgrade == special_ammo_explosive)
    {
        experience = level * 5000;
    }
}