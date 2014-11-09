#include "upgrademod/interface"

public Plugin:myinfo = 
{
    name = "Upgrademod - Engine - Database",
    author = "Glider",
    description = "Connects Upgrademod to the database. Based on the War3Source DatabaseConnect Engine"
};

new Handle:hThreadedDB;
new Handle:hDBLoadedForward;
new Handle:hSaveInterval;
new bool:bPlayerDataLoaded[MAXPLAYERS];

public OnPluginStart()
{
    RegConsoleCmd("upgrademod_save", Command_Save);
    hSaveInterval = CreateConVar("upgrademod_savetimer", "60");
    
    CreateTimer(GetConVarFloat(hSaveInterval), AutosaveExperience);
}

public Action:Command_Save(client, args)
{
    SaveEverythingForClient(client);

    return Plugin_Handled;  
}

public Action:AutosaveExperience(Handle:timer, any:data)
{
    SaveEverything();
    
    CreateTimer(GetConVarFloat(hSaveInterval), AutosaveExperience);
}

public APLRes:AskPluginLoad2(Handle:myself, bool:late, String:error[], err_max)
{
    hDBLoadedForward = CreateGlobalForward("OnUpgrademodDatabaseLoaded", ET_Ignore, Param_Cell);

    return APLRes_Success;
}

public OnAllPluginsLoaded()
{
    SQL_TConnect(ConnectThreadedDatabase);
}

public ConnectThreadedDatabase(Handle:owner, Handle:hndl, const String:error[], any:data)
{
    if (hndl == INVALID_HANDLE)
    {
        Upgrademod_LogCritical("Database failure: %s", error);
    } 
    else 
    {
        hThreadedDB = hndl;

        decl String:sDBMS[64];
        SQL_ReadDriver(hThreadedDB, sDBMS, sizeof(sDBMS));
        if (!StrEqual(sDBMS, "sqlite", false))
        {
            SetFailState("Only sqlite is supported");
        }

        Upgrademod_LogInfo("Established connection to %s database", sDBMS);

        SQL_LockDatabase(hThreadedDB);
        SQL_FastQuery(hThreadedDB, "SET NAMES \"UTF8\""); 
        SQL_UnlockDatabase(hThreadedDB);
        
        Initialize_SQLTables();
        
        Call_StartForward(hDBLoadedForward);
        Call_PushCell(hThreadedDB);
        Call_Finish();
    }
}

InitializePlayerTable()
{
    if(!SQL_FastQuery(hThreadedDB, "SELECT * from upgrademod_player LIMIT 1"))
    {
        new String:createtable[3000];
        Format(createtable, sizeof(createtable), "CREATE TABLE upgrademod_player (steamid varchar(64) PRIMARY KEY, name varchar(64), last_seen int)");
        if(!SQL_FastQuery(hThreadedDB, createtable))
        {
            Upgrademod_LogCritical("Could not create upgrademod_player table!");
            Upgrademod_LogCritical("Query: %s", createtable);
        }
    }
}


InitializeUpgradesTable()
{
    if(!SQL_FastQuery(hThreadedDB, "SELECT * from upgrademod_upgrade LIMIT 1"))
    {
        new String:createtable[3000];
        Format(createtable, sizeof(createtable), "CREATE TABLE upgrademod_upgrade(steamid varchar(64), weapon varchar(%d), upgrade varchar(%d), level int, \
                                                  PRIMARY KEY(steamid, weapon, upgrade), \
                                                  FOREIGN KEY(steamid) REFERENCES upgrademod_player (steamid))", WEAPON_NAME_MAXLENGTH, UPGRADE_SHORTNAME_MAXLENGTH);
        if(!SQL_FastQuery(hThreadedDB, createtable))
        {
            Upgrademod_LogCritical("Could not create upgrademod_upgrade table!");
            Upgrademod_LogCritical("Query: %s", createtable);
        }
    }
}


InitializeExperienceTable()
{
    if(!SQL_FastQuery(hThreadedDB, "SELECT * from upgrademod_experience LIMIT 1"))
    {
        new String:createtable[3000];
        Format(createtable, sizeof(createtable), "CREATE TABLE upgrademod_experience(steamid varchar(64), weapon varchar(%d), experience int, \
                                                  FOREIGN KEY(steamid) REFERENCES upgrademod_player (steamid))", WEAPON_NAME_MAXLENGTH);
        if(!SQL_FastQuery(hThreadedDB, createtable))
        {
            Upgrademod_LogCritical("Could not create upgrademod_experience table!");
            Upgrademod_LogCritical("Query: %s", createtable);
        }
    }
}

