#include "upgrademod/interface"

public Plugin:myinfo = 
{
    name = "Upgrademod - Upgrade - Improved Reload",
    author = "Glider",
};

// Based on https://forums.alliedmods.net/showthread.php?p=1187539

#define MAX_LEVEL 4

new reload;
new Float:fReloadSpeed[MAX_LEVEL + 1]= {1.0, 0.89285, 0.7857, 0.67855, 0.5714};

new Float:fClientReloadRate[MAXPLAYERS];

//offsets
new g_iNextPAttO        = -1;
new g_iActiveWO         = -1;
new g_iShotStartDurO    = -1;
new g_iShotInsertDurO   = -1;
new g_iShotEndDurO      = -1;
new g_iPlayRateO        = -1;
new g_iShotRelStateO    = -1;
new g_iNextAttO         = -1;
new g_iTimeIdleO        = -1;
new g_iVMStartTimeO     = -1;
new g_iViewModelO       = -1;

//This keeps track of the default values for reload speeds for the different shotgun types
//NOTE: I got these values from tPoncho's own source
//NOTE: Pump and Chrome have identical values
const Float:g_fl_AutoS = 0.666666;
const Float:g_fl_AutoI = 0.4;
const Float:g_fl_AutoE = 0.675;
const Float:g_fl_SpasS = 0.5;
const Float:g_fl_SpasI = 0.375;
const Float:g_fl_SpasE = 0.699999;
const Float:g_fl_PumpS = 0.5;
const Float:g_fl_PumpI = 0.5;
const Float:g_fl_PumpE = 0.6;

public OnUpgrademodDatabaseLoaded(Handle:hDB)
{
    reload = RegisterUpgrade("reload");
}

public OnPluginStart()
{
    HookEvent("weapon_reload", Event_Reload);
    
    //get offsets
    g_iNextPAttO        =   FindSendPropInfo("CBaseCombatWeapon","m_flNextPrimaryAttack");
    g_iActiveWO         =   FindSendPropInfo("CBaseCombatCharacter","m_hActiveWeapon");
    g_iShotStartDurO    =   FindSendPropInfo("CBaseShotgun","m_reloadStartDuration");
    g_iShotInsertDurO   =   FindSendPropInfo("CBaseShotgun","m_reloadInsertDuration");
    g_iShotEndDurO      =   FindSendPropInfo("CBaseShotgun","m_reloadEndDuration");
    g_iPlayRateO        =   FindSendPropInfo("CBaseCombatWeapon","m_flPlaybackRate");
    g_iShotRelStateO    =   FindSendPropInfo("CBaseShotgun","m_reloadState");
    g_iNextAttO         =   FindSendPropInfo("CTerrorPlayer","m_flNextAttack");
    g_iTimeIdleO        =   FindSendPropInfo("CTerrorGun","m_flTimeWeaponIdle");
    g_iVMStartTimeO     =   FindSendPropInfo("CTerrorViewModel","m_flLayerStartTime");
    g_iViewModelO       =   FindSendPropInfo("CTerrorPlayer","m_hViewModel");
}

public Event_Reload (Handle:event, const String:name[], bool:dontBroadcast)
{
    new client = GetClientOfUserId(GetEventInt(event, "userid"));
    if(!IsValidPlayer(client, true))
    {
        return;
    }
    
    new iCurrentWeapon = GetEntPropEnt(client, Prop_Send, "m_hActiveWeapon");

    if (!IsValidEntity(iCurrentWeapon))
    {
        return;
    }

    decl String:sWeaponName[WEAPON_NAME_MAXLENGTH];
    GetEdictClassname(iCurrentWeapon, sWeaponName, sizeof(sWeaponName));

    new level = GetUpgradeLevel(client, reload, sWeaponName);
    
    if (level == 0)
    {
        return;
    }
    
    fClientReloadRate[client] = fReloadSpeed[level];
    PerformFastReload(client);
}

