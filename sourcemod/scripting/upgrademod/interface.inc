/**
 * File: interface.inc
 * Description: The big interface
 * Author(s): Glider
 */
#pragma semicolon 1

#include <sourcemod>
#include <sdkhooks>
#include <sdktools>
#include <regex>

#include <sceneprocessor>
#include <colors>

#include "upgrademod/constants"
#include "upgrademod/guns"
#include "upgrademod/forwards"
#include "upgrademod/logging"
#include "upgrademod/upgrades"
#include "upgrademod/player"
#include "upgrademod/l4d"
#include "upgrademod/effects"

/** 
 * Prints a message in the chat area with [Upgrademod] pre-appended.
 * Check morecolors.inc for the supported tags.
 * The text is ran through Upgrademod_FormatText before being printed.
 * 
 * @param client      Client index, pass 0 for message to all.
 * @param szMessage   Message (formatting rules).
 * @return            No return
 */
stock Upgrade_ChatMessage(client, const String:szMessage[], any:...)
{
    if (client == 0)
    {
        decl String:szBuffer[MAX_MESSAGE_LENGTH];
        for (new i = 1; i <= MaxClients; i++)
        {
            if (IsClientInGame(i) && !IsFakeClient(i))
            {
                VFormat(szBuffer, sizeof(szBuffer), szMessage, 3);
                Upgrademod_FormatText(szBuffer);
                Format(szBuffer, sizeof(szBuffer), "{olive}[Upgrademod] {blue}%s", szBuffer);
                CPrintToChat(i, szBuffer);
            }
        }
    }
    else
    {
        decl String:szBuffer[MAX_MESSAGE_LENGTH];
        VFormat(szBuffer, sizeof(szBuffer), szMessage, 3);
        Upgrademod_FormatText(szBuffer);
        Format(szBuffer, sizeof(szBuffer), "{olive}[Upgrademod] {blue}%s", szBuffer);
        CPrintToChat(client, szBuffer);
    }
}

stock bool:IsValidPlayer(client, bool:bIsAlive=false) 
{
    if(client > 0 && client <= MaxClients && IsClientConnected(client) && IsClientInGame(client))
    {
        if(bIsAlive && !IsPlayerAlive(client))
        {
            return false;
        }

        return true;
    }
    
    return false;
}

stock GetPrimaryWeaponName(client, String:sWeaponName[WEAPON_NAME_MAXLENGTH])
{
    new iPrimaryWeapon = GetPlayerWeaponSlot(client, 0);
    if (IsValidEdict(iPrimaryWeapon))
    {
        GetEdictClassname(iPrimaryWeapon, sWeaponName, sizeof(sWeaponName));
    }
}

stock GetEntityHP(entity)
{
    return GetEntProp(entity, Prop_Data, "m_iHealth");
}

stock CheatCommand(client, String:command[], String:arguments[]="")
{
    new userflags = GetUserFlagBits(client);
    SetUserFlagBits(client, ADMFLAG_ROOT);
    new flags = GetCommandFlags(command);
    SetCommandFlags(command, flags & ~FCVAR_CHEAT);
    FakeClientCommand(client, "%s %s", command, arguments);
    SetCommandFlags(command, flags);
    SetUserFlagBits(client, userflags);
}

stock bool:CanBeUpgraded(const String:weaponName[])
{
    return (StrEqual(weaponName, "weapon_rifle", false) || 
            StrEqual(weaponName, "weapon_rifle_ak47", false) || 
            StrEqual(weaponName, "weapon_rifle_desert", false) || 
            StrEqual(weaponName, "weapon_rifle_sg552", false) || 
            StrEqual(weaponName, "weapon_smg", false) || 
            StrEqual(weaponName, "weapon_smg_silenced", false) || 
            StrEqual(weaponName, "weapon_smg_mp5", false) || 
            StrEqual(weaponName, "weapon_pumpshotgun", false) || 
            StrEqual(weaponName, "weapon_shotgun_chrome", false) || 
            StrEqual(weaponName, "weapon_autoshotgun", false) || 
            StrEqual(weaponName, "weapon_shotgun_spas", false) || 
            StrEqual(weaponName, "weapon_hunting_rifle", false) || 
            StrEqual(weaponName, "weapon_sniper_military", false) || 
            StrEqual(weaponName, "weapon_sniper_awp", false) || 
            StrEqual(weaponName, "weapon_sniper_scout", false) || 
            StrEqual(weaponName, "weapon_grenade_launcher", false) || 
            StrEqual(weaponName, "weapon_rifle_m60", false) ||
            StrEqual(weaponName, "weapon_melee", false) ||
            StrEqual(weaponName, "weapon_chainsaw", false) ||
            StrEqual(weaponName, "weapon_pistol", false) ||
            StrEqual(weaponName, "weapon_pistol_magnum", false) ||
            StrEqual(weaponName, "weapon_pipe_bomb", false) ||
            StrEqual(weaponName, "weapon_molotov", false) ||
            StrEqual(weaponName, "weapon_dual_pistols", false) ||
            StrEqual(weaponName, "weapon_first_aid_kit", false) ||
            StrEqual(weaponName, "weapon_defibrillator", false) ||
            StrEqual(weaponName, "weapon_pain_pills", false) ||
            StrEqual(weaponName, "weapon_upgradepack_explosive", false) ||
            StrEqual(weaponName, "weapon_vomitjar", false) ||
            StrEqual(weaponName, "weapon_adrenaline", false) ||
            StrEqual(weaponName, "weapon_upgradepack_incendiary", false));
}