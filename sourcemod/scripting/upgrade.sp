#include "upgrademod/interface"

public Plugin:myinfo = 
{
    name = "Upgrademod - Engine - Upgrades",
    author = "Glider",
};

// This is an array that contains a adt_array
// the adt_array can be indexed with an upgrade index
// there you'll find a trie that contains the weapons and their
// levels for this particular upgrade
new Handle:hPlayerUpgrades[MAXPLAYERS];

// This is an array that contains a adt_array
// The adt_array can be indexed with an upgrade index
// There you'll find another adt_array that contains a list
// of weaponNames that were modified
new Handle:hModifiedUpgrades[MAXPLAYERS];

new Handle:hUpgradeArray;

new Handle:hUpgradeAvailableForWeapon;
new Handle:hRequestUpgradeDescription;
new Handle:hRequestUpgradeName;
new Handle:hRequestUpgradeMaxLevel;
new Handle:hRequestedUpgradeExperienceRequired;

public APLRes:AskPluginLoad2(Handle:myself, bool:late, String:error[], err_max)
{
    CreateNative("RegisterUpgrade", Native_RegisterUpgrade);
    CreateNative("GetUpgradeShortname", Native_GetUpgradeShortname);
    CreateNative("GetUpgradeIndex", Native_GetUpgradeIndex);
    
    CreateNative("GetAmountOfUpgrades", Native_GetAmountOfUpgrades);
    CreateNative("WeaponHasUpgrades", Native_WeaponHasUpgrades);

    CreateNative("GetUpgradeName", Native_GetUpgradeName);
    CreateNative("GetUpgradeDescription", Native_GetUpgradeDescription);
    CreateNative("GetUpgradeMaxLevel", Native_GetUpgradeMaxLevel);
    CreateNative("GetUpgradeExperienceRequired", Native_GetUpgradeExperienceRequired);
    
    CreateNative("IsUpgradeAvailableForWeapon", Native_IsUpgradeAvailableForWeapon);
    
    CreateNative("SetUpgradeLevel", Native_SetUpgradeLevel);
    CreateNative("GetUpgradeLevel", Native_GetUpgradeLevel);

    CreateNative("GetModifiedUpgradeArray", Native_GetModifiedUpgradeArray);
    CreateNative("ClearModifiedUpgradeArray", Native_ClearModifiedUpgradeArray);
    
    hUpgradeAvailableForWeapon = CreateGlobalForward("OnIsUpgradeAvailableForWeapon", ET_Ignore, Param_Cell, Param_String, Param_CellByRef);
    hRequestUpgradeDescription = CreateGlobalForward("OnUpgradeDescriptionRequested", ET_Ignore, Param_Cell, Param_String, Param_Cell, Param_String);
    hRequestUpgradeName = CreateGlobalForward("OnUpgradeNameRequested", ET_Ignore, Param_Cell, Param_String, Param_String);
    hRequestUpgradeMaxLevel = CreateGlobalForward("OnUpgradeMaxLevelRequested", ET_Ignore, Param_Cell, Param_String, Param_CellByRef);
    hRequestedUpgradeExperienceRequired = CreateGlobalForward("OnUpgradeExperienceRequiredRequested", ET_Ignore, Param_Cell, Param_String, Param_Cell, Param_CellByRef);
    
    return APLRes_Success;
}

public OnPluginStart()
{
    hUpgradeArray = CreateArray(UPGRADE_SHORTNAME_MAXLENGTH);
    
    for(new client=0; client < MAXPLAYERS; client++)
    {
        hPlayerUpgrades[client] = CreateArray(1);
        hModifiedUpgrades[client] = CreateArray(1);
    }
}

public OnClientDisconnect(client)
{
    ResetUpgradeStruct(client);
}

ResetUpgradeStruct(client)
{
    // This might leak memory because we don't touch the trie
    new Handle:hUpgrades = hPlayerUpgrades[client];
    ClearArray(hUpgrades);
    
    // Maybe not necessary because we overwrite when the player connects anyway?
    for(new upgrade=0; upgrade < Internal_GetAmountOfUpgrades(); upgrade++)
    {
        new Handle:hUpgradeTrie = CreateTrie();
        PushArrayCell(hUpgrades, hUpgradeTrie);
    }
}
 
public Native_RegisterUpgrade(Handle:plugin, numParams)
{
    decl String:sUpgradeShortname[UPGRADE_SHORTNAME_MAXLENGTH];
    if(GetNativeString(1, sUpgradeShortname, sizeof(sUpgradeShortname)) != SP_ERROR_NONE)
    {
        Upgrademod_LogCritical("Could not register upgrade!!");
        return -1;
    }
    
    return Internal_RegisterUpgrade(sUpgradeShortname);
}

