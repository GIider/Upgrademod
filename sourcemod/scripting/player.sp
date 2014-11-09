#include "upgrademod/interface"

public Plugin:myinfo = 
{
    name = "Upgrademod - Engine - Player",
    author = "Glider",
    description = "The player class for the upgrademod"
};

// Array of tries that contain the experience for each weapon
new Handle:hWeaponExperienceTrie[MAXPLAYERS] = INVALID_HANDLE; 

// Array that contains every weapon that was modified since the last clear
new Handle:hModifiedWeapons[MAXPLAYERS] = INVALID_HANDLE;

public OnPluginStart()
{
    for (new i=0; i < MAXPLAYERS; i++)
    {
        hWeaponExperienceTrie[i] = GetWeaponTrie();
        hModifiedWeapons[i] = CreateArray(WEAPON_NAME_MAXLENGTH);
    }
}

public APLRes:AskPluginLoad2(Handle:myself, bool:late, String:error[], err_max)
{
    CreateNative("GetWeaponExperience", Native_GetWeaponExperience);
    CreateNative("SetWeaponExperience", Native_SetWeaponExperience);
    CreateNative("GiveWeaponExperience", Native_GiveWeaponExperience);
    CreateNative("RemoveWeaponExperience", Native_RemoveWeaponExperience);
    
    CreateNative("GetModifiedWeaponExperienceArray", Native_GetModifiedWeaponExperienceArray);
    CreateNative("ClearModifiedWeaponExperienceArray", Native_ClearModifiedWeaponExperienceArray);
    
    return APLRes_Success;
}

Handle:GetWeaponTrie()
{
    new Handle:hWeaponTrie = CreateTrie();
    new Handle:hWeaponStack = GetUpgradeableItemStack();
    
    decl String:sWeapon[WEAPON_NAME_MAXLENGTH];
    
    while(!IsStackEmpty(hWeaponStack))
    {
        PopStackString(hWeaponStack, sWeapon, sizeof(sWeapon));
        SetTrieValue(hWeaponTrie, sWeapon, 0);
    }
    
    CloseHandle(hWeaponStack);
    
    return hWeaponTrie;
}

public Native_GetWeaponExperience(Handle:plugin, numParams)
{
    new client = GetNativeCell(1);
        
    decl String:sWeaponName[WEAPON_NAME_MAXLENGTH];
    GetNativeString(2, sWeaponName, sizeof(sWeaponName));
    
    return Internal_GetWeaponExperience(client, sWeaponName);
}

Internal_GetWeaponExperience(client, String:sWeaponName[WEAPON_NAME_MAXLENGTH])
{
    if (!IsValidPlayer(client))
    {
        Upgrademod_LogError("Tried to retrieve weapon experience for invalid client %d", client);
        return 0;
    }

    if(!CanBeUpgraded(sWeaponName))
    {
        Upgrademod_LogError("Tried to retrieve weapon experience for invalid weapon: \"%s\"!", sWeaponName);
        return 0;
    }

    new value;
    GetTrieValue(hWeaponExperienceTrie[client], sWeaponName, value);
    
    return value;
}

public Native_SetWeaponExperience(Handle:plugin, numParams)
{
    new client = GetNativeCell(1);
        
    decl String:sWeaponName[WEAPON_NAME_MAXLENGTH];
    GetNativeString(2, sWeaponName, sizeof(sWeaponName));
    
    new value = GetNativeCell(3);
    new bool:bUpdateDatabase = GetNativeCell(4);
    
    return Internal_SetWeaponExperience(client, sWeaponName, value, bUpdateDatabase);
}

bool:Internal_SetWeaponExperience(client, String:sWeaponName[WEAPON_NAME_MAXLENGTH], value, bool:bUpdateDatabase)
{
    if (!IsValidPlayer(client))
    {
        Upgrademod_LogError("Tried to set weapon experience for invalid client %d", client);
        return false;
    }

    if(!CanBeUpgraded(sWeaponName))
    {
        Upgrademod_LogError("Tried to set weapon experience for invalid weapon: \"%s\"!", sWeaponName);
        return false;
    }
    
    new bool:was_successful = SetTrieValue(hWeaponExperienceTrie[client], sWeaponName, value);
    
    if(was_successful && bUpdateDatabase)
    {
        new Handle:hArray = hModifiedWeapons[client];
        if(FindStringInArray(hArray, sWeaponName) == -1)
        {
            PushArrayString(hArray, sWeaponName);
        }
    }
    
    return was_successful;
}

public Native_GiveWeaponExperience(Handle:plugin, numParams)
{
    new client = GetNativeCell(1);
        
    decl String:sWeaponName[WEAPON_NAME_MAXLENGTH];
    GetNativeString(2, sWeaponName, sizeof(sWeaponName));
    
    new value = GetNativeCell(3);
    
    Internal_GiveWeaponExperience(client, sWeaponName, value);
}

Internal_GiveWeaponExperience(client, String:sWeaponName[WEAPON_NAME_MAXLENGTH], value)
{
    if (!IsValidPlayer(client))
    {
        Upgrademod_LogError("Tried to set weapon experience for invalid client %d", client);
        return false;
    }

    if(!CanBeUpgraded(sWeaponName))
    {
        Upgrademod_LogError("Tried to set weapon experience for invalid weapon: \"%s\"!", sWeaponName);
        return false;
    }
    
    new iOldExperience = Internal_GetWeaponExperience(client, sWeaponName);
    new iNewExperience = iOldExperience + value;
    
    return Internal_SetWeaponExperience(client, sWeaponName, iNewExperience, true);
}

public Native_RemoveWeaponExperience(Handle:plugin, numParams)
{
    new client = GetNativeCell(1);
        
    decl String:sWeaponName[WEAPON_NAME_MAXLENGTH];
    GetNativeString(2, sWeaponName, sizeof(sWeaponName));
    
    new value = GetNativeCell(3);
    
    return Internal_RemoveWeaponExperience(client, sWeaponName, value);
}

Internal_RemoveWeaponExperience(client, String:sWeaponName[WEAPON_NAME_MAXLENGTH], value)
{
    if (!IsValidPlayer(client))
    {
        Upgrademod_LogError("Tried to set weapon experience for invalid client %d", client);
        return false;
    }

    if(!CanBeUpgraded(sWeaponName))
    {
        Upgrademod_LogError("Tried to set weapon experience for invalid weapon: \"%s\"!", sWeaponName);
        return false;
    }
    
    new iOldExperience = Internal_GetWeaponExperience(client, sWeaponName);
    new iNewExperience = iOldExperience - value;
    
    if (iNewExperience < 0)
    {
        Upgrademod_LogError("Something tried setting the exp lower than 0!?");
        return false;
    }
    
    return Internal_SetWeaponExperience(client, sWeaponName, iNewExperience, true);
}

public OnClientDisconnect(client)
{
    WipeModifiedArray(client);
}

WipeModifiedArray(client)
{
    Upgrademod_LogInfo("Wiping modifed array for \"{client %d}\"", client);
    
    new Handle:hArray = hModifiedWeapons[client];
    ClearArray(hArray);
}

public Native_GetModifiedWeaponExperienceArray(Handle:plugin, numParams)
{
    new client = GetNativeCell(1);
    new Handle:hArray = hModifiedWeapons[client];
    
    return _:hArray;
}

public Native_ClearModifiedWeaponExperienceArray(Handle:plugin, numParams)
{
    new client = GetNativeCell(1);
    
    WipeModifiedArray(client);
}