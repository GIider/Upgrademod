#include "upgrademod/interface"

public Plugin:myinfo = 
{
    name = "Upgrademod - Engine - Menu",
    author = "Glider",
};

#define SELECTION_UPGRADE_WEAPON   1
#define SELECTION_CANCEL           2
#define SELECTION_DEBUG            3
#define SELECTION_BROWSE           4

#define SELECTION_BUY_UPGRADE      1
#define SELECTION_REFUND_UPGRADE   2
#define SELECTION_RETURN           3
#define SELECTION_CANCEL_UPGRADE   4

new String:sWeaponNameArray[MAXPLAYERS][WEAPON_NAME_MAXLENGTH];
new gUpgradeSelected[MAXPLAYERS];

public OnPluginStart()
{
    //RegConsoleCmd("upgrademod", Command_DebugMenu);

    HookEvent("player_use", Event_PlayerUse);
    HookEvent("ammo_pickup", Event_AmmoPickup);
}

public OnMapStart()
{
    PrecacheParticle("achieved");
}

PartyEffect(client)
{
    AttachThrowAwayParticle(client, "achieved", NULL_VECTOR, "eyes", 5.0);
}

public Event_PlayerUse(Handle:event, const String:name[], bool:dontBroadcast)
{
    new client = GetClientOfUserId(GetEventInt(event, "userid"));
    new iEntity = GetEventInt(event, "targetid");

    if (IsValidEntity(iEntity))
    {
        decl String:entityName[64];
        GetEdictClassname(iEntity, entityName, sizeof(entityName));

        if (StrEqual(entityName, "weapon_ammo_spawn"))
        {
            ShowUpgradeMenu(client);
        }
    }
}

public Event_AmmoPickup(Handle:event, const String:name[], bool:dontBroadcast)
{
    new client = GetClientOfUserId(GetEventInt(event, "userid"));
    
    ShowUpgradeMenu(client);
}

/*
public Action:Command_DebugMenu(client, args)
{
    ShowUpgradeMenu(client);
    return Plugin_Handled;  
}
*/

ShowUpgradeMenu(client)
{
    new iCurrentWeapon = GetEntPropEnt(client, Prop_Send, "m_hActiveWeapon");
    decl String:sWeaponName[WEAPON_NAME_MAXLENGTH];

    if (IsValidEntity(iCurrentWeapon))
    {
        GetEdictClassname(iCurrentWeapon, sWeaponName, sizeof(sWeaponName));
        sWeaponNameArray[client] = sWeaponName;
    }
    else
    {
        Upgrademod_LogCritical("Player \"{client %d}\" was not holding a valid weapon?", client);
    }
    
    new Handle:panel = CreatePanel();

    decl String:sLine[1000];
    Format(sLine, sizeof(sLine), "Upgrade your \"%s\"", sWeaponName);
    
    SetPanelTitle(panel, "<< UPGRADEMOD >>");
    DrawPanelText(panel, sLine);
    DrawPanelText(panel, " ");

    new experience = GetWeaponExperience(client, sWeaponName);
    Format(sLine, sizeof(sLine), "You have %d experience left for this weapon", experience);
    DrawPanelText(panel, sLine);

    DrawPanelItem(panel, "Upgrade", WeaponHasUpgrades(sWeaponName) ? ITEMDRAW_DEFAULT : ITEMDRAW_DISABLED);
    DrawPanelItem(panel, "Close");
    DrawPanelItem(panel, "Give yourself free EXP", GetAdminFlag(GetUserAdmin(client), Admin_RCON) == true ? ITEMDRAW_DEFAULT : ITEMDRAW_DISABLED);
    DrawPanelItem(panel, "Browse all upgrades");
    
    SendPanelToClient(panel, client, UpgradeMenuHandler, 10);
    
    CloseHandle(panel);
}

