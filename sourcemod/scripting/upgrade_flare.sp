#include "upgrademod/interface"

public Plugin:myinfo = 
{
    name = "Upgrademod - Upgrade - Flare",
    author = "Glider",
};

// Based on https://forums.alliedmods.net/showthread.php?p=1606590

#define FLARE_ALIVE_TIMER 30.0
#define FLARE_MARK_DISTANCE 100.0
#define FLARE_MARK_DURATION 0.1

#define MODEL_FLARE         "models/props_lighting/light_flares.mdl"
#define PARTICLE_FLARE      "flare_burning"
#define PARTICLE_FUSE       "weapon_pipebomb_fuse"
#define SOUND_CRACKLE       "ambient/fire/fire_small_loop2.wav"

new flare;
new g_iGrndLAlpha = 255; // Light alpha
new g_iGrndSAlpha = 60; // Smoke alpha
new g_iGrndSHeight = 100; // Smoke height
new Float:g_fFlareAngle;

new Handle:hExistingFlaresArray = INVALID_HANDLE;

public OnUpgrademodDatabaseLoaded(Handle:hDB)
{
    flare = RegisterUpgrade("flare");
}

public OnMapStart()
{
    PrecacheModel(MODEL_FLARE, true);
    PrecacheSound(SOUND_CRACKLE, true);

    PrecacheParticle(PARTICLE_FLARE);
    PrecacheParticle(PARTICLE_FUSE);
}

public OnPluginStart()
{
    hExistingFlaresArray = CreateArray(1);
    
    CreateTimer(0.1, CheckFlaresTimer, _, TIMER_REPEAT);
}

public bool:OnIsUpgradeAvailableForWeapon(upgrade, String:sWeaponName[WEAPON_NAME_MAXLENGTH], &bool:result)
{
    if (upgrade == flare)
    {
        result = IsTierOneWeapon(sWeaponName);
    }
}


public OnUpgradeNameRequested(upgrade, String:sWeaponName[WEAPON_NAME_MAXLENGTH], String:sUpgradeName[UPGRADE_NAME_MAXLENGTH])
{
    if(upgrade == flare)
    {
        Format(sUpgradeName, UPGRADE_NAME_MAXLENGTH, "Flare (+zoom)");
    }
}

public OnUpgradeMaxLevelRequested(upgrade, String:sWeaponName[WEAPON_NAME_MAXLENGTH], &maxlevel)
{
    if(upgrade == flare)
    {
        maxlevel = 1;
    }
}

public OnUpgradeDescriptionRequested(upgrade, String:sWeaponName[WEAPON_NAME_MAXLENGTH], level, String:sUpgradeDescription[UPGRADE_DESCRIPTION_MAXLENGTH])
{
    if(upgrade == flare)
    {
        Format(sUpgradeDescription, UPGRADE_DESCRIPTION_MAXLENGTH, "Hold your zoom key to drop a flare.\nA flare will last %0f seconds", FLARE_ALIVE_TIMER);
    }
}

public OnUpgradeExperienceRequiredRequested(upgrade, String:sWeaponName[WEAPON_NAME_MAXLENGTH], level, &experience)
{
    if(upgrade == flare)
    {
        experience = 3000;
    }
}

new Handle:g_hTimerHandleProgress[MAXPLAYERS+1];
new bool:g_bIsMakingProgress[MAXPLAYERS+1];
new ProgressID = 0;
new g_ClientProgressID[MAXPLAYERS+1];

