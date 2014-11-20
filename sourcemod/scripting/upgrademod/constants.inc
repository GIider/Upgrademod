#define  TEAM_SURVIVORS 2
#define  TEAM_INFECTED 3

// Comes from colors.inc
//#define MAX_MESSAGE_LENGTH 256

// How long a player name can be
#define FULLNAME_LENGTH 64

// Max length for the identifier of a upgrade
#define UPGRADE_SHORTNAME_MAXLENGTH 32

// Max length of a description
#define UPGRADE_DESCRIPTION_MAXLENGTH 1000

// Max length of a upgrade name
#define UPGRADE_NAME_MAXLENGTH 64

// Max length for a weapon
#define WEAPON_NAME_MAXLENGTH 64

#define MODEL_GASCAN    "models/props_junk/gascan001a.mdl"
#define MODEL_PROPANE   "models/props_junk/propanecanister001a.mdl"

// Max length for a convar
#define CONVAR_MAXLENGTH UPGRADE_SHORTNAME_MAXLENGTH + 20

// Default costs for upgrades

#define TIER_ONE_MODIFIER 0.75
#define TIER_TWO_MODIFIER 1.0
#define MELEE_MODIFIER 0.95

#define TIER_ONE_COSTS 500
#define TIER_TWO_COSTS 1000
#define MELEE_COSTS 900

#define INVALID_EXPERIENCE -1