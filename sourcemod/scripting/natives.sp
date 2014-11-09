#include "upgrademod/interface"

public Plugin:myinfo = 
{
    name = "Upgrademod - Engine - Natives",
    author = "Glider",
};

new bool:g_bIsHelpless[MAXPLAYERS+1];
new Handle:g_hArrayOfKaboom = INVALID_HANDLE;

static const String:CLASSNAME_INFECTED[]    = "infected";
static const String:CLASSNAME_WITCH[]       = "witch";


public APLRes:AskPluginLoad2(Handle:myself, bool:late, String:error[], err_max)
{
    CreateNative("IsHelpless", Native_IsHelpless);
    CreateNative("L4D_Explode", Native_L4D_CauseExplosion);
    CreateNative("Upgrade_MarkEnemy", Native_MarkEnemy);
    CreateNative("Upgrade_UnmarkEnemy", Native_UnmarkEnemy);
    
    return APLRes_Success;
}

public OnMapStart()
{
    PrecacheModel(MODEL_GASCAN, true);
    PrecacheModel(MODEL_PROPANE, true);
}

public OnPluginStart()
{
	// Hunter
	HookEvent("lunge_pounce", Event_IsHelpless);
	HookEvent("pounce_stopped", Event_IsNoLongerHelpless);
	
	// Smoker
	HookEvent("tongue_grab", Event_IsHelpless);
	HookEvent("tongue_release", Event_IsNoLongerHelpless);
	
	// Charger
	HookEvent("charger_carry_start", Event_IsHelpless);
	HookEvent("charger_carry_end", Event_IsNoLongerHelpless);
	// Yes, there is a small time gap between carrying and pummeling that
	// is not accounted for.
	HookEvent("charger_pummel_start", Event_IsHelpless);
	HookEvent("charger_pummel_end", Event_IsNoLongerHelpless);
		
	// Jockey
	HookEvent("jockey_ride", Event_IsHelpless);
	HookEvent("jockey_ride_end", Event_IsNoLongerHelpless);
	
	HookEvent("round_start", Event_ResetHelplessAll);
	HookEvent("round_end", Event_ResetHelplessAll);
	
	HookEvent("player_spawn", Event_ResetHelplessUserID);
	HookEvent("player_death", Event_ResetHelplessUserID);
	HookEvent("player_connect_full", Event_ResetHelplessUserID);
	HookEvent("player_disconnect", Event_ResetHelplessUserID);
	
	g_hArrayOfKaboom = CreateArray();
}


public Event_IsHelpless (Handle:event, const String:name[], bool:dontBroadcast)
{
	new victim = GetClientOfUserId(GetEventInt(event, "victim"));
	if (!victim) return;
	
	g_bIsHelpless[victim] = true;
}

public Event_IsNoLongerHelpless (Handle:event, const String:name[], bool:dontBroadcast)
{
	new victim = GetClientOfUserId(GetEventInt(event, "victim"));
	if (!victim) return;
	
	g_bIsHelpless[victim] = false;
}

public Event_ResetHelplessAll (Handle:event, const String:name[], bool:dontBroadcast)
{
	for (new i=1 ; i<=MaxClients ; i++)
	{
		g_bIsHelpless[i] = false;
	}
}

public Event_ResetHelplessUserID (Handle:event, const String:name[], bool:dontBroadcast)
{
	new client = GetClientOfUserId(GetEventInt(event, "userid"));
	if (!client) return;
	
	g_bIsHelpless[client] = false;
}

public Native_IsHelpless(Handle:plugin, numParams)
{
	new client = GetNativeCell(1);
	
	return g_bIsHelpless[client];
}

public Native_L4D_CauseExplosion(Handle:plugin, numParams)
{
    decl Float:pos[3];
    
    new attacker = GetNativeCell(1);
    GetNativeArray(2, pos, sizeof(pos));
    new type = GetNativeCell(3);
            
    CauseExplosion(attacker, pos, type);
}

/* type == 0: Fire
 * type != 0: Explosion
 */