public UpgradeMenuHandler(Handle:menu, MenuAction:action, client, selected_item)
{
    if (!IsValidPlayer(client))
    {
        return;
    }
    
    decl String:sWeaponName[WEAPON_NAME_MAXLENGTH];
    strcopy(sWeaponName, sizeof(sWeaponName), sWeaponNameArray[client]);
    
    switch (action)
    {
        case MenuAction_Select:
        {
            if(!IsValidPlayer(client))
            {
                return;
            }
            
            if(selected_item == SELECTION_UPGRADE_WEAPON)
            {
                ShowUpgradeWeaponMenu(client, sWeaponName);
            }
            else if(selected_item == SELECTION_DEBUG)
            {
                DisplayDebugMenu(client, sWeaponName);
            }
            else if(selected_item == SELECTION_BROWSE)
            {
                ShowBrowseWeaponMenu(client);
            }
        }
        case MenuAction_End:
        {
            CloseHandle(menu);
        }
    }
}

ShowBrowseWeaponMenu(client)
{
    new Handle:menu = CreateMenu(BrowseWeaponHandler, MENU_ACTIONS_DEFAULT);

    decl String:sTitle[1000];
    Format(sTitle, sizeof(sTitle), "<< UPGRADE BROWSER >>");

    SetMenuTitle(menu, sTitle);
    
    new Handle:hWeaponStack = GetUpgradeableItemStack();
    
    decl String:sWeapon[WEAPON_NAME_MAXLENGTH];
    
    while(!IsStackEmpty(hWeaponStack))
    {
        PopStackString(hWeaponStack, sWeapon, sizeof(sWeapon));
        AddMenuItem(menu, sWeapon, sWeapon, WeaponHasUpgrades(sWeapon) ? ITEMDRAW_DEFAULT : ITEMDRAW_DISABLED);
    }
    
    CloseHandle(hWeaponStack);
    
    SetMenuExitButton(menu, true);
    DisplayMenu(menu, client, MENU_TIME_FOREVER);
}

public BrowseWeaponHandler(Handle:menu, MenuAction:action, client, selected_item)
{
    switch (action)
    {
        case MenuAction_Select:
        {
            decl String:sWeapon[WEAPON_NAME_MAXLENGTH];
            GetMenuItem(menu, selected_item, sWeapon, sizeof(sWeapon));

            ShowUpgradeWeaponMenu(client, sWeapon);
        }
        case MenuAction_End:
        {
            CloseHandle(menu);
        }
    }
}

ShowUpgradeWeaponMenu(client, String:sWeaponName[WEAPON_NAME_MAXLENGTH])
{
    new Handle:menu = CreateMenu(UpgradeWeaponHandler, MENU_ACTIONS_DEFAULT);

    decl String:sTitle[1000];
    Format(sTitle, sizeof(sTitle), "<< AVAILABLE UPGRADES FOR \"%s\" >>", sWeaponName);

    SetMenuTitle(menu, sTitle);
    
    decl String:sUpgradeNumber[10];
    decl String:sUpgradeName[UPGRADE_NAME_MAXLENGTH];
    decl String:sMenuItem[UPGRADE_NAME_MAXLENGTH * 2];
    new iAmountOfUpgrades = GetAmountOfUpgrades();
    new level;
    new max_level;
    
    for(new upgrade=0; upgrade < iAmountOfUpgrades; upgrade++)
    {
        if(IsUpgradeAvailableForWeapon(upgrade, sWeaponName))
        {
            IntToString(upgrade, sUpgradeNumber, sizeof(sUpgradeNumber));
            GetUpgradeName(upgrade, sWeaponName, sUpgradeName);
            
            level = GetUpgradeLevel(client, upgrade, sWeaponName);
            max_level = GetUpgradeMaxLevel(upgrade, sWeaponName);
            
            Format(sMenuItem, sizeof(sMenuItem), "%s [%d/%d]", sUpgradeName, level, max_level);
            
            AddMenuItem(menu, sUpgradeNumber, sMenuItem);
        }
    }
    
    SetMenuExitButton(menu, true);
    DisplayMenu(menu, client, MENU_TIME_FOREVER);
}

