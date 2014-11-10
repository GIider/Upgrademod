static const	ASSAULT_RIFLE_OFFSET_IAMMO		= 12;
static const	SMG_OFFSET_IAMMO				= 20;
static const	PUMPSHOTGUN_OFFSET_IAMMO		= 28;
static const	AUTO_SHOTGUN_OFFSET_IAMMO		= 32;
static const	HUNTING_RIFLE_OFFSET_IAMMO		= 36;
static const	MILITARY_SNIPER_OFFSET_IAMMO	= 40;
static const	GRENADE_LAUNCHER_OFFSET_IAMMO	= 68;

/* Weapon upgrade bit flags */
#define L4D2_WEPUPGFLAG_NONE            (0 << 0)
#define L4D2_WEPUPGFLAG_INCENDIARY      (1 << 0)
#define L4D2_WEPUPGFLAG_EXPLOSIVE       (1 << 1)
#define L4D2_WEPUPGFLAG_LASER           (1 << 2)

// I dunno how to make a constant string array :(
/** Get a stack containing all weapons
 * Example usage:
 * 
new Handle:hWeaponStack = GetWeaponStack();
    
decl String:sWeapon[WEAPON_NAME_MAXLENGTH];
    
while(!IsStackEmpty(hWeaponStack))
{
    PopStackString(hWeaponStack, sWeapon, sizeof(sWeapon));
    // Do something with it
}
    
CloseHandle(hWeaponStack);
 * 
 */
stock Handle:GetUpgradeableItemStack()
{
    new Handle:hWeaponStack = CreateStack(WEAPON_NAME_MAXLENGTH);
    
    PushStackString(hWeaponStack, "weapon_rifle");
    PushStackString(hWeaponStack, "weapon_rifle_ak47");
    PushStackString(hWeaponStack, "weapon_rifle_desert");
    PushStackString(hWeaponStack, "weapon_rifle_sg552");
    PushStackString(hWeaponStack, "weapon_smg");
    PushStackString(hWeaponStack, "weapon_smg_silenced");
    PushStackString(hWeaponStack, "weapon_smg_mp5");
    PushStackString(hWeaponStack, "weapon_pumpshotgun");
    PushStackString(hWeaponStack, "weapon_shotgun_chrome");
    PushStackString(hWeaponStack, "weapon_autoshotgun");
    PushStackString(hWeaponStack, "weapon_shotgun_spas");
    PushStackString(hWeaponStack, "weapon_hunting_rifle");
    PushStackString(hWeaponStack, "weapon_sniper_military");
    PushStackString(hWeaponStack, "weapon_sniper_awp");
    PushStackString(hWeaponStack, "weapon_sniper_scout");
    PushStackString(hWeaponStack, "weapon_grenade_launcher");
    PushStackString(hWeaponStack, "weapon_rifle_m60");
    PushStackString(hWeaponStack, "weapon_melee");
    PushStackString(hWeaponStack, "weapon_chainsaw");

    // Pistols
    PushStackString(hWeaponStack, "weapon_pistol");
    PushStackString(hWeaponStack, "weapon_pistol_magnum");
    PushStackString(hWeaponStack, "weapon_dual_pistols");
    
    // Throwables
    PushStackString(hWeaponStack, "weapon_pipe_bomb");
    PushStackString(hWeaponStack, "weapon_molotov");

    // Healing Items
    PushStackString(hWeaponStack, "weapon_first_aid_kit");
    PushStackString(hWeaponStack, "weapon_defibrillator");
    PushStackString(hWeaponStack, "weapon_pain_pills");
    PushStackString(hWeaponStack, "weapon_adrenaline");

    // Upgrade packs
    PushStackString(hWeaponStack, "weapon_upgradepack_explosive");
    PushStackString(hWeaponStack, "weapon_upgradepack_incendiary");

    return hWeaponStack;
}

stock bool:CouldConsumePrimaryMagazineFromPool(client)
{
    new iPrimaryWeapon = GetPlayerWeaponSlot(client, 0);
    if (!IsValidEntity(iPrimaryWeapon))
    {
        return false;
    }

    decl String:sWeaponName[64];
    GetEdictClassname(iPrimaryWeapon, sWeaponName, sizeof(sWeaponName));
    
    new iMaxMagSize = GetMaxMagSize(sWeaponName);
    new iBackupAmmo = GetCurrentBackupAmmo(client);
    
    return iBackupAmmo >= iMaxMagSize;

}

