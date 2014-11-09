/**
 * File: logging.inc
 * Description: Methods regarding logging
 * Author(s): Glider
 */

enum LogLevel
{
    LOG_LEVEL_OFF,
    LOG_LEVEL_CRITICAL,
    LOG_LEVEL_ERROR,
    LOG_LEVEL_WARNING,
    LOG_LEVEL_INFO 
};

/**
 * When you use logging or Upgrade_ChatMessage then certain keywords will get replaced.
 * The keywords are the following:
 * 
 * {client <clientid>} - replaced with the name of the client.
 */
native Upgrademod_FormatText(const String:fmt[], any:...);

/**
 * Log a info message. Info messages are mainly for debugging.
 */
native Upgrademod_LogInfo(const String:fmt[], any:...);

/**
 * Log a warning message. No error yet, but what's happening could lead to an error!
 */
native Upgrademod_LogWarning(const String:fmt[], any:...);

/**
 * Log a error message. Something has gone wrong, but we can still continue.
 */
native Upgrademod_LogError(const String:fmt[], any:...);

/**
 * Log a critical message. Something has gone very wrong and we're unable to handle it.
 */
native Upgrademod_LogCritical(const String:fmt[], any:...);

/**
 * Get the current log level
 */
native LogLevel:GetLogLevel();