// TODO: Add a check so this can't overwrite another progress bar
public ActivateProgressBar(client, Float:fTime)
{
    new iCurrentWeapon = GetEntPropEnt(client, Prop_Send, "m_hActiveWeapon");
    decl String:sWeaponName[WEAPON_NAME_MAXLENGTH];

    if (!IsValidEntity(iCurrentWeapon))
    {
        return -1;
    }
    
    GetEdictClassname(iCurrentWeapon, sWeaponName, sizeof(sWeaponName));
    if(!IsTierOneWeapon(sWeaponName))
    {
        return -1;
    }
    
    new level = GetUpgradeLevel(client, flare, sWeaponName);
    if (level == 0)
    {
        return -1;
    }
    
    new client_ref = EntIndexToEntRef(client);
    
    if (!g_bIsMakingProgress[client]) 
    {
        new progress_id = ProgressID++;
        g_bIsMakingProgress[client] = true;
        g_ClientProgressID[client] = progress_id;
        
        SetEntProp(client, Prop_Send, "m_iCurrentUseAction", L4D2UseAction_Button);
        CreateProgressBar(client, fTime);

        // should probaly not send the client through here
        g_hTimerHandleProgress[client] = CreateTimer(fTime, TimerProgressBarSuccess, client_ref, TIMER_FLAG_NO_MAPCHANGE);
        
        return progress_id;
    }
    else 
    {
        return -1;
    }
}

CancelProgressBar(client) 
{
    g_bIsMakingProgress[client] = false;
    KillProgressBar(client);
    
    KillTimer(g_hTimerHandleProgress[client]);
    g_hTimerHandleProgress[client] = INVALID_HANDLE;
}

public Action:TimerProgressBarSuccess(Handle:timer, any:client_ref)
{
    new client = EntRefToEntIndex(client_ref);
    if (IsValidPlayer(client, true) && g_bIsMakingProgress[client] == true) 
    {
        KillProgressBar(client);
        
        new flare_entity = CreateFlare(client, "200 20 15", "200 20 15");
        if (IsValidEntity(flare_entity))
        {
            PushArrayCell(hExistingFlaresArray, flare_entity);
        }
    }
    
    g_bIsMakingProgress[client] = false;
}

public Action:CheckFlaresTimer(Handle:timer, any:data)
{
    new flare_entity = -1;
    for(new index=0; index < GetArraySize(hExistingFlaresArray); index++)
    {
        flare_entity = GetArrayCell(hExistingFlaresArray, index);

        if (IsValidEntity(flare_entity))
        {
            new Float:fFlarePosition[3];
            new Float:fEnemyPosition[3];
            GetEntPropVector(flare_entity, Prop_Send, "m_vecOrigin", fFlarePosition);
            
            // check special infected
            for(new i=1; i <= MaxClients; i++)
            {
                if(IsValidPlayer(i, true) && GetClientTeam(i) == TEAM_INFECTED)
                {
                    
                    GetClientAbsOrigin(i, fEnemyPosition);
                    if(GetVectorDistance(fEnemyPosition, fFlarePosition) <= FLARE_MARK_DISTANCE)
                    {
                        Upgrade_MarkEnemy(i, FLARE_MARK_DURATION);
                    }
                }
            }
            
            // check common infected
            new entity = -1;
            while ((entity = FindEntityByClassname(entity, "infected")) != INVALID_ENT_REFERENCE) 
            {
                GetEntPropVector(entity, Prop_Send, "m_vecOrigin", fEnemyPosition);
                if(GetVectorDistance(fEnemyPosition, fFlarePosition) <= FLARE_MARK_DISTANCE)
                {
                    Upgrade_MarkEnemy(entity, FLARE_MARK_DURATION);
                }
            }
        }
        // Problematic as it will shift down??
        else
        {
            RemoveFromArray(hExistingFlaresArray, index);
        }
    }
}
 
public Action:OnPlayerRunCmd(client, &buttons, &impulse, Float:vel[3], Float:angles[3], &weapon)
{
    if (IsValidPlayer(client, true) && GetClientTeam(client) == TEAM_SURVIVORS)
    {
        if(g_bIsMakingProgress[client])
        {
            if (buttons & IN_JUMP || buttons & IN_FORWARD || buttons & IN_BACK || 
                buttons & IN_LEFT || buttons & IN_RIGHT || buttons & IN_MOVELEFT || 
                buttons & IN_MOVERIGHT || buttons & IN_ATTACK || buttons ^ IN_ZOOM) 
            {
                CancelProgressBar(client);  
            }
        }
        else
        {
            if (buttons & IN_ZOOM)
            {
                ActivateProgressBar(client, 1.5);
            }
        }
    }

    return Plugin_Continue; 
}






