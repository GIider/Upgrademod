#include "upgrademod/constants"

// Register a new upgrade
// Returns the index
native RegisterUpgrade(String:sUpgradeShortname[UPGRADE_SHORTNAME_MAXLENGTH]);

native GetUpgradeShortname(upgrade, String:sUpgradeShortname[UPGRADE_SHORTNAME_MAXLENGTH]);
native GetUpgradeIndex(String:sUpgradeShortname[UPGRADE_SHORTNAME_MAXLENGTH]);

// Check if a upgrade is available for this weapon
native bool:IsUpgradeAvailableForWeapon(upgrade, String:sWeaponName[WEAPON_NAME_MAXLENGTH]);

// Returns the amount of upgrades
native GetAmountOfUpgrades();

native GetAmountOfAvailableUpgrades(String:sWeaponName[WEAPON_NAME_MAXLENGTH]);
native GetAmountOfPurchasedUpgrades(client, String:sWeaponName[WEAPON_NAME_MAXLENGTH]);
native GetTotalAmountOfPurchasedUpgrades(client);

native bool:WeaponHasUpgrades(String:sWeaponname[WEAPON_NAME_MAXLENGTH]);

// Retrieve the description for this upgrade
native GetUpgradeDescription(upgrade, String:sWeaponName[WEAPON_NAME_MAXLENGTH], level, String:sUpgradeDescription[UPGRADE_DESCRIPTION_MAXLENGTH]);

// Retrieve the description for this upgrade
native GetUpgradeName(upgrade, String:sWeaponName[WEAPON_NAME_MAXLENGTH], String:sUpgradeName[UPGRADE_NAME_MAXLENGTH]);

native GetUpgradeMaxLevel(upgrade, String:sWeaponName[WEAPON_NAME_MAXLENGTH]);

native GetExperienceRequiredForNextUpgrade(client);
native GetExperienceRequiredForUpgrade(upgrades_purchased);

native SetUpgradeLevel(client, upgrade, String:sWeaponName[WEAPON_NAME_MAXLENGTH], level);
native GetUpgradeLevel(client, upgrade, String:sWeaponName[WEAPON_NAME_MAXLENGTH]);
// Reset the upgrades for a client, refunding a percentage
native ResetUpgradesForClient(client, String:sWeaponName[WEAPON_NAME_MAXLENGTH]);

native PurchasePermanentUpgrade(client, upgrade, String:sWeaponName[WEAPON_NAME_MAXLENGTH]);

// Returns the handle to a adt_array that contains
// a adt_array that you can index with a upgrade number
// that contains a adt_array of weapon names
native Handle:GetModifiedUpgradeArray(client);

// Clear the array of modified upgrades experiences
native ClearModifiedUpgradeArray(client);