stock bool:ConsumePrimaryMagazineFromPool(client)
{
    new iPrimaryWeapon = GetPlayerWeaponSlot(client, 0);
    if (!IsValidEntity(iPrimaryWeapon))
    {
        return false;
    }

    decl String:sWeaponName[64];
    GetEdictClassname(iPrimaryWeapon, sWeaponName, sizeof(sWeaponName));
    
    new iMaxMagSize = GetMaxMagSize(sWeaponName);
    new iBackupAmmo = GetCurrentBackupAmmo(client);
    
    if (iBackupAmmo >= iMaxMagSize)
    {
        SetBackupAmmo(client, iBackupAmmo - iMaxMagSize);
        return true;
    }
    
    return false;
}

stock bool:ConsumePrimaryMagazine(client)
{
    new iPrimaryWeapon = GetPlayerWeaponSlot(client, 0);
    if (!IsValidEntity(iPrimaryWeapon))
    {
        return false;
    }

    decl String:sWeaponName[64];
    GetEdictClassname(iPrimaryWeapon, sWeaponName, sizeof(sWeaponName));
    
    new iMaxMagSize = GetMaxMagSize(sWeaponName);
    new iMagSize = GetMagazineAmmo(iPrimaryWeapon);
    
    if (iMagSize >= iMaxMagSize)
    {
        SetMagazineAmmo(iPrimaryWeapon, 0);
        return true;
    }
    
    return false;
}

stock GetMaxMagSize(const String:weapon[])
{
    if ((StrEqual(weapon, "weapon_rifle", false)) || (StrEqual(weapon, "weapon_rifle_sg552", false)) || (StrEqual(weapon, "weapon_smg", false) || StrEqual(weapon, "weapon_smg_silenced", false) || StrEqual(weapon, "weapon_smg_mp5", false)))
    {
        return 50;
    }
    else if (StrEqual(weapon, "weapon_rifle_ak47", false))
    {
        return 40;
    }
    else if (StrEqual(weapon, "weapon_rifle_desert", false))
    {
        return 60;
    }
    else if (StrEqual(weapon, "weapon_autoshotgun", false) || StrEqual(weapon, "weapon_shotgun_spas", false))
    {
        return 10;
    }
    else if (StrEqual(weapon, "weapon_grenade_launcher", false))
    {
        return 1;
    }
    else if (StrEqual(weapon, "weapon_pumpshotgun", false) || StrEqual(weapon, "weapon_shotgun_chrome", false))
    {
        return 8;
    }
    else if (StrEqual(weapon, "weapon_hunting_rifle", false))
    {
        return 15;
    }
    else if (StrEqual(weapon, "weapon_sniper_military", false))
    {
        return 30;
    }
    else if (StrEqual(weapon, "weapon_sniper_awp", false))
    {
        return 20;
    }
    else if (StrEqual(weapon, "weapon_sniper_scout", false))
    {
        return 15;
    }
    else if (StrEqual(weapon, "weapon_rifle_m60", false))
    {
        return 150;
    }
    
    return 0;
}

stock GetMagazineAmmo(weapon)
{
    if (!IsValidEdict(weapon))
    {
        return 0; 
    }
    
    return GetEntProp(weapon, Prop_Send, "m_iClip1");
}

stock SetMagazineAmmo(weapon, amount)
{
    if (!IsValidEdict(weapon))
    {
        return; 
    }
    
    SetEntProp(weapon, Prop_Send, "m_iClip1", amount);
}