// Create flare Attached / Ground, called from incap events and sm_flare commands.
CreateFlare(client, const String:sColorL[], const String:sColorS[]="")
{
    new Float:vAngles[3], Float:vOrigin[3];

    // Flare position
    if( !MakeFlarePosition(client, vOrigin, vAngles) )
    {
        //CPrintToChat(client, "%s%T", CHAT_TAG, "Flare Invalid Place", client);
        return -1; // Could not place after 12 attempts?!
    }

    return MakeFlare(vAngles, vOrigin, sColorL, sColorS);
}

bool:MakeFlarePosition(client, Float:vOrigin[3], Float:vAngles[3])
{
    new Float:i, Float:iLoop, Float:fRadius=30.0, Float:vAngle, Float:vTargetOrigin[3];

    GetClientAbsOrigin(client, vOrigin);
    iLoop = GetRandomFloat(1.0, 360.0); // Random circle starting point

    // Loop through 12 positions around the player to find a good flare position
    for (i = iLoop; i <= iLoop + 6.0; i += 0.5)
    {
        vTargetOrigin = vOrigin;
        vAngle = i * 360.0 / 12.0; // Divide circle into 12
        fRadius -= GetRandomFloat(0.0, 10.0); // Randomise circle radius

        // Draw in a circle around player
        vTargetOrigin[0] += fRadius * (Sine(vAngle));
        vTargetOrigin[1] += fRadius * (Cosine(vAngle));

        // Trace from target origin and get ground positon/angles for placement
        GetGroundAngles(vTargetOrigin, vAngles);

        // Make sure the flare is within a resonable height and distance
        fRadius = vTargetOrigin[2] - vOrigin[2];
        if( (fRadius >= -60.0 && fRadius <= 5.0) && GetVectorDistance(vTargetOrigin, vOrigin) <= 100.0)
        {
            vOrigin = vTargetOrigin;
            return true;
        }
    }
    return false;
}


GetGroundAngles(Float:vOrigin[3], Float:vAngles[3])
{
    decl Float:vAng[3], Float:vLookAt[3], Float:vTargetOrigin[3];

    vTargetOrigin = vOrigin;
    vTargetOrigin[2] -= 20.0; // Point to the floor
    MakeVectorFromPoints(vOrigin, vTargetOrigin, vLookAt);
    GetVectorAngles(vLookAt, vAng); // get angles from vector for trace

    // execute Trace
    new Handle:trace = TR_TraceRayFilterEx(vOrigin, vAng, MASK_ALL, RayType_Infinite, _TraceFilter);

    if( TR_DidHit(trace) )
    {
        decl Float:vStart[3], Float:vNorm[3];
        TR_GetEndPosition(vStart, trace); // retrieve our trace endpoint
        TR_GetPlaneNormal(trace, vNorm); // Ground angles
        GetVectorAngles(vNorm, vAngles);

        new Float:fRandom = GetRandomFloat(1.0, 360.0); // Random angle

        if( vNorm[2] == 1.0 ) // Is flat on ground
        {
            vAngles[0] = 0.0;
            vAngles[1] = fRandom;           // Rotate the prop in a random direction
        }
        else
        {
            vAngles[0] += 90.0;
            RotateYaw(vAngles, fRandom);    // Rotate the prop in a random direction
        }

        vOrigin = vStart;
    }
    CloseHandle(trace);
}

public bool:_TraceFilter(entity, contentsMask)
{
    if( !entity || entity <= MaxClients || !IsValidEntity(entity) ) // dont let WORLD, or invalid entities be hit
        return false;
    return true;
}

