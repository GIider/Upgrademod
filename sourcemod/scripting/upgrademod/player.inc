#include "upgrademod/constants"

// Retrieve the amount of weapon experience a player has
native GetWeaponExperience(client, String:sWeaponName[WEAPON_NAME_MAXLENGTH]);

// Set the amount of weapon experience a player has
// When bUpdateDatabase is set to false the changes will not be propagated to the database...
// this is used when loading the data initially so we don't write it back immediatly
native bool:SetWeaponExperience(client, String:sWeaponName[WEAPON_NAME_MAXLENGTH], value, bUpdateDatabase=true);

// Gives additional experience
native bool:GiveWeaponExperience(client, String:sWeaponName[WEAPON_NAME_MAXLENGTH], value);

// Removes experience
native bool:RemoveWeaponExperience(client, String:sWeaponName[WEAPON_NAME_MAXLENGTH], value);

// Returns the handle to a adt_array that contains weapon names of
// weapons whose weapon experience was modified
// Close the handle after you're done with it!
native Handle:GetModifiedWeaponExperienceArray(client);

// Clear the array of modified weapon experiences
native ClearModifiedWeaponExperienceArray(client);