stock GetCurrentBackupAmmo(client)
{
	decl String:weapon[64];
	new iWeapon = GetPlayerWeaponSlot(client, 0);
	GetEdictClassname(iWeapon, weapon, sizeof(weapon));
	
	new iAmmoOffset = FindDataMapOffs(client, "m_iAmmo");
	new backup_ammo = 0;

	if (StrEqual(weapon, "weapon_rifle", false) || StrEqual(weapon, "weapon_rifle_ak47", false) || StrEqual(weapon, "weapon_rifle_desert", false) || StrEqual(weapon, "weapon_rifle_sg552", false))
	{
		backup_ammo = GetEntData(client, iAmmoOffset + ASSAULT_RIFLE_OFFSET_IAMMO);
	}
	else if (StrEqual(weapon, "weapon_smg", false) || StrEqual(weapon, "weapon_smg_silenced", false) || StrEqual(weapon, "weapon_smg_mp5", false))
	{
		backup_ammo = GetEntData(client, iAmmoOffset + SMG_OFFSET_IAMMO);
	}		
	else if (StrEqual(weapon, "weapon_pumpshotgun", false) || StrEqual(weapon, "weapon_shotgun_chrome", false))
	{
		backup_ammo = GetEntData(client, iAmmoOffset + PUMPSHOTGUN_OFFSET_IAMMO);
	}
	else if (StrEqual(weapon, "weapon_autoshotgun", false) || StrEqual(weapon, "weapon_shotgun_spas", false))
	{
		backup_ammo = GetEntData(client, iAmmoOffset + AUTO_SHOTGUN_OFFSET_IAMMO);
	}
	else if (StrEqual(weapon, "weapon_hunting_rifle", false))
	{
		backup_ammo = GetEntData(client, iAmmoOffset + HUNTING_RIFLE_OFFSET_IAMMO);
	}
	else if (StrEqual(weapon, "weapon_sniper_military", false) || StrEqual(weapon, "weapon_sniper_awp", false) || StrEqual(weapon, "weapon_sniper_scout", false))
	{
		backup_ammo = GetEntData(client, iAmmoOffset + MILITARY_SNIPER_OFFSET_IAMMO);
	}
	else if (StrEqual(weapon, "weapon_grenade_launcher"))
	{
		backup_ammo = GetEntData(client, iAmmoOffset + GRENADE_LAUNCHER_OFFSET_IAMMO);
	}
	
	return backup_ammo;
}

stock GetMaxBackupAmmo(const String:weapon[])
{
    if (StrEqual(weapon, "weapon_rifle", false) || StrEqual(weapon, "weapon_rifle_ak47", false) || StrEqual(weapon, "weapon_rifle_desert", false) || StrEqual(weapon, "weapon_rifle_sg552", false))
    {
        return GetConVarInt(FindConVar("ammo_assaultrifle_max"));
    }
    else if (StrEqual(weapon, "weapon_smg", false) || StrEqual(weapon, "weapon_smg_silenced", false) || StrEqual(weapon, "weapon_smg_mp5", false))
    {
        return GetConVarInt(FindConVar("ammo_smg_max"));
    }	
    else if (StrEqual(weapon, "weapon_pumpshotgun", false) || StrEqual(weapon, "weapon_shotgun_chrome", false))
    {
        return GetConVarInt(FindConVar("ammo_shotgun_max"));
    }
    else if (StrEqual(weapon, "weapon_autoshotgun", false) || StrEqual(weapon, "weapon_shotgun_spas", false))
    {
        return GetConVarInt(FindConVar("ammo_autoshotgun_max"));
    }
    else if (StrEqual(weapon, "weapon_hunting_rifle", false))
    {
        return GetConVarInt(FindConVar("ammo_huntingrifle_max"));
    }
    else if (StrEqual(weapon, "weapon_sniper_military", false) || StrEqual(weapon, "weapon_sniper_awp", false) || StrEqual(weapon, "weapon_sniper_scout", false))
    {
        return GetConVarInt(FindConVar("ammo_sniperrifle_max"));
    }
    else if (StrEqual(weapon, "weapon_grenade_launcher", false))
    {
        return GetConVarInt(FindConVar("ammo_grenadelauncher_max"));
    }
    else if (StrEqual(weapon, "weapon_rifle_m60", false))
    {
        return 0;
    }
    
    return 0;
}

