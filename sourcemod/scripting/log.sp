#include "upgrademod/interface"

public Plugin:myinfo = 
{
    name = "Upgrademod - Engine - Logging",
    author = "Glider",
    description = "A logging engine, based on the War3Source Logging engine"
};

enum LogSeverity
{
    SEVERITY_CRITICAL,
    SEVERITY_ERROR,
    SEVERITY_WARNING,
    SEVERITY_INFO
};

new LogLevel:iLogLevel;
new iPrintToConsole;

new Handle:g_hLogLevel = INVALID_HANDLE;
new Handle:g_hPrintToServer = INVALID_HANDLE;
new Handle:hUpgrademodLog = INVALID_HANDLE;

public OnPluginStart()
{
    g_hLogLevel = CreateConVar("upgrademod_log_level", "4", "Set the log level for Upgrademod", FCVAR_PLUGIN, true, 0.0, true, 4.0);
    g_hPrintToServer = CreateConVar("upgrademod_print_to_server", "1", "Toggle logging to the server console. Note that critical errors are always printed to the console", FCVAR_PLUGIN, true, 0.0, true, 1.0);
    
    iLogLevel = LogLevel:GetConVarInt(g_hLogLevel);
    HookConVarChange(g_hLogLevel, ConVarChange_LogLevel);
    
    iPrintToConsole = GetConVarInt(g_hPrintToServer);
    HookConVarChange(g_hPrintToServer, ConVarChange_PrintToServer);
}

public ConVarChange_LogLevel(Handle:convar, const String:oldValue[], const String:newValue[])
{
    iLogLevel = LogLevel:StringToInt(newValue);
}

public ConVarChange_PrintToServer(Handle:convar, const String:oldValue[], const String:newValue[])
{
    iPrintToConsole = StringToInt(newValue);
}

public Native_GetLogLevel(Handle:plugin, numParams)
{
    return _:iLogLevel;
}

public APLRes:AskPluginLoad2(Handle:myself, bool:late, String:error[], err_max)
{
    new String:sLogPath[1024];
    
    decl String:sLogfilePath[64];
    decl String:sDate[32];
    FormatTime(sDate, sizeof(sDate), "%Y%m%d");
    Format(sLogfilePath, sizeof(sLogfilePath), "logs/upgrademod_%s.log", sDate);
    
    BuildPath(Path_SM, sLogPath, sizeof(sLogPath), sLogfilePath);
    hUpgrademodLog = OpenFile(sLogPath, "a+");
    
    CreateNative("Upgrademod_LogInfo", Native_Upgrademod_LogInfo);
    CreateNative("Upgrademod_LogWarning", Native_Upgrademod_LogWarning);
    CreateNative("Upgrademod_LogError", Native_Upgrademod_LogError);
    CreateNative("Upgrademod_LogCritical", Native_Upgrademod_LogCritical);
    CreateNative("GetLogLevel", Native_GetLogLevel);

    return APLRes_Success;
}

LogGeneric(String:sMessage[], Handle:hSourcePlugin, LogSeverity:logSeverity)
{
    if(hUpgrademodLog != INVALID_HANDLE)
    {
        Upgrademod_FormatText(sMessage);
        
        decl String:sOutput[MAX_MESSAGE_LENGTH];
        decl String:sFileName[256];
        decl String:sDate[32];
        
        FormatTime(sDate, sizeof(sDate), "%c");
        GetPluginFilename(hSourcePlugin, sFileName, sizeof(sFileName)); 
        Format(sOutput, sizeof(sOutput), "[%s] <%s>: %s", sDate, sFileName, sMessage);
        
        switch (logSeverity)
        {
            case SEVERITY_CRITICAL:
            {
                Format(sOutput, sizeof(sOutput), "CRITICAL: %s", sOutput);
            }
            case SEVERITY_ERROR:
            {
                Format(sOutput, sizeof(sOutput), "ERROR: %s", sOutput);
            }
            case SEVERITY_WARNING:
            {
                Format(sOutput, sizeof(sOutput), "WARNING: %s", sOutput);
            }
            case SEVERITY_INFO:
            {
                Format(sOutput, sizeof(sOutput), "INFO: %s", sOutput);
            }
        }
        
        WriteFileLine(hUpgrademodLog, sOutput);
        FlushFile(hUpgrademodLog);
        
        if(iPrintToConsole || logSeverity == SEVERITY_CRITICAL)
        {
            PrintToServer(sOutput);
        }
    }
}

public Native_Upgrademod_LogCritical(Handle:plugin, numParams)
{
    if(iLogLevel >= LOG_LEVEL_CRITICAL)
    {
        decl String:sMessage[MAX_MESSAGE_LENGTH];
        FormatNativeString(0, 1, 2, sizeof(sMessage), _, sMessage);
        
        LogGeneric(sMessage, plugin, SEVERITY_CRITICAL);
    }
}

public Native_Upgrademod_LogError(Handle:plugin, numParams)
{
    if(iLogLevel >= LOG_LEVEL_ERROR)
    {
        decl String:sMessage[MAX_MESSAGE_LENGTH];
        FormatNativeString(0, 1, 2, sizeof(sMessage), _, sMessage);
        
        LogGeneric(sMessage, plugin, SEVERITY_ERROR);
    }
}

public Native_Upgrademod_LogWarning(Handle:plugin, numParams)
{
    if(iLogLevel >= LOG_LEVEL_WARNING)
    {
        decl String:sMessage[MAX_MESSAGE_LENGTH];
        FormatNativeString(0, 1, 2, sizeof(sMessage), _, sMessage);
        
        LogGeneric(sMessage, plugin, SEVERITY_WARNING);
    }
}

public Native_Upgrademod_LogInfo(Handle:plugin, numParams)
{
    if(iLogLevel >= LOG_LEVEL_INFO)
    {
        decl String:sMessage[MAX_MESSAGE_LENGTH];
        FormatNativeString(0, 1, 2, sizeof(sMessage), _, sMessage);
        
        LogGeneric(sMessage, plugin, SEVERITY_INFO);
    }
}