#include "upgrademod/interface"

public Plugin:myinfo = 
{
    name = "Upgrademod - Upgrade - Underslung Grenade Launcher",
    author = "Glider",
};

#define MAX_LEVEL 4

new Float:fGrenadeRange = 600.0;
new GrenadeDamage[MAX_LEVEL + 1]= {0, 75, 100, 125, 150};

new upgrade_grenade;
new g_iVelocity;
new GrenadeLauncher[MAXPLAYERS+1];
new gGrenadeLevel[MAXPLAYERS];

new String:sWeaponNameArray[MAXPLAYERS][WEAPON_NAME_MAXLENGTH];

#define GRENADE_SHOOT_SND "weapons/grenade_launcher/grenadefire/grenade_launcher_fire_1.wav"
#define GRENADE_EXPLODE_SND "weapons/grenade_launcher/grenadefire/grenade_launcher_explode_1.wav"
#define GRENADE_EXPLOSION_PARTICLE "gas_explosion_pump"

public OnMapStart()
{
    PrecacheParticle(GRENADE_EXPLOSION_PARTICLE);
    
    PrecacheSound(GRENADE_SHOOT_SND, true);
    PrecacheSound(GRENADE_EXPLODE_SND, true);
}

public OnPluginStart()
{
    g_iVelocity = FindSendPropOffs("CBasePlayer","m_vecVelocity[0]");
    
    HookEvent("grenade_bounce", grenade_bounce);
}


public OnUpgrademodDatabaseLoaded(Handle:hDB)
{
    upgrade_grenade = RegisterUpgrade("underslunggrenade");
}

public Action:OnPlayerRunCmd(client, &buttons, &impulse, Float:vel[3], Float:angles[3], &weapon)
{
    if (!IsValidPlayer(client, true))
    {
        return Plugin_Continue;
    }
    
    if (buttons & IN_ZOOM)
    {
        ShootUnderslungGrenade(client);
    }

    return Plugin_Continue;
}

ShootUnderslungGrenade(client)
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
        if(!IsAssaultRifle(sWeaponName))
        {
            return;
        }
        
        new level = GetUpgradeLevel(client, upgrade_grenade, sWeaponName);
        if (level == 0)
        {
            return;
        }
    
        if(!ConsumePrimaryMagazine(client))
        {
            return;
        }

        gGrenadeLevel[client] = level;
        sWeaponNameArray[client] = sWeaponName;
        FireGrenade(client);
        EmitSoundToAll(GRENADE_SHOOT_SND, client);
    }
}