stock SetBackupAmmo(client, ammo)
{
	decl String:weapon[64];
	new iWeapon = GetPlayerWeaponSlot(client, 0);
	GetEdictClassname(iWeapon, weapon, sizeof(weapon));
	
	new iAmmoOffset = FindDataMapOffs(client, "m_iAmmo");

	if (StrEqual(weapon, "weapon_rifle", false) || StrEqual(weapon, "weapon_rifle_ak47", false) || StrEqual(weapon, "weapon_rifle_desert", false) || StrEqual(weapon, "weapon_rifle_sg552", false))
	{
		SetEntData(client, iAmmoOffset + ASSAULT_RIFLE_OFFSET_IAMMO, ammo);
	}
	else if (StrEqual(weapon, "weapon_smg", false) || StrEqual(weapon, "weapon_smg_silenced", false) || StrEqual(weapon, "weapon_smg_mp5", false))
	{
		SetEntData(client, iAmmoOffset + SMG_OFFSET_IAMMO, ammo);
	}		
	else if (StrEqual(weapon, "weapon_pumpshotgun", false) || StrEqual(weapon, "weapon_shotgun_chrome", false))
	{
		SetEntData(client, iAmmoOffset + PUMPSHOTGUN_OFFSET_IAMMO, ammo);
	}
	else if (StrEqual(weapon, "weapon_autoshotgun", false) || StrEqual(weapon, "weapon_shotgun_spas", false))
	{
		SetEntData(client, iAmmoOffset + AUTO_SHOTGUN_OFFSET_IAMMO, ammo);
	}
	else if (StrEqual(weapon, "weapon_hunting_rifle", false))
	{
		SetEntData(client, iAmmoOffset + HUNTING_RIFLE_OFFSET_IAMMO, ammo);
	}
	else if (StrEqual(weapon, "weapon_sniper_military", false) || StrEqual(weapon, "weapon_sniper_awp", false) || StrEqual(weapon, "weapon_sniper_scout", false))
	{
		SetEntData(client, iAmmoOffset + MILITARY_SNIPER_OFFSET_IAMMO, ammo);
	}
	else if (StrEqual(weapon, "weapon_grenade_launcher"))
	{
		SetEntData(client, iAmmoOffset + GRENADE_LAUNCHER_OFFSET_IAMMO, ammo);
	}
}

// Super Generic check
stock bool:IsWeapon(const String:weaponName[])
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
			StrEqual(weaponName, "weapon_dual_pistols", false));
}

// Only Primaries!
stock bool:IsPrimaryWeapon(const String:weaponName[])
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
            StrEqual(weaponName, "weapon_rifle_m60", false));
}

stock bool:IsGunWeapon(const String:weaponName[])
{
    return (IsWeapon(weaponName) && !IsMeleeWeapon(weaponName) && !IsThrowableWeapon(weaponName));
}

stock bool:IsMeleeWeapon(const String:weaponName[])
{
    return (StrEqual(weaponName, "weapon_melee", false) ||
            StrEqual(weaponName, "weapon_chainsaw", false));
}


stock bool:IsSpecialWeapon(const String:weaponName[])
{
    return (StrEqual(weaponName, "weapon_grenade_launcher", false) || 
            StrEqual(weaponName, "weapon_rifle_m60", false),
            StrEqual(weaponName, "weapon_chainsaw", false));
}

stock bool:IsThrowableWeapon(const String:weaponName[])
{
    return (StrEqual(weaponName, "weapon_pipe_bomb", false) ||
            StrEqual(weaponName, "weapon_molotov", false) ||
            StrEqual(weaponName, "weapon_vomitjar", false));
}

// Super Generic check
stock bool:IsSecondaryWeapon(const String:weaponName[])
{
    return (StrEqual(weaponName, "weapon_melee", false) ||
            StrEqual(weaponName, "weapon_pistol", false) ||
            StrEqual(weaponName, "weapon_pistol_magnum", false) ||
            StrEqual(weaponName, "weapon_dual_pistols", false));
}

stock bool:IsTierOneWeapon(const String:weaponName[])
{
    return (StrEqual(weaponName, "weapon_smg", false) || 
            StrEqual(weaponName, "weapon_smg_silenced", false) || 
            StrEqual(weaponName, "weapon_smg_mp5", false) || 
            StrEqual(weaponName, "weapon_pumpshotgun", false) || 
            StrEqual(weaponName, "weapon_shotgun_chrome", false));
}

