/**
 * File: forwards.inc
 * Description: All forwards
 * Author(s): Glider
 */

forward OnUpgrademodDatabaseLoaded(Handle:hDB);

// Forwards that request information about a upgrade
forward bool:OnIsUpgradeAvailableForWeapon(upgrade, String:sWeaponName[WEAPON_NAME_MAXLENGTH], &bool:result);
forward OnUpgradeNameRequested(upgrade, String:sWeaponName[WEAPON_NAME_MAXLENGTH], String:sUpgradeName[UPGRADE_NAME_MAXLENGTH]);
forward OnUpgradeDescriptionRequested(upgrade, String:sWeaponName[WEAPON_NAME_MAXLENGTH], level, String:sUpgradeDescription[UPGRADE_DESCRIPTION_MAXLENGTH]);
forward OnUpgradeMaxLevelRequested(upgrade, String:sWeaponName[WEAPON_NAME_MAXLENGTH], &maxlevel);
forward OnUpgradeExperienceRequiredRequested(upgrade, String:sWeaponName[WEAPON_NAME_MAXLENGTH], level, &experience);