//---------------------------------------------------------
// do a specific rotation on the given angles
//---------------------------------------------------------
RotateYaw( Float:angles[3], Float:degree )
{
    decl Float:direction[3], Float:normal[3];
    GetAngleVectors( angles, direction, NULL_VECTOR, normal );

    new Float:sin = Sine( degree * 0.01745328 );     // Pi/180
    new Float:cos = Cosine( degree * 0.01745328 );
    new Float:a = normal[0] * sin;
    new Float:b = normal[1] * sin;
    new Float:c = normal[2] * sin;
    new Float:x = direction[2] * b + direction[0] * cos - direction[1] * c;
    new Float:y = direction[0] * c + direction[1] * cos - direction[2] * a;
    new Float:z = direction[1] * a + direction[2] * cos - direction[0] * b;
    direction[0] = x;
    direction[1] = y;
    direction[2] = z;

    GetVectorAngles( direction, angles );

    decl Float:up[3];
    GetVectorVectors( direction, NULL_VECTOR, up );

    new Float:roll = GetAngleBetweenVectors( up, normal, direction );
    angles[2] += roll;
}

//---------------------------------------------------------
// calculate the angle between 2 vectors
// the direction will be used to determine the sign of angle (right hand rule)
// all of the 3 vectors have to be normalized
//---------------------------------------------------------
Float:GetAngleBetweenVectors( const Float:vector1[3], const Float:vector2[3], const Float:direction[3] )
{
    decl Float:vector1_n[3], Float:vector2_n[3], Float:direction_n[3], Float:cross[3];
    NormalizeVector( direction, direction_n );
    NormalizeVector( vector1, vector1_n );
    NormalizeVector( vector2, vector2_n );
    new Float:degree = ArcCosine( GetVectorDotProduct( vector1_n, vector2_n ) ) * 57.29577951;   // 180/Pi
    GetVectorCrossProduct( vector1_n, vector2_n, cross );

    if ( GetVectorDotProduct( cross, direction_n ) < 0.0 )
        degree *= -1.0;

    return degree;
}

// After getting the flare position, we finally make it...
MakeFlare(Float:vAngles[3], Float:vOrigin[3], const String:sColorL[], const String:sColorS[])
{
    new flare_entity;
    
    // Flare model
    flare_entity = CreateEntityByName("prop_dynamic");
    new entity = flare_entity;
    
    if( flare_entity == -1 )
    {
        LogError("Failed to create 'prop_dynamic'. Stopped making flare.");
        return -1;
    }
    else
    {
        ModifyEntityAddDeathTimer(entity, FLARE_ALIVE_TIMER);
        SetEntityModel(entity, MODEL_FLARE);
        DispatchSpawn(entity);
        TeleportEntity(entity, vOrigin, vAngles, NULL_VECTOR);
    }

    // Light
    vOrigin[2] += 15.0;
    entity = MakeLightDynamic(vOrigin, Float:{ 90.0, 0.0, 0.0 }, sColorL, g_iGrndLAlpha);
    ModifyEntityAddDeathTimer(entity, FLARE_ALIVE_TIMER);
    vOrigin[2] -= 15.0;

    // Position particles / smoke
    entity = 0;
    if( g_fFlareAngle == 0.0 ) g_fFlareAngle = GetRandomFloat(1.0, 360.0);
    vAngles[1] = g_fFlareAngle;
    vAngles[0] = -80.0;
    vOrigin[0] += (1.0 * (Cosine(DegToRad(vAngles[1]))));
    vOrigin[1] += (1.5 * (Sine(DegToRad(vAngles[1]))));
    vOrigin[2] += 1.0;

    // Flare particles
    entity = DisplayParticle(PARTICLE_FLARE, vOrigin, vAngles);
    ModifyEntityAddDeathTimer(entity, FLARE_ALIVE_TIMER);
    
    // Fuse particles
    entity = DisplayParticle(PARTICLE_FUSE, vOrigin, vAngles);
    ModifyEntityAddDeathTimer(entity, FLARE_ALIVE_TIMER);

    // Smoke
    vAngles[0] = -85.0;
    entity = MakeEnvSteam(vOrigin, vAngles, sColorS, g_iGrndSAlpha, g_iGrndSHeight);
    ModifyEntityAddDeathTimer(entity, FLARE_ALIVE_TIMER);

    PlaySound(entity);
    
    return flare_entity;
}