//On the start of a reload
PerformFastReload(client)
{
    if (GetClientTeam(client) == TEAM_SURVIVORS)
    {
        new iEntid = GetEntDataEnt2(client, g_iActiveWO);
        if (IsValidEntity(iEntid)==false) return;
    
        decl String:stClass[32];
        GetEntityNetClass(iEntid,stClass,32);

        //for non-shotguns
        if (StrContains(stClass,"shotgun",false) == -1)
        {
            MagStart(iEntid, client);
            return;
        }
        //shotguns are a bit trickier since the game tracks per shell inserted
        //and there's TWO different shotguns with different values...
        else if (StrContains(stClass,"autoshotgun",false) != -1)
        {
            //create a pack to send clientid and gunid through to the timer
            new Handle:hPack = CreateDataPack();
            WritePackCell(hPack, client);
            WritePackCell(hPack, iEntid);
            CreateTimer(0.1,Timer_AutoshotgunStart,hPack);
            return;
        }
        else if (StrContains(stClass,"shotgun_spas",false) != -1)
        {
            //similar to the autoshotgun, create a pack to send
            new Handle:hPack = CreateDataPack();
            WritePackCell(hPack, client);
            WritePackCell(hPack, iEntid);
            CreateTimer(0.1,Timer_SpasShotgunStart,hPack);
            return;
        }
        else if (StrContains(stClass,"pumpshotgun",false) != -1 || StrContains(stClass,"shotgun_chrome",false) != -1)
        {
            new Handle:hPack = CreateDataPack();
            WritePackCell(hPack, client);
            WritePackCell(hPack, iEntid);
            CreateTimer(0.1,Timer_PumpshotgunStart,hPack);
            return;
        }
        
    }
}
// ////////////////////////////////////////////////////////////////////////////
//called for mag loaders
MagStart (iEntid, client)
{
    new Float:flGameTime = GetGameTime();
    new Float:flNextTime_ret = GetEntDataFloat(iEntid,g_iNextPAttO);

    //this is a calculation of when the next primary attack will be after applying reload values
    //NOTE: at this point, only calculate the interval itself, without the actual game engine time factored in
    new Float:flNextTime_calc = ( flNextTime_ret - flGameTime ) * fClientReloadRate[client] ;
    //we change the playback rate of the gun, just so the player can "see" the gun reloading faster
    SetEntDataFloat(iEntid, g_iPlayRateO, 1.0/fClientReloadRate[client], true);
    //create a timer to reset the playrate after time equal to the modified attack interval
    CreateTimer( flNextTime_calc, Timer_MagEnd, iEntid);
    //experiment to remove double-playback bug
    new Handle:hPack = CreateDataPack();
    WritePackCell(hPack, client);
    //this calculates the equivalent time for the reload to end
    new Float:flStartTime_calc = flGameTime - ( flNextTime_ret - flGameTime ) * ( 1 - fClientReloadRate[client] ) ;
    WritePackFloat(hPack, flStartTime_calc);
    //now we create the timer that will prevent the annoying double playback
    if ( (flNextTime_calc - 0.4) > 0 )
        CreateTimer( flNextTime_calc - 0.4 , Timer_MagEnd2, hPack);
    //and finally we set the end reload time into the gun so the player can actually shoot with it at the end
    flNextTime_calc += flGameTime;
    SetEntDataFloat(iEntid, g_iTimeIdleO, flNextTime_calc, true);
    SetEntDataFloat(iEntid, g_iNextPAttO, flNextTime_calc, true);
    SetEntDataFloat(client, g_iNextAttO, flNextTime_calc, true);
}

//called for autoshotguns
public Action:Timer_AutoshotgunStart (Handle:timer, Handle:hPack)
{
    KillTimer(timer);
    if (IsServerProcessing()==false)
        return Plugin_Stop;

    ResetPack(hPack);
    new iCid = ReadPackCell(hPack);
    new iEntid = ReadPackCell(hPack);
    CloseHandle(hPack);
    hPack = CreateDataPack();
    WritePackCell(hPack, iCid);
    WritePackCell(hPack, iEntid);

    if (iCid <= 0
        || iEntid <= 0
        || IsValidEntity(iCid)==false
        || IsValidEntity(iEntid)==false
        || IsClientInGame(iCid)==false)
        return Plugin_Stop;

    //then we set the new times in the gun
    SetEntDataFloat(iEntid, g_iShotStartDurO,   g_fl_AutoS*fClientReloadRate[iCid],    true);
    SetEntDataFloat(iEntid, g_iShotInsertDurO,  g_fl_AutoI*fClientReloadRate[iCid],    true);
    SetEntDataFloat(iEntid, g_iShotEndDurO,     g_fl_AutoE*fClientReloadRate[iCid],    true);

    //we change the playback rate of the gun just so the player can "see" the gun reloading faster
    SetEntDataFloat(iEntid, g_iPlayRateO, 1.0/fClientReloadRate[iCid], true);

    //and then call a timer to periodically check whether the gun is still reloading or not to reset the animation
    //but first check the reload state; if it's 2, then it needs a pump/cock before it can shoot again, and thus needs more time
    CreateTimer(0.3,Timer_ShotgunEnd,hPack,TIMER_REPEAT);

    return Plugin_Stop;
}