stock bool:IsTierTwoWeapon(const String:weaponName[])
{
    return (StrEqual(weaponName, "weapon_rifle", false) || 
            StrEqual(weaponName, "weapon_rifle_ak47", false) || 
            StrEqual(weaponName, "weapon_rifle_desert", false) || 
            StrEqual(weaponName, "weapon_rifle_sg552", false) || 
            StrEqual(weaponName, "weapon_autoshotgun", false) || 
            StrEqual(weaponName, "weapon_shotgun_spas", false) || 
            StrEqual(weaponName, "weapon_hunting_rifle", false) || 
            StrEqual(weaponName, "weapon_sniper_military", false) || 
            StrEqual(weaponName, "weapon_sniper_awp", false) || 
            StrEqual(weaponName, "weapon_sniper_scout", false));
}

stock bool:IsShotgun(const String:weaponName[])
{
    return (StrEqual(weaponName, "weapon_pumpshotgun", false) || 
            StrEqual(weaponName, "weapon_shotgun_chrome", false) || 
            StrEqual(weaponName, "weapon_autoshotgun", false) || 
            StrEqual(weaponName, "weapon_shotgun_spas", false));
}

stock bool:IsAssaultRifle(const String:weaponName[])
{
    return (StrEqual(weaponName, "weapon_rifle", false) || 
            StrEqual(weaponName, "weapon_rifle_ak47", false) || 
            StrEqual(weaponName, "weapon_rifle_desert", false) || 
            StrEqual(weaponName, "weapon_rifle_sg552", false));
}

stock bool:IsSMG(const String:weaponName[])
{
    return (StrEqual(weaponName, "weapon_smg", false) || 
            StrEqual(weaponName, "weapon_smg_silenced", false) || 
            StrEqual(weaponName, "weapon_smg_mp5", false));
}

stock bool:IsSniper(const String:weaponName[])
{
    return (StrEqual(weaponName, "weapon_hunting_rifle", false) || 
            StrEqual(weaponName, "weapon_sniper_military", false) || 
            StrEqual(weaponName, "weapon_sniper_awp", false) || 
            StrEqual(weaponName, "weapon_sniper_scout", false));
}

stock bool:HasScope(const String:weaponName[])
{
    return (StrEqual(weaponName, "weapon_rifle_sg552", false) || IsSniper(weaponName)); 
}

stock bool:IsFirstAid(const String:weaponName[])
{
    return (StrEqual(weaponName, "weapon_first_aid_kit", false) || StrEqual(weaponName, "weapon_defibrillator", false)); 
}

/* TAKEN FROM l4d_stocks.inc http://code.google.com/p/l4dstocks/source/browse/l4d_stocks.inc */

/**
 * Returns weapon upgrades of weapon.
 *
 * @param weapon		Weapon entity index.
 * @return				Weapon upgrade bits.
 * @error				Invalid entity index.
 */
stock L4D2_GetWeaponUpgrades(weapon)
{
	return GetEntProp(weapon, Prop_Send, "m_upgradeBitVec");
}

/**
 * Set weapon upgrades for weapon.
 *
 * @param weapon		Weapon entity index.
 * @param upgrades		Weapon upgrade bits.
 * @noreturn
 * @error				Invalid entity index.
 */
stock L4D2_SetWeaponUpgrades(weapon, upgrades)
{
	SetEntProp(weapon, Prop_Send, "m_upgradeBitVec", upgrades);
}

/**
 * Returns upgraded ammo count for weapon.
 *
 * @param weapon		Weapon entity index.
 * @return				Upgraded ammo count.
 * @error				Invalid entity index.
 */
stock L4D2_GetWeaponUpgradeAmmoCount(weapon)
{
	return GetEntProp(weapon, Prop_Send, "m_nUpgradedPrimaryAmmoLoaded");
}

/**
 * Set upgraded ammo count in weapon.
 *
 * @param weapon		Weapon entity index.
 * @param count			Upgraded ammo count.
 * @noreturn
 * @error				Invalid entity index.
 */
stock L4D2_SetWeaponUpgradeAmmoCount(weapon, count)
{
	SetEntProp(weapon, Prop_Send, "m_nUpgradedPrimaryAmmoLoaded", count);
}