stock CauseExplosion(attacker, Float:pos[3], type)
{
    new entity = CreateEntityByName("prop_physics");
    if (IsValidEntity(entity))
    {
        PushArrayCell(g_hArrayOfKaboom, entity);
        SDKHook(entity, SDKHook_SetTransmit, Hook_SetTransmit);
        
        pos[2] += 10.0;
        if (type == 0)
            DispatchKeyValue(entity, "model", MODEL_GASCAN);
        else
            DispatchKeyValue(entity, "model", MODEL_PROPANE);
        DispatchSpawn(entity);
        TeleportEntity(entity, pos, NULL_VECTOR, NULL_VECTOR);
        SetEntPropEnt(entity, Prop_Send, "m_hOwnerEntity", attacker);
    }
}

public Action:Hook_SetTransmit(temp_explosive, client)
{
    return Plugin_Handled; 
}

public OnGameFrame()
{
    new iAmountOfKabooms = GetArraySize(g_hArrayOfKaboom);
    for(new i; i < iAmountOfKabooms; i++)
    {
        new item = GetArrayCell(g_hArrayOfKaboom, i);
        if(IsValidEntity(item))
        {
            // Normally the entity would explode instantly,
            // but when you create it from a timer there's a slight
            // delay where the entity isn't correctly spawned(?) yet,
            // so keep hammering until it's finished
            if(ExplodeThisEntity(item))
            {
                RemoveFromArray(g_hArrayOfKaboom, i);
            }
        }
        else
        {
            RemoveFromArray(g_hArrayOfKaboom, i);
        }
    }
}

// Apply damage to an entity until its broken...
// Returns true when the entity hp drops to 0 or below
bool:ExplodeThisEntity(entity)
{
    new attacker = GetEntPropEnt(entity, Prop_Data, "m_hOwnerEntity");
    
    SDKHooks_TakeDamage(entity, attacker, attacker, 100.0);
    
    return GetEntityHP(entity) <= 0;
}

public Native_MarkEnemy(Handle:plugin, numParams)
{
    new entity = GetNativeCell(1);
    new Float:fDuration = GetNativeCell(2);
            
    if(IsValidEntity(entity))
    {
        return MarkEnemy(entity, fDuration);
    }
    
    return false;
}

public Native_UnmarkEnemy(Handle:plugin, numParams)
{
    new entity = GetNativeCell(1);
            
    if(IsValidEntity(entity))
    {
        UnmarkEntity(entity);
    }
}

bool:MarkEnemy(entity, Float:fDuration)
{
    new hp = GetEntityHP(entity);
    
    if (hp <= 0)
    {
        return false;
    }
    
    if(IsZombieEntity(entity))
    {
        // Don't mess with biled commons
        new biled = GetEntProp(entity, Prop_Send, "m_glowColorOverride");
        if (biled == -4713783)
        {
            return false;
        }
        
        new ragdoll = GetEntProp(entity, Prop_Send, "m_bClientSideRagdoll");
        if (ragdoll == 1)
        {
            SetEntProp(entity, Prop_Send, "m_iGlowType", 0);
            return false;
        }
    }
    else if(IsValidPlayer(entity, true) && GetClientTeam(entity) == TEAM_INFECTED)
    {
        new Float:fBiledTime = GetEntPropFloat(entity, Prop_Send, "m_vomitFadeStart");
        if (fBiledTime != 0.0 && fBiledTime + 5.0 > GetGameTime())
        {
            SetEntProp(entity, Prop_Send, "m_iGlowType", 0);
            return false;
        }
    }
    
    SetEntProp(entity, Prop_Send, "m_glowColorOverride", 255);
    SetEntProp(entity, Prop_Send, "m_iGlowType", 3);

    CreateTimer(fDuration, UnmarkEntityTimer, EntIndexToEntRef(entity));
    
    return true;
}

public Action:UnmarkEntityTimer(Handle:timer, any:victim)
{
    victim = EntRefToEntIndex(victim);
    UnmarkEntity(victim);
    
    return Plugin_Handled;
}

UnmarkEntity(entity)
{
    if (IsValidEntity(entity))
    {
        SetEntProp(entity, Prop_Send, "m_iGlowType", 0);
    }
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
    if(IsValidEntity(victim) || IsValidPlayer(victim))
    {
        new hp = GetEntityHP(victim);
        
        if (hp <= 0 || damage >= hp)
        {
            UnmarkEntity(victim);
        }
    }
    
    return Plugin_Continue;
}