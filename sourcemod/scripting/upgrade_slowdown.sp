#include "upgrademod/interface"

public Plugin:myinfo = 
{
    name = "Upgrademod - Upgrade - Zedtime",
    author = "Glider",
};

new zedtime;
new Float:fZedTimeCooldown[MAXPLAYERS];

public OnUpgrademodDatabaseLoaded(Handle:hDB)
{
    zedtime = RegisterUpgrade("zedtime");
}

public OnMapStart()
{
    for(new client=0; client <= MaxClients; client++)
    {
        fZedTimeCooldown[client] = 0.0;
    }
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
    if(!IsSniper(sWeaponName))
    {
        return Plugin_Continue;
    }
    
    new level = GetUpgradeLevel(client, zedtime, sWeaponName);
    if (level == 0)
    {
        return Plugin_Continue;
    }
    
    if(buttons & IN_RELOAD)
    {
        new iMaxMagSize = GetMaxMagSize(sWeaponName);
        new iMagSize = GetMagazineAmmo(iCurrentWeapon);
        new iBackupAmmo = GetCurrentBackupAmmo(client);
        
        if (iMaxMagSize == iMagSize && iBackupAmmo >= iMaxMagSize && (fZedTimeCooldown[client] <= GetGameTime()))
        {
            SetBackupAmmo(client, iBackupAmmo - iMaxMagSize);
            
            ActivateZedTime(client);
            
            fZedTimeCooldown[client] = GetGameTime() + 5.0;
        }
    }
    
    return Plugin_Continue;
}

ActivateZedTime(client)
{
    new iWeapon = GetEntPropEnt(client, Prop_Send, "m_hActiveWeapon");
    SetEntProp(iWeapon, Prop_Send, "m_helpingHandState", 3);
    
    decl i_Ent, Handle:h_pack;
    i_Ent = CreateEntityByName("func_timescale");
    DispatchKeyValue(i_Ent, "desiredTimescale", "0.2");
    DispatchKeyValue(i_Ent, "acceleration", "1.0");
    DispatchKeyValue(i_Ent, "minBlendRate", "1.0");
    DispatchKeyValue(i_Ent, "blendDeltaMultiplier", "2.0");
    DispatchSpawn(i_Ent);
    AcceptEntityInput(i_Ent, "Start");
    h_pack = CreateDataPack();
    WritePackCell(h_pack, i_Ent);
    CreateTimer(1.0, ZedBlendBack, h_pack);
    
    //EmitSoundToAll(Sound1, client);
}

public Action:ZedBlendBack(Handle:Timer, Handle:h_pack)
{
    decl i_Ent;
    ResetPack(h_pack, false);
    i_Ent = ReadPackCell(h_pack);
    CloseHandle(h_pack);
    if(IsValidEdict(i_Ent))
    {
        AcceptEntityInput(i_Ent, "Stop");
    }
    else
    {
        PrintToServer("[SM] i_Ent is not a valid edict!");
    }   
}   

public bool:OnIsUpgradeAvailableForWeapon(upgrade, String:sWeaponName[WEAPON_NAME_MAXLENGTH], &bool:result)
{
    if (upgrade == zedtime)
    {
        if(IsSniper(sWeaponName))
        {
            result = true;
        }
    }
}

public OnUpgradeDescriptionRequested(upgrade, String:sWeaponName[WEAPON_NAME_MAXLENGTH], level, String:sUpgradeDescription[UPGRADE_DESCRIPTION_MAXLENGTH])
{
    if(upgrade == zedtime)
    {
        Format(sUpgradeDescription, UPGRADE_DESCRIPTION_MAXLENGTH, "Reloading while your magazine is full will slow down time for a second.\nThis consumes full magazine from your reserves and has a 5 second cooldown.");
    }
}

public OnUpgradeNameRequested(upgrade, String:sWeaponName[WEAPON_NAME_MAXLENGTH], String:sUpgradeName[UPGRADE_NAME_MAXLENGTH])
{
    if(upgrade == zedtime)
    {
        Format(sUpgradeName, UPGRADE_NAME_MAXLENGTH, "Bullet Time");
    }
}

public OnUpgradeMaxLevelRequested(upgrade, String:sWeaponName[WEAPON_NAME_MAXLENGTH], &maxlevel)
{
    if(upgrade == zedtime)
    {
        maxlevel = 1;
    }
}