public UpgradeWeaponHandler(Handle:menu, MenuAction:action, client, selected_item)
{
    switch (action)
    {
        case MenuAction_Select:
        {
            new String:sUpgradeNumber[10];
            GetMenuItem(menu, selected_item, sUpgradeNumber, sizeof(sUpgradeNumber));

            decl String:sWeaponName[WEAPON_NAME_MAXLENGTH];
            strcopy(sWeaponName, sizeof(sWeaponName), sWeaponNameArray[client]);
            
            ShowUpgradeInformation(client, StringToInt(sUpgradeNumber), sWeaponName);
        }
        case MenuAction_End:
        {
            CloseHandle(menu);
        }
    }
}

ShowUpgradeInformation(client, upgrade, String:sWeaponName[WEAPON_NAME_MAXLENGTH])
{
    new Handle:panel = CreatePanel();

    decl String:sUpgradeName[UPGRADE_NAME_MAXLENGTH];
    decl String:sLine[1000];
    GetUpgradeName(upgrade, sWeaponName, sUpgradeName);

    new current_level = GetUpgradeLevel(client, upgrade, sWeaponName);
    new max_level = GetUpgradeMaxLevel(upgrade, sWeaponName);
    new experience = GetWeaponExperience(client, sWeaponName);
    new experience_required = GetUpgradeExperienceRequired(upgrade, sWeaponName, current_level + 1);
    
    SetPanelTitle(panel, sUpgradeName);
    DrawPanelText(panel, " ");
    
    decl String:sDescription[UPGRADE_DESCRIPTION_MAXLENGTH];
    GetUpgradeDescription(upgrade, sWeaponName, current_level, sDescription);
    
    DrawPanelText(panel, sDescription);
    DrawPanelText(panel, " ");
    
    if(current_level < max_level)
    {
        Format(sLine, sizeof(sLine), "Your current level is %d of %d", current_level, max_level);    
        DrawPanelText(panel, sLine);

        Format(sLine, sizeof(sLine), "It would cost you %d experience to level it up", experience_required);
        DrawPanelText(panel, sLine);
    }
    else
    {
        DrawPanelText(panel, "You have maxed out this upgrade!");
    }
    
    DrawPanelText(panel, " ");
    
    Format(sLine, sizeof(sLine), "You have %d experience left for this weapon", experience);
    DrawPanelText(panel, sLine);

    DrawPanelItem(panel, "Upgrade", (experience >= experience_required) && (current_level < max_level) ? ITEMDRAW_DEFAULT : ITEMDRAW_DISABLED);
    DrawPanelItem(panel, "Reset", ITEMDRAW_DISABLED); //current_level > 0 ? ITEMDRAW_DEFAULT : ITEMDRAW_DISABLED);
    DrawPanelItem(panel, "Back");
    DrawPanelItem(panel, "Cancel");
    
    SendPanelToClient(panel, client, UpgradePanelHandler, MENU_TIME_FOREVER);
    
    CloseHandle(panel);
    
    gUpgradeSelected[client] = upgrade;
}

public UpgradePanelHandler(Handle:menu, MenuAction:action, client, selected_item) 
{
    if (action == MenuAction_Select)
    {
        decl String:sWeaponName[WEAPON_NAME_MAXLENGTH];
        strcopy(sWeaponName, sizeof(sWeaponName), sWeaponNameArray[client]);
        
        if(selected_item == SELECTION_BUY_UPGRADE)
        {
            new upgrade = gUpgradeSelected[client];
            new desired_level = GetUpgradeLevel(client, upgrade, sWeaponName) + 1;
            new experience_required = GetUpgradeExperienceRequired(upgrade, sWeaponName, desired_level);
            
            if(RemoveWeaponExperience(client, sWeaponName, experience_required))
            {
                PartyEffect(client);
                Upgrade_ChatMessage(client, "You purchased an upgrade!");
                SetUpgradeLevel(client, upgrade, sWeaponName, desired_level);
            }
            else
            {
                Upgrademod_LogError("Not enough dosh!?");
            }
            
            ShowUpgradeInformation(client, upgrade, sWeaponName);
        }
        else if (selected_item == SELECTION_RETURN)
        {
            ShowUpgradeWeaponMenu(client, sWeaponName);
        }
    }
}

DisplayDebugMenu(client, String:sWeaponName[WEAPON_NAME_MAXLENGTH])
{
    GiveWeaponExperience(client, sWeaponName, 50000);
    ShowUpgradeMenu(client);
}