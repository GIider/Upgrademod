#include "upgrademod/interface"

public Plugin:myinfo = 
{
    name = "Upgrademod - Engine - Cvar",
    author = "Glider",
    description = "Engine controlling cvars for upgrademod"
};

public APLRes:AskPluginLoad2(Handle:myself, bool:late, String:error[], err_max)
{
    CreateNative("GetUpgradeExperienceModifier", Native_GetUpgradeExperienceModifier);
    CreateNative("RegisterUpgradeExperienceModifierConVar", Native_RegisterUpgradeExperienceModifierConVar);

    return APLRes_Success;
}

public Native_GetUpgradeExperienceModifier(Handle:plugin, numParams)
{
    new upgrade = GetNativeCell(1);
    
    decl String:sUpgradeShortname[UPGRADE_SHORTNAME_MAXLENGTH];
    GetUpgradeShortname(upgrade, sUpgradeShortname);
    
    return _:Internal_GetUpgradeExperienceModifier(sUpgradeShortname);
}

Float:Internal_GetUpgradeExperienceModifier(String:sUpgradeShortname[UPGRADE_SHORTNAME_MAXLENGTH])
{
    new Handle:hCvar;
    decl String:sConVarName[CONVAR_MAXLENGTH];
    
    Format(sConVarName, sizeof(sConVarName), "upgrademod_%s_modifier", sUpgradeShortname);
    
    hCvar = FindConVar(sConVarName);
    
    if(hCvar == INVALID_HANDLE)
    {
        Upgrademod_LogError("The ConVar \"%s\" does not exist!?", sConVarName);
        return 1.0;
    }
    
    return GetConVarFloat(hCvar);
}

public Native_RegisterUpgradeExperienceModifierConVar(Handle:plugin, numParams)
{
    decl String:sUpgradeShortname[UPGRADE_SHORTNAME_MAXLENGTH];
    GetNativeString(1, sUpgradeShortname, sizeof(sUpgradeShortname));
    
    Internal_RegisterUpgradeExperienceModifierConVar(sUpgradeShortname);
}

Internal_RegisterUpgradeExperienceModifierConVar(String:sUpgradeShortname[UPGRADE_SHORTNAME_MAXLENGTH])
{
    new Handle:hCvar;
    decl String:sConVarName[CONVAR_MAXLENGTH];
    
    Format(sConVarName, sizeof(sConVarName), "upgrademod_%s_modifier", sUpgradeShortname);
    
    hCvar = FindConVar(sConVarName);
    
    if(hCvar == INVALID_HANDLE)
    {
        // TODO: Do this properly :)
        hCvar = CreateConVar(sConVarName, "1.0", "Experience modifier for a upgrade");
        if(hCvar == INVALID_HANDLE)
        {
            Upgrademod_LogError("Could not register ConVar \"%s\"", sConVarName);
        }
    }
}