CreateIndexes()
{
    if(!SQL_FastQuery(hThreadedDB, "CREATE UNIQUE INDEX upgrademod_player_index ON upgrademod_player (steamid)"))
    {
        Upgrademod_LogWarning("Could not create upgrademod_player_index");
    }
    if(!SQL_FastQuery(hThreadedDB, "CREATE INDEX upgrademod_upgrade_index ON upgrademod_upgrade (steamid)"))
    {
        Upgrademod_LogWarning("Could not create upgrademod_upgrade_index");
    }
    if(!SQL_FastQuery(hThreadedDB, "CREATE UNIQUE INDEX upgrademod_experience_index ON upgrademod_experience (steamid, weapon)"))
    {
        Upgrademod_LogWarning("Could not create upgrademod_experience_index");
    }
}

Initialize_SQLTables()
{
    
    if(hThreadedDB != INVALID_HANDLE)
    {
        Upgrademod_LogInfo("Locking Database to initialize Database tables");
        SQL_LockDatabase(hThreadedDB);
        
        InitializePlayerTable();
        InitializeExperienceTable();
        InitializeUpgradesTable();
        CreateIndexes();

        SQL_UnlockDatabase(hThreadedDB);
        
        Upgrademod_LogInfo("Initialized Database");
    }
}

public OnClientDisconnect(client)
{
    SaveEverythingForClient(client);
    bPlayerDataLoaded[client] = false;
}

SaveEverything()
{
    for(new client=1; client <= MaxClients; client++)
    {
        if(IsValidPlayer(client) && !IsFakeClient(client))
        {
            SaveEverythingForClient(client);
        }
    }
}

SaveEverythingForClient(client)
{
    if(!IsValidPlayer(client) || IsFakeClient(client))
    {
        return;
    }
    
    if (bPlayerDataLoaded[client])
    {
        SavePlayerData(client);
        SavePlayerWeaponExperienceData(client);
        SavePlayerWeaponUpgrades(client);
    }
    else
    {
        Upgrademod_LogWarning("Refusing to save data for unloaded player!");
    }
}

SavePlayerData(client)
{
    decl String:sSteamId[64];
    decl String:sName[64];
    decl String:sEscapedName[64 * 2 + 1];

    if(!GetClientAuthString(client, sSteamId, sizeof(sSteamId)) || !GetClientName(client, sName, sizeof(sName)) || IsFakeClient(client))
    {   
        return;
    }

    SQL_EscapeString(hThreadedDB, sName, sEscapedName, sizeof(sEscapedName));
    
    decl String:query[1000];
    Format(query, sizeof(query), "INSERT OR REPLACE INTO upgrademod_player (steamid, name, last_seen) VALUES ('%s', '%s', %d)", sSteamId, sEscapedName, GetTime());
    
    SQL_TQuery(hThreadedDB, T_GenericQuery, query);
}

SavePlayerWeaponExperienceData(client)
{
    decl String:steamid[64];

    if(!GetClientAuthString(client, steamid, sizeof(steamid)) || IsFakeClient(client))
    {   
        return;
    }
    
    new Handle:hModifiedWeapons = GetModifiedWeaponExperienceArray(client);    
    decl String:sWeapon[WEAPON_NAME_MAXLENGTH];
    
    //Upgrademod_LogInfo("Doing optimized weapon experience for client \"{client %d}\" - %d updates!", client, GetArraySize(hModifiedWeapons));
    while(GetArraySize(hModifiedWeapons) > 0)
    {
        GetArrayString(hModifiedWeapons, 0, sWeapon, sizeof(sWeapon));
        RemoveFromArray(hModifiedWeapons, 0);
        
        InsertOrUpdateWeaponExperience(client, sWeapon);
    }
}

SavePlayerWeaponUpgrades(client)
{
    decl String:steamid[64];

    if(!GetClientAuthString(client, steamid, sizeof(steamid)) || IsFakeClient(client))
    {   
        return;
    }
    
    decl String:sWeapon[WEAPON_NAME_MAXLENGTH];
    new level;

    new Handle:hModifiedUpgrades = GetModifiedUpgradeArray(client);
    new Handle:hWeaponNames = INVALID_HANDLE;
    for (new upgrade=0; upgrade < GetAmountOfUpgrades(); upgrade++)
    {
        hWeaponNames = GetArrayCell(hModifiedUpgrades, upgrade);
        
        //Upgrademod_LogInfo("Doing optimized weapon upgrades for client \"{client %d}\" - %d updates!", client, GetArraySize(hWeaponNames));
        while(GetArraySize(hWeaponNames) > 0)
        {
            GetArrayString(hWeaponNames, 0, sWeapon, sizeof(sWeapon));
            RemoveFromArray(hWeaponNames, 0);
            
            level = GetUpgradeLevel(client, upgrade, sWeapon);
            if (level > 0)
            {
                UpdateOrInsertPlayerWeaponUpgrade(client, upgrade, sWeapon, level);
            }
        }
    }
}

