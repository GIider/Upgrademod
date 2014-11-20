#include "upgrademod/interface"

public Plugin:myinfo = 
{
    name = "Upgrademod - Upgrade - Tracer Rounds",
    author = "Glider",
};

new marker;

static const String:CLASSNAME_INFECTED[]    = "infected";
static const String:CLASSNAME_WITCH[]       = "witch";


public OnUpgrademodDatabaseLoaded(Handle:hDB)
{
    marker = RegisterUpgrade("marker");
}

public OnEntityCreated(entity, const String:classname[])
{
    if (StrEqual(classname, CLASSNAME_INFECTED, false) || StrEqual(classname, CLASSNAME_WITCH, false))
    {
        SDKHook(entity, SDKHook_OnTakeDamage, SDK_Forwarded_OnTakeDamage);
    }
}

public OnClientPutInServer(client)
{
    SDKHook(client, SDKHook_OnTakeDamage, SDK_Forwarded_OnTakeDamage);
}

public Action:SDK_Forwarded_OnTakeDamage(victim, &attacker, &inflictor, &Float:damage, &damagetype)
{
    if(IsValidPlayer(attacker, true) && (damagetype & DMG_BULLET))
    {
        new iCurrentWeapon = GetEntPropEnt(attacker, Prop_Send, "m_hActiveWeapon");
        decl String:sWeaponName[WEAPON_NAME_MAXLENGTH];

        if (IsValidEntity(iCurrentWeapon))
        {
            GetEdictClassname(iCurrentWeapon, sWeaponName, sizeof(sWeaponName));
        }
        else
        {
            return Plugin_Continue;
        }
        
        if (!IsSMG(sWeaponName) && !IsSniper(sWeaponName))
        {
            return Plugin_Continue;
        }
        
        new level = GetUpgradeLevel(attacker, marker, sWeaponName);
        if (level == 0)
        {
            return Plugin_Continue;
        }
        
        new hp = GetEntityHP(victim);
        
        if (hp > 0 && hp > damage)
        {
            new Float:duration = GetUpgradeDuration(level, sWeaponName);
            Upgrade_MarkEnemy(victim, duration);
        }
        else
        {
            Upgrade_UnmarkEnemy(victim);
        }
    }

    return Plugin_Continue;
}

public bool:OnIsUpgradeAvailableForWeapon(upgrade, String:sWeaponName[WEAPON_NAME_MAXLENGTH], &bool:result)
{
    if (upgrade == marker)
    {
        if(IsSMG(sWeaponName) || IsSniper(sWeaponName))
        {
            result = true;
        }
    }
}

public OnUpgradeDescriptionRequested(upgrade, String:sWeaponName[WEAPON_NAME_MAXLENGTH], level, String:sUpgradeDescription[UPGRADE_DESCRIPTION_MAXLENGTH])
{
    if(upgrade == marker)
    {
        new Float:duration = GetUpgradeDuration(level, sWeaponName);
        
        Format(sUpgradeDescription, UPGRADE_DESCRIPTION_MAXLENGTH, "Your gunfire will mark enemies for %.1f seconds", duration);
    }
}

Float:GetUpgradeDuration(level, String:sWeaponName[WEAPON_NAME_MAXLENGTH])
{
    new Float:seconds;
    
    if(IsSMG(sWeaponName))
    {
        seconds = level * 0.1;
    }
    else if (IsSniper(sWeaponName))
    {
        seconds = level * 2.5;
    }

    return seconds;
}

public OnUpgradeNameRequested(upgrade, String:sWeaponName[WEAPON_NAME_MAXLENGTH], String:sUpgradeName[UPGRADE_NAME_MAXLENGTH])
{
    if(upgrade == marker)
    {
        if(IsSMG(sWeaponName))
        {
            Format(sUpgradeName, UPGRADE_NAME_MAXLENGTH, "Tracer Rounds");
        }
        else if (IsSniper(sWeaponName))
        {
            Format(sUpgradeName, UPGRADE_NAME_MAXLENGTH, "Advanced Tracer Rounds");
        }
    }
}

public OnUpgradeMaxLevelRequested(upgrade, String:sWeaponName[WEAPON_NAME_MAXLENGTH], &maxlevel)
{
    if(upgrade == marker)
    {
        if(IsSMG(sWeaponName))
        {
            maxlevel = 10;
        }
        else if (IsSniper(sWeaponName))
        {
            maxlevel = 3;
        }
    }
}