#include "upgrademod/interface"

public Plugin:myinfo = 
{
    name = "Upgrademod - Upgrade - Dragon Breath",
    author = "Glider",
};

#define MAX_LEVEL 5

new Float:fDragonBreathDistance[MAX_LEVEL + 1] = {0.0, 200.0, 400.0, 600.0, 800.0, 1000.0};

new upgrade_db;

#define ULTIMATE_SND "weapons/grenade_launcher/grenadefire/grenade_launcher_explode_1.wav"
#define ULTIMATE_PARTICLE_1 "sline_sparks"
#define ULTIMATE_PARTICLE_2 "impact_explosive_ammo_large"

public OnMapStart()
{
    PrecacheParticle(ULTIMATE_PARTICLE_1);
    PrecacheParticle(ULTIMATE_PARTICLE_2);
    
    PrecacheSound(ULTIMATE_SND, true);
}

public OnUpgrademodDatabaseLoaded(Handle:hDB)
{
    upgrade_db = RegisterUpgrade("dragonbreath");
}

public Action:OnPlayerRunCmd(client, &buttons, &impulse, Float:vel[3], Float:angles[3], &weapon)
{
    if (!IsValidPlayer(client, true))
    {
        return Plugin_Continue;
    }
    
    if (buttons & IN_ZOOM)
    {
        ActivateDragonBreath(client);
    }

    return Plugin_Continue;
}

ActivateDragonBreath(client)
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
        
        new level = GetUpgradeLevel(client, upgrade_db, sWeaponName);
        if (level == 0)
        {
            return;
        }
        
        decl Float:VictimPosition[3];
        decl Float:CasterPosition[3];
        decl Float:EffectPosition[3];
    
        GetClientEyePosition(client, CasterPosition);
        
        new entity = GetClientAimedLocationData(client, NULL_VECTOR);

        if (IsCommonInfected(entity))
        {
            GetEntPropVector(entity, Prop_Send, "m_vecOrigin", VictimPosition);
            new Float:dis = GetVectorDistance(CasterPosition, VictimPosition);
            
            if(dis >= fDragonBreathDistance[level])
            {
                return;
            }

            if(!ConsumePrimaryMagazine(client))
            {
                return;
            }
            
            SetEntProp(iCurrentWeapon, Prop_Send, "m_helpingHandState", 3);
            
            GetEntPropVector(entity, Prop_Send, "m_vecOrigin", VictimPosition);
            GetEntPropVector(entity, Prop_Send, "m_vecOrigin", EffectPosition);
            
            new Float:ZombieVector[3];
            new Float:DirectionVector[3];
            GetEntPropVector(entity, Prop_Send, "m_vecOrigin", ZombieVector);
            ZombieVector[2] += 65.0;
            
            SubtractVectors(ZombieVector, CasterPosition, DirectionVector);
            NormalizeVector(DirectionVector, DirectionVector);
            
            ScaleVector(DirectionVector, 12000.0);
            
            SetEntPropVector(entity, Prop_Send, "m_gibbedLimbForce", DirectionVector);
            SetEntProp(entity, Prop_Send, "m_iRequestedWound1", 24);
            
            EffectPosition[2] += 50.0;
            
            ThrowAwayParticle(ULTIMATE_PARTICLE_1, EffectPosition, 2.5); 
            ThrowAwayParticle(ULTIMATE_PARTICLE_2, EffectPosition, 2.5); 
                            
            ThrowAwayLightEmitter(EffectPosition, "225 30 0 255", "5", 400.0, 0.4);
            
            TeleportEntity(client, VictimPosition, NULL_VECTOR, NULL_VECTOR);
            DealDamage(client, entity, 10000, 1, sWeaponName);
            
            // stagger special infected around the impact location
            for(new i=1; i <= MaxClients; i++)
            {
                if(IsValidPlayer(i, true) && GetClientTeam(i) == TEAM_INFECTED)
                {
                    GetClientAbsOrigin(i, VictimPosition);
                    dis = GetVectorDistance(CasterPosition, VictimPosition);
                    
                    if (dis < (150.0))
                    {
                        DealDamage(client, i, 10, DMG_BLAST, sWeaponName);
                    }
                }
            }
            
            EmitSoundToAll(ULTIMATE_SND, client);
        }
    }
}

