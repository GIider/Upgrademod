#include "upgrademod/interface"

public Plugin:myinfo = 
{
    name = "Upgrademod - Upgrade - Melee Upgrades",
    author = "Glider",
};

#define MAX_LEVEL 5

new Float:fLeapStrength[MAX_LEVEL + 1] = {0.0, 300.0, 333.0, 366.0, 399.0, 432.0};
new Float:fMeleeASPDBuff[MAX_LEVEL + 1] = {1.0, 1.15, 1.3, 1.45, 1.5, 1.6};

new upgrade_leap;
new upgrade_speed;

new bool:g_bHasDoubleJumped[MAXPLAYERS];
new bool:g_bIsJumping[MAXPLAYERS];
new Float:g_fPressedJump[MAXPLAYERS];

public OnMapStart()
{
    PrecacheParticle("impact_explosive_ammo_small");
    PrecacheParticle("weapon_pipebomb_blinking_light");
}

public OnUpgrademodDatabaseLoaded(Handle:hDB)
{
    upgrade_leap = RegisterUpgrade("leap");
    upgrade_speed = RegisterUpgrade("swingspeed");
}

public Action:OnPlayerRunCmd(client, &buttons, &impulse, Float:vel[3], Float:angles[3], &weapon)
{
    if (!IsValidPlayer(client, true))
    {
        return Plugin_Continue;
    }
    
    new iCurrentWeapon = GetEntPropEnt(client, Prop_Send, "m_hActiveWeapon");
    decl String:sWeaponName[WEAPON_NAME_MAXLENGTH];

    if (!IsValidEntity(iCurrentWeapon))
    {
        return Plugin_Continue;
    }
    
    GetEdictClassname(iCurrentWeapon, sWeaponName, sizeof(sWeaponName));
    if(!IsMeleeWeapon(sWeaponName))
    {
        return Plugin_Continue;
    }
    
    new leap_level = GetUpgradeLevel(client, upgrade_leap, sWeaponName);
    new speed_level = GetUpgradeLevel(client, upgrade_speed, sWeaponName);
    if (leap_level == 0 && speed_level == 0)
    {
        return Plugin_Continue;
    }
    
    if (buttons & IN_ATTACK && speed_level > 0)
    {
        AdjustWeaponSpeed(client, speed_level);
    }

    if (leap_level > 0)
    {
        if(leap_level > 0 && !IsHelpless(client) && !IsPlayerIncapped(client) && !IsFakeClient(client))
        {
            // Double jumping on ladders? No sir!
            if (GetEntityMoveType(client) == MOVETYPE_LADDER) 
            {
                return Plugin_Continue;
            }
            
            new flags = GetEntityFlags(client);
    
            if(buttons & IN_JUMP)
            {
                if (!g_bIsJumping[client])
                {
                    g_fPressedJump[client] = GetGameTime() + 0.20;
                    g_bIsJumping[client] = true;
                }
                        
                if (!(flags & FL_ONGROUND) && g_fPressedJump[client] <= GetGameTime())
                    if (!g_bHasDoubleJumped[client])
                    {   
                        Leap(client, leap_level);
                    }
            }
            else if (flags & FL_ONGROUND)
            {
                g_bIsJumping[client] = false;
                g_bHasDoubleJumped[client] = false;
            }
        }
    }

    return Plugin_Continue;
}

AdjustWeaponSpeed(client, level)
{
    new Float:amount = fMeleeASPDBuff[level];
    new slot = 1;
    
    if (GetPlayerWeaponSlot(client, slot) > 0)
    {
        new Float:m_flNextPrimaryAttack = GetEntPropFloat(GetPlayerWeaponSlot(client, slot), Prop_Send, "m_flNextPrimaryAttack");
        new Float:m_flNextSecondaryAttack = GetEntPropFloat(GetPlayerWeaponSlot(client, slot), Prop_Send, "m_flNextSecondaryAttack");
        new Float:m_flCycle = GetEntPropFloat(GetPlayerWeaponSlot(client, slot), Prop_Send, "m_flCycle");
        new m_bInReload = GetEntProp(GetPlayerWeaponSlot(client, slot), Prop_Send, "m_bInReload");
        
        if (m_flCycle == 0.000000 && m_bInReload < 1)
        {
            SetEntPropFloat(GetPlayerWeaponSlot(client, slot), Prop_Send, "m_flPlaybackRate", amount);
            SetEntPropFloat(GetPlayerWeaponSlot(client, slot), Prop_Send, "m_flNextPrimaryAttack", m_flNextPrimaryAttack - ((amount - 1.0) / 2));
            SetEntPropFloat(GetPlayerWeaponSlot(client, slot), Prop_Send, "m_flNextSecondaryAttack", m_flNextSecondaryAttack - ((amount - 1.0) / 2));
        }
    }
}

