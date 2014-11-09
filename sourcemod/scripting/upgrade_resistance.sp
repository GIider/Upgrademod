#include "upgrademod/interface"

public Plugin:myinfo = 
{
    name = "Upgrademod - Upgrade - Resistances",
    author = "Glider",
};

#define MAX_LEVEL 10

new upgrade_explosive_resistance;
new upgrade_fire_resistance;
new upgrade_spitter_resistance;

new Float:fResistance[MAX_LEVEL + 1] = {1.0, 0.96, 0.92, 0.88, 0.84, 0.8, 0.76, 0.72, 0.68, 0.64, 0.6};

public OnUpgrademodDatabaseLoaded(Handle:hDB)
{
    upgrade_explosive_resistance = RegisterUpgrade("explosive_resistance");
    //upgrade_fire_resistance = RegisterUpgrade("fire_resistance");
    upgrade_spitter_resistance = RegisterUpgrade("spitter_resistance");
}

public bool:OnIsUpgradeAvailableForWeapon(upgrade, String:sWeaponName[WEAPON_NAME_MAXLENGTH], &bool:result)
{
    if (upgrade == upgrade_explosive_resistance)
    {
        result = StrEqual(sWeaponName, "weapon_pipe_bomb", false);
    }
    // Broken...
    /*
    else if (upgrade == upgrade_fire_resistance)
    {
        result = StrEqual(sWeaponName, "weapon_molotov", false);
    }
    */
    else if (upgrade == upgrade_spitter_resistance)
    {
        result = StrEqual(sWeaponName, "weapon_vomitjar", false);
    }
}

public OnUpgradeDescriptionRequested(upgrade, String:sWeaponName[WEAPON_NAME_MAXLENGTH], level, String:sUpgradeDescription[UPGRADE_DESCRIPTION_MAXLENGTH])
{
    new amount = level * 4;
    if (upgrade == upgrade_explosive_resistance)
    {
        Format(sUpgradeDescription, UPGRADE_DESCRIPTION_MAXLENGTH, "You gain resistance to explosive damage.\nYou currently have an extra %d %% resistance.", amount);
    }
    else if (upgrade == upgrade_fire_resistance)
    {
        Format(sUpgradeDescription, UPGRADE_DESCRIPTION_MAXLENGTH, "You gain resistance to fire damage.\nYou currently have an extra %d %% resistance.", amount);
    }
    else if (upgrade == upgrade_spitter_resistance)
    {
        Format(sUpgradeDescription, UPGRADE_DESCRIPTION_MAXLENGTH, "You gain resistance to spitter goo.\nYou currently have an extra %d %% resistance.", amount);
    }
}

public OnUpgradeNameRequested(upgrade, String:sWeaponName[WEAPON_NAME_MAXLENGTH], String:sUpgradeName[UPGRADE_NAME_MAXLENGTH])
{
    if (upgrade == upgrade_explosive_resistance)
    {
        Format(sUpgradeName, UPGRADE_NAME_MAXLENGTH, "Explosive Resistance");
    }
    else if (upgrade == upgrade_fire_resistance)
    {
        Format(sUpgradeName, UPGRADE_NAME_MAXLENGTH, "Fire Resistance");
    }
    else if (upgrade == upgrade_spitter_resistance)
    {
        Format(sUpgradeName, UPGRADE_NAME_MAXLENGTH, "Spitter Goo Resistance");
    }
}

public OnUpgradeMaxLevelRequested(upgrade, String:sWeaponName[WEAPON_NAME_MAXLENGTH], &maxlevel)
{
    if (upgrade == upgrade_explosive_resistance || upgrade == upgrade_fire_resistance || upgrade == upgrade_fire_resistance)
    {
        maxlevel = MAX_LEVEL;
    }
}

public OnUpgradeExperienceRequiredRequested(upgrade, String:sWeaponName[WEAPON_NAME_MAXLENGTH], level, &experience)
{
    if (upgrade == upgrade_explosive_resistance || upgrade == upgrade_fire_resistance || upgrade == upgrade_fire_resistance)
    {
        experience = level * 5000;
    }
}

public OnClientPutInServer(client)
{
    SDKHook(client, SDKHook_OnTakeDamage, SDK_Forwarded_OnTakeDamage);
}

public Action:SDK_Forwarded_OnTakeDamage(victim, &attacker, &inflictor, &Float:damage, &damagetype)
{
    if(IsValidPlayer(victim, true))
    {
        if(damagetype & DMG_RADIATION)
        {
            decl String:sWeaponName[64];
            new throwable = GetPlayerWeaponSlot(victim, 2);
            if(IsValidEdict(throwable))
            {
                GetEdictClassname(throwable, sWeaponName, sizeof(sWeaponName));
        
                new level = GetUpgradeLevel(victim, upgrade_spitter_resistance, sWeaponName);
                damage *= fResistance[level];

                return Plugin_Changed;
            }
        }
        /*
        else if(damagetype & DMG_BURN)
        {
            decl String:sWeaponName[64];
            new throwable = GetPlayerWeaponSlot(victim, 2);
            if(IsValidEdict(throwable))
            {
                GetEdictClassname(throwable, sWeaponName, sizeof(sWeaponName));
        
                // Lowering fire damage seems to make you immune to fire
                new level = GetUpgradeLevel(victim, upgrade_explosive_resistance, sWeaponName);
                if(level > 0)
                {
                    new Float:fGenericDamage = damage * fResistance[level];
                    damage = 0.0;
                    
                    SDKHooks_TakeDamage(victim, victim, victim, fGenericDamage);
                }
                //damage *= fResistance[level];
                return Plugin_Changed;
            }
        }
        */
        else if(damagetype & (DMG_BLAST | DMG_AIRBOAT))
        {
            decl String:sWeaponName[64];
            new throwable = GetPlayerWeaponSlot(victim, 2);
            if(IsValidEdict(throwable))
            {
                GetEdictClassname(throwable, sWeaponName, sizeof(sWeaponName));
        
                new level = GetUpgradeLevel(victim, upgrade_explosive_resistance, sWeaponName);
                damage *= fResistance[level];

                return Plugin_Changed;
            }
        }
    }

    return Plugin_Continue;
}