public Action:Timer_SpasShotgunStart (Handle:timer, Handle:hPack)
{
    KillTimer(timer);
    if (IsServerProcessing()==false)
        return Plugin_Stop;

    ResetPack(hPack);
    new iCid = ReadPackCell(hPack);
    new iEntid = ReadPackCell(hPack);
    CloseHandle(hPack);
    hPack = CreateDataPack();
    WritePackCell(hPack, iCid);
    WritePackCell(hPack, iEntid);

    if (iCid <= 0
        || iEntid <= 0
        || IsValidEntity(iCid)==false
        || IsValidEntity(iEntid)==false
        || IsClientInGame(iCid)==false)
        return Plugin_Stop;

    //then we set the new times in the gun
    SetEntDataFloat(iEntid, g_iShotStartDurO,   g_fl_SpasS*fClientReloadRate[iCid],    true);
    SetEntDataFloat(iEntid, g_iShotInsertDurO,  g_fl_SpasI*fClientReloadRate[iCid],    true);
    SetEntDataFloat(iEntid, g_iShotEndDurO,     g_fl_SpasE*fClientReloadRate[iCid],    true);

    //we change the playback rate of the gun just so the player can "see" the gun reloading faster
    SetEntDataFloat(iEntid, g_iPlayRateO, 1.0/fClientReloadRate[iCid], true);

    //and then call a timer to periodically check whether the gun is still reloading or not to reset the animation
    //but first check the reload state; if it's 2, then it needs a pump/cock before it can shoot again, and thus needs more time
    CreateTimer(0.3,Timer_ShotgunEnd,hPack,TIMER_REPEAT);

    return Plugin_Stop;
}

//called for pump/chrome shotguns
public Action:Timer_PumpshotgunStart (Handle:timer, Handle:hPack)
{
    KillTimer(timer);
    if (IsServerProcessing()==false)
        return Plugin_Stop;

    ResetPack(hPack);
    new iCid = ReadPackCell(hPack);
    new iEntid = ReadPackCell(hPack);
    CloseHandle(hPack);
    hPack = CreateDataPack();
    WritePackCell(hPack, iCid);
    WritePackCell(hPack, iEntid);

    if (iCid <= 0
        || iEntid <= 0
        || IsValidEntity(iCid)==false
        || IsValidEntity(iEntid)==false
        || IsClientInGame(iCid)==false)
        return Plugin_Stop;

    //then we set the new times in the gun
    SetEntDataFloat(iEntid, g_iShotStartDurO,   g_fl_PumpS*fClientReloadRate[iCid],    true);
    SetEntDataFloat(iEntid, g_iShotInsertDurO,  g_fl_PumpI*fClientReloadRate[iCid],    true);
    SetEntDataFloat(iEntid, g_iShotEndDurO,     g_fl_PumpE*fClientReloadRate[iCid],    true);

    //we change the playback rate of the gun just so the player can "see" the gun reloading faster
    SetEntDataFloat(iEntid, g_iPlayRateO, 1.0/fClientReloadRate[iCid], true);

    //and then call a timer to periodically check whether the gun is still reloading or not to reset the animation
    CreateTimer(0.3,Timer_ShotgunEnd,hPack,TIMER_REPEAT);

    return Plugin_Stop;
}
// ////////////////////////////////////////////////////////////////////////////
//this resets the playback rate on non-shotguns
public Action:Timer_MagEnd (Handle:timer, any:iEntid)
{
    KillTimer(timer);
    if (IsServerProcessing()==false)
        return Plugin_Stop;

    if (iEntid <= 0
        || IsValidEntity(iEntid)==false)
        return Plugin_Stop;

    SetEntDataFloat(iEntid, g_iPlayRateO, 1.0, true);

    return Plugin_Stop;
}

public Action:Timer_MagEnd2 (Handle:timer, Handle:hPack)
{
    KillTimer(timer);
    if (IsServerProcessing()==false)
    {
        CloseHandle(hPack);
        return Plugin_Stop;
    }

    ResetPack(hPack);
    new iCid = ReadPackCell(hPack);
    new Float:flStartTime_calc = ReadPackFloat(hPack);
    CloseHandle(hPack);

    if (iCid <= 0
        || IsValidEntity(iCid)==false
        || IsClientInGame(iCid)==false)
        return Plugin_Stop;

    //experimental, remove annoying double-playback
    new iVMid = GetEntDataEnt2(iCid,g_iViewModelO);
    SetEntDataFloat(iVMid, g_iVMStartTimeO, flStartTime_calc, true);

    return Plugin_Stop;
}

