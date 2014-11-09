#include "upgrademod/interface"

public Plugin:myinfo = 
{
    name = "Upgrademod - Engine - Text Processor",
    author = "Glider",
    description = ""
};

// Log prettifier
new Handle:hRegexClient = INVALID_HANDLE;
new Handle:hRegexID = INVALID_HANDLE;

public OnPluginStart()
{
    // Sadly sourcemod doesn't handle regex groups x_X
    if(hRegexID == INVALID_HANDLE)
    {
        hRegexID = CompileRegex("\\d+");
    }
    if(hRegexClient == INVALID_HANDLE)
    {
        hRegexClient = CompileRegex("{client (\\d+)}");
    }
}

public APLRes:AskPluginLoad2(Handle:myself, bool:late, String:error[], err_max)
{
    CreateNative("Upgrademod_FormatText", Native_Upgrademod_FormatText);
    
    return APLRes_Success;
}

ReadRawFromString(String:sInput[], maxlength, Handle:hRegex)
{
    GetRegexSubString(hRegex, 0, sInput, maxlength);

    decl String:sDummy[128];
    MatchRegex(hRegexID, sInput);
    GetRegexSubString(hRegexID, 0, sDummy, sizeof(sDummy));

    return StringToInt(sDummy);
}

MakeReadable(String:sUnreadable[], maxlength)
{
    // Replace client ids with the name
    while (MatchRegex(hRegexClient, sUnreadable) > 0)
    {
        decl String:sNameRaw[64];
        new iClientID = ReadRawFromString(sNameRaw, sizeof(sNameRaw), hRegexClient);
        
        new String:sPlayerName[FULLNAME_LENGTH];
        if (IsValidPlayer(iClientID))
        {
            GetClientName(iClientID, sPlayerName, sizeof(sPlayerName));
        }
        else
        {
            strcopy(sPlayerName, sizeof(sPlayerName), "invalidplayer");
        }

        ReplaceString(sUnreadable, maxlength, sNameRaw, sPlayerName, true);
    }
}

public Native_Upgrademod_FormatText(Handle:plugin, numParams)
{
    decl String:sMessage[MAX_MESSAGE_LENGTH];
    FormatNativeString(0, 1, 2, sizeof(sMessage), _, sMessage);
    
    MakeReadable(sMessage, sizeof(sMessage));
    
    SetNativeString(1, sMessage, sizeof(sMessage));
}