UpdateOrInsertPlayerWeaponUpgrade(client, upgrade, String:sWeaponName[WEAPON_NAME_MAXLENGTH], level)
{
    decl String:steamid[64];
    GetClientAuthString(client, steamid, sizeof(steamid));
    
    decl String:sUpgradeShortname[UPGRADE_SHORTNAME_MAXLENGTH];
    GetUpgradeShortname(upgrade, sUpgradeShortname);
    
    decl String:query[1000];
    Format(query, sizeof(query), "INSERT OR REPLACE INTO upgrademod_upgrade (steamid, weapon, upgrade, level) VALUES ('%s', '%s', '%s', %d)", steamid, sWeaponName, sUpgradeShortname, level);
    
    SQL_TQuery(hThreadedDB, T_GenericQuery, query);
}

InsertOrUpdateWeaponExperience(client, String:sWeaponName[WEAPON_NAME_MAXLENGTH])
{
    decl String:steamid[64];
    GetClientAuthString(client, steamid, sizeof(steamid));
    
    new value = GetWeaponExperience(client, sWeaponName);
    
    decl String:query[1000];
    Format(query, sizeof(query), "INSERT OR REPLACE INTO upgrademod_experience (steamid, weapon, experience) VALUES ('%s', '%s', %d)", steamid, sWeaponName, value);
    
    SQL_TQuery(hThreadedDB, T_GenericQuery, query);
}

public OnClientPostAdminCheck(client)
{
    // Update the last seen value
    SavePlayerData(client);
    LoadWeaponExperienceData(client);
    LoadWeaponUpgradeData(client);
}

LoadWeaponExperienceData(client)
{
    decl String:steamid[64];
    if(!GetClientAuthString(client, steamid, sizeof(steamid)) || IsFakeClient(client))
    {   
        return;
    }
    
    decl String:query[1000];
    Format(query, sizeof(query), "SELECT weapon, experience FROM upgrademod_experience WHERE steamid = '%s'", steamid);
    
    SQL_TQuery(hThreadedDB, T_LoadWeaponExperience, query, client);
}

public T_LoadWeaponExperience(Handle:owner, Handle:hndl, const String:error[], any:client)
{
    if (hndl == INVALID_HANDLE)
    {
        Upgrademod_LogError("Query failed! %s", error);
    }
    else
    {
        if (!IsValidPlayer(client) || IsFakeClient(client))
        {
            Upgrademod_LogError("Fetched experience for a wrong client!?");
        }
        else
        {
            decl String:sWeaponName[WEAPON_NAME_MAXLENGTH];
            new experience;
            
            while (SQL_FetchRow(hndl))
            {
                SQL_FetchString(hndl, 0, sWeaponName, sizeof(sWeaponName));
                experience = SQL_FetchInt(hndl, 1);
                
                SetWeaponExperience(client, sWeaponName, experience, false);
            }
        }
    }
}

LoadWeaponUpgradeData(client)
{
    decl String:steamid[64];
    if(!GetClientAuthString(client, steamid, sizeof(steamid)) || IsFakeClient(client))
    {   
        return;
    }
    
    decl String:query[1000];
    Format(query, sizeof(query), "SELECT weapon, upgrade, level FROM upgrademod_upgrade WHERE steamid = '%s'", steamid);
    
    SQL_TQuery(hThreadedDB, T_LoadWeaponUpgrade, query, client);
}

public T_LoadWeaponUpgrade(Handle:owner, Handle:hndl, const String:error[], any:client)
{
    if (hndl == INVALID_HANDLE)
    {
        Upgrademod_LogError("Query failed! %s", error);
    }
    else
    {
        if (!IsValidPlayer(client) || IsFakeClient(client))
        {
            Upgrademod_LogError("Fetched experience for a wrong client!?");
        }
        else
        {
            decl String:sWeaponName[WEAPON_NAME_MAXLENGTH];
            decl String:sUpgradeShortname[UPGRADE_SHORTNAME_MAXLENGTH];
            new level;
            
            while (SQL_FetchRow(hndl))
            {
                SQL_FetchString(hndl, 0, sWeaponName, sizeof(sWeaponName));
                SQL_FetchString(hndl, 1, sUpgradeShortname, sizeof(sUpgradeShortname));
                level = SQL_FetchInt(hndl, 2);
                
                SetUpgradeLevel(client, GetUpgradeIndex(sUpgradeShortname), sWeaponName, level);
            }
            
            bPlayerDataLoaded[client] = true;
        }
    }
}

public T_GenericQuery(Handle:owner, Handle:hndl, const String:error[], any:data)
{
    if (hndl == INVALID_HANDLE)
    {
        Upgrademod_LogError("Query failed! %s", error);
    }
}