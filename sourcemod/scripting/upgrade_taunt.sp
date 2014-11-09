#include "upgrademod/interface"

public Plugin:myinfo = 
{
    name = "Upgrademod - Upgrade - Taunt",
    author = "Glider",
};

#define MAX_LEVEL 5

new Float:fTauntDuration[MAX_LEVEL + 1] = {0.0, 3.0, 6.0, 9.0, 12.0, 15.0};
new Float:fTauntCooldown[MAXPLAYERS];

new upgrade_taunt;

#define ULTIMATE_PARTICLE_1 "weapon_pipebomb_blinking_light"

public OnMapStart()
{
    PrecacheParticle(ULTIMATE_PARTICLE_1);
}

public OnUpgrademodDatabaseLoaded(Handle:hDB)
{
    upgrade_taunt = RegisterUpgrade("taunt");
}

public Action:OnPlayerRunCmd(client, &buttons, &impulse, Float:vel[3], Float:angles[3], &weapon)
{
    if (!IsValidPlayer(client, true))
    {
        return Plugin_Continue;
    }
    
    if (buttons & IN_RELOAD)
    {
        ActivateTaunt(client);
    }

    return Plugin_Continue;
}

ActivateTaunt(client)
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
        if(!IsMeleeWeapon(sWeaponName))
        {
            return;
        }
        
        new level = GetUpgradeLevel(client, upgrade_taunt, sWeaponName);
        if (level == 0)
        {
            return;
        }
        
        if(fTauntCooldown[client] <= GetGameTime())
        {
            fTauntCooldown[client] = GetGameTime() + 3.0 + fTauntDuration[level];
        }
        else
        {
            return;
        }
        
        if (!ConsumePrimaryMagazineFromPool(client))
        {
            return;
        }
        
        new iChaseEntity = CreateEntityByName("info_goal_infected_chase");
        if (IsValidEntity(iChaseEntity))
        {
            new Float:casterPos[3]; 
            
            GetClientAbsOrigin(client, casterPos);
            TeleportEntity(iChaseEntity, casterPos, NULL_VECTOR, NULL_VECTOR);
            
            DispatchSpawn(iChaseEntity);
            
            ModifyEntityAttach(iChaseEntity, client, "eyes");
            
            ActivateEntity(iChaseEntity);
            AcceptEntityInput(iChaseEntity, "enable");
            
            PerformSceneEx(client, "PlayerTaunt", "PlayerTaunt", 0.0, DEFAULT_SCENE_PITCH);

            AttachThrowAwayParticle(client, ULTIMATE_PARTICLE_1, NULL_VECTOR, "eyes", 15.0);
            ModifyEntityAddDeathTimer(iChaseEntity, fTauntDuration[level]);
        }
    }
}

public bool:OnIsUpgradeAvailableForWeapon(upgrade, String:sWeaponName[WEAPON_NAME_MAXLENGTH], &bool:result)
{
    if (upgrade == upgrade_taunt)
    {
        result = IsMeleeWeapon(sWeaponName);
    }
}

public OnUpgradeDescriptionRequested(upgrade, String:sWeaponName[WEAPON_NAME_MAXLENGTH], level, String:sUpgradeDescription[UPGRADE_DESCRIPTION_MAXLENGTH])
{
    if (upgrade == upgrade_taunt)
    {
        new Float:amount = fTauntDuration[level];
        Format(sUpgradeDescription, UPGRADE_DESCRIPTION_MAXLENGTH, "When you reload with a melee weapon all common infected suddenly become attracted to you.\nThis skill consumes a full magazine from your primary weapon.\nIt will last %f seconds", amount);
    }
}

public OnUpgradeNameRequested(upgrade, String:sWeaponName[WEAPON_NAME_MAXLENGTH], String:sUpgradeName[UPGRADE_NAME_MAXLENGTH])
{
    if (upgrade == upgrade_taunt)
    {
        Format(sUpgradeName, UPGRADE_NAME_MAXLENGTH, "Taunt (+reload)");
    }
}

public OnUpgradeMaxLevelRequested(upgrade, String:sWeaponName[WEAPON_NAME_MAXLENGTH], &maxlevel)
{
    if (upgrade == upgrade_taunt)
    {
        maxlevel = MAX_LEVEL;
    }
}

public OnUpgradeExperienceRequiredRequested(upgrade, String:sWeaponName[WEAPON_NAME_MAXLENGTH], level, &experience)
{
    if (upgrade == upgrade_taunt)
    {
        experience = 10000;
    }
}