Internal_RegisterUpgrade(String:sUpgradeShortname[UPGRADE_SHORTNAME_MAXLENGTH])
{
    new index = FindStringInArray(hUpgradeArray, sUpgradeShortname);
    
    if (index == -1)
    {
        Upgrademod_LogInfo("Registered new upgrade: \"%s\"", sUpgradeShortname);
        index = PushArrayString(hUpgradeArray, sUpgradeShortname);
        
        for(new client=0; client < MAXPLAYERS; client++)
        {
            new Handle:hPlayerUpgradeArray = hPlayerUpgrades[client];
            new Handle:hUpgradeTrie = CreateTrie();
            PushArrayCell(hPlayerUpgradeArray, hUpgradeTrie);

            new Handle:hModifications = hModifiedUpgrades[client];
            new Handle:hUpgradeNames = CreateArray(WEAPON_NAME_MAXLENGTH);
            PushArrayCell(hModifications, hUpgradeNames);
        }
        
        return index;
    }
    
    Upgrademod_LogWarning("Tried to register known upgrade: \"%s\" - duplicate shortname?", sUpgradeShortname);
    return index;
}

public Native_GetUpgradeShortname(Handle:plugin, numParams)
{
    new index = GetNativeCell(1);
    
    decl String:sUpgradeShortname[UPGRADE_SHORTNAME_MAXLENGTH];
    GetArrayString(hUpgradeArray, index, sUpgradeShortname, sizeof(sUpgradeShortname));
    
    SetNativeString(2, sUpgradeShortname, sizeof(sUpgradeShortname));
}

public Native_GetUpgradeIndex(Handle:plugin, numParams)
{
    decl String:sUpgradeShortname[UPGRADE_SHORTNAME_MAXLENGTH];
    GetNativeString(1, sUpgradeShortname, sizeof(sUpgradeShortname));
    
    return FindStringInArray(hUpgradeArray, sUpgradeShortname);
}

public Native_GetAmountOfUpgrades(Handle:plugin, numParams)
{
    return Internal_GetAmountOfUpgrades();
}

public Native_WeaponHasUpgrades(Handle:plugin, numParams)
{
    decl String:sWeaponName[WEAPON_NAME_MAXLENGTH];
    GetNativeString(1, sWeaponName, sizeof(sWeaponName));
    
    for(new upgrade; upgrade < Internal_GetAmountOfUpgrades(); upgrade++)
    {
        if(IsUpgradeAvailableForWeapon(upgrade, sWeaponName))
        {
            return true;
        }
    }
    
    return false;
}

Internal_GetAmountOfUpgrades()
{
    return GetArraySize(hUpgradeArray);
}

public Native_IsUpgradeAvailableForWeapon(Handle:plugin, numParams)
{
    new upgrade = GetNativeCell(1);
    decl String:sWeaponName[WEAPON_NAME_MAXLENGTH];
    if(GetNativeString(2, sWeaponName, sizeof(sWeaponName)) != SP_ERROR_NONE)
    {
        return false;
    }
    
    new bool:result;

    Call_StartForward(hUpgradeAvailableForWeapon);
    Call_PushCell(upgrade);
    Call_PushString(sWeaponName);
    Call_PushCellRef(result);
    Call_Finish();
    
    return result;
}


public Native_GetUpgradeName(Handle:plugin, numParams)
{
    new upgrade = GetNativeCell(1);
    decl String:sWeaponName[WEAPON_NAME_MAXLENGTH];
    if(GetNativeString(2, sWeaponName, sizeof(sWeaponName)) != SP_ERROR_NONE)
    {
        return false;
    }
    
    new String:sName[UPGRADE_NAME_MAXLENGTH];
   
    Call_StartForward(hRequestUpgradeName);
    Call_PushCell(upgrade);
    Call_PushString(sWeaponName);
    Call_PushStringEx(sName, UPGRADE_NAME_MAXLENGTH, SM_PARAM_STRING_COPY, SM_PARAM_COPYBACK);
    Call_Finish();
    
    // Nobody handled the requirement
    if(StrEqual(sName, ""))
    {
        strcopy(sName, UPGRADE_NAME_MAXLENGTH, "THIS SHOULD NOT HAPPEN, FUCKING LAZY DEVELOPERS >:(");
    }
    
    SetNativeString(3, sName, UPGRADE_NAME_MAXLENGTH);
    
    return true;
}