public Action:Timer_ShotgunEnd (Handle:timer, Handle:hPack)
{
    ResetPack(hPack);
    new iCid = ReadPackCell(hPack);
    new iEntid = ReadPackCell(hPack);

    if (IsServerProcessing()==false
        || iCid <= 0
        || iEntid <= 0
        || IsValidEntity(iCid)==false
        || IsValidEntity(iEntid)==false
        || IsClientInGame(iCid)==false)
    {
        KillTimer(timer);
        return Plugin_Stop;
    }

    if (GetEntData(iEntid,g_iShotRelStateO)==0)
    {
        SetEntDataFloat(iEntid, g_iPlayRateO, 1.0, true);

        //new iCid=GetEntPropEnt(iEntid,Prop_Data,"m_hOwner");
        new Float:flTime=GetGameTime()+0.2;
        SetEntDataFloat(iCid,   g_iNextAttO,    flTime, true);
        SetEntDataFloat(iEntid, g_iTimeIdleO,   flTime, true);
        SetEntDataFloat(iEntid, g_iNextPAttO,   flTime, true);

        KillTimer(timer);
        CloseHandle(hPack);
        return Plugin_Stop;
    }

    return Plugin_Continue;
}
// ////////////////////////////////////////////////////////////////////////////
//since cocking requires more time, this function does
//exactly as the above, except it adds slightly more time
public Action:Timer_ShotgunEndCock (Handle:timer, any:hPack)
{
    ResetPack(hPack);
    new iCid = ReadPackCell(hPack);
    new iEntid = ReadPackCell(hPack);

    if (IsServerProcessing()==false
        || iCid <= 0
        || iEntid <= 0
        || IsValidEntity(iCid)==false
        || IsValidEntity(iEntid)==false
        || IsClientInGame(iCid)==false)
    {
        KillTimer(timer);
        return Plugin_Stop;
    }

    if (GetEntData(iEntid,g_iShotRelStateO)==0)
    {
        SetEntDataFloat(iEntid, g_iPlayRateO, 1.0, true);

        //new iCid=GetEntPropEnt(iEntid,Prop_Data,"m_hOwner");
        new Float:flTime= GetGameTime() + 1.0;
        SetEntDataFloat(iCid,   g_iNextAttO,    flTime, true);
        SetEntDataFloat(iEntid, g_iTimeIdleO,   flTime, true);
        SetEntDataFloat(iEntid, g_iNextPAttO,   flTime, true);

        KillTimer(timer);
        CloseHandle(hPack);
        return Plugin_Stop;
    }

    return Plugin_Continue;
}

public bool:OnIsUpgradeAvailableForWeapon(upgrade, String:sWeaponName[WEAPON_NAME_MAXLENGTH], &bool:result)
{
    if (upgrade == reload)
    {
        if(IsGunWeapon(sWeaponName))
        {
            result = true;
        }
    }
}

public OnUpgradeDescriptionRequested(upgrade, String:sWeaponName[WEAPON_NAME_MAXLENGTH], level, String:sUpgradeDescription[UPGRADE_DESCRIPTION_MAXLENGTH])
{
    if(upgrade == reload)
    {
        Format(sUpgradeDescription, UPGRADE_DESCRIPTION_MAXLENGTH, "You reload your gun faster");
    }
}

public OnUpgradeNameRequested(upgrade, String:sWeaponName[WEAPON_NAME_MAXLENGTH], String:sUpgradeName[UPGRADE_NAME_MAXLENGTH])
{
    if(upgrade == reload)
    {
        Format(sUpgradeName, UPGRADE_NAME_MAXLENGTH, "Faster Reload");
    }
}

public OnUpgradeMaxLevelRequested(upgrade, String:sWeaponName[WEAPON_NAME_MAXLENGTH], &maxlevel)
{
    if(upgrade == reload)
    {
        maxlevel = MAX_LEVEL;
    }
}

public OnUpgradeExperienceRequiredRequested(upgrade, String:sWeaponName[WEAPON_NAME_MAXLENGTH], level, &experience)
{
    if(upgrade == reload)
    {
        experience = level * 10000;
        
        if (IsTierTwoWeapon(sWeaponName))
        {
            experience *= 2;
        }
    }
}