DealDamage(attacker, victim, damage, damage_type, String:sWeapon[WEAPON_NAME_MAXLENGTH])
{
    decl String:sDamage[16];
    IntToString(damage, sDamage, sizeof(sDamage));
    
    decl String:sDamageType[32];
    IntToString(damage_type, sDamageType,sizeof(sDamageType));
    
    new pointHurt = CreateEntityByName("point_hurt");
    if(pointHurt && IsValidEdict(victim))
    {
        DispatchKeyValue(victim, "targetname", "damagedealer");
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
    if (upgrade == upgrade_grenade)
    {
        result = IsAssaultRifle(sWeaponName) && !HasScope(sWeaponName);
    }
}

public OnUpgradeDescriptionRequested(upgrade, String:sWeaponName[WEAPON_NAME_MAXLENGTH], level, String:sUpgradeDescription[UPGRADE_DESCRIPTION_MAXLENGTH])
{
    if (upgrade == upgrade_grenade)
    {
        new damage= GrenadeDamage[level];
        Format(sUpgradeDescription, UPGRADE_DESCRIPTION_MAXLENGTH, "When you press zoom with a full magazine you fire a underslung grenadelauncher.\nThis skill consumes a full magazine from your primary weapon.\nYou deal %d damage with your grenade", damage);
    }
}

public OnUpgradeNameRequested(upgrade, String:sWeaponName[WEAPON_NAME_MAXLENGTH], String:sUpgradeName[UPGRADE_NAME_MAXLENGTH])
{
    if (upgrade == upgrade_grenade)
    {
        Format(sUpgradeName, UPGRADE_NAME_MAXLENGTH, "Underslung Grenade Launcher (+zoom)");
    }
}

public OnUpgradeMaxLevelRequested(upgrade, String:sWeaponName[WEAPON_NAME_MAXLENGTH], &maxlevel)
{
    if (upgrade == upgrade_grenade)
    {
        maxlevel = MAX_LEVEL;
    }
}

//=======================================================================
//                                 GRENADE LAUNCHER
//=======================================================================

FireGrenade(userid)
{
    decl Float:pos[3];
    decl Float:angles[3];
    decl Float:velocity[3];
    new Float:force = 500.0;
    GetClientEyePosition(userid, pos);
     
    GetClientEyeAngles(userid, angles);
    GetEntDataVector(userid, g_iVelocity, velocity);
    
    angles[0]-=5.0;
    
    velocity[0] = force * Cosine(DegToRad(angles[1])) * Cosine(DegToRad(angles[0]));
    velocity[1] = force * Sine(DegToRad(angles[1])) * Cosine(DegToRad(angles[0]));
    velocity[2] = force * Sine(DegToRad(angles[0])) * -1.0;

    //new Float:force=GetConVarFloat(w_laugch_force);

    GetAngleVectors(angles, velocity, NULL_VECTOR, NULL_VECTOR);
    NormalizeVector(velocity, velocity);
    ScaleVector(velocity, force);
    
    {
        new Float:B=-3.1415926/2.0;
        decl Float:vec[3];
        decl Float:vec2[3];
        GetAngleVectors(angles,vec, NULL_VECTOR, NULL_VECTOR);
        GetAngleVectors(angles,vec2, NULL_VECTOR, NULL_VECTOR);
        new Float:x0=vec[0];
        new Float:y0=vec[1];
        new Float:x1=x0*Cosine(B)-y0*Sine(B);
        new Float:y1=x0*Sine(B)+y0*Cosine(B);
        vec[0]=x1;
        vec[1]=y1;
        vec[2]=0.0;
        NormalizeVector(vec,vec);
        NormalizeVector(vec2,vec2);
        ScaleVector(vec, 8.0);
        ScaleVector(vec2, 20.0);
        AddVectors(pos, vec, pos);
    }

    new ent = 0;

    ent=CreateEntityByName("grenade_launcher_projectile");
    DispatchKeyValue(ent, "model", "models/w_models/weapons/w_HE_grenade.mdl");  

    SetEntPropEnt(ent, Prop_Data, "m_hOwnerEntity", userid) ;           

    DispatchSpawn(ent);  
    TeleportEntity(ent, pos, NULL_VECTOR, velocity);
    ActivateEntity(ent);

    SetEntityGravity(ent, 0.4);
 
    if(GrenadeLauncher[userid] > 0 && IsValidEntity(GrenadeLauncher[userid]))
    {
        RemoveEdict(GrenadeLauncher[userid]);
    }
    GrenadeLauncher[userid]=ent;
    
    return;
}

public Action:grenade_bounce(Handle:h_Event, const String:s_Name[], bool:b_DontBroadcast)
{
    new client = GetClientOfUserId(GetEventInt(h_Event, "userid"));
    
    if(GrenadeLauncher[client] > 0 && IsValidEntity(GrenadeLauncher[client]))
    {
        new Float:CasterPosition[3];    
        new Float:VictimPosition[3];
        new Float:EffectPosition[3];
        
        GetEntPropVector(GrenadeLauncher[client], Prop_Send, "m_vecOrigin", CasterPosition);
        GetEntPropVector(GrenadeLauncher[client], Prop_Send, "m_vecOrigin", EffectPosition);
        EffectPosition[2] += 40.0;
        
        EmitSoundToAll(GRENADE_EXPLODE_SND, GrenadeLauncher[client]);
        L4D_Explode(client, CasterPosition, 1); 
        
        GetEntPropVector(GrenadeLauncher[client], Prop_Send, "m_vecOrigin", EffectPosition);
        EffectPosition[2] += 40.0;
        
        ThrowAwayParticle(GRENADE_EXPLOSION_PARTICLE, EffectPosition, 2.5); 
        ThrowAwayLightEmitter(EffectPosition, "225 30 0 255", "5", 500.0, 0.4);
        EmitSoundToAll(GRENADE_EXPLODE_SND, GrenadeLauncher[client]);

        new entity = -1;
        new skill = gGrenadeLevel[client];
        new damage;
        decl String:sWeaponName[WEAPON_NAME_MAXLENGTH];
        strcopy(sWeaponName, sizeof(sWeaponName), sWeaponNameArray[client]);
        
        while ((entity = FindEntityByClassname(entity, "infected")) != INVALID_ENT_REFERENCE) 
        {
            GetEntPropVector(entity, Prop_Send, "m_vecOrigin", VictimPosition);
            new Float:dis = GetVectorDistance(CasterPosition, VictimPosition);
            
            if (dis < (fGrenadeRange))
            {
                damage =  RoundToCeil(GrenadeDamage[skill] * (1 - (dis / fGrenadeRange)));
                
                if ( damage >= GetEntityHP(entity) )
                {
                    new Float:DirectionVector[3];
                    VictimPosition[2] += 65.0;
                    
                    SubtractVectors(VictimPosition, CasterPosition, DirectionVector);
                    NormalizeVector(DirectionVector, DirectionVector);
                    
                    ScaleVector(DirectionVector, 12000.0);
                    
                    SetEntPropVector(entity, Prop_Send, "m_gibbedLimbForce", DirectionVector);
                    SetEntProp(entity, Prop_Send, "m_iRequestedWound1", 24);
                    
                }

                DealDamage(client, entity, damage, 1, sWeaponName);
            }
        } 
        
        while ((entity = FindEntityByClassname(entity, "witch")) != INVALID_ENT_REFERENCE) 
        {
            GetEntPropVector(entity, Prop_Send, "m_vecOrigin", VictimPosition);
            new Float:dis = GetVectorDistance(CasterPosition, VictimPosition);
            
            if (dis < (fGrenadeRange))
            {
                damage =  RoundToCeil(GrenadeDamage[skill] * (1 - (dis / fGrenadeRange)));
                DealDamage(client, entity, damage, 1, sWeaponName);
            }
        }
        
        // check special infected
        for(new i=1; i <= MaxClients; i++)
        {
            if(IsValidPlayer(i, true) && GetClientTeam(i) == TEAM_INFECTED)
            {
                GetClientAbsOrigin(i, VictimPosition);
                new Float:dis = GetVectorDistance(CasterPosition, VictimPosition);
                
                if (dis < (fGrenadeRange))
                {
                    damage =  RoundToCeil(GrenadeDamage[skill] * (1 - (dis / fGrenadeRange)));
                    DealDamage(client, entity, damage, 1, sWeaponName);
                }
            }
        }
        
        
        if(GrenadeLauncher[client] > 0 && IsValidEntity(GrenadeLauncher[client]))
        {
            AcceptEntityInput(GrenadeLauncher[client], "break");
            RemoveEdict(GrenadeLauncher[client]);
        }
        
        GrenadeLauncher[client] = 0;
        
    }
}