public Native_GetUpgradeDescription(Handle:plugin, numParams)
{
    new upgrade = GetNativeCell(1);
    decl String:sWeaponName[WEAPON_NAME_MAXLENGTH];
    if(GetNativeString(2, sWeaponName, sizeof(sWeaponName)) != SP_ERROR_NONE)
    {
        return false;
    }
    new level = GetNativeCell(3);
    
    new String:sDescription[UPGRADE_DESCRIPTION_MAXLENGTH];
   
    Call_StartForward(hRequestUpgradeDescription);
    Call_PushCell(upgrade);
    Call_PushString(sWeaponName);
    Call_PushCell(level);
    Call_PushStringEx(sDescription, UPGRADE_DESCRIPTION_MAXLENGTH, SM_PARAM_STRING_COPY, SM_PARAM_COPYBACK);
    Call_Finish();
    
    // Nobody handled the requirement
    if(StrEqual(sDescription, ""))
    {
        strcopy(sDescription, UPGRADE_DESCRIPTION_MAXLENGTH, "THIS SHOULD NOT HAPPEN, FUCKING LAZY DEVELOPERS >:(");
    }
    
    SetNativeString(4, sDescription, UPGRADE_DESCRIPTION_MAXLENGTH);
    
    return true;
}

public Native_GetUpgradeMaxLevel(Handle:plugin, numParams)
{
    new upgrade = GetNativeCell(1);
    decl String:sWeaponName[WEAPON_NAME_MAXLENGTH];
    if(GetNativeString(2, sWeaponName, sizeof(sWeaponName)) != SP_ERROR_NONE)
    {
        return false;
    }
    
    new result;

    Call_StartForward(hRequestUpgradeMaxLevel);
    Call_PushCell(upgrade);
    Call_PushString(sWeaponName);
    Call_PushCellRef(result);
    Call_Finish();
    
    return result;
}

public Native_GetUpgradeExperienceRequired(Handle:plugin, numParams)
{
    new upgrade = GetNativeCell(1);
    decl String:sWeaponName[WEAPON_NAME_MAXLENGTH];
    if(GetNativeString(2, sWeaponName, sizeof(sWeaponName)) != SP_ERROR_NONE)
    {
        return false;
    }
    new level = GetNativeCell(3);
    
    new result;

    Call_StartForward(hRequestedUpgradeExperienceRequired);
    Call_PushCell(upgrade);
    Call_PushString(sWeaponName);
    Call_PushCell(level);
    Call_PushCellRef(result);
    Call_Finish();
    
    return result;
}

public Native_GetUpgradeLevel(Handle:plugin, numParams)
{
    new client = GetNativeCell(1);
    new upgrade = GetNativeCell(2);
    
    decl String:sWeaponName[WEAPON_NAME_MAXLENGTH];
    GetNativeString(3, sWeaponName, sizeof(sWeaponName));

    new Handle:hPlayerUpgradeArray = hPlayerUpgrades[client];
    new Handle:hUpgradeTrie = GetArrayCell(hPlayerUpgradeArray, upgrade);
    
    new level;
    
    if (!GetTrieValue(hUpgradeTrie, sWeaponName, level))
    {
        level = 0;
    }
    
    return level;
}

public Native_SetUpgradeLevel(Handle:plugin, numParams)
{
    new client = GetNativeCell(1);
    new upgrade = GetNativeCell(2);
    
    decl String:sWeaponName[WEAPON_NAME_MAXLENGTH];
    GetNativeString(3, sWeaponName, sizeof(sWeaponName));

    new level = GetNativeCell(4);
    
    Upgrademod_LogInfo("Trying to set upgrade level for client %d - upgrade %d", client, upgrade);
    
    new Handle:hPlayerUpgradeArray = hPlayerUpgrades[client];
    new Handle:hUpgradeTrie = GetArrayCell(hPlayerUpgradeArray, upgrade);

    SetTrieValue(hUpgradeTrie, sWeaponName, level);

    // Set the flags for the database
    new Handle:hModifications = hModifiedUpgrades[client];
    new Handle:hUpgradeNames = GetArrayCell(hModifications, upgrade);

    if(FindStringInArray(hUpgradeNames, sWeaponName) == -1)
    {
        PushArrayString(hUpgradeNames, sWeaponName);
    }
}

public Native_GetModifiedUpgradeArray(Handle:plugin, numParams)
{
    new client = GetNativeCell(1);
    new Handle:hArray = hModifiedUpgrades[client];
    
    return _:hArray;
}

public Native_ClearModifiedUpgradeArray(Handle:plugin, numParams)
{
    new client = GetNativeCell(1);
    
    WipeModifiedArray(client);
}

WipeModifiedArray(client)
{
    Upgrademod_LogInfo("Wiping modifed array for \"{client %d}\"", client);
    
    new Handle:hArray = hModifiedUpgrades[client];
    ClearArray(hArray);
}