DisplayParticle(const String:sParticle[], const Float:vPos[3], const Float:vAng[3], client=0, const String:sAttachment[] = "")
{
    new entity = CreateEntityByName("info_particle_system");

    if( entity != -1 )
    {
        DispatchKeyValue(entity, "effect_name", sParticle);
        DispatchSpawn(entity);
        ActivateEntity(entity);
        AcceptEntityInput(entity, "start");

        if( client )
        {
            // Attach to survivor
            SetVariantString("!activator");
            AcceptEntityInput(entity, "SetParent", client);

            if( strlen(sAttachment) != 0 )
            {
                SetVariantString(sAttachment);
                AcceptEntityInput(entity, "SetParentAttachment");
            }
        }

        TeleportEntity(entity, vPos, vAng, NULL_VECTOR);
        return entity;
    }
    return 0;
}

// ====================================================================================================
//                  SOUND
// ====================================================================================================
PlaySound(entity)
{
    EmitSoundToAll(SOUND_CRACKLE, entity, SNDCHAN_AUTO, SNDLEVEL_DISHWASHER, SND_SHOULDPAUSE, SNDVOL_NORMAL, SNDPITCH_HIGH, -1, NULL_VECTOR, NULL_VECTOR);
}

// ====================================================================================================
//                  LIGHTS
// ====================================================================================================
MakeLightDynamic(const Float:vOrigin[3], const Float:vAngles[3], const String:sColor[], iDist, bool:bFlicker = true, client = 0, const String:sAttachment[] = "")
{
    new entity = CreateEntityByName("light_dynamic");
    if( entity == -1)
    {
        LogError("Failed to create 'light_dynamic'");
        return 0;
    }

    decl String:sTemp[16];
    if( bFlicker )
        Format(sTemp, sizeof(sTemp), "6");
    else
        Format(sTemp, sizeof(sTemp), "0");
    DispatchKeyValue(entity, "style", sTemp);
    Format(sTemp, sizeof(sTemp), "%s 255", sColor);
    DispatchKeyValue(entity, "_light", sTemp);
    DispatchKeyValue(entity, "brightness", "1");
    DispatchKeyValueFloat(entity, "spotlight_radius", 32.0);
    DispatchKeyValueFloat(entity, "distance", float(iDist));
    DispatchSpawn(entity);
    AcceptEntityInput(entity, "TurnOn");
    TeleportEntity(entity, vOrigin, vAngles, NULL_VECTOR);

    // Attach to survivor
    new len = strlen(sAttachment);
    if( client )
    {
        SetVariantString("!activator");
        AcceptEntityInput(entity, "SetParent", client);

        if( len != 0 )
        {
            SetVariantString(sAttachment);
            AcceptEntityInput(entity, "SetParentAttachment");
        }
    }
    return entity;
}

MakeEnvSteam(const Float:vOrigin[3], const Float:vAngles[3], const String:sColor[], iAlpha, iLength)
{
    new entity = CreateEntityByName("env_steam");
    if( entity == -1 )
    {
        LogError("Failed to create 'env_steam'");
        return 0;
    }

    decl String:sTemp[5];
    DispatchKeyValue(entity, "SpawnFlags", "1");
    DispatchKeyValue(entity, "rendercolor", sColor);
    DispatchKeyValue(entity, "SpreadSpeed", "1");
    DispatchKeyValue(entity, "Speed", "15");
    DispatchKeyValue(entity, "StartSize", "1");
    DispatchKeyValue(entity, "EndSize", "3");
    DispatchKeyValue(entity, "Rate", "10");
    IntToString(iLength, sTemp, sizeof(sTemp));
    DispatchKeyValue(entity, "JetLength", sTemp);
    IntToString(iAlpha, sTemp, sizeof(sTemp));
    DispatchKeyValue(entity, "renderamt", sTemp);
    DispatchKeyValue(entity, "InitialState", "1");
    DispatchSpawn(entity);
    AcceptEntityInput(entity, "TurnOn");
    TeleportEntity(entity, vOrigin, vAngles, NULL_VECTOR);
    return entity;
}