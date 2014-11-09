enum L4D2UseAction
{
    L4D2UseAction_None              = 0, // No use action active
    L4D2UseAction_Healing           = 1, // Includes healing yourself or a teammate.
    L4D2UseAction_Defibing          = 4, // When defib'ing a dead body.
    L4D2UseAction_GettingDefibed    = 5, // When comming back to life from a dead body.
    L4D2UseAction_PouringGas        = 8, // Pouring gas into a generator
    L4D2UseAction_Cola              = 9, // For Dead Center map 2 cola event, when handing over the cola to whitalker.
    L4D2UseAction_Button            = 10 // Such as buttons, timed buttons, generators, etc.
    /* List is not fully done, these are just the ones I have found so far */
}

stock CreateProgressBar(client, Float:fTimeDur)
{
    SetEntPropFloat(client, Prop_Send, "m_flProgressBarDuration", fTimeDur);
    SetEntPropFloat(client, Prop_Send, "m_flProgressBarStartTime", GetGameTime());
}

stock KillProgressBar(client)
{
    SetEntProp(client, Prop_Send, "m_iCurrentUseAction", L4D2UseAction_None);
    
    SetEntPropFloat(client, Prop_Send, "m_flProgressBarDuration", 0.0);
    SetEntPropFloat(client, Prop_Send, "m_flProgressBarStartTime", GetGameTime());
}

stock bool:IsZombieEntity(iEntity)
{
    return IsCommonInfected(iEntity) || IsWitch(iEntity);
}

// returns true for both common and uncommon infected
stock bool:IsCommonInfected(iEntity)
{
    if(iEntity > 0 && IsValidEntity(iEntity) && IsValidEdict(iEntity))
    {
        decl String:strClassName[64];
        GetEdictClassname(iEntity, strClassName, sizeof(strClassName));
        
        return StrEqual(strClassName, "infected");
    }
    return false;
}

stock bool:IsUncommonInfected(iEntity)
{
    if(iEntity > 0 && IsValidEntity(iEntity) && IsValidEdict(iEntity))
    {
        decl String:ModelName[128];
        GetEntPropString(iEntity, Prop_Data, "m_ModelName", ModelName, sizeof(ModelName));
        
        return (StrEqual(ModelName, "models/infected/common_male_riot.mdl") ||
                StrEqual(ModelName, "models/infected/common_male_ceda.mdl") ||
                StrEqual(ModelName, "models/infected/common_male_clown.mdl") ||
                StrEqual(ModelName, "models/infected/common_male_mud.mdl") ||
                StrEqual(ModelName, "models/infected/common_male_roadcrew.mdl") ||
                StrEqual(ModelName, "models/infected/common_male_jimmy.mdl") ||
                StrEqual(ModelName, "models/infected/common_male_fallen_survivor.mdl"));
    }
    return false;
}

stock bool:IsWitch(iEntity)
{
    if(iEntity > 0 && IsValidEntity(iEntity) && IsValidEdict(iEntity))
    {
        decl String:strClassName[64];
        GetEdictClassname(iEntity, strClassName, sizeof(strClassName));
        return StrEqual(strClassName, "witch");
    }
    return false;
}

stock SetSpecialAmmoInPlayerGun(client, amount)
{
    if (!client) client = 1;
    
    new gunent = GetPlayerWeaponSlot(client, 0);
    if (IsValidEdict(gunent) && amount > 0)
    {
        new Handle:datapack = CreateDataPack();
        WritePackCell(datapack, gunent);
        WritePackCell(datapack, amount);
        CreateTimer(0.1, SetGunSpecialAmmo, datapack);
    }
}

public Action:SetGunSpecialAmmo(Handle:timer, Handle:datapack)
{
    ResetPack(datapack);
    new ent = ReadPackCell(datapack);
    new amount = ReadPackCell(datapack);
    CloseHandle(datapack);
    
    SetEntProp(ent, Prop_Send, "m_nUpgradedPrimaryAmmoLoaded", amount, 1);
}

stock SetIncendiaryAmmoInMagazine(client, amount)
{
    CheatCommand(client, "upgrade_add", "INCENDIARY_AMMO");
    SetSpecialAmmoInPlayerGun(client, amount);
}

stock SetExplosiveAmmoInMagazine(client, amount)
{
    CheatCommand(client, "upgrade_add", "EXPLOSIVE_AMMO");
    SetSpecialAmmoInPlayerGun(client, amount);
}

/**
 * Returns true if a infected is making love to a client.
 * 
 * Bug: If you kick the infected then this function will still return true
 * for the client until he gets properly freed from a infected attack.
 */
native bool:IsHelpless(client);  

stock bool:IsPlayerIncapped(client)
{
    if (GetEntProp(client, Prop_Send, "m_isIncapacitated", 1)) return true;
    return false;
}

//  * type == 0: Fire
//  * type != 0: Explosion
native L4D_Explode(attacker, Float:pos[3], type);

// To check if an infected in versus hasn't spawned yet
stock bool:IsPlayerGhost(client)
{
    if (GetEntProp(client, Prop_Send, "m_isGhost", 1) == 1)
    {
        return true;
    }
    
    return false;
}

stock GotoFirstPerson(client)
{
    SetEntPropFloat(client, Prop_Send, "m_TimeForceExternalView", 0.0);
}

stock GotoThirdPersonVisible(client)
{
    SetEntPropFloat(client, Prop_Send, "m_TimeForceExternalView", 99999.3);
}

native bool:Upgrade_MarkEnemy(enemy, Float:fDuration);
native bool:Upgrade_UnmarkEnemy(enemy);