Leap(client, level)
{
    new Float:amount = fLeapStrength[level];
    
    decl Float:fPos[3];
    GetEntPropVector(client, Prop_Send, "m_vecOrigin", fPos);
    fPos[2] += 5.0;
    ThrowAwayParticle("impact_explosive_ammo_small", fPos, 1.0);

    new Float:vAngles[3], Float:vReturn[3]; 
    GetClientEyeAngles(client, vAngles);

    vReturn[0] = FloatMul(Cosine(DegToRad(vAngles[1])), amount);
    vReturn[1] = FloatMul(Sine(DegToRad(vAngles[1])), amount);
    vReturn[2] = FloatMul(Sine(DegToRad(vAngles[0])), (0 - amount));

    // Enables user to escape fall damage
    new Float:EmptyVector[3] = {0.0, 0.0, 0.0};
    TeleportEntity(client, NULL_VECTOR, NULL_VECTOR, EmptyVector);
    
    // Now make them leap
    TeleportEntity(client, NULL_VECTOR, NULL_VECTOR, vReturn);  
    g_bHasDoubleJumped[client] = true;
}

public bool:OnIsUpgradeAvailableForWeapon(upgrade, String:sWeaponName[WEAPON_NAME_MAXLENGTH], &bool:result)
{
    if (upgrade == upgrade_leap || upgrade == upgrade_speed)
    {
        result = IsMeleeWeapon(sWeaponName) && !IsSpecialWeapon(sWeaponName);
    }
}

public OnUpgradeDescriptionRequested(upgrade, String:sWeaponName[WEAPON_NAME_MAXLENGTH], level, String:sUpgradeDescription[UPGRADE_DESCRIPTION_MAXLENGTH])
{
    if (upgrade == upgrade_leap)
    {
        Format(sUpgradeDescription, UPGRADE_DESCRIPTION_MAXLENGTH, "When you jump in midair you leap forward.\nEvery level increase the distance you can leap by.");
    }
    else if (upgrade == upgrade_speed)
    {
        new percentage = RoundToFloor(fMeleeASPDBuff[level] * 100) - 100;
        Format(sUpgradeDescription, UPGRADE_DESCRIPTION_MAXLENGTH, "Increases your swing speed with melee weapons.\nYou currently swing %d %% faster", percentage);
    }
}

public OnUpgradeNameRequested(upgrade, String:sWeaponName[WEAPON_NAME_MAXLENGTH], String:sUpgradeName[UPGRADE_NAME_MAXLENGTH])
{
    if (upgrade == upgrade_leap)
    {
        Format(sUpgradeName, UPGRADE_NAME_MAXLENGTH, "Leap (+jump)");
    }
    else if (upgrade == upgrade_speed)
    {
        Format(sUpgradeName, UPGRADE_NAME_MAXLENGTH, "Blood Rush");
    }
}

public OnUpgradeMaxLevelRequested(upgrade, String:sWeaponName[WEAPON_NAME_MAXLENGTH], &maxlevel)
{
    if (upgrade == upgrade_leap || upgrade == upgrade_speed)
    {
        maxlevel = MAX_LEVEL;
    }
}

public OnUpgradeExperienceRequiredRequested(upgrade, String:sWeaponName[WEAPON_NAME_MAXLENGTH], level, &experience)
{
    if (upgrade == upgrade_leap || upgrade == upgrade_speed)
    {
        experience = level * 10000;
    }
}