GetClientAimedLocationData(client, Float:position[3])
{
    new index = -1;
    
    decl Float:_origin[3], Float:_angles[3];
    GetClientEyePosition( client, _origin );
    GetClientEyeAngles( client, _angles );

    new Handle:trace = TR_TraceRayFilterEx( _origin, _angles, MASK_SOLID_BRUSHONLY, RayType_Infinite, TraceEntityFilterPlayers );
    if( !TR_DidHit( trace ) )
    { 
        index = -1;
    }
    else
    {
        TR_GetEndPosition( position, trace );
        index = TR_GetEntityIndex( trace );
    }
    CloseHandle( trace );
    
    return index;
}

DealDamage(attacker, victim, damage, damage_type, String:sWeapon[WEAPON_NAME_MAXLENGTH])
{
    decl String:sDamage[16];
    IntToString(damage, sDamage, sizeof(sDamage));
    
    decl String:sDamageType[32];
    IntToString(damage_type, sDamageType,sizeof(sDamageType));
    
    new pointHurt=CreateEntityByName("point_hurt");
    if(pointHurt)
    {
        DispatchKeyValue(victim,"targetname", "damagedealer");
        DispatchKeyValue(pointHurt,"Damagetarget", "damagedealer");
        DispatchKeyValue(pointHurt,"Damage", sDamage);
        DispatchKeyValue(pointHurt,"DamageType",sDamageType);
        DispatchKeyValue(pointHurt,"classname", sWeapon);
        DispatchSpawn(pointHurt);

        AcceptEntityInput(pointHurt,"Hurt",(attacker > 0) ? attacker : -1);
        DispatchKeyValue(victim, "targetname", "donthurtme");
        RemoveEdict(pointHurt);
    }
}

public bool:TraceEntityFilterPlayers( entity, contentsMask, any:data )
{
    return entity > MaxClients && entity != data;
}

public bool:OnIsUpgradeAvailableForWeapon(upgrade, String:sWeaponName[WEAPON_NAME_MAXLENGTH], &bool:result)
{
    if (upgrade == upgrade_db)
    {
        result = IsMeleeWeapon(sWeaponName);
    }
}

public OnUpgradeDescriptionRequested(upgrade, String:sWeaponName[WEAPON_NAME_MAXLENGTH], level, String:sUpgradeDescription[UPGRADE_DESCRIPTION_MAXLENGTH])
{
    if (upgrade == upgrade_db)
    {
        new Float:amount = fDragonBreathDistance[level];
        Format(sUpgradeDescription, UPGRADE_DESCRIPTION_MAXLENGTH, "When you zoom while looking at a common infected you explode them and teleport to their location.\nThis skill consumes a full magazine from your primary weapon.\nYou can teleport to common infected %f units away.", amount);
    }
}

public OnUpgradeNameRequested(upgrade, String:sWeaponName[WEAPON_NAME_MAXLENGTH], String:sUpgradeName[UPGRADE_NAME_MAXLENGTH])
{
    if (upgrade == upgrade_db)
    {
        Format(sUpgradeName, UPGRADE_NAME_MAXLENGTH, "Dragon Breath (+zoom)");
    }
}

public OnUpgradeMaxLevelRequested(upgrade, String:sWeaponName[WEAPON_NAME_MAXLENGTH], &maxlevel)
{
    if (upgrade == upgrade_db)
    {
        maxlevel = MAX_LEVEL;
    }
}

public OnUpgradeExperienceRequiredRequested(upgrade, String:sWeaponName[WEAPON_NAME_MAXLENGTH], level, &experience)
{
    if (upgrade == upgrade_db)
    {
        experience = level * 10000;
    }
}