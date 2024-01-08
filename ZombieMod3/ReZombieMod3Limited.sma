#include <amxmodx>
#include <amxmisc>
#include <fakemeta>
#include <engine>
#include <cstrike>
#include <csm>
#include <misc>
#include <hamsandwich>
#include <fakemeta_util>
#include <reapi>

#define MOD_VERSION	"2.0R"
#define MAX_CSDM_SPAWNS 128

#define SPAWN_DATA_ORIGIN_X 0
#define SPAWN_DATA_ORIGIN_Y 1
#define SPAWN_DATA_ORIGIN_Z 2
#define SPAWN_DATA_ANGLES_X 3
#define SPAWN_DATA_ANGLES_Y 4
#define SPAWN_DATA_ANGLES_Z 5
#define SPAWN_DATA_V_ANGLES_X 6
#define SPAWN_DATA_V_ANGLES_Y 7
#define SPAWN_DATA_V_ANGLES_Z 8

#define OFFSET_32BIT 235
#define OFFSET_64BIT 268
#define OFFSET_LINUX_DIFF 5

#if !defined PROCESSOR_TYPE
	#if cellbits == 32
		#define OFFSET OFFSET_32BIT
	#else
		#define OFFSET OFFSET_64BIT
	#endif
#else 
	#if PROCESSOR_TYPE == 0
		#define OFFSET OFFSET_32BIT
	#else
		#define OFFSET OFFSET_64BIT
	#endif
#endif

#define CS_GET_USER_MAPZONES(%1) get_pdata_int(%1, OFFSET, OFFSET_LINUX_DIFF)
#define CS_SET_USER_MAPZONES(%1,%2) set_pdata_int(%1, OFFSET, %2, OFFSET_LINUX_DIFF)

new Float:g_spawns_csdm[MAX_CSDM_SPAWNS][SPAWN_DATA_V_ANGLES_Z+1], Float:g_spawns_regular[MAX_CSDM_SPAWNS][SPAWN_DATA_V_ANGLES_Z+1]
new g_SpawnCountCSDM, g_SpawnCountRegular
new Float:g_spawns_box[MAX_CSDM_SPAWNS][3], g_SpawnCountBox

new setting_file[] = "zombiemod3.cfg"
new setting_escape_file[] = "zombiemod3_escape.cfg"

const PRIMARY_WEAPONS_BIT_SUM = (1<<CSW_SCOUT)|(1<<CSW_XM1014)|(1<<CSW_UMP45)|(1<<CSW_SG550)|(1<<CSW_GALIL)|(1<<CSW_FAMAS)|(1<<CSW_AWP)|(1<<CSW_MP5NAVY)|(1<<CSW_M249)|(1<<CSW_M3)|(1<<CSW_M4A1)|(1<<CSW_TMP)|(1<<CSW_G3SG1)|(1<<CSW_SG552)|(1<<CSW_AK47)|(1<<CSW_P90)|(1<<CSW_AUG)|(1<<CSW_MAC10)
const SECONDARY_WEAPONS_BIT_SUM = (1<<CSW_P228)|(1<<CSW_ELITE)|(1<<CSW_FIVESEVEN)|(1<<CSW_USP)|(1<<CSW_GLOCK18)|(1<<CSW_DEAGLE)
const CSWPN_NOTCHALLENGE = (1<<2)|(1<<CSW_HEGRENADE)|(1<<CSW_C4)|(1<<CSW_SMOKEGRENADE)|(1<<CSW_FLASHBANG)|(1<<CSW_KNIFE)
const CSWPN_NOCLIP = (1<<0)|(1<<2)|(1<<CSW_HEGRENADE)|(1<<CSW_C4)|(1<<CSW_SMOKEGRENADE)|(1<<CSW_FLASHBANG)|(1<<CSW_KNIFE)
const CSWPN_NADE = (1<<CSW_HEGRENADE)|(1<<CSW_SMOKEGRENADE)|(1<<CSW_FLASHBANG)

new Array:c_objective_ents
new Float:c_respawntime, c_roundtime, c_strip_weapon, block_buy,c_refill_ammo

new g_rebuy[33][4], Debug

enum (+= 100)
{
	TASK_GIVE_WEAPON = 2300,
	TASK_RESPAWN,
	TASK_ROUNDTIME,
	TASK_RESET_FRAGS,
	TASK_UPDATE_SCORE,
	TASK_RANDOM_WEAPON,
	TASK_PREV_WEAPON,
	TASK_AFTERDISCONNECT,
	TASK_WELCOME
}
enum
{
	ZTEAM_UNASSIGNED = 0,
	ZTEAM_TERRORIST,
	ZTEAM_CT
}

new const Float:szOffsetSize[][3] = 
{
	{0.0, 0.0, 1.0}, {0.0, 0.0, -1.0}, {0.0, 1.0, 0.0}, {0.0, -1.0, 0.0}, {1.0, 0.0, 0.0}, {-1.0, 0.0, 0.0}, {-1.0, 1.0, 1.0}, {1.0, 1.0, 1.0}, {1.0, -1.0, 1.0}, {1.0, 1.0, -1.0}, {-1.0, -1.0, 1.0}, {1.0, -1.0, -1.0}, {-1.0, 1.0, -1.0}, {-1.0, -1.0, -1.0},
	{0.0, 0.0, 2.0}, {0.0, 0.0, -2.0}, {0.0, 2.0, 0.0}, {0.0, -2.0, 0.0}, {2.0, 0.0, 0.0}, {-2.0, 0.0, 0.0}, {-2.0, 2.0, 2.0}, {2.0, 2.0, 2.0}, {2.0, -2.0, 2.0}, {2.0, 2.0, -2.0}, {-2.0, -2.0, 2.0}, {2.0, -2.0, -2.0}, {-2.0, 2.0, -2.0}, {-2.0, -2.0, -2.0},
	{0.0, 0.0, 3.0}, {0.0, 0.0, -3.0}, {0.0, 3.0, 0.0}, {0.0, -3.0, 0.0}, {3.0, 0.0, 0.0}, {-3.0, 0.0, 0.0}, {-3.0, 3.0, 3.0}, {3.0, 3.0, 3.0}, {3.0, -3.0, 3.0}, {3.0, 3.0, -3.0}, {-3.0, -3.0, 3.0}, {3.0, -3.0, -3.0}, {-3.0, 3.0, -3.0}, {-3.0, -3.0, -3.0},
	{0.0, 0.0, 4.0}, {0.0, 0.0, -4.0}, {0.0, 4.0, 0.0}, {0.0, -4.0, 0.0}, {4.0, 0.0, 0.0}, {-4.0, 0.0, 0.0}, {-4.0, 4.0, 4.0}, {4.0, 4.0, 4.0}, {4.0, -4.0, 4.0}, {4.0, 4.0, -4.0}, {-4.0, -4.0, 4.0}, {4.0, -4.0, -4.0}, {-4.0, 4.0, -4.0}, {-4.0, -4.0, -4.0},
	{0.0, 0.0, 5.0}, {0.0, 0.0, -5.0}, {0.0, 5.0, 0.0}, {0.0, -5.0, 0.0}, {5.0, 0.0, 0.0}, {-5.0, 0.0, 0.0}, {-5.0, 5.0, 5.0}, {5.0, 5.0, 5.0}, {5.0, -5.0, 5.0}, {5.0, 5.0, -5.0}, {-5.0, -5.0, 5.0}, {5.0, -5.0, -5.0}, {-5.0, 5.0, -5.0}, {-5.0, -5.0, -5.0}
}

new const Weapon_Bpammo[CSW_P90+1] = { -1,  52, -1, 180,  3,  180,    1, 200, 180, 3, 180, 150, 150, 180, 180, 180,   150, 180, 90, 180, 250, 180 , 180, 180, 180, 3, 175, 180, 180, -1, 150 }
new Float:Weapon_Knockback[CSW_P90+1] =  { -1.0, 2.4, -1.0, 6.5, -1.0, 8.0, -1.0, 2.3, 5.0, -1.0, 2.4, 2.0, 2.4, 5.3, 5.5, 5.5, 2.2, 2.0, 10.0, 2.5, 5.2, 8.0, 5.0, 2.4, 6.5, -1.0, 5.3, 5.0, 6.0, -1.0, 2.0 }

#define MAXMENUPOS 35

new szBlockRadioMessage[][] = { "#Cover_me" , "#You_take_the_point", "#Hold_this_position", "#Regroup_team", "#Follow_me", "#Taking_fire", "#Go_go_go", "#Team_fall_back", "#Stick_together_team", "#Get_in_position_and_wait",
	"#Storm_the_front", "#Report_in_team", "#Need_backup", "#In_position", "#Reporting_in", "#Get_out_of_there", "#Enemy_down", "#Hostage_down", "#Fire_in_the_hole" }
	
new g_Aliases[MAXMENUPOS][] = {"buy","usp","glock","deagle","p228","elites","fn57","m3","xm1014","mp5","tmp","p90","mac10","ump45","ak47","galil","famas","sg552","m4a1","aug","scout","awp","g3sg1","sg550","m249","vest","vesthelm","flash","hegren","sgren","defuser","nvgs","shield","primammo","secammo"} 
new g_Aliases2[MAXMENUPOS][] = {"buyequip","km45","9x19mm","nighthawk","228compact","elites","fiveseven","12gauge","autoshotgun","smg","mp","c90","mac10","ump45","cv47","defender","clarion","krieg552","m4a1","bullpup","scout","magnum","d3au1","krieg550","m249","vest","vesthelm","flash","hegren","sgren","defuser","nvgs","shield","primammo","secammo"}
new Array:AutoItem

new Array:c_skynames, g_fwSpawn

new c_human_health, c_human_armor, c_virus_time, c_instant_infect, c_minmoney, Float:c_human_gravity, c_enable_hero
new c_countdown, Float:c_zombie_ratio, c_zombie_health[3], c_zombie_armor, c_hero_model[32]
new c_ambience_rain, c_ambience_snow, c_ambience_fog, c_fog_color[12], c_fog_density[10], c_sky_enable
new c_supply_max, Float:c_supply_time
new Float:c_zbomb_radius, Float:c_zbomb_damage, Float:c_zbomb_knockback;
new Float:c_moneydamage_rate, c_escape_mode
new c_music_start[256], c_music_appear[256]

new c_decoder_cost, c_decoder_given[3]
new Float:c_decoder_rate[2] = {0.13,0.06}
new Float:c_decoder_chance = 100.0
new c_decoder_guarantee[2] = {10,80}

#define MAX_RAGE	1200
#define MAX_KARMA	3000

#define SPARK_COST_PRE	1000
#define SPARK_COST_UNI	500
#define SPARK_UNI	10
#define SPARK_PRE	500
#define SPARK_NOR	5

#define FROGBOMB_MODEL	"models/zbz/w_zombibomb.mdl"

new g_hud_sync[6], g_hud_plrsync[33], cvar_ze_hpmult, cvar_vip_deco, cvar_vip_money
new g_team_score[3], g_class_count, g_RoundStatus, Float:g_flButtonUse, g_iVipUser[33], Float:g_SupplyRadarInterval
new g_EndRound, g_NewRound, g_RoundTime, g_firstspawn, g_Countdown, cvar_force_vip, cvar_light, cvar_unlock_allskin, cvar_unlock_wpn, cvar_testing, g_Virus, Float:g_flLastAnnounce, g_Release
new g_zombie[33], g_nightvision[33], Float:g_oldmaxspeed[33], g_nextclass[33], g_zombieclass[33], g_respawnzb[33], g_choosedzb[33], g_fastbuy[33]
new g_rage[2][33], g_choosedhr[33], g_iHero[33], g_iKarma[2][33], Float:flHpRegenTime[33], Float:g_vLastDeathOrigin[33][3], Float:g_vLastOrigin[33][3]
new Float:g_flLastLucky[33], g_morale[33], g_iSparkPoint[33], g_iAutoBuy[33], g_iAdvanRandom[33], g_iDecodingCount[2][33],g_iTraceDmg[33], g_iHasItem[33], g_iHasBuy[33]

// round status
enum
{
	ROUND_WARMUP,
	ROUND_NEW,
	ROUND_COUNTDOWN,
	ROUND_RUNNING,
	ROUND_ENDING
}

enum
{
	RAGE_STAT,
	RAGE_LEVEL
}

// V 1.5 EXTRA ITEMS
new c_extraitem_cost[] = {18000, 14000, 10000, 10000, 12000}
new szExtraItemName[][] = { "Classic Weapon Extra Damage", "HE Grenade Extra Damage","Extra Ammo", "Frost Grenade", "Vaccine Grenade" }
new szExtraItemSysName[][] = { "damage", "hedmg", "extraammo", "frostnade", "vacnade" }
enum
{
	EXTRAITEM_DAMAGE,
	EXTRAITEM_HEDMG,
	EXTRAITEM_AMMO,
	EXTRAITEM_FROST,
	EXTRAITEM_VACCINE
}

new const zombie_attack_sound[3][] = { "zombi/zombi_attack_1.wav ", "zombi/zombi_attack_2.wav", "zombi/zombi_attack_3.wav" }
new const zombie_wall_sound[3][] = { "zombi/zombi_wall_1.wav ", "zombi/zombi_wall_2.wav", "zombi/zombi_wall_3.wav" }
new const zombie_swing_sound[3][] = { "zombi/zombi_swing_1.wav ", "zombi/zombi_swing_2.wav", "zombi/zombi_swing_3.wav" }
new const zombie_pain_sound[2][] = { "zombi/zombie_pain1.wav ", "zombi/zombie_pain2.wav"  }
new const zombie_die_sound[2][] = { "zombi/zombie_die1.wav ", "zombi/zombie_die2.wav" }

new const human_infected[2][] = { "zombi/human_death_01.wav", "zombi/human_death_02.wav" }
new const human_infected_female[2][] = { "zombi/human_death_female_01.wav", "zombi/human_death_female_02.wav" }
new const ZBombBounceSound[] = "zombi/zombi_bomb_bounce_1.wav"

new const szStationary[][] = { "func_tank" , "func_tankrocket" , "func_tankmortar" , "func_tanklaser" }

// zclass array
new Array:c_zombie_model, Array:c_zombie_name, Array:c_zombie_gravity, Array:c_zombie_maxspeed
new Array:c_zombie_claws, Array:c_zombie_knockback,Array:c_zombie_usemodelindex, Array:c_zombie_level, Array:c_zombie_zbomb
new Array:c_zombie_disablesound, Array:c_zombie_sysname

// zombie skin system
new Array:ZSkinAddons
enum _:SkinData
{
	SkinData_sysname[32],
	SkinData_name[64],
	SkinData_Model[64],
	SkinData_ClawModel[64]
}
new g_iHasSkin[33], g_iUsedSkin[33]

// default zombie skill var
new g_DefZombie, Float:g_flFastrunTime[33], g_iFastrunStat[33], Float:g_flHealTime[33], g_iHealStat[33]

// weapon renewal
new Array:PrimWPN, Array:SecWPN, Array:MeleeWPN, Array:NadeWPN, g_iHasWpn[4][33], g_iDecoder[33], g_iManualDecoding[33], Float:g_flLastDecoding[33]
enum _:WpnData
{
	WpnData_Class[32],
	WpnData_Grade
}
enum
{
	WPNGRADE_NORMAL,
	WPNGRADE_UNIQUE,
	WPNGRADE_PREMIUM
}
new const szGradeName[][] = { "Normal" , "\yUnique" , "\rPremium" }

// Balancing Round prevent to be hero or zombies continuesly
new g_iBalance[2][33]
enum
{
	BALANCE_ISZOMBIE,
	BALANCE_ISHERO
}

//supply box
new g_SupplySpawnExist, Float:g_flSupplyTime, g_SupplySpawn
new const szSupplyModel[2][] = { "models/zbz/supplybox_child.mdl" , "models/zbz/box_renewal01.mdl" }
new const szSupplyPickupSound[] = "zombi/supply_pickup.wav"
enum
{
	SUPPLY_NORMAL,
	SUPPLY_EXCLUSIVE
}
// human skill
enum _:SKILL
{
	SKILL_SPRINT,
	SKILL_DEADLYSHOT
}
new const szSkillStat[3][] = { "Used", "Ready", "Activated" }
new g_iUsedSkill[2][33], Float:g_flSkillTime[2][33], Float:g_flOldMaxSpeed[33];

// forward handle
new g_iForward[9], g_iNadeForward[2], fwResult

native pl_set_game_random_class(on)
native cs_zb_is_defending(id)

public plugin_precache()
{
	PrimWPN = ArrayCreate(WpnData)
	SecWPN = ArrayCreate(WpnData)
	MeleeWPN = ArrayCreate(WpnData)
	NadeWPN = ArrayCreate(WpnData)
	AutoItem = ArrayCreate(64, 1)
	
	ZSkinAddons  = ArrayCreate(SkinData)
	
	c_objective_ents = ArrayCreate(64, 1)
	c_skynames = ArrayCreate(64, 1)
	
	c_zombie_sysname = ArrayCreate(32, 1)
	c_zombie_model = ArrayCreate(128, 1)
	c_zombie_claws = ArrayCreate(128, 1)
	c_zombie_zbomb = ArrayCreate(128, 1)
	c_zombie_name = ArrayCreate(64, 1)
	
	c_zombie_gravity = ArrayCreate(1, 1)
	c_zombie_maxspeed = ArrayCreate(1, 1)
	c_zombie_knockback = ArrayCreate(1, 1)
	c_zombie_usemodelindex = ArrayCreate(1, 1)
	c_zombie_level = ArrayCreate(1, 1)
	c_zombie_disablesound = ArrayCreate(1, 1)
	
	engfunc(EngFunc_PrecacheModel, "models/zbz/p_zombibomb.mdl");
	engfunc(EngFunc_PrecacheModel, FROGBOMB_MODEL);
	engfunc(EngFunc_PrecacheModel, "sprites/zombiebomb_exp.spr");
	
	engfunc(EngFunc_PrecacheSound, ZBombBounceSound);
	
	engfunc(EngFunc_PrecacheSound, "zombi/zombi_bomb_exp.wav")
	engfunc(EngFunc_PrecacheSound, "zombi/zombi_pressure.wav")
	
	for(new i = 0; i<2; i++)
	{
		engfunc(EngFunc_PrecacheSound, human_infected[i])
		engfunc(EngFunc_PrecacheSound, human_infected_female[i])
		engfunc(EngFunc_PrecacheModel, szSupplyModel[i])
	}
	for(new i = 0; i<3; i++)
	{
		engfunc(EngFunc_PrecacheSound, zombie_attack_sound[i])
		engfunc(EngFunc_PrecacheSound, zombie_wall_sound[i])
		engfunc(EngFunc_PrecacheSound, zombie_swing_sound[i])
	}
	for(new i = 0; i<2; i++)
	{
		engfunc(EngFunc_PrecacheSound, zombie_pain_sound[i])
		engfunc(EngFunc_PrecacheSound, zombie_die_sound[i])
	}
	
	engfunc(EngFunc_PrecacheModel, "sprites/zombiheal_head.spr");
	engfunc(EngFunc_PrecacheModel, "sprites/e_button01.spr");
	engfunc(EngFunc_PrecacheModel, "sprites/icon_supplybox.spr");
	engfunc(EngFunc_PrecacheModel, "sprites/icon_supplybox2.spr");
	engfunc(EngFunc_PrecacheModel, "sprites/zb_hero.spr");
	engfunc(EngFunc_PrecacheModel, "sprites/gas_puff_01.spr");
	
	engfunc(EngFunc_PrecacheSound, szSupplyPickupSound);
	engfunc(EngFunc_PrecacheSound, "player/heartbeat2.wav");
	
	engfunc(EngFunc_PrecacheSound, "gachapon/open_weapon_item_top.wav")
	engfunc(EngFunc_PrecacheSound, "gachapon/open_weapon_item_top_sss.wav")
	
	engfunc(EngFunc_PrecacheGeneric, "sound/music/combat/startround_02.mp3")
	
	engfunc(EngFunc_PrecacheSound, "zombi/z4_zombi_comeback.wav")
	engfunc(EngFunc_PrecacheSound, "zombi/z4_zombi_coming_1.wav")
	engfunc(EngFunc_PrecacheSound, "zombi/z4_zombi_coming_2.wav")

	load_extraitems()
	load_config()
	load_spawns()
	g_SupplySpawnExist = load_supply_spawn();
	
	// Set a random skybox?
	if (c_sky_enable)
	{
		new sky[32]
		ArrayGetString(c_skynames, random_num(0, ArraySize(c_skynames) - 1), sky, charsmax(sky))
		set_cvar_string("sv_skyname", sky)
	}
	
	new ent
	if (c_ambience_fog)
	{
		ent = engfunc(EngFunc_CreateNamedEntity, engfunc(EngFunc_AllocString, "env_fog"))
		if (pev_valid(ent))
		{
			fm_set_kvd(ent, "density", c_fog_density, "env_fog")
			fm_set_kvd(ent, "rendercolor", c_fog_color, "env_fog")
		}
	}
	if (c_ambience_rain) engfunc(EngFunc_CreateNamedEntity, engfunc(EngFunc_AllocString, "env_rain"))
	if (c_ambience_snow) engfunc(EngFunc_CreateNamedEntity, engfunc(EngFunc_AllocString, "env_snow"))
	
	if(block_buy)
	{
		fm_remove_entity_name("func_buyzone")
		engfunc(EngFunc_CreateNamedEntity, engfunc(EngFunc_AllocString, "func_buyzone"));
	}
	
	if(c_escape_mode)
	{
		AnalyzeEscapeBreakable()
		AnalyzeEscapeTriggerHurt()
	}
	g_fwSpawn = register_forward(FM_Spawn, "fw_Spawn")
	
	engfunc(EngFunc_PrecacheModel, "models/player/zbz_tank/zbz_tank.mdl")
	engfunc(EngFunc_PrecacheModel, "models/zbz/v_knife_tank.mdl")
	engfunc(EngFunc_PrecacheModel, "models/zbz/v_zombibomb_tank.mdl")
}

public plugin_init() 
{
	register_plugin("Zombie The Hero Z(Limited)", MOD_VERSION, "csbtedhan")
	
	register_event("HLTV", "event_round_freeze", "a", "1=0", "2=0")
	register_logevent("event_newRound", 2, "1=Round_Start")
	register_event("CurWeapon", "event_current_weapon", "be", "1=1")
	register_event("Damage", "OnDamage", "b", "2!0", "3=0", "4!0")	
	register_event("DeathMsg", "event_DeathMsg", "a")
	
	RegisterHam(Ham_TraceAttack, "player", "fw_TraceAttack")
	RegisterHam(Ham_TraceAttack, "player", "fw_TraceAttack_Post", 1)
	RegisterHam(Ham_Spawn, "player", "HamF_PlayerSpawn_Post", 1)
	RegisterHam(Ham_TakeDamage, "player", "HamF_TakeDamage")
	RegisterHam(Ham_Spawn, "func_buyzone", "HamF_BuyZoneSpawn")
	RegisterHam(Ham_Touch, "grenade", "fw_Grenade_Touch")
	RegisterHam(Ham_Think, "grenade", "fw_Grenade_Think")
	
	RegisterHam(Ham_TakeDamage, "func_breakable", "HamF_BreakableTakeDamage")
	RegisterHam(Ham_TakeDamage, "func_pushable", "HamF_BreakableTakeDamage")
	
	for(new x = 0; x < sizeof(szStationary); x ++ )
		RegisterHam(Ham_Use, szStationary[x], "fw_UseStationary")
	
	RegisterHam(Ham_Use, "func_button", "fw_UseButton")
	RegisterHam(Ham_Use, "func_rot_button", "fw_UseButton")
	
	register_forward(FM_PlayerPreThink, "fw_PlayerThink_Pre")
	register_forward(FM_PlayerPostThink, "fw_PlayerThink_Post")
	register_forward(FM_EmitSound, "fw_EmitSound")
	register_forward(FM_Touch, "fw_Touch")
	register_forward(FM_SetModel, "fw_SetModel");
	register_forward(FM_StartFrame, "fw_ServerFrame");
	register_forward(FM_GetGameDescription, "fw_GetGameDescription")
	
	register_message(get_user_msgid("TextMsg"), "message_TextMsg")
	register_message(get_user_msgid("NVGToggle"), "message_nvgtoggle")
	register_message(get_user_msgid("SendAudio"), "message_SendAudio")
	register_message(get_user_msgid("Health"), "Message_Health")
	register_message(get_user_msgid("Battery"), "Message_Armor")
	register_message(get_user_msgid("DeathMsg"), "Message_DeathMsg")
	
	// CVAR
	cvar_light = register_cvar("mp_zombie_light", "e")
	cvar_testing = register_cvar("mp_zombie_admin_testmode", "0")
	cvar_force_vip = register_cvar("mp_zombie_force_vip", "0")
	cvar_unlock_wpn = register_cvar("mp_zombie_unlock_wpngrade", "0")
	cvar_unlock_allskin = register_cvar("mp_zombie_unlock_allskins", "0")
	cvar_ze_hpmult = register_cvar("mp_zombie_escape_zombiehp_multi", "6.0")
	cvar_vip_deco = register_cvar("mp_zombie_vip_extra_decoder", "5")
	cvar_vip_money = register_cvar("mp_zombie_vip_extra_money", "2000")

	// Server Set Command
	server_cmd("mp_startmoney %i", c_minmoney)
	server_cmd("mp_round_infinite 1")
	server_cmd("sv_maxspeed 9999")
	if(block_buy) server_cmd("mp_buytime 0")
	
	// client command
	register_clcmd("chooseteam", "CmdClassMenu")
	register_clcmd("buyammo1", "ModMenu")
	register_clcmd("buyammo2", "ReOpenBuymenu")
	register_clcmd("cheer", "DecoderMenu")
	register_clcmd("kill", "clcmd_BlockCmd")
	register_clcmd("nightvision", "clcmd_nightvision_toggle")
	register_clcmd("say /modmenu", "ModMenu")
	register_clcmd("say_team /modmenu", "ModMenu")
	register_clcmd("say /help", "ModMenu")
	register_clcmd("say_team /help", "ModMenu")
	register_clcmd("say /karma", "UseKarma");
	register_clcmd("say_team /karma", "UseKarma");
	register_clcmd("say /buy", "ReOpenBuymenu");
	register_clcmd("say_team /buy", "ReOpenBuymenu");
	register_clcmd("say /unstuck", "UnStuck");
	register_clcmd("say_team /unstuck", "UnStuck");
	register_clcmd("deadly", "clcmd_skillhumanskilldeadly")
	register_clcmd("sprint", "clcmd_skillhumanskillsprint")

	// test cmd
	register_concmd("zombieme", "SetUserZombie")
	register_concmd("herome", "SetUserHero")
	register_concmd("zombierage", "SetUserRageLevel")
	register_concmd("humanme", "SetUserHuman")
	register_concmd("giveguarantee", "SetUserGP")
	
	unregister_forward(FM_Spawn, g_fwSpawn)
	
	g_iForward[0] = CreateMultiForward("fw_CSZB_Infected", ET_IGNORE, FP_CELL, FP_CELL);
	g_iForward[1] = CreateMultiForward("fw_CSZB_Killed", ET_IGNORE, FP_CELL, FP_CELL);
	g_iForward[2] = CreateMultiForward("fw_CSZB_OnSpawn", ET_IGNORE, FP_CELL);
	g_iForward[3] = CreateMultiForward("fw_CSZB_OnStartRound", ET_IGNORE, FP_CELL);
	g_iForward[5] = CreateMultiForward("fw_CSZB_OnPreThink", ET_IGNORE, FP_CELL);
	g_iForward[6] = CreateMultiForward("fw_CSZB_OnPostThink", ET_IGNORE, FP_CELL);
	g_iForward[7] = CreateMultiForward("fw_CSZB_OnEquip", ET_IGNORE, FP_CELL);
	g_iForward[8] = CreateMultiForward("fw_CSZB_Infecting", ET_CONTINUE, FP_CELL,FP_CELL);
	g_iNadeForward[0] = CreateMultiForward("fw_CSZB_HumanNade_Pre", ET_CONTINUE, FP_CELL,FP_CELL);
	g_iNadeForward[1] = CreateMultiForward("fw_CSZB_HumanNade_Post", ET_IGNORE, FP_CELL,FP_CELL);
	
	//hud sync
	for(new x = 0; x < sizeof(g_hud_sync); x ++)
		g_hud_sync[x] = CreateHudSyncObj();
		
	for(new x = 0; x < sizeof(g_hud_plrsync); x ++)
		g_hud_plrsync[x] = CreateHudSyncObj();
	
	pl_set_game_random_class(1)
	
	g_DefZombie = RegDefaultClasses("Normal Zombie", "zbz_tank", "tank", 0.8, 270.0, 1.1, 1);
	
	register_dictionary("zombie3.txt")
}

public plugin_cfg()
{
	// Lighting task
	set_task(2.5, "lighting_effects")
	server_cmd("exec cfg/zombie3.cfg")
}
public plugin_natives()
{
	register_native("cs_zb_is_zombie", "natives_is_zombie", 1)
	register_native("cs_zb_is_using_nvgs", "natives_using_nvgs", 1)
	register_native("cs_zb_get_user_maxhealth", "natives_get_maxhealth", 1)
	register_native("cs_zb_get_zombie_class", "natives_get_zombie_class", 1)
	register_native("cs_zb_register_class", "natives_register_class", 1)
	register_native("cs_zb_get_user_hero", "natives_get_hero", 1)
	register_native("cs_zb_is_choosedzb", "natives_is_choosed", 1)
	register_native("cs_zb_set_user_choosed", "natives_set_user_choosed", 1)
	register_native("cs_zb_get_round_status", "natives_round_status", 1)
	register_native("cs_zb_set_user_unstuck", "natives_unstuck", 1)
	register_native("cs_zb_is_escape_mode", "natives_is_escape", 1)
}

//===============================
// Natives
//===============================
public natives_is_escape(index)
{
	return c_escape_mode
}
public natives_unstuck(index)
{
	if(!is_user_connected(index) || !is_user_alive(index)) return;
	
	SetUserUnstuck(index)
}
public natives_is_zombie(index)
{
	if(!is_user_connected(index)) return 0;
	
	return g_zombie[index];
}
public natives_get_hero(index)
{
	if(!is_user_connected(index) || g_zombie[index]) return 0;
	
	return g_iHero[index]
}
public natives_using_nvgs(index)
{
	return g_nightvision[index]
}

public natives_get_zombie_class(index)
{
	if(!is_user_connected(index) || !g_zombie[index]) return -1;
	
	return g_zombieclass[index];
}
public natives_get_maxhealth(index)
{
	if(!is_user_connected(index)) return 0;
	
	return GetMaxHealth(index)
}
public natives_register_class(const name[], const sysname[], const models[], const clawmodel[], Float:gravity, Float:maxspeed, Float:knockback, usemodelindex, level, disablesound)
{
	param_convert(1);
	param_convert(2);
	param_convert(3);
	param_convert(4);
	
	new filename[256]
	ArrayPushString(c_zombie_name, name);
	ArrayPushString(c_zombie_model, models);
	ArrayPushString(c_zombie_sysname, sysname);
	
	format(filename, charsmax(filename), "models/zbz/v_knife_%s.mdl", clawmodel);
	ArrayPushString(c_zombie_claws, filename);
	format(filename, charsmax(filename), "models/zbz/v_zombibomb_%s.mdl", clawmodel);
	ArrayPushString(c_zombie_zbomb, filename);
	
	ArrayPushCell(c_zombie_gravity, gravity);
	ArrayPushCell(c_zombie_maxspeed, maxspeed);
	ArrayPushCell(c_zombie_knockback, knockback);
	ArrayPushCell(c_zombie_usemodelindex, usemodelindex);
	ArrayPushCell(c_zombie_level, level);
	ArrayPushCell(c_zombie_disablesound, disablesound);
	
	g_class_count++
	return g_class_count - 1;
}
public natives_is_choosed(index)
{
	if(!is_user_connected(index) || !is_user_alive(index)) return 0;	
	
	return g_choosedzb[index]
}
public natives_set_user_choosed(index, iSet)
{
	if(!is_user_connected(index) || !is_user_alive(index)) return;	
	
	g_choosedzb[index] = iSet
}
public natives_round_status()
	return g_RoundStatus
//===============================
// Load Config
//===============================
public load_config()
{
	new cfg[64], path[128]
	get_mapname(cfg, charsmax(cfg))
	format(path, charsmax(path), "script/zombie3/%s.txt", cfg)
	
	if (!file_exists(path))
	{
		format(path, charsmax(path), "%s", (contain(cfg, "ze_") != -1) ? setting_escape_file : setting_file)
	}
	
	if (!file_exists(path))
	{
		new error[100]
		formatex(error, charsmax(error), "Cannot load customization file %s!", path)
		set_fail_state(error)
		return;
	}
	
	new linedata[1386], key[512], value[960], section, file, aWpnData[WpnData], valuedata[4][32], szMdl[256], aSkinData[SkinData], skindata[5][64]
	file = fopen(path, "rt")
	
	while (file && !feof(file))
	{
		fgets(file, linedata, charsmax(linedata))
		replace(linedata, charsmax(linedata), "^n", "")
		
		if (!linedata[0] || linedata[0] == ';') continue;
		if (linedata[0] == '[')
		{
			section++
			continue;
		}
		
		if(section != 3 && section != 4 && section != 5 && section != 6 && section != 10)
		{
			strtok(linedata, key, charsmax(key), value, charsmax(value), '=')
			trim(key)
			trim(value)
		}
		
		if(section == 1) // general
		{
			if(equal(key, "zombie_respawn_time")) c_respawntime = str_to_float(value)
			else if(equal(key, "minimum_money")) c_minmoney = str_to_num(value)
			else if(equal(key, "countdown")) c_countdown = str_to_num(value)
			else if(equal(key, "escape_mode")) c_escape_mode = str_to_num(value)
			else if(equal(key, "virus_time")) c_virus_time = str_to_num(value)
			else if(equal(key, "instant_infection")) c_instant_infect = str_to_num(value)
			else if(equal(key, "round_time")) c_roundtime = str_to_num(value) * 60
			else if(equal(key, "human_gravity")) c_human_gravity = str_to_float(value)
			else if(equal(key, "human_health")) c_human_health = str_to_num(value)
			else if(equal(key, "human_armor")) c_human_armor = str_to_num(value)
			else if(equal(key, "round_time")) c_roundtime = str_to_num(value) * 60
			else if(equal(key, "zombie_ratio")) c_zombie_ratio = str_to_float(value)
			else if(equal(key, "money_damage_rate")) c_moneydamage_rate = str_to_float(value)
			else if(equal(key, "zombie_armor")) c_zombie_armor = str_to_num(value)
			else if(equal(key, "zombie_health_infected")) c_zombie_health[0] = str_to_num(value)
			else if(equal(key, "zombie_health_host")) c_zombie_health[1] = str_to_num(value)
			else if(equal(key, "zombie_health_evolution")) c_zombie_health[2] = str_to_num(value)
		}
		if(section == 2) // equip system
		{
			if (equal(key, "block_buy")) block_buy = str_to_num(value)
			else if (equal(key, "strip_weapon")) c_strip_weapon = str_to_num(value)
			else if (equal(key, "refill_ammo")) c_refill_ammo = str_to_num(value)
			else if(equal(key, "additional_equipment"))
			{
				while (value[0] != 0 && strtok(value, key, charsmax(key), value, charsmax(value), ','))
				{
					trim(key)
					trim(value)
					ArrayPushString(AutoItem, key)
				}
			}
		}
		else if(section == 3) // prim weapon
		{
			parse(linedata, valuedata[0], 31, valuedata[1], 31);
			format(aWpnData[WpnData_Class], 31, "weapon_%s", valuedata[0])
			aWpnData[WpnData_Grade] = str_to_num(valuedata[1]);
			
			ArrayPushArray(PrimWPN, aWpnData);
		}
		else if(section == 4) // sec weapon
		{
			parse(linedata, valuedata[0], 31, valuedata[1], 31);
			format(aWpnData[WpnData_Class], 31, "weapon_%s", valuedata[0])
			aWpnData[WpnData_Grade] = str_to_num(valuedata[1]);
			
			ArrayPushArray(SecWPN, aWpnData);
		}
		else if(section == 5) // melee weapon
		{
			parse(linedata, valuedata[0], 31, valuedata[1], 31);
			format(aWpnData[WpnData_Class], 31, "weapon_%s", valuedata[0])
			aWpnData[WpnData_Grade] = str_to_num(valuedata[1]);
			
			ArrayPushArray(MeleeWPN, aWpnData);
		}
		else if(section == 6) // nade weapon
		{
			parse(linedata, valuedata[0], 31, valuedata[1], 31);
			format(aWpnData[WpnData_Class], 31, "weapon_%s", valuedata[0])
			aWpnData[WpnData_Grade] = str_to_num(valuedata[1]);
			
			ArrayPushArray(NadeWPN, aWpnData);
		}
		else if(section == 7) // hero
		{
			if(equal(key, "hero_enable")) c_enable_hero = str_to_num(value)
			else if(equal(key, "hero_model")) format(c_hero_model, 31, "%s", value);
			
			format(szMdl, charsmax(szMdl), "models/player/%s/%s.mdl", c_hero_model, c_hero_model)
			if(file_exists(szMdl)) engfunc(EngFunc_PrecacheModel, szMdl);
		}
		else if(section == 8) // supplybox
		{
			if(equal(key, "supplybox_max")) c_supply_max =  str_to_num(value)
			else if(equal(key, "supplybox_time")) c_supply_time = str_to_float(value)
		}
		else if(section == 9) // decoder
		{
			if(equal(key, "decoder_cost")) c_decoder_cost =  str_to_num(value)
			else if(equal(key, "decoder_reward_newround")) c_decoder_given[0] = str_to_num(value)
			else if(equal(key, "decoder_reward_supplynormal")) c_decoder_given[1] = str_to_num(value)
			else if(equal(key, "decoder_reward_supplyexclusive")) c_decoder_given[2] = str_to_num(value)
			else if(equal(key, "decoder_rate_chance")) c_decoder_chance = str_to_float(value)
			else if(equal(key, "decoder_rate_unique")) c_decoder_rate[0] = str_to_float(value)
			else if(equal(key, "decoder_rate_premium")) c_decoder_rate[1] = str_to_float(value)
			else if(equal(key, "decoder_unique_guaranted")) c_decoder_guarantee[0] = str_to_num(value)
			else if(equal(key, "decoder_premium_guaranted")) c_decoder_guarantee[1] = str_to_num(value)
		}
		else if(section == 10) // zombie skin
		{
			parse(linedata, skindata[0], 63, skindata[1], 63, skindata[2], 63, skindata[3], 63);
			copy(aSkinData[SkinData_name], 63, skindata[0])
			copy(aSkinData[SkinData_sysname], 31, skindata[1])
			copy(aSkinData[SkinData_Model], 63, skindata[2])
			copy(aSkinData[SkinData_ClawModel], 63, skindata[3])
			
			format(szMdl, charsmax(szMdl), "models/player/%s/%s.mdl", skindata[2], skindata[2])
			engfunc(EngFunc_PrecacheModel, szMdl);
			format(szMdl, charsmax(szMdl), "models/zbz/v_knife_%s.mdl", skindata[3])
			engfunc(EngFunc_PrecacheModel, szMdl);
			format(szMdl, charsmax(szMdl), "models/zbz/v_zombibomb_%s.mdl", skindata[3])
			engfunc(EngFunc_PrecacheModel, szMdl);
			ArrayPushArray(ZSkinAddons, aSkinData);
		}
		else if(section == 11) // zombie bomb
		{
			if(equal(key, "zombie_bomb_radius")) c_zbomb_radius =  str_to_float(value)
			else if(equal(key, "zombie_bomb_damage")) c_zbomb_damage =  str_to_float(value)
			else if(equal(key, "zombie_bomb_knockback")) c_zbomb_knockback =  str_to_float(value)
		}
		else if(section == 12) // music
		{
			if(equal(key, "music_round_start")) format(c_music_start, charsmax(c_music_start), "%s", value)
			else if(equal(key, "music_round_appear")) format(c_music_appear, charsmax(c_music_appear), "%s", value)
			
			format(szMdl, 255, "sound/%s", c_music_start)
			if(file_exists(szMdl)) engfunc(EngFunc_PrecacheGeneric, szMdl)
			format(szMdl, 255, "sound/%s", c_music_appear)
			if(file_exists(szMdl)) engfunc(EngFunc_PrecacheGeneric, szMdl)		
			
		}
		else if(section == 13) // wheater
		{
			if (equal(key, "rain"))
				c_ambience_rain = str_to_num(value)
			else if (equal(key, "snow"))
				c_ambience_snow = str_to_num(value)
			else if (equal(key, "fog"))
				c_ambience_fog = str_to_num(value)
			else if (equal(key, "fog_density"))
				copy(c_fog_density, charsmax(c_fog_density), value)
			else if (equal(key, "fog_color"))
				copy(c_fog_color, charsmax(c_fog_color), value)
		}
		
		else if(section == 14) // sky
		{
			if (equal(key, "custom_sky"))
				c_sky_enable = str_to_num(value)
			else if (equal(key, "sky_names"))
			{
				// Parse sky names
				while (value[0] != 0 && strtok(value, key, charsmax(key), value, charsmax(value), ','))
				{
					// Trim spaces
					trim(key)
					trim(value)
						
					// Add to skies array
					ArrayPushString(c_skynames, key)
						
					// Preache custom sky files
					formatex(linedata, charsmax(linedata), "gfx/env/%sbk.tga", key)
					engfunc(EngFunc_PrecacheGeneric, linedata)
					formatex(linedata, charsmax(linedata), "gfx/env/%sdn.tga", key)
					engfunc(EngFunc_PrecacheGeneric, linedata)
					formatex(linedata, charsmax(linedata), "gfx/env/%sft.tga", key)
					engfunc(EngFunc_PrecacheGeneric, linedata)
					formatex(linedata, charsmax(linedata), "gfx/env/%slf.tga", key)
					engfunc(EngFunc_PrecacheGeneric, linedata)
					formatex(linedata, charsmax(linedata), "gfx/env/%srt.tga", key)
					engfunc(EngFunc_PrecacheGeneric, linedata)
					formatex(linedata, charsmax(linedata), "gfx/env/%sup.tga", key)
					engfunc(EngFunc_PrecacheGeneric, linedata)
				}
			}
		}
		else if(section == 15) // objective entity remover
		{
			if (equal(key, "removed_entity"))
			{
				while (value[0] != 0 && strtok(value, key, charsmax(key), value, charsmax(value), ','))
				{
					trim(key)
					trim(value)
					ArrayPushString(c_objective_ents, key)
				}
			}
		}
	}
	if (file) fclose(file)
}
public load_extraitems()
{
	new cfg[64], path[128]
	get_mapname(cfg, charsmax(cfg))
	format(path, charsmax(path), "script/zombie3/extra_items/%s.txt", cfg)
	
	if (!file_exists(path))
		return;
		
	new linedata[1386], section, file, aWpnData[WpnData], valuedata[4][32], szMdl[256], aSkinData[SkinData], skindata[5][64]
	file = fopen(path, "rt")
	
	while (file && !feof(file))
	{
		fgets(file, linedata, charsmax(linedata))
		replace(linedata, charsmax(linedata), "^n", "")
		
		if (!linedata[0] || linedata[0] == ';') continue;
		if (linedata[0] == '[')
		{
			section++
			continue;
		}
		
		if(section == 1) // prim weapon
		{
			parse(linedata, valuedata[0], 31, valuedata[1], 31);
			format(aWpnData[WpnData_Class], 31, "weapon_%s", valuedata[0])
			aWpnData[WpnData_Grade] = str_to_num(valuedata[1]);
			
			ArrayPushArray(PrimWPN, aWpnData);
		}
		else if(section == 2) // sec weapon
		{
			parse(linedata, valuedata[0], 31, valuedata[1], 31);
			format(aWpnData[WpnData_Class], 31, "weapon_%s", valuedata[0])
			aWpnData[WpnData_Grade] = str_to_num(valuedata[1]);
			
			ArrayPushArray(SecWPN, aWpnData);
		}
		else if(section == 3) // melee weapon
		{
			parse(linedata, valuedata[0], 31, valuedata[1], 31);
			format(aWpnData[WpnData_Class], 31, "weapon_%s", valuedata[0])
			aWpnData[WpnData_Grade] = str_to_num(valuedata[1]);
			
			ArrayPushArray(MeleeWPN, aWpnData);
		}
		else if(section == 4) // nade weapon
		{
			parse(linedata, valuedata[0], 31, valuedata[1], 31);
			format(aWpnData[WpnData_Class], 31, "weapon_%s", valuedata[0])
			aWpnData[WpnData_Grade] = str_to_num(valuedata[1]);
			
			ArrayPushArray(NadeWPN, aWpnData);
		}
		else if(section == 5) // zombie skin
		{
			parse(linedata, skindata[0], 63, skindata[1], 63, skindata[2], 63, skindata[3], 63);
			copy(aSkinData[SkinData_name], 63, skindata[0])
			copy(aSkinData[SkinData_sysname], 31, skindata[1])
			copy(aSkinData[SkinData_Model], 63, skindata[2])
			copy(aSkinData[SkinData_ClawModel], 63, skindata[3])
			
			format(szMdl, charsmax(szMdl), "models/player/%s/%s.mdl", skindata[2], skindata[2])
			engfunc(EngFunc_PrecacheModel, szMdl);
			format(szMdl, charsmax(szMdl), "models/zbz/v_knife_%s.mdl", skindata[3])
			engfunc(EngFunc_PrecacheModel, szMdl);
			format(szMdl, charsmax(szMdl), "models/zbz/v_zombibomb_%s.mdl", skindata[3])
			engfunc(EngFunc_PrecacheModel, szMdl);
			ArrayPushArray(ZSkinAddons, aSkinData);
		}
	}
	if (file) fclose(file)
}
//===============================
// Client management
//===============================
public client_putinserver(id)
{
	if(!Debug && is_user_bot(id) && get_cvar_num("bot_quota"))
	{
		set_task(0.1, "RegHamBots", id)
	}
	
	g_zombie[id] = 0
	g_iHero[id] = 0;
	g_iUsedSkill[0][id] = 0;
	g_iUsedSkill[1][id] = 0;
	g_iDecoder[id] = 0;
	g_iBalance[0][id] = 0;
	g_iBalance[1][id] = 0;
	g_choosedhr[id] = 0;
	g_iHasWpn[0][id] = 0;
	g_iHasWpn[1][id] = 0;
	g_iHasWpn[2][id] = 0;
	g_iHasWpn[3][id] = 0;
	g_iHasSkin[id] = 0;
	g_iUsedSkin[id] = 0;
	g_iKarma[0][id] = 0;
	g_iKarma[1][id] = 0;
	g_rebuy[id][0] = -1;
	g_rebuy[id][1] = -1;
	g_rebuy[id][2] = -1;
	g_rebuy[id][3] = -1;
	g_iManualDecoding[id] = 0;
	g_fastbuy[id] = 0;
	g_vLastDeathOrigin[id] = Float:{0.0, 0.0, 0.0}
	g_iVipUser[id] = 0;
	g_iAutoBuy[id] = 0;
	g_iSparkPoint[id] = 0;
	g_iAdvanRandom[id] = 0;
	g_iDecodingCount[0][id] = 0;
	g_iDecodingCount[1][id] = 0;
	g_iTraceDmg[id] = 0;
	g_iHasItem[id] = 0;
	g_iHasBuy[id] = 0;

	CheckSelectedWeapon(id)
	
	if(get_user_flags(id) & ADMIN_LEVEL_E || get_pcvar_num(cvar_force_vip))
		g_iVipUser[id] = 1;
		
	set_task(10.0, "task_welcome", id+TASK_WELCOME)
}
public RegHamBots(id)
{
	if(Debug)return;
	
	RegisterHamFromEntity(Ham_Spawn, id, "HamF_PlayerSpawn_Post", 1)
	RegisterHamFromEntity(Ham_TakeDamage, id, "HamF_TakeDamage")
	RegisterHamFromEntity(Ham_TraceAttack, id, "fw_TraceAttack")
	RegisterHamFromEntity(Ham_TraceAttack, id, "fw_TraceAttack_Post", 1)
	
	Debug = 1
}

public client_disconnected(id)
{	
	g_zombie[id] = 0
	g_iHero[id] = 0;
	g_iDecoder[id] = 0;
	g_iUsedSkill[0][id] = 0;
	g_iUsedSkill[1][id] = 0;
	g_iBalance[0][id] = 0;
	g_iBalance[1][id] = 0;
	g_choosedhr[id] = 0;
	g_iHasWpn[0][id] = 0;
	g_iHasWpn[1][id] = 0;
	g_iHasWpn[2][id] = 0;
	g_iHasWpn[3][id] = 0;
	g_iHasSkin[id] = 0;
	g_iUsedSkin[id] = 0;
	g_iKarma[0][id] = 0;
	g_iKarma[1][id] = 0;
	g_rebuy[id][0] = -1;
	g_rebuy[id][1] = -1;
	g_rebuy[id][2] = -1;
	g_rebuy[id][3] = -1;
	g_iAutoBuy[id] = 0;
	g_iManualDecoding[id] = 0;
	g_fastbuy[id] = 0;
	g_vLastDeathOrigin[id] = Float:{0.0, 0.0, 0.0}
	g_iVipUser[id] = 0;
	g_iSparkPoint[id] = 0;
	g_iAdvanRandom[id] = 0;
	g_iDecodingCount[0][id] = 0;
	g_iDecodingCount[1][id] = 0;
	g_iTraceDmg[id] = 0;
	g_iHasItem[id] = 0;
	g_iHasBuy[id] = 0;

	if(g_RoundStatus == ROUND_RUNNING)
		Check_Force_EndRound()
	
	remove_task(id+TASK_RANDOM_WEAPON)
	remove_task(id+TASK_RESPAWN)
	
	if(!task_exists(TASK_AFTERDISCONNECT))
		set_task(0.5, "task_afterdisconnect", TASK_AFTERDISCONNECT)
}

public client_command(id)
{
	new cmd[32]
	if (read_argv(0, cmd, 31) > 30) return PLUGIN_CONTINUE 
	if (block_buy)
	{
		new a = 0 
		do {
			if (equali(g_Aliases[a], cmd) || equali(g_Aliases2[a], cmd)) return PLUGIN_HANDLED
		} while(++a < MAXMENUPOS)
	}
	
	if(g_zombie[id])
	{
		if(equal(cmd, "drop") && g_zombieclass[id] == g_DefZombie && g_iFastrunStat[id] == 0 && g_flFastrunTime[id] <= get_gametime())
		{
			g_iFastrunStat[id] = 1
			set_pdata_int(id, 363, 110);
			set_pev(id, pev_maxspeed, 450.0);
			set_rendering(id, kRenderFxGlowShell, 255, 0, 0);
			engfunc(EngFunc_EmitSound, id, CHAN_VOICE, "zombi/zombi_pressure.wav", 1.0, 0.8, 0, 100);
			g_flFastrunTime[id] = get_gametime() + 8.0;
		}
		
	} else {
		if(equal(cmd, "cl_autobuy") || equal(cmd, "autobuy"))
		{
			clcmd_skillhumanskilldeadly(id)
			return 1;
		}
		else if(equal(cmd, "cl_rebuy") || equal(cmd, "rebuy"))
		{
			clcmd_skillhumanskillsprint(id)
			return 1;
		}
	}
	return PLUGIN_CONTINUE 
} 

//====================================
// Message
//====================================

public message_TextMsg()
{
	static textmsg[22]
	get_msg_arg_string(2, textmsg, charsmax(textmsg))
	
	// block message
	if (equal(textmsg, "#Game_will_restart_in"))
	{
		return PLUGIN_HANDLED;
	}
	else if (equal(textmsg, "#Hostages_Not_Rescued") || equal(textmsg, "#Round_Draw") || equal(textmsg, "#Terrorists_Win") || equal(textmsg, "#CTs_Win"))
	{
		return PLUGIN_HANDLED;
	}
	
	if(get_msg_args() == 5)
	{
		if(get_msg_argtype(5) == ARG_STRING)
		{
			new value5[64];
			get_msg_arg_string(5 ,value5 ,63);
			
			for(new x=0; x<sizeof(szBlockRadioMessage); x++)
			{
				if(equal(value5, szBlockRadioMessage[x]))
					return PLUGIN_HANDLED;
			}
		}
	} else if(get_msg_args() == 6) {
		if(get_msg_argtype(6) == ARG_STRING)
		{
			new value5[64];
			get_msg_arg_string(6 ,value5 ,63);
			
			for(new x=0; x<sizeof(szBlockRadioMessage); x++)
			{
				if(equal(value5, szBlockRadioMessage[x]))
					return PLUGIN_HANDLED;
			}
		}
	}
	
	return PLUGIN_CONTINUE;
}

public message_nvgtoggle(msg_id, msg_dest, msg_entity)
	return PLUGIN_HANDLED;

public message_SendAudio(msg_id, msg_dest, msg_entity)
{
	static audio[17]
	get_msg_arg_string(2, audio, charsmax(audio))
	
	if(equal(audio[7], "terwin") || equal(audio[7], "ctwin") || equal(audio[7], "rounddraw") || equal(audio[7], "rescued"))
		return PLUGIN_HANDLED;
		
	if(equal(audio[7], "woman/terwin") || equal(audio[7], "woman/ctwin") || equal(audio[7], "woman/rounddraw") || equal(audio[7], "woman/rescued"))
		return PLUGIN_HANDLED;
		
	return PLUGIN_CONTINUE;
}

public Message_Health(msg_id, msg_dest, id)
{
	// Get player's health
	static health
	health = get_user_health(id)
	
	// Don't bother
	if(health < 1) 
		return
	
	static Float:NewHealth, RealHealth, Health
	
	NewHealth = (float(health) / float(GetMaxHealth(id))) * 100.0; 
	RealHealth = min(100, floatround(NewHealth))
	Health = clamp(RealHealth, 1, 255)
	
	set_msg_arg_int(1, get_msg_argtype(1), Health)
}


public Message_Armor(msg_id, msg_dest, id)
{
	// Get player's health
	static health
	health = floatround(float(get_user_armor(id)) * 0.1)
	
	// Don't bother
	if(health < 1) 
		return
	
	set_msg_arg_int(1, get_msg_argtype(1), clamp(health, 0, 999))
}
public OnDamage(id)
{
	new attacker = get_user_attacker(id)
	new Float:vOrigin[3]; pev(id, pev_origin, vOrigin)
	new Float:flHudPos[2]; GetHudLoc(attacker, vOrigin, flHudPos)
	
	if(is_user_connected(attacker) && is_in_viewcone(attacker, vOrigin, 1))
	{
		set_hudmessage(100, 100, 100, flHudPos[0], flHudPos[1], 0, 1.0, 1.0, 0.0, 0.5, 29)
		ShowSyncHudMsg(attacker, g_hud_plrsync[id], "%i", read_data(2))
	}
}
public Message_DeathMsg(msg_id, msg_dest)
{
	new killer = get_msg_arg_int(1)
	if(!is_user_connected(killer)) return;
	
	if(g_iUsedSkill[1][killer] == 2)
		set_msg_arg_int(3, get_msg_argtype(3), 1)
}
//====================================
// Event
//====================================
public event_round_freeze()
{
	if(!g_firstspawn) return
	
	g_EndRound = 0
	g_NewRound = 0
	g_SupplySpawn = 0
	g_Countdown = 0
	g_Release =0
	g_RoundStatus = ROUND_NEW
	
	client_cmd(0, "mp3 stop")
	
	g_RoundTime = get_cvar_num("mp_freezetime")
	play_sound(0, "music/combat/startround_02.mp3")
	
	server_cmd("sypb_gamemod 2")
	
	if(c_escape_mode) 
	{
		AnalyzeEscapeTriggerHurt()
		AnalyzeEscapeBreakable()
		server_cmd("mp_semiclip 1")
		server_cmd("sv_protection 0")
	} else {
		server_cmd("mp_semiclip 0")
		server_cmd("sv_protection 0")
	}
	
	remove_task(TASK_ROUNDTIME)
	task_round_time()
	
	for(new id = 0; id < get_maxplayers(); id ++ )
	{
		if(!is_user_connected(id)) continue;
		
		ExecuteForward(g_iForward[3], fwResult, id);
		
		cs_set_user_money(id, cs_get_user_money(id) + 1000);
		if(cs_get_user_money(id) < c_minmoney)
			cs_set_user_money(id, c_minmoney, 0);
		
		g_iDecoder[id] += c_decoder_given[0]
		SetMorale(id, 3, 0)
			
		g_iHasBuy[id] = 0;
		g_iUsedSkill[SKILL_SPRINT][id] = 1;
		g_iUsedSkill[SKILL_DEADLYSHOT][id] = 1;

		if(get_user_flags(id) & ADMIN_LEVEL_E || get_pcvar_num(cvar_force_vip)) 
		{
			g_iVipUser[id] = 1
			g_iDecoder[id] += get_pcvar_num(cvar_vip_deco)
			cs_set_user_money(id, cs_get_user_money(id) + get_pcvar_num(cvar_vip_money));
		}
		
		g_fastbuy[id] = 1;
		g_iAutoBuy[id] = 0;
		set_user_nvision(id, 0);
	}
	ResetValuePlayer()
	
	play_sound(0, "misc/cs_stinger.wav")
	send_center_text("Prepare to Fight !", 4.0, {168,204,238}, 0)
}

public event_newRound()
{
	if(!g_firstspawn) return
	
	g_EndRound = 0
	g_NewRound = 1
	g_RoundTime = c_roundtime
	
	remove_task(TASK_ROUNDTIME)
	
	InitializeMakeRandomZombie()
	if(random(100)<45) InitializeMakeRandomHero()
	
	g_RoundStatus = ROUND_COUNTDOWN
	
	g_Countdown = c_countdown+1
	task_round_time()
	
	play_sound(0, c_music_start)
	
	send_center_text(c_escape_mode ? "Run from those Zombies!" : "Prepare for Killing Zombies!", 4.0, {168,204,238}, 0)
}

public event_current_weapon(id)
{
	if(!is_user_alive(id) || !is_user_connected(id) || !g_zombie[id]) return PLUGIN_CONTINUE
	
	CheckZombieHand(id)
	
	return PLUGIN_CONTINUE
}
public event_DeathMsg()
{
	static id, victim, headshot, weapon[33]
	id = read_data(1)
	victim = read_data(2)
	headshot = read_data(3)
	read_data(4, weapon, charsmax(weapon))
		
	if(is_user_connected(victim))
	{
		ExecuteForward(g_iForward[1], fwResult, victim, id)
		
		set_user_nvision(victim, 0)
		g_nightvision[victim] = 0;
		
		pev(victim, pev_origin, g_vLastDeathOrigin[victim])
		
		static string[2]
		get_pcvar_string(cvar_light, string, sizeof(string))
		set_player_light(victim, string)
		if(is_user_connected(id))
		{
			static name[2][32], szText[128]
			get_user_name(id, name[0], 31)
			get_user_name(victim, name[1], 31);
		
			if(g_zombie[victim])
			{	
				if(g_iUsedSkill[SKILL_DEADLYSHOT][id] == 2) headshot = 1
				
				if(random(50) < 10)
				{
					g_iDecoder[id] ++
					colored_print(id, "!d[!gZombie The Hero!d] Obtain !g1x Decoder !dfor Killing")
				}
				g_flLastLucky[id] = get_gametime() + random_float(10.0, 30.0)
			
				if(headshot && g_Virus <= 0)
				{
					set_pev(id, pev_frags, pev(id, pev_frags) + 3.0)
					update_player_score(id)
					
					IncreaseHumanMorale()
					
					if(headshot && !c_escape_mode)
					{
						format(szText, 127, "A zombie %s has been killed by %s on head!", name[1], name[0]) 
						send_center_text(szText, 4.0, {168,204,238}, 0)
					}
					
					Check_Force_EndRound()
					
				} else {
					set_task(c_respawntime, "task_player_respawn", victim+TASK_RESPAWN)
						
					SetMorale(id, g_morale[id] + 1, 1)
					set_pev(id, pev_frags, pev(id, pev_frags) + 2.0)
					update_player_score(id)
				}
			} 
			
			if(victim == id || g_zombie[id])
			{
				if(victim != id && g_zombie[id])
				{
					if(random(50) < 10)
					{
						g_iDecoder[id] ++
						colored_print(id, "!d[!gZombie The Hero!d] Obtain !g1x Decoder !dfor Killing")
					}
					g_flLastLucky[id] = get_gametime() + random_float(10.0, 30.0)
				
					set_pev(id, pev_frags, pev(id, pev_frags) + 2.0)
					update_player_score(id)
					SetRage(id, 500);
				}

				g_iHero[victim] = 0;
				g_respawnzb[victim] = 1
				set_task(c_respawntime, "task_player_respawn", victim+TASK_RESPAWN)
				Check_Force_EndRound()
			}
		}
	}
	
	if(is_user_connected(victim) && !is_user_connected(id))
	{
		g_iHero[victim] = 0;
		if(c_escape_mode)
		{
			Check_Force_EndRound()
			if(g_RoundStatus == ROUND_RUNNING)
			{
				if(!g_zombie[victim]) 
				{
					g_rage[RAGE_LEVEL][victim] = 0
					g_respawnzb[victim] = 1
					set_task(c_respawntime, "task_player_respawn", victim+TASK_RESPAWN)
				}
			}
		} else {
			set_task(c_respawntime, "task_player_respawn", victim+TASK_RESPAWN)
			if(g_RoundStatus == ROUND_RUNNING && !g_zombie[victim]) 
			{	
				g_rage[RAGE_LEVEL][victim] = 0
				g_respawnzb[victim] = 1
				Check_Force_EndRound()
			}
		}
	}
}

//===============================
// Forward
//===============================
public fw_ServerFrame()
{
	SetSupplyBox()
}
public fw_Spawn(entity)
{
	// Invalid entity
	if (!pev_valid(entity)) return FMRES_IGNORED;
	
	// Get classname
	new classname[32], objective[32], size = ArraySize(c_objective_ents)
	pev(entity, pev_classname, classname, charsmax(classname))
	
	// Check whether it needs to be removed
	for (new i = 0; i < size; i++)
	{
		ArrayGetString(c_objective_ents, i, objective, charsmax(objective))
		
		if (equal(classname, objective))
		{
			engfunc(EngFunc_RemoveEntity, entity)
			return FMRES_SUPERCEDE;
		}
	}
	
	return FMRES_IGNORED;
}
public fw_SetModel(Ent , const Model[])
{
	if(!pev_valid(Ent)) 
		return FMRES_IGNORED
	static szClass[32], iTemp
	pev(Ent, pev_classname, szClass, 31);
	static id; id = pev(Ent, pev_owner)
	if(!pev_valid(id) || !equal(szClass, "grenade"))
		return FMRES_IGNORED;

	if(Model[7] == 'w' && Model[8] == '_' && Model[9] == 'h' && Model[10] == 'e')
	{
		if(g_zombie[id])
		{
			set_pev(Ent, pev_dmgtime, get_gametime() + 1.9);
			set_pev(Ent, pev_iuser4, 2003);
			engfunc(EngFunc_SetModel, Ent, FROGBOMB_MODEL);
			return FMRES_SUPERCEDE;
		} else {
			ExecuteForward(g_iNadeForward[0], fwResult, Ent, id)
			ExecuteForward(g_iNadeForward[1], iTemp, Ent, id)
			
			if(cs_get_user_bpammo(id, CSW_HEGRENADE) <= 1) cs_remove_item(id, -1, 3)
			if(fwResult > 0) return FMRES_SUPERCEDE;
		}
	}
	return FMRES_IGNORED;
}
public fw_Grenade_Think(Ent)
{
	if(!pev_valid(Ent)) 
		return HAM_IGNORED;
		
	if(get_gametime() < pev(Ent, pev_dmgtime))
		return HAM_IGNORED;
		
	if(pev(Ent, pev_iuser4) == 2003)
	{
		ZBombExplode(Ent)
		engfunc(EngFunc_RemoveEntity, Ent);
		return HAM_SUPERCEDE;
	}
	return HAM_IGNORED;
}

public fw_Grenade_Touch(Ent, iPtd)
{
	if(!pev_valid(Ent)) 
		return HAM_IGNORED;
		
	if(pev(Ent, pev_iuser4) == 2003)
	{
		if(fm_get_speed(Ent) > 150)
			emit_sound(Ent, CHAN_WEAPON, ZBombBounceSound, 1.0, 0.8, 0, random_num(94, 102))
		
	}
	return HAM_IGNORED;
}
public HamF_BuyZoneSpawn(iEnt)
{
	if(!pev_valid(iEnt) || !block_buy) return HAM_IGNORED;
	
	engfunc(EngFunc_RemoveEntity, iEnt)
	return HAM_SUPERCEDE;
}
public HamF_PlayerSpawn_Post(id)
{
	if(!is_user_alive(id)) return
	
	ExecuteForward(g_iForward[2], fwResult, id);
	
	pev(id, pev_origin, g_vLastDeathOrigin[id])

	g_iFastrunStat[id] = 0;	
	g_iHealStat[id] = 0;
	g_iHero[id] = 0;
	g_iTraceDmg[id] = 0;

	set_rendering(id)
	if(get_pdata_int(id, 363) > 90) set_pdata_int(id, 363, 90);
	
	if(!g_firstspawn && get_player_count() > 1)
	{
		client_print(0, print_center, "#Cstrike_TitlesTXT_Game_Commencing")
		g_firstspawn = 1
		server_cmd("sv_restart 3")
	}
	if(c_strip_weapon)
	{
		Stock_Drop_Slot(id, 1, 1)
		Stock_Drop_Slot(id, 2, 1)
		cs_remove_item(id, -1, 2);
		Stock_Drop_Slot(id, 4, 1)
		engclient_cmd(id, "weapon_knife")
		if(!g_zombie[id] && get_user_weapon(id) == CSW_KNIFE)
		{
			set_pev(id,pev_weaponmodel2,"models/p_knife.mdl")
			set_pev(id,pev_viewmodel2,"models/v_knife.mdl")
		}
	}
	
	g_nightvision[id] = 0
	set_user_nvision(id, 0)
		
	if(!g_oldmaxspeed[id]) 
		g_oldmaxspeed[id] = entity_get_float(id, EV_FL_maxspeed)
		
	if(!g_zombie[id] && !(g_respawnzb[id] && g_RoundStatus == ROUND_RUNNING))
	{
		pl_set_user_sound(id, 0)
		rg_set_user_team(id, TEAM_CT)
		pl_reset_user_model(id)
		set_pev(id, pev_gravity, c_human_gravity)
		
		CheckSelectedWeapon(id)
		
		set_rendering(id, kRenderFxGlowShell, GetMoraleColor(g_morale[id], 0), GetMoraleColor(g_morale[id], 1), GetMoraleColor(g_morale[id], 2), kRenderNormal)
		
		cs_set_user_armor(id, c_human_armor, CS_ARMOR_VESTHELM)
		if(pev(id, pev_health) < float(c_human_health)) set_pev(id, pev_health, float(c_human_health))
		
		if(!is_user_bot(id)) BuyMenu(id, 1)
		else set_task(random_float(0.5, 1.5), "task_random_weapon", id+TASK_RANDOM_WEAPON)
	
	} else {
		rg_set_user_team(id, TEAM_TERRORIST)
		pl_set_user_sound(id, 1)
		
		Stock_Drop_Slot(id, 1, 1)
		Stock_Drop_Slot(id, 2, 1)
		Stock_Drop_Slot(id, 4, 1)
		Stock_Drop_Slot(id, 5, 1)
		fm_give_item(id, "weapon_hegrenade")
		engclient_cmd(id, "weapon_knife")
		
		play_message_sound(0, "zombi/z4_zombi_comeback.wav")
		
		if(g_zombieclass[id] != g_nextclass[id])
		{
			g_zombieclass[id] = g_nextclass[id]
			SetZombieModel(id, g_zombieclass[id])
		}
		new Float:hp = float(c_zombie_health[g_rage[RAGE_LEVEL][id]])
		cs_set_user_armor(id, c_zombie_armor, CS_ARMOR_KEVLAR)
		entity_set_float(id, EV_FL_health, hp)
		set_pev(id, pev_gravity, ArrayGetCell(c_zombie_gravity, g_zombieclass[id]))
		set_pev(id, pev_maxspeed, ArrayGetCell(c_zombie_maxspeed, g_zombieclass[id]))
	}
	
	if((g_respawnzb[id] && !g_zombie[id] && g_RoundStatus == ROUND_RUNNING) || (g_choosedzb[id] && g_RoundStatus == ROUND_RUNNING && !g_zombie[id]))
	{
		ExecuteForward(g_iForward[0], fwResult, id, 0);
		MakeZombie(id)
		Check_Force_EndRound()
	}
	if(!c_escape_mode)
	{
		do_random_spawn(id)
	} else {
		if(g_zombie[id])
		{
			set_pev(id, pev_origin, g_vLastDeathOrigin[id])
			SetUserUnstuck(id)
		}
	}
	
	play_sound(id, "player/pl_respawn.wav")
}

public HamF_TakeDamage(victim, inflictor, attacker, Float:flDamage, dmgbits)
{
	if(!is_user_connected(victim) || !is_user_connected(attacker)) 
		return HAM_IGNORED;
	
	new iTrace = g_iTraceDmg[attacker]
	g_iTraceDmg[attacker] = 0;

	if(g_EndRound || !g_NewRound)
		return HAM_SUPERCEDE;
	if(attacker == victim && !(dmgbits & (1<<24)))
		return HAM_SUPERCEDE;
	if(get_user_team(attacker) == get_user_team(victim) && attacker != victim)
		return HAM_SUPERCEDE;
	if(dmgbits & (1<<24) && g_zombie[attacker])
		return HAM_SUPERCEDE;
	
	if(!g_zombie[attacker] && attacker == victim && dmgbits & (1<<24))
	{
		SetHamParamFloat(4, flDamage * 7.0);
		return HAM_HANDLED;
	}
	if(!g_zombie[attacker] && g_zombie[victim])
	{
		SetRage(victim, floatround(flDamage * 0.1))
		SetKarma(victim, floatround(flDamage * 0.03))
		
		flHpRegenTime[victim] = get_gametime() + 5.0
		
		cs_set_user_money(attacker, cs_get_user_money(attacker) + floatround(flDamage * c_moneydamage_rate))
		cs_set_user_money(victim, cs_get_user_money(victim) + floatround(flDamage * c_moneydamage_rate))
	
		if(dmgbits & (1<<24)) 
		{
			flDamage *= (g_iHasItem[attacker] & (1<<EXTRAITEM_HEDMG)) ? 25.0 : 7.0;
		}

		if(g_iUsedSkill[SKILL_DEADLYSHOT][attacker] == 2 && !iTrace)
			flDamage *= 3.0;

		new current_morale = clamp(g_morale[attacker] + FindClosestHuman(attacker, 250.0), 1, 13)
		SetHamParamFloat(4, flDamage * GetMoraleDamage(current_morale));
			
		if(c_escape_mode)
		{
			new Float:vOrigin[3]; pev(attacker, pev_origin, vOrigin);
			
			HookEnt(victim, vOrigin, 40.0, 2)
			return HAM_SUPERCEDE;
		}
		return HAM_HANDLED;
	}
	if(g_zombie[attacker] && !g_zombie[victim] && dmgbits & DMG_BULLET)
	{
		if(c_escape_mode && g_Virus > 0)
			return HAM_SUPERCEDE;
		
		ExecuteForward(g_iForward[8], fwResult, victim, attacker)
		
		new Float:flHp; pev(victim, pev_health, flHp)
		if((g_iHero[victim] != 1 || c_escape_mode) && fwResult < 2)
		{
			static Float:armor; armor = entity_get_float(victim, EV_FL_armorvalue)
			if(!c_instant_infect && armor > 0.0) entity_set_float(victim, EV_FL_armorvalue, armor - flDamage);
			else Player_Infected(attacker, victim)
		
			return HAM_SUPERCEDE;
		} else {
			if(g_iHero[victim] == 1 && flDamage < 300.0) SetHamParamFloat(4, flDamage * 10.0);
			SetHamParamInteger(5, dmgbits|DMG_NEVERGIB)
			return HAM_HANDLED;
		}
	}
	return HAM_IGNORED;
}
public HamF_BreakableTakeDamage(victim, inflictor, attacker, Float:flDamage, dmgbits)
{
	if(!c_escape_mode)
		return HAM_IGNORED;
		
	if(!isBreakable(victim) || !is_user_connected(attacker))
		return HAM_IGNORED;
		
	if(pev(victim, pev_spawnflags) & SF_BREAK_TRIGGER_ONLY)
		return HAM_IGNORED;
		
	new Float:flHp; pev(victim, pev_health, flHp)
	if(flDamage >= flHp)
	{
		new name[64]; get_user_name(attacker, name, 63);
		colored_print(0, ">x01[>x04Zombie The Hero>x01] >x03%s>x01 Destroy an Object", name)
	}
	return HAM_IGNORED;
}
public fw_Touch(ent, id)
{
	if(c_escape_mode)
	{
		if(isGrenade(ent) && isBreakable(id) && !(pev(id, pev_spawnflags) & SF_BREAK_TRIGGER_ONLY))
		{
			new name[64], attacker; attacker = pev(ent, pev_owner)
			get_user_name(attacker, name, 63);
			colored_print(0, ">x01[>x04Zombie The Hero>x01] >x03%s>x01 Destroy an Object", name)
		}
		if(isTrigger(ent) && is_user_connected(id) && g_zombie[id])
			return HAM_SUPERCEDE;
	}
	if (!is_user_connected(id))
		return HAM_IGNORED;
	
	if (g_zombie[id] && is_weapon_entity(ent))
		return HAM_SUPERCEDE;

	return HAM_IGNORED;
}	
public fw_GetGameDescription()
{
	forward_return(FMV_STRING, c_escape_mode ? "Zombie Escape" : "Zombie The Hero")
	return FMRES_SUPERCEDE;
}
public fw_UseStationary(entity, caller, activator, use_type)
{
	if(use_type == 2 && is_user_connected(caller))
		return HAM_SUPERCEDE;
		
	return HAM_IGNORED;
}
public fw_UseButton(entity, id, activator, use_type)
{
	if(!is_user_connected(id) || !c_escape_mode || g_flButtonUse > get_gametime())
		return HAM_IGNORED;
		
	g_flButtonUse = get_gametime() + 1.0
	new name[64]; get_user_name(id, name, 63);
	colored_print(0, ">x01[>x04Zombie The Hero>x01] >x03%s>x01 Is using a button", name)
	return HAM_IGNORED;
}
// Emit Sound Forward
public fw_EmitSound(id, channel, const sample[], Float:volume, Float:attn, flags, pitch)
{
	// Replace these next sounds for zombies only
	if (!is_user_connected(id) || !g_zombie[id])
		return FMRES_IGNORED;
		
	// Zombie attacks with knife
	if (sample[8] == 'k' && sample[9] == 'n' && sample[10] == 'i')
	{
		if (sample[14] == 's' && sample[15] == 'l' && sample[16] == 'a') // slash
		{
			emit_sound(id, channel, zombie_swing_sound[random(sizeof(zombie_swing_sound)-1)], volume, attn, flags, pitch)
			return FMRES_SUPERCEDE;
		}
		if (sample[14] == 'h' && sample[15] == 'i' && sample[16] == 't') // hit
		{
			if (sample[17] == 'w') // wall
			{
				emit_sound(id, channel, zombie_wall_sound[random(sizeof(zombie_wall_sound) - 1)], volume, attn, flags, pitch)
				return FMRES_SUPERCEDE;
			}
			else
			{
				emit_sound(id, channel, zombie_attack_sound[random(sizeof(zombie_attack_sound) - 1)], volume, attn, flags, pitch)
				return FMRES_SUPERCEDE;
			}
		}
		if (sample[14] == 's' && sample[15] == 't' && sample[16] == 'a') // stab
		{
			emit_sound(id, channel, zombie_attack_sound[random(sizeof(zombie_attack_sound) - 1)], volume, attn, flags, pitch)
			return FMRES_SUPERCEDE;
		}
	}
	
	if(ArrayGetCell(c_zombie_disablesound, g_zombieclass[id]))
		return HAM_IGNORED;
		
	// Zombie being hit
	if (sample[7] == 'b' && sample[8] == 'h' && sample[9] == 'i' && sample[10] == 't')
	{
		emit_sound(id, channel, zombie_pain_sound[random(sizeof(zombie_pain_sound)-1)], volume, attn, flags, pitch)
		return FMRES_SUPERCEDE;
	}
	
	// Zombie dies
	if (sample[7] == 'd' && ((sample[8] == 'i' && sample[9] == 'e') || (sample[8] == 'e' && sample[9] == 'a')))
	{
		emit_sound(id, channel, zombie_die_sound[random(sizeof(zombie_die_sound)-1)], volume, attn, flags, pitch)
		return FMRES_SUPERCEDE;
	}
		
	// Zombie falls off
	if (sample[10] == 'f' && sample[11] == 'a' && sample[12] == 'l' && sample[13] == 'l')
	{
		emit_sound(id, channel, zombie_pain_sound[random(sizeof(zombie_pain_sound)-1)], volume, attn, flags, pitch)
		return FMRES_SUPERCEDE;
	}
	
	return FMRES_IGNORED;
}
public fw_TraceAttack(victim, attacker, Float:flDamage, Float:vDir[3], tr, damagetype)
{
	if(!is_user_connected(victim) || !is_user_connected(attacker))
		return HAM_IGNORED;
	
	g_iTraceDmg[attacker] = 1;

	if(pev(victim, pev_takedamage) <= 0.0)
		return HAM_IGNORED;
	
	new iHitGroup
	if(g_zombie[victim])
	{

		iHitGroup = get_tr2(tr, TR_iHitgroup)
		if(g_iUsedSkill[SKILL_DEADLYSHOT][attacker] == 2 && iHitGroup != HIT_HEAD)
		{
			set_tr2(tr, TR_iHitgroup, HIT_HEAD);
			ExecuteHamB(Ham_TraceAttack, victim, attacker, flDamage, vDir, tr, damagetype)
			return HAM_SUPERCEDE;
		}
		if((g_iHasItem[attacker] & (1<<EXTRAITEM_DAMAGE)) && is_using_default_weapon(attacker))
		{
			flDamage *= (iHitGroup == HIT_HEAD) ? 3.5 : 7.5;
			SetHamParamFloat(3, flDamage)
			return HAM_HANDLED;
		}
	}
	return HAM_IGNORED;
}
public fw_TraceAttack_Post(victim, attacker, Float:damage, Float:direction[3], tracehandle, damage_type)
{
	if (victim == attacker || !is_user_alive(attacker))
		return;
	
	if (!g_zombie[victim] || g_zombie[attacker])
		return;
	
	if (!(damage_type & DMG_BULLET))
		return;
		
	if (GetHamReturnStatus() == HAM_SUPERCEDE)
		return;
		
	new ducking = pev(victim, pev_flags) & (FL_DUCKING | FL_ONGROUND) == (FL_DUCKING | FL_ONGROUND)
	
	static Float:velocity[3], Float:zbKb
	pev(victim, pev_velocity, velocity)
	new attacker_weapon = get_user_weapon(attacker)
	
	zbKb = ArrayGetCell(c_zombie_knockback, g_zombieclass[victim])
	
	if (Weapon_Knockback[attacker_weapon] > 0.0)
	{
		xs_vec_mul_scalar(direction, Weapon_Knockback[attacker_weapon], direction)
	}
	
	if (ducking) xs_vec_mul_scalar(direction, 0.25, direction)
	if(zbKb > 0.0) xs_vec_mul_scalar(direction, zbKb, direction)
	
	xs_vec_add(velocity, direction, direction)
	direction[2] = velocity[2]
	
	set_pev(victim, pev_velocity, direction)
}
public fw_CSPlayer_Kill(victim, attacker)
{
	if(g_zombie[victim])
	{
		Stock_Drop_Slot(victim, 4, 1);
	}
}

//====================================
// Player Think
//====================================
public fw_PlayerThink_Pre(id)
{
	if(!is_user_alive(id)) return
	
	ExecuteForward(g_iForward[5], fwResult, id);
	
	if(g_zombie[id])
	{
		if(user_has_weapon(id, PRIMARY_WEAPONS_BIT_SUM))
			Stock_Drop_Slot(id, 1, 1);
		if(user_has_weapon(id, SECONDARY_WEAPONS_BIT_SUM))
			Stock_Drop_Slot(id, 2, 1);	
			
		cs_remove_item(id, -1, 0)
		cs_remove_item(id, -1, 1)
		cs_remove_item(id, -1, 2)
		cs_remove_item(id, -1, 3)
		
		new Float:flHp, Float:flMaxHp; flMaxHp = float(GetMaxHealth(id))
		pev(id, pev_health, flHp);
		
		if(g_zombieclass[id] == g_DefZombie)
		{
			if(g_flFastrunTime[id] <= get_gametime())
			{
				if(g_iFastrunStat[id] == 1)
				{
					g_iFastrunStat[id] = 0;
					set_pev(id, pev_maxspeed, 270.0);
					set_rendering(id);
					set_pdata_int(id, 363, 90);
					g_flFastrunTime[id] = get_gametime() + 6.0
				}
			}
			if(g_iFastrunStat[id] == 1) set_pev(id, pev_maxspeed, 450.0);
			if(g_iHealStat[id] == 0 && g_flHealTime[id] <= get_gametime() && pev(id, pev_button) & IN_RELOAD && flHp < flMaxHp)
			{
				set_pev(id, pev_health, floatmin(flMaxHp, flHp + (flMaxHp * 0.25)));
				play_sound(id, "zombi/smallmedkit1.wav");
				ZHealEffect(id)
				
				if(!g_nightvision[id])
				{
					message_begin(MSG_ONE_UNRELIABLE, get_user_msgid("ScreenFade"), _, id);
					write_short(1<<9);
					write_short(0);
					write_short(0x0000);
					write_byte(0);//r
					write_byte(200);  //g
					write_byte(0);  //b
					write_byte(100);
					message_end();
				} 
	
				g_flHealTime[id] = get_gametime() + 15.0;
				g_iHealStat[id] = 1
			}
			else if (g_iHealStat[id] == 1 && g_flHealTime[id] <= get_gametime())
			{
				g_iHealStat[id] = 0
			}
		}
		if(flHpRegenTime[id] <= get_gametime() && flHp < flMaxHp)
		{
			if(get_speed(id) <= 150.0)
			{
				set_pev(id, pev_health, floatmin(flMaxHp, flHp + (flMaxHp * 0.07)));
				play_sound(id, "player/heartbeat2.wav");
			}
			flHpRegenTime[id] = get_gametime() + 1.0
		}
		
		if(c_escape_mode)
		{
			new Float:vOrigin[3]; pev(id, pev_origin, vOrigin)
			if(g_Virus > 0)
			{
				set_pdata_float(id, 83, 1.0);
				set_pev(id, pev_velocity, Float:{0.0, 0.0, 0.0})
				g_vLastOrigin[id][2] = vOrigin[2]
				set_pev(id, pev_origin, g_vLastOrigin[id])
			}
		}
	} else {
		if(((get_user_button(id) & IN_USE) && !(get_user_oldbutton(id) & IN_USE)) || is_user_bot(id))
			SupplyUse(id);

		if(g_iUsedSkill[SKILL_SPRINT][id] == 2)
		{
			set_pev(id, pev_maxspeed, c_escape_mode ? 450.0 : 420.0);
		}
	}
	for(new x = 0; x < 2; x ++ )
	{
		if(g_iUsedSkill[x][id] == 2 && g_flSkillTime[x][id] <= get_gametime())
		{
			g_iUsedSkill[x][id] = 0;
			if(x == SKILL_SPRINT) set_pev(id, pev_maxspeed, g_flOldMaxSpeed[id])
		}
	}	
	if(!g_iManualDecoding[id] || is_user_bot(id))
	{
		if(g_iDecoder[id] > 0 && g_flLastDecoding[id] <= get_gametime())	
		{
			DecodingReward(id)
			g_iDecoder[id] --
			g_flLastDecoding[id] = get_gametime() + 1.0;
		}
	}
	static WpnID;WpnID = get_user_weapon(id)
	if(c_refill_ammo && WpnID)
	{
		if(!((1<<WpnID) & CSWPN_NOCLIP) && cs_get_user_bpammo(id, WpnID) < Weapon_Bpammo[WpnID]) 
			cs_set_user_bpammo(id, WpnID, Weapon_Bpammo[WpnID])
	}
}
public fw_PlayerThink_Post(id)
{
	if(!is_user_alive(id)) return
	
	ExecuteForward(g_iForward[6], fwResult, id);
	
}
//====================================
// Task
//====================================
public task_welcome(id)
{
	id-=TASK_WELCOME
	if(!is_user_connected(id)) return;
	
	colored_print(id, "!d[!gSawaHijau!d] Zombie The Hero Z and Zombie Escape %s by !tcsbtedhan", MOD_VERSION)
	colored_print(id, "!d[!gZombie The Hero!d] Press !t(,) Buy Ammo !dto Open Mod Menu")
}
public task_random_weapon(id)
{
	id-=TASK_RANDOM_WEAPON
	if(!is_user_alive(id)) return
	
	if(!is_user_bot(id)) auto_give_item(id)
	else bot_auto_give_item(id)
}
public task_prev_weapon(id)
{
	id-=TASK_PREV_WEAPON
	if(!is_user_alive(id)) return
	
	give_previous_item(id)
}
public task_player_respawn(id)
{
	id-=TASK_RESPAWN
	if( !is_user_connected(id) || is_user_alive(id)) return
	
	rg_round_respawn(id)
}
public task_afterdisconnect()
{
	if(g_RoundStatus == ROUND_RUNNING) Check_Force_EndRound()
	if(get_player_count() <= 0)
		g_firstspawn = 0
}
public task_round_time()
{
	g_RoundTime--
	if(g_RoundTime < 0)
	{
		g_RoundTime = 0
		Check_Force_EndRound()
	}
	
	new txt[64]
	if(g_Countdown > 0)
	{
		g_Countdown --
		if(g_Countdown > 0)
		{
			switch(g_Countdown)
			{
				case 1 : play_sound(0, "vox/ghostfury/one.wav")
				case 2 : play_sound(0, "vox/ghostfury/two.wav")
				case 3 : play_sound(0, "vox/ghostfury/three.wav")
				case 4 : play_sound(0, "vox/ghostfury/four.wav")
				case 5 : 
				{
					play_sound(0, "vox/ghostfury/five.wav")
					ShowChoosedZbMessage()
				}
				case 6 : play_sound(0, "vox/ghostfury/six.wav")
				case 7 : play_sound(0, "vox/ghostfury/seven.wav")
				case 8 : play_sound(0, "vox/ghostfury/eight.wav")
				case 9 : play_sound(0, "vox/ghostfury/nine.wav")
				case 10 : play_sound(0, "vox/ghostfury/ten.wav")
				case 20 : play_sound(0, "vox/20secremain.wav")
			}
			format(txt, 63, "Zombie will appear in %i second", g_Countdown)
			client_print(0, print_center, "%s", txt)
		}
		else
		{
			if(!c_escape_mode) ShowVirusStatusMessage()
			g_Virus = c_virus_time
			g_SupplySpawn = 1
			g_Release = 1
			g_RoundStatus = ROUND_RUNNING
			g_flSupplyTime = get_gametime() + c_supply_time
			ResetBalance()
			make_random_player_zombie()
			CheckMakeHero()
			CheckPlayerAutoBuy()
			if(c_music_appear[0]) play_mp3_loop(0, c_music_appear)
		}
	}
	if(g_Virus > 0)
	{
		g_Virus --
		if(g_Virus <= 0 && !c_escape_mode) ShowVirusStatusMessage(1)
		else {
			if(!c_escape_mode) format(txt, 63, "Virus detoxified in %i second", g_Virus)
			else format(txt, 63, "Zombie Released in %i second", g_Virus)
			client_print(0, print_center, "%s", txt)
		}
	}
	message_begin(MSG_ALL, get_user_msgid("RoundTime"), _, 0)
	write_short(g_RoundTime)
	message_end()
	
	set_task(1.0, "task_round_time", TASK_ROUNDTIME)
}

public fw_CSHUD(id)
{	
	if(is_user_bot(id)) return;
	
	new message[3][256], fixednum[3][32], width, PowerUp[32], PowerDown[32], human_num, current_morale, damage_percent, damage_extra
	new ct = g_team_score[ZTEAM_CT]
	new t = g_team_score[ZTEAM_TERRORIST]
	
	if(get_cvar_num("mp_roundlimit") > 0) 
		fix_number(get_cvar_num("mp_roundlimit"), 2, fixednum[2], 31)
	else if(get_cvar_num("mp_winlimit") > 0) 
		fix_number(get_cvar_num("mp_winlimit"), 2, fixednum[2], 31)
	else fix_number((ct+t)+1, 2, fixednum[2], 4)	
	
	format(message[2], 255, "%s", fixednum[2])
	
	fix_number(ct, 2, fixednum[0], 31)
	fix_number(t, 2, fixednum[1], 31)
	format(message[0], 255, "%s", fixednum[1])
	format(message[1], 255, "%s", fixednum[0])
	
	set_dhudmessage(255, 255, 255, -1.0, 0.02, 0, 0.0, 1.0, 0.0, 0.0);
	show_dhudmessage(id, "[HUMAN %s] ROUND %s [%s ZOMBIE]", message[1], message[2], message[0]);
	
	width = (((g_iKarma[0][id] - 1 ) * 100) / MAX_KARMA)
	width = max(0, min(100, width))
	
	if(!g_zombie[id]) format(message[1], 255, "HP: %i AP: %i ^nKARMA: %i/%i%", get_user_health(id), get_user_armor(id), g_iKarma[1][id], width)
	else format(message[1], 255, "HP: %i AP: %i ^nEVOLUTION: %i^nKARMA: %i/%i%", get_user_health(id), get_user_armor(id), g_rage[RAGE_LEVEL][id]+1, g_iKarma[1][id], width)
		
	if(is_user_alive(id))
	{
		if(c_escape_mode)
		{
			new aim, body, Float:hp;
			get_user_aiming(id, aim, body, 750)
			if(isBreakable(aim) && !(pev(aim, pev_spawnflags) & SF_BREAK_TRIGGER_ONLY))
			{
				pev(aim, pev_health, hp)
				client_print(id, print_center, "Wall Health: %.1f", hp)
			}
		}
		set_hudmessage(0, 255, 0, -1.0, 0.775, 0, 0.0, 0.2, 0.0, 0.0)
		ShowSyncHudMsg(id, g_hud_sync[0], "%s", message[1])
		
		if(!g_zombie[id]) 
		{
			SupplyIcon(id)
			HeroIcon(id)
			
			human_num = FindClosestHuman(id, 250.0)
			current_morale = clamp(g_morale[id] + human_num, 1, 13)
			damage_percent = 100 + (10 * g_morale[id])
			damage_extra = 10 * (clamp(human_num, 1, 13))
				
			format(message[1], 255, "+%i%", damage_extra)
			for(new i = 0; i < current_morale; i++)
				formatex(PowerUp, sizeof(PowerUp), "%s||", PowerUp)
			for(new i = 13; i > current_morale; i--)
				formatex(PowerDown, sizeof(PowerDown), "%s--", PowerDown)
				
			format(message[0], 100, "[F1] DEADLYSHOT: %s [F2] SPRINT: %s", szSkillStat[g_iUsedSkill[SKILL_DEADLYSHOT][id]], szSkillStat[g_iUsedSkill[SKILL_SPRINT][id]])
			
			set_hudmessage(128, 255, 0, -1.0, 0.25, 0, 0.0, 0.5, 0.0, 0.0);
			ShowSyncHudMsg(id, g_hud_sync[3], "%s", message[0])

			format(message[0], 255, "ATTACK %i% %s ^n[%s%s]", damage_percent, human_num > 0 ? message[1] : "", PowerUp, PowerDown)
			set_hudmessage(GetMoraleColor(current_morale, 0), GetMoraleColor(current_morale, 1), GetMoraleColor(current_morale, 2), -1.0, 0.9, 0, 0.0, 0.2, 0.0, 0.0)
			ShowSyncHudMsg(id, g_hud_sync[4], "%s", message[0])
			
		} else {
			if(g_zombieclass[id] == g_DefZombie)
			{
				set_hudmessage(255, 255, 255, -1.0, 0.25, 0, 0.0, 0.2, 0.0, 0.0);
				ShowSyncHudMsg(id, g_hud_sync[2], "[G]Fastrun: %s [R]Self-Healing: %s", (g_flFastrunTime[id] <= get_gametime() && g_iFastrunStat[id]==0) ? "Ready" : "Cooldown",  (g_flHealTime[id] <= get_gametime() && g_iHealStat[id]==0) ? "Ready" : "Cooldown");
			}
			
			current_morale = clamp((((g_rage[RAGE_STAT][id] - 1 ) * 10) / MAX_RAGE), 0, 10)
			if(g_rage[RAGE_LEVEL][id] >= 2)
				current_morale = 10
				
			for(new i = 0; i < current_morale; i++)
				formatex(PowerUp, sizeof(PowerUp), "%s||", PowerUp)
			for(new i = 10; i > current_morale; i--)
				formatex(PowerDown, sizeof(PowerDown), "%s--", PowerDown)
					
			format(message[0], 255, "[%s%s]", PowerUp, PowerDown)
			set_hudmessage(255, 255, 0, -1.0, 0.9, 0, 0.0, 0.2, 0.0, 0.0)
			ShowSyncHudMsg(id, g_hud_sync[4], "%s", message[0])
		}
	}
	
}

//===============================
// TEST CMD
//===============================
public SetUserZombie(id)
{
	if(!get_pcvar_num(cvar_testing)) return;
	
	new name[64]; get_user_name(id, name, 63);
	colored_print(0, ">x01[>x04Zombie The Hero>x01] >x03%s>x01 Is using Zombie test command", name)
	
	ExecuteForward(g_iForward[0], fwResult, id, 0);
	MakeZombie(id)
}
public SetUserRageLevel(id)
{
	if(!get_pcvar_num(cvar_testing)) return;
	
	new arg[32]
	read_argv(1, arg, 31);
	
	new name[64]; get_user_name(id, name, 63);
	colored_print(0, ">x01[>x04Zombie The Hero>x01] >x03%s>x01 Is using Rage test command", name)
	
	g_rage[RAGE_LEVEL][id] = min(2, str_to_num(arg));
}
public SetUserGP(id)
{
	if(!get_pcvar_num(cvar_testing)) return;

	g_iSparkPoint[id] += 5000
}
public SetUserHuman(id)
{
	if(!g_zombie[id] || !get_pcvar_num(cvar_testing)) return;
	
	rg_set_user_team(id, TEAM_CT)
	pl_reset_user_model_index(id)
	pl_reset_user_model(id)
	pl_set_user_sound(id, 0)
		
	g_iHero[id] = 0;
	g_zombie[id] = 0;
	g_respawnzb[id] = 0;
		
	new name[64]; get_user_name(id, name, 63);
	colored_print(0, ">x01[>x04Zombie The Hero>x01] >x03%s>x01 Is using human test command", name)
	
	cs_set_user_armor(id, c_human_armor, CS_ARMOR_VESTHELM)
	set_pev(id, pev_health, float(c_human_health))
	set_pev(id, pev_gravity, c_human_gravity)
		
	remove_task(id+TASK_RANDOM_WEAPON)
	remove_task(id+TASK_RESPAWN)
}

public SetUserHero(id)
{
	if(!is_user_alive(id) || g_zombie[id] || !get_pcvar_num(cvar_testing))
		return PLUGIN_CONTINUE;
		
	MakeHero(id, 0)
	return PLUGIN_CONTINUE;
}
//===============================
// Other
//===============================
public clcmd_skillhumanskilldeadly(id)
{
	if(!is_user_alive(id) || g_zombie[id])
		return;
	if(g_RoundStatus != ROUND_RUNNING)
		return
	
	if(g_iUsedSkill[SKILL_DEADLYSHOT][id] == 1)
	{
		pl_play_voice(id, 10)
		g_iUsedSkill[SKILL_DEADLYSHOT][id] = 2;
		g_flSkillTime[SKILL_DEADLYSHOT][id] = get_gametime() + 6.0;
		play_sound(id, "zombi/speedup.wav")
	} 
	
}
public clcmd_skillhumanskillsprint(id)
{
	if(!is_user_alive(id) || g_zombie[id])
		return;
	if(g_RoundStatus != ROUND_RUNNING)
		return
		
	if(g_iUsedSkill[SKILL_SPRINT][id] == 1)
	{
		pl_play_voice(id, 9)
		pev(id, pev_maxspeed, g_flOldMaxSpeed[id]);
		set_pev(id, pev_maxspeed, 420.0);
		g_iUsedSkill[SKILL_SPRINT][id] = 2;
		g_flSkillTime[SKILL_SPRINT][id] = get_gametime() + 6.0;
		play_sound(id, "zombi/speedup.wav")
	}
}
public clcmd_BlockCmd(id)
	return 1;

public ReOpenBuymenu(id)
{
	if(g_RoundStatus == ROUND_RUNNING || g_iHasBuy[id] >= 2)
	{
		client_print(id, print_center, "Your buy session is over!")
		colored_print(id, "!d[!gZombie The Hero!d] Your buy session is over!")
		return 1;
	}

	BuyMenu(id, 1)
	return 1;
}
public UnStuck(id)
{
	if(!is_user_alive(id))
		return PLUGIN_CONTINUE;
		
	SetUserUnstuck(id)
	
	return PLUGIN_HANDLED;
}
public UseKarma(id)
{
	if(!is_user_alive(id) || g_zombie[id] || g_Release || g_choosedzb[id])
		return PLUGIN_CONTINUE;
		
	switch(g_iKarma[1][id])
	{
		case 1: cs_set_user_money(id, get_cvar_num("mp_maxmoney"))
		case 2: MakeHero(id, 1);
		case 3: MakeHero(id, 0);
		default: return PLUGIN_CONTINUE;
	}
	
	g_iKarma[0][id] = 0;
	g_iKarma[1][id] = 0;
	return PLUGIN_HANDLED;
}
public ZHealEffect(id)
{
	static Float:vOrigin[3], Float:vUp[3];
	pev(id, pev_origin, vOrigin);
	pev(id, pev_view_ofs, vUp);
	vOrigin[2] += vUp[2];
	
	message_begin(MSG_BROADCAST, SVC_TEMPENTITY);
	write_byte( TE_SPRITE );
	engfunc(EngFunc_WriteCoord, vOrigin[0]);
	engfunc(EngFunc_WriteCoord, vOrigin[1]);
	engfunc(EngFunc_WriteCoord, vOrigin[2] + 5.0);
	write_short( engfunc(EngFunc_ModelIndex, "sprites/zombiheal_head.spr") )
	write_byte(10)
	write_byte(255)
	message_end()
}
public ZBombExplode(Ent)
{
	static Float:vecOrigin[3]; pev(Ent, pev_origin, vecOrigin);
	static Float:flMaxDamage, Float:flKnock, pevAttacker; pevAttacker = pev(Ent, pev_owner);
	
	message_begin(MSG_BROADCAST, SVC_TEMPENTITY);
	write_byte( TE_EXPLOSION );
	engfunc(EngFunc_WriteCoord, vecOrigin[0])
	engfunc(EngFunc_WriteCoord, vecOrigin[1])
	engfunc(EngFunc_WriteCoord, vecOrigin[2])
	write_short(engfunc(EngFunc_ModelIndex, "sprites/zombiebomb_exp.spr"))
	write_byte(30);
	write_byte(30);
	write_byte(14);
	message_end();
	
	message_begin(MSG_BROADCAST, SVC_TEMPENTITY)
	write_byte(122)
	engfunc(EngFunc_WriteCoord, vecOrigin[0]);
	engfunc(EngFunc_WriteCoord, vecOrigin[1]);
	engfunc(EngFunc_WriteCoord, vecOrigin[2]);
	write_short(150)
	write_byte(111)
	write_byte(5)
	message_end()
	
	engfunc(EngFunc_EmitAmbientSound, 0, vecOrigin, "zombi/zombi_bomb_exp.wav", 1.0, 0.6, 0, 100);
	
	flMaxDamage = c_zbomb_damage;
	flKnock = c_zbomb_knockback;
	
	static Float:vOrigin[3], Float:flDist, Float:flDamage, pEnt; pEnt= -1
	while((pEnt = engfunc(EngFunc_FindEntityInSphere, pEnt, vecOrigin, c_zbomb_radius)) != 0 )
	{
		if(!pev_valid(pEnt))
			continue;
			
		pev(pEnt, pev_origin, vOrigin);
		flDist = vector_distance(vOrigin, vecOrigin);
		flDamage = flMaxDamage - floatmul(flMaxDamage, floatdiv(flDist, c_zbomb_radius));
		
		if(isBreakable(pEnt) && flDamage <= 0.0) flDamage = floatdiv(flMaxDamage, 2.0)
		
		if(flDamage > 0.0 && pev(pEnt, pev_health) > 0.0 && pev(pEnt, pev_takedamage) > 0.0)
			ExecuteHamB(Ham_TakeDamage, pEnt, Ent, pevAttacker, flDamage, isBreakable(pEnt) ? DMG_BLAST : DMG_CLUB);
			
		if(is_user_alive(pEnt))
		{
			ZBombSlapAngle(pEnt)
			Stock_MakeKnockback(pEnt, vOrigin, vecOrigin, flDist, flKnock);
			message_begin(MSG_ONE_UNRELIABLE, get_user_msgid("ScreenShake"), _, pEnt)
			write_short((1<<12)*4)
			write_short((1<<12)*2)
			write_short((1<<12)*10)
			message_end()
		}
	}
}
public Player_Infected(attacker, victim)
{
	if(!is_user_alive(victim)) return
	
	if(is_user_connected(attacker))
	{
		if(random(50) < 10)
		{
			g_iDecoder[attacker] ++
			colored_print(attacker, "!d[!gZombie The Hero!d] Obtain !g1x Decoder !dfor Infecting")
		}
		g_flLastLucky[attacker] = get_gametime() + random_float(10.0, 30.0)
					
		make_deathmsg(attacker, victim, 0, "knife")
		set_pev(attacker, pev_frags, pev(attacker, pev_frags) + 1.0)
		
		static name[2][32], szText[128]
		get_user_name(attacker, name[0], 31)
		get_user_name(victim, name[1], 31);
				
		format(szText, 127, "%s has been infected by %s!", name[1], name[0]) 
		send_center_text(szText, 4.0, {200,110,110}, 0)

		SetRage(attacker, 500);
	}
	
	cs_set_user_deaths(victim, cs_get_user_deaths(victim) + 1)
	
	ExecuteForward(g_iForward[0], fwResult, victim, attacker);
	
	update_player_score(attacker)
	update_player_score(victim)
	
	g_rage[RAGE_LEVEL][victim] = 0;
	g_rage[RAGE_STAT][victim] = 0;
	MakeZombie(victim)
	
	Check_Force_EndRound()
}
public MakeZombie(id)
{
	if(!is_user_connected(id)) return
	
	Stock_Drop_Slot(id, 1, 1)
	Stock_Drop_Slot(id, 2, 1)
	Stock_Drop_Slot(id, 4, 1)
	Stock_Drop_Slot(id, 5, 1)
	
	cs_remove_item(id, -1, 0)
	cs_remove_item(id, -1, 1)
	cs_remove_item(id, -1, 2)
	cs_remove_item(id, -1, 3)
		
	fm_give_item(id, "weapon_hegrenade")
	fm_give_item(id, "weapon_knife")
	engclient_cmd(id, "weapon_knife")
	
	if(user_has_weapon(id, CSW_HEGRENADE)) cs_set_user_bpammo(id, CSW_HEGRENADE, 2)

	if(is_user_bot(id)) 
	{
		g_zombieclass[id] = BotGetRandomZombieClass()
		g_nextclass[id] = g_zombieclass[id]
	} else {
		g_zombieclass[id] = g_nextclass[id]
	}
	g_iHero[id] = 0;
	g_zombie[id] = 1	
	g_respawnzb[id] = 0;
	g_choosedzb[id] = 0;
	switch(pl_get_user_sex(id))
	{
		case 1: emit_sound(id, CHAN_VOICE, human_infected_female[random(1)], 1.0, 0.8, 0, 100);
		default: emit_sound(id, CHAN_VOICE, human_infected[random(1)], 1.0, 0.8, 0, 100);
	}
	
	play_message_sound(0, random(5) > 3 ? "zombi/z4_zombi_coming_1.wav" : "zombi/z4_zombi_coming_2.wav")
	
	static Float:Origin[3]
	pev(id, pev_origin, Origin)
	
	message_begin(MSG_PVS, SVC_TEMPENTITY)
	write_byte(TE_PARTICLEBURST) // TE id
	engfunc(EngFunc_WriteCoord, Origin[0]) // x
	engfunc(EngFunc_WriteCoord, Origin[1]) // y
	engfunc(EngFunc_WriteCoord, Origin[2]) // z
	write_short(50)
	write_byte(70)
	write_byte(3)
	message_end()
		
	message_begin(MSG_ONE_UNRELIABLE, get_user_msgid("ScreenShake"), _, id)
	write_short((1<<12)*4) // amplitude
	write_short((1<<12)*2) // duration
	write_short((1<<12)*10) // frequency
	message_end()
		
	
	if(!g_nightvision[id])
	{
		message_begin(MSG_ONE_UNRELIABLE, get_user_msgid("ScreenFade"), _, id);
		write_short(1<<9);
		write_short(0);
		write_short(0x0000);
		write_byte(200);//r
		write_byte(50);  //g
		write_byte(50);  //b
		write_byte(100);
		message_end();
	} else set_user_nvision(id, g_nightvision[id])
		
	pl_set_user_sound(id, 1)
	set_rendering(id)
	
	new Float:hp = float(c_zombie_health[g_rage[RAGE_LEVEL][id]])
	entity_set_float(id, EV_FL_health, hp)
	set_pev(id, pev_gravity, ArrayGetCell(c_zombie_gravity, g_zombieclass[id]))
	set_pev(id, pev_maxspeed, ArrayGetCell(c_zombie_maxspeed, g_zombieclass[id]))
	
	rg_set_user_team(id, TEAM_TERRORIST)
	cs_set_user_armor(id, c_zombie_armor, CS_ARMOR_KEVLAR)
	
	FixDeadAttrib(id)
	
	SetZombieModel(id, g_zombieclass[id])
	ClassMenu(id, 1)
}
public ChangeZombieClass(id, classid)
{
	if(!is_user_connected(id) || !is_user_alive(id) || !g_zombie[id]) return
	
	g_zombieclass[id] = classid
	
	engclient_cmd(id, "weapon_knife")
	
	set_rendering(id)
	
	set_pev(id, pev_gravity, ArrayGetCell(c_zombie_gravity, g_zombieclass[id]))
	set_pev(id, pev_maxspeed, ArrayGetCell(c_zombie_maxspeed, g_zombieclass[id]))
	
	SetZombieModel(id, g_zombieclass[id])
}
public MakeHero(id, iSide)
{
	if(!is_user_connected(id) || !is_user_alive(id) || !c_enable_hero || g_iHero[id]) return	
	
	if(!iSide)
	{
		entity_set_float(id, EV_FL_health, float(c_human_health * 4))
		cs_set_user_armor(id, c_human_armor, CS_ARMOR_VESTHELM)
		pl_set_user_custom_model(id, 1, c_hero_model, 0);
		pl_set_user_sound(id, 2)
	}
	
	g_iHero[id] = iSide ? 2 : 1;
	
	set_dhudmessage(200, 140, 0, -1.0, 0.2, 0, 0.0, 4.0, 0.5, 0.5);
	show_dhudmessage(id, iSide? "You're Sidekick!" : "You're Hero!");
		
	if(!is_user_bot(id))
	{
		BuyMenu(id, 1)
	}
	else bot_auto_give_item(id)
}
public HeroIcon(id)
{
	static Float:vUp[3], Float:vOrigin[3], Float:pOrigin[3]; 
	pev(id, pev_origin, vOrigin);
	pev(id, pev_view_ofs, vUp);
	xs_vec_add(vOrigin, vUp, vOrigin);
	
	static Float:vMiddle[3], Float:vOffset[2][3], Float:flDist, Float:vEnd[3]
	for(new pEnt = 0; pEnt<get_maxplayers(); pEnt ++)
	{
		if(!pev_valid(pEnt) || !is_user_alive(pEnt) || g_iHero[pEnt] != 1 || g_zombie[pEnt] || pEnt == id) continue;
		
		pev(pEnt, pev_origin, pOrigin);
		pOrigin[2] += 50.0;
		
		xs_vec_sub(pOrigin, vOrigin, vMiddle);
		engfunc(EngFunc_TraceLine, vOrigin, pOrigin, IGNORE_MONSTERS|IGNORE_GLASS, id, 0);
		get_tr2(0, TR_vecEndPos, vEnd);
		
		flDist = vector_distance(vOrigin, vEnd) - 10.0;
		Normalize(vMiddle, vOffset[0], flDist);
		xs_vec_add(vOffset[0], vOrigin, vOffset[1]);
		
		message_begin(MSG_ONE_UNRELIABLE, SVC_TEMPENTITY, _, id)
		write_byte(TE_SPRITE)
		engfunc(EngFunc_WriteCoord, vOffset[1][0])
		engfunc(EngFunc_WriteCoord, vOffset[1][1])
		engfunc(EngFunc_WriteCoord, vOffset[1][2])
		write_short(engfunc(EngFunc_ModelIndex, "sprites/zb_hero.spr"))
		write_byte(max(1, min(2, floatround(0.01 * flDist)))) 
		write_byte(150)
		message_end()
	}
}
public make_random_player_zombie()
{
	if(!g_firstspawn || get_player_count() <= 1)
		return;
	if(g_NewRound){
		
		//Show Message
		send_center_text("Zombies Appear!", 5.0, {255, 110, 110}, 0)
		// Randomly turn iMaxZombies players into zombies
		CheckMakeRandomZombie()
	}
}
public CheckPlayerAutoBuy()
{
	for(new id = 0; id<get_maxplayers(); id++)
	{
		if(!is_user_connected(id) || !is_user_alive(id) || is_user_bot(id) || g_zombie[id])
			continue;

		// prevent new player confused for buying weapon and became weaponless
		if(g_iAutoBuy[id] == 0)
		{
			auto_give_item(id)
			g_iAutoBuy[id] = 1;
		}
	}
}
public lighting_effects()
{
	// Get lighting style
	static lighting[2]
	get_pcvar_string(cvar_light, lighting, charsmax(lighting))
	strtolower(lighting)
	
	// Lighting disabled? ["0"]
	if (lighting[0] == '0')
		return;
	
	// Set lighting
	engfunc(EngFunc_LightStyle, 0, lighting)
}

public set_user_nvision(id, mode)
{	
	if (!is_user_connected(id)) return;

	new alpha
	if (mode) alpha = 70
	else alpha = 0
	
	message_begin(MSG_ONE, get_user_msgid("ScreenFade"), _, id)
	write_short(0) // duration
	write_short(0) // hold time
	write_short(0x0004) // fade type
	if (g_zombie[id])
	{
		write_byte(200) // r
		write_byte(110) // g
		write_byte(110) // b
	} else {
		write_byte(0) // r
		write_byte(150) // g
		write_byte(0) // b
	}
	write_byte(alpha) // alpha
	message_end()
	
	if(mode)
	{
		set_player_light(id, "0")
	} else {
		
		static string[2]
		get_pcvar_string(cvar_light, string, sizeof(string))
		set_player_light(id, string)
	}
}
public clcmd_nightvision_toggle(id)
{
	if(!is_user_connected(id))
	{
		return
	}
	
	switch(g_nightvision[id])
	{
		case 0: g_nightvision[id] = 1
		case 1: g_nightvision[id] = 0
	}
	if(is_user_alive(id))
		engfunc(EngFunc_EmitSound, id, CHAN_ITEM, g_nightvision[id] ? "items/nvg_on.wav" : "items/nvg_off.wav", 1.0, ATTN_STATIC, 0, 100);
		
	set_user_nvision(id, g_nightvision[id])
}
//===============================
// Supply Box
//===============================
public SetSupplyBox()
{
	if(!g_SupplySpawn || g_flSupplyTime > get_gametime() || GetSupplyCount() >= c_supply_max || c_escape_mode)
		return;
	
	new spawnid, Float:vOrigin[3], TotalSpawn, iSupplyNum = random_num(1, 2)
	while(TotalSpawn < iSupplyNum && GetSupplyCount() < c_supply_max)
	{
		if(g_SupplySpawnExist) 
		{
			spawnid = random_num(0, g_SpawnCountBox-1)
			vOrigin = g_spawns_box[spawnid]
		} else {
			if(g_SpawnCountCSDM)
			{
				spawnid = random_num(0, g_SpawnCountCSDM-1)
				vOrigin[0] = g_spawns_csdm[spawnid][0]
				vOrigin[1] = g_spawns_csdm[spawnid][1]
				vOrigin[2] = g_spawns_csdm[spawnid][2]
			} else {
				spawnid = random_num(0, g_SpawnCountRegular-1)
				vOrigin[0] = g_spawns_regular[spawnid][0]
				vOrigin[1] = g_spawns_regular[spawnid][1]
				vOrigin[2] = g_spawns_regular[spawnid][2]
			}
		}
	
		if(!CheckSupplyPoint(vOrigin)) continue;
		
		MakeSupplyBox(vOrigin, random(20) < 3 ? SUPPLY_EXCLUSIVE : SUPPLY_NORMAL)
		TotalSpawn ++
	}
	
	client_print(0, print_center, "A Supply Box has arrived!")
	play_sound(0, "zombi/supplybox_drop.wav");
	g_flSupplyTime = get_gametime() + c_supply_time
}
public MakeSupplyBox(Float:vOrigin[3], iType)
{
	static pEnt; pEnt = engfunc(EngFunc_CreateNamedEntity, engfunc(EngFunc_AllocString, "info_target"));
	
	set_pev(pEnt, pev_origin, vOrigin);
	set_pev(pEnt, pev_classname, "zombiezsupply");
	set_pev(pEnt, pev_iuser1, iType);
	
	engfunc(EngFunc_SetModel, pEnt, szSupplyModel[iType])
	
	set_pev(pEnt, pev_movetype, 6);
	engfunc(EngFunc_SetSize, pEnt, Float:{-1.0, -1.0, -1.0}, Float:{1.0, 1.0, 1.0})
	set_pev(pEnt, pev_solid, SOLID_TRIGGER);	
}
public SupplyUse(id)
{
	static Float:vOrigin[3]; pev(id, pev_origin, vOrigin);
	
	static iType, pEnt; pEnt = -1;
	while (( pEnt = engfunc( EngFunc_FindEntityInSphere, pEnt, vOrigin, 70.0 )) != 0 )
	{
		if(!isSupplyBox(pEnt))
			continue;
			
		set_pev(id, pev_frags, pev(id, pev_frags) +1.0)
		update_player_score(id)
					
		if(is_user_bot(id)) bot_auto_give_item(id)
		else {
			set_pdata_int(id, 205, 0);
			g_iAdvanRandom[id] = 1;
			BuyMenu(id, 1);
			g_iAdvanRandom[id] = 0;
			give_additional_item(id)
			GiveAmmo(id)
			GiveAmmo(id, 1);
		}
		engfunc(EngFunc_EmitSound, pEnt, CHAN_ITEM, szSupplyPickupSound, 1.0, 0.8, 0, 100);
		iType = pev(pEnt, pev_iuser1)
		g_iDecoder[id] += iType == SUPPLY_EXCLUSIVE ? c_decoder_given[2] : c_decoder_given[1]
		
		if(get_user_flags(id) & ADMIN_LEVEL_E || get_pcvar_num(cvar_force_vip))
			g_iDecoder[id] += iType == SUPPLY_EXCLUSIVE ? 2 : 1
			
		engfunc(EngFunc_RemoveEntity, pEnt);
		
		break;
	}
}
public SupplyIcon(id)
{
	static iType, Float:vUp[3], Float:vOrigin[3], Float:pOrigin[3]; 
	pev(id, pev_origin, vOrigin);
	pev(id, pev_view_ofs, vUp);
	xs_vec_add(vOrigin, vUp, vOrigin);
	
	static iTotal, Float:vMiddle[3], Float:vOffset[2][3], Float:flDist, Float:vEnd[3], pEnt; pEnt = -1
	iTotal = 1;
	while(( pEnt = engfunc(EngFunc_FindEntityByString, pEnt, "classname", "zombiezsupply")) != 0 )
	{
		if(!isSupplyBox(pEnt)) continue;
		
		pev(pEnt, pev_origin, pOrigin);
		pOrigin[2] += 40.0;
		
		xs_vec_sub(pOrigin, vOrigin, vMiddle);
		engfunc(EngFunc_TraceLine, vOrigin, pOrigin, IGNORE_MONSTERS|IGNORE_GLASS, id, 0);
		get_tr2(0, TR_vecEndPos, vEnd);
		
		flDist = vector_distance(vOrigin, vEnd) - 10.0;
		Normalize(vMiddle, vOffset[0], flDist);
		xs_vec_add(vOffset[0], vOrigin, vOffset[1]);
		
		iType = pev(pEnt, pev_iuser1)
		
		if(vector_distance(vOrigin, pOrigin) > 120.0)
		{
			message_begin(MSG_ONE_UNRELIABLE, SVC_TEMPENTITY, _, id)
			write_byte(TE_SPRITE)
			engfunc(EngFunc_WriteCoord, vOffset[1][0])
			engfunc(EngFunc_WriteCoord, vOffset[1][1])
			engfunc(EngFunc_WriteCoord, vOffset[1][2])
			write_short(engfunc(EngFunc_ModelIndex, iType ? "sprites/icon_supplybox2.spr" : "sprites/icon_supplybox.spr"))
			write_byte(max(1, min(2, floatround(0.01 * flDist)))) 
			write_byte(150)
			message_end()
		}
		if(vector_distance(vOrigin, pOrigin) <= 200.0)
		{
			message_begin(MSG_ONE_UNRELIABLE, SVC_TEMPENTITY, _, id)
			write_byte(TE_SPRITE)
			engfunc(EngFunc_WriteCoord, pOrigin[0])
			engfunc(EngFunc_WriteCoord, pOrigin[1])
			engfunc(EngFunc_WriteCoord, pOrigin[2])
			write_short(engfunc(EngFunc_ModelIndex, "sprites/e_button01.spr"))
			write_byte(1) 
			write_byte(150)
			message_end()
		}
		
		if(g_SupplyRadarInterval <= get_gametime())
		{
			message_begin(MSG_ONE_UNRELIABLE, get_user_msgid("HostagePos"), {0,0,0}, id)
			write_byte(id)
			write_byte(iTotal)		
			engfunc(EngFunc_WriteCoord, pOrigin[0])
			engfunc(EngFunc_WriteCoord, pOrigin[1])
			engfunc(EngFunc_WriteCoord, pOrigin[2])
			message_end()
				
			message_begin(MSG_ONE_UNRELIABLE, get_user_msgid("HostageK"), {0,0,0}, id)
			write_byte(iTotal)
			message_end()
			
			iTotal++
			g_SupplyRadarInterval = get_gametime() + 2.0
		}
	}
}
//===============================
// Skin Menu
//===============================

public zSkinMenu(id)
{
	if(!is_user_connected(id) || !ArraySize(ZSkinAddons)) return PLUGIN_CONTINUE;
	
	new iMenu, aSkinData[SkinData], szName[64], szText[256], iData[2], ClassID;
	iMenu = menu_create("Zombie Skin", "zSkinMenuHandler")
	
	for(new x = 0 ; x < ArraySize(ZSkinAddons); x ++ )
	{
		ClassID = GetSkinZombieClassIndex(x)
		if( ClassID <= -1) continue;
		
		ArrayGetArray(ZSkinAddons, x, aSkinData);
		ArrayGetString(c_zombie_name, ClassID, szName, 63);
		if(!(g_iHasSkin[id] & (1<<x)) && !get_pcvar_num(cvar_unlock_allskin))
			format(szText, 255, "\d%s \wSkin: \y%s", aSkinData[SkinData_name], szName);
		else format(szText, 255, "%s \wSkin: \y%s \w[\r%s\w]", aSkinData[SkinData_name], szName, isSkinActive(id, x) ? "Active" : "Available");
		
		iData[0] = x
		menu_additem(iMenu, szText, iData);
	}
	
	set_pdata_int(id, 205, 0)
	menu_display(id, iMenu, 0);
	return PLUGIN_HANDLED;
}
public zSkinMenuHandler(id, menu, item)
{
	if(item == MENU_EXIT)
	{
		menu_destroy(menu)
		return;
	}
	new cmd[10], iName[64]
	new saccess, callback
	
	menu_item_getinfo(menu, item, saccess, cmd, 9, iName, 63, callback)
	
	new aSkinData[SkinData], zClass = GetSkinZombieClassIndex(cmd[0])
	ArrayGetArray(ZSkinAddons, cmd[0], aSkinData);
	
	if((!(g_iHasSkin[id] & (1<<cmd[0])) && !get_pcvar_num(cvar_unlock_allskin)) || zClass <= -1)
	{
		zSkinMenu(id)
		return;
	}
	
	if(isSkinActive(id, cmd[0]))
		g_iUsedSkin[id] &= ~(1 << cmd[0])
	else SetSkinActive(id, cmd[0])
	
	zSkinMenu(id);
}
//===============================
// New Menu
//===============================
public ModMenu(id)
{
	if(!is_user_connected(id)) 
		return PLUGIN_CONTINUE;

	new iMenu, szText[128];iMenu = menu_create(c_escape_mode ? "\w[\yCS\w]\r Zombie Escape" : "\w[\yCS\w]\r Zombie The Hero", "ModMenuHandler");
	if(g_RoundStatus < ROUND_RUNNING && !g_choosedzb[id]) 
	{
		menu_additem(iMenu, "Re-Open Buy Menu", "1");
		if(g_iKarma[1][id] != 0)
		{
			switch(g_iKarma[1][id])
			{
				case 1: szText = "Max Money"
				case 2: szText = "Side Kick"
				case 3: szText = "Hero"
				default: szText = "Unavailable"
			}
			format(szText, 127, "Use Karma: \r%s", szText)
			menu_additem(iMenu, szText, "7")
		}
	}
	menu_additem(iMenu, "Human Classes", "2");
	menu_additem(iMenu, "Zombie Classes", "3");
	menu_additem(iMenu, "Zombie Skin", "4")
	menu_additem(iMenu, "Extra Items", "10");
	menu_additem(iMenu, "Decoder", "5");
	menu_additem(iMenu, "Camera Mode", "8");
	menu_additem(iMenu, "Mod Info", "9");

	set_pdata_int(id, 205, 0)
	menu_display(id, iMenu, 0);
	return PLUGIN_HANDLED;
}
public ModMenuHandler(id, menu, item)
{
	if(item == MENU_EXIT)
	{
		menu_destroy(menu)
		return;
	}

	new cmd[10], iName[64]
	new saccess, callback, choice
	
	menu_item_getinfo(menu, item, saccess, cmd, 9, iName, 63, callback)
	choice = str_to_num(cmd)
	switch(choice)
	{
		case 1: ReOpenBuymenu(id)
		case 2: client_cmd(id, "pl_classmenu")
		case 3: ClassMenu(id, 0)
		case 4: zSkinMenu(id)
		case 5: DecoderMenu(id)
		case 7: UseKarma(id)
		case 8: client_cmd(id, "camera_menu")
		case 9:
		{
			static string_name[128]
			formatex(string_name, sizeof(string_name), "%L", LANG_SERVER, "MODNAME")
			
			show_motd(id, "zbzinfo.txt", string_name)
		}
		case 10: ExtraItemMenu(id)
	}
}
//===============================
// Decoder Menu
//===============================
public DecoderMenu(id)
{
	if(!is_user_connected(id)) return PLUGIN_CONTINUE;
	
	new iMenu, szText[256]; format(szText, charsmax(szText), "\w[\yDecoder Owned: \r%i\w]", g_iDecoder[id]);
	iMenu = menu_create(szText, "DecoderMenuHandler");
	menu_additem(iMenu, g_iManualDecoding[id] ? "Auto Decoding: \rOFF" : "Auto Decoding: \rON", "9")
	if(g_iManualDecoding[id])
	{
		menu_additem(iMenu, "Open Decoder", "1");
		
		format(szText, charsmax(szText), "Open %ix Decoder", min(5, g_iDecoder[id]))
		menu_additem(iMenu, szText, "2");
	}
	
	format(szText, charsmax(szText), "\dBuy 1x Decoder \wCost:\r$%i", c_decoder_cost)
	if(cs_get_user_money(id) < c_decoder_cost)
		format(szText, charsmax(szText), "\dBuy x1 Decoder \wCost:\r$%i", c_decoder_cost)
	else format(szText, charsmax(szText), "Buy 1x Decoder \wCost:\y$%i", c_decoder_cost)
	menu_additem(iMenu, szText, "3")
	menu_additem(iMenu, "Guarantee Blessing", "11");
	
	menu_additem(iMenu, "Decoder Info", "4")
	
	set_pdata_int(id, 205, 0)
	menu_display(id, iMenu, 0);
	return PLUGIN_HANDLED;
}
public DecoderMenuHandler(id, menu, item)
{
	if(item == MENU_EXIT)
	{
		menu_destroy(menu)
		return;
	}
	new cmd[10], iName[64]
	new saccess, callback, choice
	
	menu_item_getinfo(menu, item, saccess, cmd, 9, iName, 63, callback)

	choice = str_to_num(cmd)
	switch(choice)
	{
		case 1: { 
			if(g_iDecoder[id] > 0) 
			{
				DecodingReward(id); 
				g_iDecoder[id] --;
			}
		}
		case 2:
		{
			new decOpen = 0
			while(g_iDecoder[id] > 0 && decOpen < 5)
			{
				DecodingReward(id)
				g_iDecoder[id] --
				decOpen ++
			}
		}
		case 3:
		{
			if(cs_get_user_money(id) >= c_decoder_cost)
			{
				g_iDecoder[id] ++
				cs_set_user_money(id, cs_get_user_money(id) - c_decoder_cost)
			}
		}
		case 5:
		{
			zSkinMenu(id);
			return;
		}
		case 6:
		{
			if(g_zombie[id]) 
			{
				DecoderMenu(id)
				return;
			}
			client_cmd(id, "pl_classmenu")
			
			return;
		}
		case 7:
		{
			static string_name[128]
			formatex(string_name, sizeof(string_name), "%L", LANG_SERVER, "MODNAME")
			
			show_motd(id, "zbzinfo.txt", string_name)
		
		}
		case 8:
		{
			UseKarma(id)
		}
		case 9: g_iManualDecoding[id] = 1-g_iManualDecoding[id]
		case 11:
		{
			GuaranteMenu(id)
			return;
		}
		default:
		{
			ShowDecoderInfo(id)
			return;
		}
	}
	DecoderMenu(id)
}
public GuaranteMenu(id)
{

	new iMenu, szText[256]; format(szText, charsmax(szText), "\w[\yGuarantee Point: \r%i\w]", g_iSparkPoint[id]);
	iMenu = menu_create(szText, "GuaranteMenuHandler");
	new aWpnData[WpnData], sWpnName[64], data[10]

	for(new i = 0; i < ArraySize(PrimWPN); i++)
	{
		ArrayGetArray(PrimWPN, i, aWpnData)
		if(aWpnData[WpnData_Grade] == WPNGRADE_NORMAL)
			continue;

		copy(sWpnName, 63, aWpnData[WpnData_Class])
		replace(sWpnName, 63, "weapon_", "")
		strtoupper(sWpnName);
		format(sWpnName, 63, "%L", LANG_SERVER, sWpnName);
		if(!HasLimitedWeapon(id, i, 0, 0)) 
			format(szText, charsmax(szText), "\y%s\w Cost:\r%i", sWpnName, (aWpnData[WpnData_Grade] == WPNGRADE_PREMIUM) ? SPARK_COST_PRE:SPARK_COST_UNI)
		else format(szText, charsmax(szText), "\d%s Cost:%i \w(\yOwned\w)", sWpnName, (aWpnData[WpnData_Grade] == WPNGRADE_PREMIUM) ? SPARK_COST_PRE:SPARK_COST_UNI)
		data[0] = i;
		data[1] = 0;
		menu_additem(iMenu, szText, data)
	}
	for(new i = 0; i < ArraySize(SecWPN); i++)
	{
		ArrayGetArray(SecWPN, i, aWpnData)
		if(aWpnData[WpnData_Grade] == WPNGRADE_NORMAL)
			continue;

		copy(sWpnName, 63, aWpnData[WpnData_Class])
		replace(sWpnName, 63, "weapon_", "")
		strtoupper(sWpnName);
		format(sWpnName, 63, "%L", LANG_SERVER, sWpnName);
		if(!HasLimitedWeapon(id, i, 1, 0)) 
			format(szText, charsmax(szText), "\y%s\w Cost:\r%i", sWpnName, (aWpnData[WpnData_Grade] == WPNGRADE_PREMIUM) ? SPARK_COST_PRE:SPARK_COST_UNI)
		else format(szText, charsmax(szText), "\d%s Cost:%i \w(\yOwned\w)", sWpnName, (aWpnData[WpnData_Grade] == WPNGRADE_PREMIUM) ? SPARK_COST_PRE:SPARK_COST_UNI)
		data[0] = i;
		data[1] = 1;
		menu_additem(iMenu, szText, data)
	}
	for(new i = 0; i < ArraySize(MeleeWPN); i++)
	{
		ArrayGetArray(MeleeWPN, i, aWpnData)
		if(aWpnData[WpnData_Grade] == WPNGRADE_NORMAL)
			continue;

		copy(sWpnName, 63, aWpnData[WpnData_Class])
		replace(sWpnName, 63, "weapon_", "")
		strtoupper(sWpnName);
		format(sWpnName, 63, "%L", LANG_SERVER, sWpnName);
		if(!HasLimitedWeapon(id, i, 2, 0)) 
			format(szText, charsmax(szText), "\y%s\w Cost:\r%i", sWpnName, (aWpnData[WpnData_Grade] == WPNGRADE_PREMIUM) ? SPARK_COST_PRE:SPARK_COST_UNI)
		else format(szText, charsmax(szText), "\d%s Cost:%i \w(\yOwned\w)", sWpnName, (aWpnData[WpnData_Grade] == WPNGRADE_PREMIUM) ? SPARK_COST_PRE:SPARK_COST_UNI)
		data[0] = i;
		data[1] = 2;
		menu_additem(iMenu, szText, data)
	}
	for(new i = 0; i < ArraySize(NadeWPN); i++)
	{
		ArrayGetArray(NadeWPN, i, aWpnData)
		if(aWpnData[WpnData_Grade] == WPNGRADE_NORMAL)
			continue;

		copy(sWpnName, 63, aWpnData[WpnData_Class])
		replace(sWpnName, 63, "weapon_", "")
		strtoupper(sWpnName);
		format(sWpnName, 63, "%L", LANG_SERVER, sWpnName);
		if(!HasLimitedWeapon(id, i, 3, 0)) 
			format(szText, charsmax(szText), "\y%s\w Cost:\r%i", sWpnName, (aWpnData[WpnData_Grade] == WPNGRADE_PREMIUM) ? SPARK_COST_PRE:SPARK_COST_UNI)
		else format(szText, charsmax(szText), "\d%s Cost:%i \w(\yOwned\w)", sWpnName, (aWpnData[WpnData_Grade] == WPNGRADE_PREMIUM) ? SPARK_COST_PRE:SPARK_COST_UNI)
		data[0] = i;
		data[1] = 3;
		menu_additem(iMenu, szText, data)
	}
	set_pdata_int(id, 205, 0)
	menu_display(id, iMenu, 0);
}
public GuaranteMenuHandler(id, menu, item)
{
	if(item == MENU_EXIT)
	{
		menu_destroy(menu)
		DecoderMenu(id)
		return;
	}
	new cmd[10], iName[64]
	new saccess, callback
	
	menu_item_getinfo(menu, item, saccess, cmd, 9, iName, 63, callback)
	new aWpnData[WpnData], sWpnName[64], szNotice[512], szName[64]
	switch(cmd[1])
	{
		case 1: ArrayGetArray(SecWPN, cmd[0], aWpnData)
		case 2: ArrayGetArray(MeleeWPN, cmd[0], aWpnData)
		case 3: ArrayGetArray(NadeWPN, cmd[0], aWpnData)
		default: ArrayGetArray(PrimWPN, cmd[0], aWpnData)
	}
	if(HasLimitedWeapon(id, cmd[0], cmd[1], 0) || g_iSparkPoint[id] < (aWpnData[WpnData_Grade] == WPNGRADE_PREMIUM?SPARK_COST_PRE:SPARK_COST_UNI))
	{
		GuaranteMenu(id)
		return;
	}

	get_user_name(id, szName, 63)
	copy(sWpnName, 63, aWpnData[WpnData_Class])
	replace(sWpnName, 63, "weapon_", "")
	strtoupper(sWpnName);
	format(sWpnName, 63, "%L", LANG_SERVER, sWpnName);
	format(szNotice, charsmax(szNotice), ">x03%s>x01 has obtained %s item >x04%s>x01", szName, aWpnData[WpnData_Grade] == WPNGRADE_PREMIUM?"Premium" : "Unique", sWpnName);
	play_sound(id, aWpnData[WpnData_Grade] == WPNGRADE_PREMIUM ? "gachapon/open_weapon_item_top_sss.wav" : "gachapon/open_weapon_item_top.wav")
	colored_print(0, ">x01[>x04Decoder>x01] %s", szNotice);
	g_iHasWpn[cmd[1]][id] |= (1<<cmd[0]);
	g_iSparkPoint[id] -= (aWpnData[WpnData_Grade] == WPNGRADE_PREMIUM)?SPARK_COST_PRE:SPARK_COST_UNI

	GuaranteMenu(id)

}
public ShowDecoderInfo(id)
{
	new Txt[512], iMenu = menu_create("Decoder Info", "DecoderInfoHandler")
	
	format(Txt, charsmax(Txt), "%L^n%L", LANG_SERVER, "DECOHELP1", LANG_SERVER, "DECOHELP2");
	menu_additem(iMenu, Txt);
	set_pdata_int(id, 205, 0)
	menu_display(id, iMenu, 0);
}
public DecoderInfoHandler(id, menu, item)
{
	menu_destroy(menu)
}
//===============================
// Extra Item Menu
//===============================
public ExtraItemMenu(id)
{
	if(!is_user_connected(id)) 
		return PLUGIN_CONTINUE;

	new iMenu, szText[128];iMenu = menu_create("Extra Items", "ExtraItemMenuHandler");
	for(new x=0;x<sizeof(c_extraitem_cost);x++)
	{
		if(c_extraitem_cost[x] > cs_get_user_money(id) && !(g_iHasItem[id] & (1<<x))) 
			format(szText, charsmax(szText), "\d%s Cost:\r%i\w %s", szExtraItemName[x], c_extraitem_cost[x], (g_iHasItem[id] & (1<<x)) ? "(\yOwned\w)" : "")
		else format(szText, charsmax(szText), "%s Cost:\r%i\w %s", szExtraItemName[x], c_extraitem_cost[x], (g_iHasItem[id] & (1<<x)) ? "(\yOwned\w)" : "")
		menu_additem(iMenu, szText, szExtraItemSysName[x])
	}
	
	set_pdata_int(id, 205, 0)
	menu_display(id, iMenu, 0);
	return PLUGIN_HANDLED;
}
public ExtraItemMenuHandler(id, menu, item)
{
	if(item == MENU_EXIT)
	{
		menu_destroy(menu)
		return;
	}

	new cmd[32], iName[64]
	new saccess, callback
	
	menu_item_getinfo(menu, item, saccess, cmd, 31, iName, 63, callback)
	for(new x=0;x<sizeof(c_extraitem_cost);x++)
	{
		if(!equal(cmd, szExtraItemSysName[x])) continue;

		if(cs_get_user_money(id) < c_extraitem_cost[x] && (g_iHasItem[id] & (1<<x)))
			continue;

		cs_set_user_money(id, cs_get_user_money(id)-c_extraitem_cost[x])
		g_iHasItem[id] |= (1<<x)
		ItemPickHandler(id, x)
	}
	ExtraItemMenu(id)
}

//===============================
// Zombie Class Menu
//===============================
public CmdClassMenu(id)
{
	if(!is_user_connected(id) || get_user_team(id) == 0 || get_user_team(id) == 3) return PLUGIN_CONTINUE;

	ClassMenu(id, 0)
	return PLUGIN_HANDLED;
}
public ClassMenu(id, fast)
{
	if(!is_user_connected(id) || get_user_team(id) == 0 || get_user_team(id) == 3) return PLUGIN_CONTINUE;
	
	new ZClassMenu = menu_create("Zombie Class", "ZombieClassMenuHandler")
	new ClassName[32], Data[64], iMenuData[2]
	for(new i = 0; i<g_class_count; i++)
	{
		if(g_class_count <= 1) continue;
		
		ArrayGetString(c_zombie_name, i, ClassName, charsmax(ClassName))
		format(Data, charsmax(Data), "%s", ClassName)
		
		iMenuData[0] = i
		iMenuData[1] = fast
		menu_additem(ZClassMenu, Data, iMenuData)
	}
	if(menu_items(ZClassMenu) <= 0) 
		 return PLUGIN_HANDLED;
		 
	set_pdata_int(id, 205, 0)
	menu_display(id, ZClassMenu, 0);
	return PLUGIN_HANDLED;
}
public ZombieClassMenuHandler(id, menu, item)
{
	if(item < 0) return PLUGIN_CONTINUE
	if(item == MENU_EXIT)
	{
		menu_destroy(menu)
		return PLUGIN_CONTINUE;
	}
	new cmd[3], iName[64]
	new saccess, callback
	
	menu_item_getinfo(menu, item, saccess, cmd, 2, iName, 63, callback)
	
	g_nextclass[id] = cmd[0]
	if(!g_zombie[id]) g_zombieclass[id] = cmd[0]
	
	new ClassName[32], Data[256]
	
	if(g_zombie[id] && cmd[1] == 1) ChangeZombieClass(id, cmd[0])
	else {
		ArrayGetString(c_zombie_name, g_nextclass[id], ClassName, charsmax(ClassName))
		format(Data, charsmax(Data), "Zombie Class next infection Name: >x03%s>x01", ClassName)
		colored_print(id, ">x01[>x04Zombie>x01] %s", Data)
	}
	
	return PLUGIN_CONTINUE;
}
//===============================
// Weapon Menu
//===============================
public BuyMenu(id, fast)
{
	new iMenu = menu_create("Equip Menu", "FastMenuHandler")
	new szText[512], aWpnData[WpnData], szMenuName[64], sWpnName[128], iData[2]
	new iGrade = (g_iHero[id] == 1) ? WPNGRADE_PREMIUM : (g_iHero[id] != 2 ? WPNGRADE_NORMAL : WPNGRADE_UNIQUE)
	
	g_fastbuy[id] = fast;
	for(new x=0;x<4;x++)
	{
		switch(x)
		{
			case 1: szMenuName = "Secondary Weapon"
			case 2: szMenuName = "Melee Weapon"
			case 3: szMenuName = "Grenade Weapon"
			default: szMenuName = "Primary Weapon"
		}
	
		if(g_rebuy[id][x] != -1)
		{
			switch(x)
			{
				case 1: ArrayGetArray(SecWPN, g_rebuy[id][x], aWpnData)
				case 2: ArrayGetArray(MeleeWPN, g_rebuy[id][x], aWpnData)
				case 3: ArrayGetArray(NadeWPN, g_rebuy[id][x], aWpnData)
				default: ArrayGetArray(PrimWPN, g_rebuy[id][x], aWpnData)
			}
		
			copy(sWpnName, 127, aWpnData[WpnData_Class])
			replace(sWpnName, 127, "weapon_", "")
			strtoupper(sWpnName)
			
			format(szText, 511, "%s [%s%L\w]", szMenuName, (!GetWeaponStatus(id, g_rebuy[id][x], x, iGrade) ? "\d" : "\y"), LANG_PLAYER, sWpnName)
		} else format(szText, 511, "%s [\dPlease Select Weapon\w]", szMenuName)
		
		iData[0] = x
		menu_additem(iMenu, szText, iData)
	}
	menu_additem(iMenu, "Random Weapons", "ra")
	if(g_iAdvanRandom[id]) menu_additem(iMenu, "Advanced Random Weapons", "rv")
	menu_additem(iMenu, fast?"Receive Current Set":"Get Previous Set", "rs")
	
	set_pdata_int(id, 205, 0)
	menu_display(id, iMenu, 0)
}
public FastMenuHandler(id, menu, item)
{
	if(item < 0 || g_zombie[id]) return PLUGIN_CONTINUE
	
	if(item == MENU_EXIT)
	{
		menu_destroy(menu);
		return PLUGIN_CONTINUE;
	}
	
	new cmd[5], iName[64]
	new saccess, callback
	
	menu_item_getinfo(menu, item, saccess, cmd, 4, iName, 63, callback);
	
	if(equal(cmd, "ra"))
	{
		g_iVipUser[id] =0
		g_iHasBuy[id]++
		if(!g_iAutoBuy[id]) g_iAutoBuy[id] = 1;
		auto_give_item(id)
	}
	else if(equal(cmd, "rv"))
	{
		g_iVipUser[id] =0 
		g_iHasBuy[id]++
		if(!g_iAutoBuy[id]) g_iAutoBuy[id] = 1;
		auto_give_item(id, 1)
	}
	else if(equal(cmd, "rs"))
	{
		if(g_rebuy[id][0] != -1 || g_rebuy[id][1] != -1 || g_rebuy[id][2] != -1 || g_rebuy[id][3] != -1) 
		{
			g_iHasBuy[id]++
			give_previous_item(id)
			if(!g_iAutoBuy[id]) g_iAutoBuy[id] = 1;
		}
	} else {
		SpawnWeaponMenu(id, cmd[0], 1)
	}
	return PLUGIN_CONTINUE
}
public SpawnWeaponMenu(id, slot, display)
{
	new iMenuData[2], szMenuName[64], sWpnName[128]
	new WpnMenu, iTotal_Items, iGrade
	switch(slot)
	{
		case 1: szMenuName = "\w[ \yCS\w ] Secondary Weapon"
		case 2: szMenuName = "\w[ \yCS\w ] Melee Weapon"
		case 3: szMenuName = "\w[ \yCS\w ] Grenade Weapon"
		default: szMenuName = "\w[ \yCS\w ] Primary Weapon"
	}
	format(szMenuName, charsmax(szMenuName), "%s", szMenuName)
	WpnMenu = menu_create(szMenuName, "WeaponMenuHandler")
	switch(slot)
	{
		case 1: iTotal_Items = ArraySize(SecWPN)
		case 2: iTotal_Items = ArraySize(MeleeWPN)
		case 3: iTotal_Items = ArraySize(NadeWPN)
		default: iTotal_Items = ArraySize(PrimWPN)
	}
	
	iGrade = (g_iHero[id] == 1) ? WPNGRADE_PREMIUM : (g_iHero[id] != 2 ? WPNGRADE_NORMAL : WPNGRADE_UNIQUE)
	
	if(iTotal_Items)
	{
		new aWpnData[WpnData]
		for(new i = 0; i<iTotal_Items; i++)
		{
			switch(slot)
			{
				case 1: ArrayGetArray(SecWPN, i, aWpnData)
				case 2: ArrayGetArray(MeleeWPN, i, aWpnData)
				case 3: ArrayGetArray(NadeWPN, i, aWpnData)
				default: ArrayGetArray(PrimWPN, i, aWpnData)
			}
			
			copy(sWpnName, 127, aWpnData[WpnData_Class])
			replace(sWpnName, 127, "weapon_", "")
			strtoupper(sWpnName)
			
			if(!HasLimitedWeapon(id, i, slot)) continue;
				
			if(!GetWeaponStatus(id, i, slot, iGrade))
			{
				format(sWpnName, 127, "\d%L \wGrade:%s", LANG_PLAYER, sWpnName, szGradeName[aWpnData[WpnData_Grade]]);
			} else {
				format(sWpnName, 127, "%L Grade: %s", LANG_PLAYER, sWpnName, szGradeName[aWpnData[WpnData_Grade]]);	
			}
			
			iMenuData[0] = i+1
			iMenuData[1] = slot
			menu_additem(WpnMenu, sWpnName, iMenuData)
		}
	}
	
	if(display)
	{
		set_pdata_int(id, 205, 0)
		menu_display(id, WpnMenu, 0)
	}
}
public WeaponMenuHandler(id, menu, item)
{
	if(item == MENU_EXIT)
	{
		menu_destroy(menu)
		return PLUGIN_CONTINUE
	}
	
	new cmd[6], iName[64]
	new saccess, callback
	
	menu_item_getinfo(menu, item, saccess, cmd, 5, iName, 63, callback)
	
	new aWpnData[WpnData], wpnid = cmd[0]-1
	new slot = cmd[1]
	
	new iGrade = (g_iHero[id] == 1) ? WPNGRADE_PREMIUM : (g_iHero[id] != 2 ? WPNGRADE_NORMAL : WPNGRADE_UNIQUE)
	if(g_zombie[id])
	{
		menu_destroy(menu)
		return PLUGIN_CONTINUE
	}
	if(slot == 1)
	{
		ArrayGetArray(SecWPN, wpnid, aWpnData)
	
		if(!GetWeaponStatus(id, wpnid, 1, iGrade))
		{
			SpawnWeaponMenu(id, 1, 1)
			return PLUGIN_CONTINUE
		}
		
		g_rebuy[id][1]=wpnid
		if(!g_fastbuy[id])
		{
			Stock_Drop_Slot(id, 2, 1)
			cs_remove_item(id, -1, 1)
			
			cs_give_item(id, aWpnData[WpnData_Class]);
			GiveAmmo(id, 1)
			if(!g_iAutoBuy[id]) g_iAutoBuy[id] = 1;
		} else BuyMenu(id, 1)
	}
	else if(slot == 2)
	{
		ArrayGetArray(MeleeWPN, wpnid, aWpnData)
	
		if(!GetWeaponStatus(id, wpnid, 2, iGrade))
		{
			SpawnWeaponMenu(id, 2, 1)
			return PLUGIN_CONTINUE
		}
		g_rebuy[id][2]=wpnid
		if(!g_fastbuy[id])
		{
			cs_remove_item(id, -1, 2)
			
			cs_give_item(id, aWpnData[WpnData_Class]);
			if(!g_iAutoBuy[id]) g_iAutoBuy[id] = 1;
		} else BuyMenu(id, 1)
	} 
	else if(slot == 3)
	{
		ArrayGetArray(NadeWPN, wpnid, aWpnData)
	
		if(!GetWeaponStatus(id, wpnid, 3, iGrade))
		{
			SpawnWeaponMenu(id, 3, 1)
			return PLUGIN_CONTINUE
		}
		g_rebuy[id][3]=wpnid
		if(!g_fastbuy[id])
		{
			cs_remove_item(id, -1, 3)
			
			cs_give_item(id, aWpnData[WpnData_Class]);
			if(!user_has_weapon(id, CSW_HEGRENADE))
				fm_give_item(id, "weapon_hegrenade")

			if(!g_iAutoBuy[id]) g_iAutoBuy[id] = 1;
		} else BuyMenu(id, 1)
	} else {
		ArrayGetArray(PrimWPN, wpnid, aWpnData)
		if(!GetWeaponStatus(id, wpnid, 0, iGrade))
		{
			SpawnWeaponMenu(id, 0, 1)
			return PLUGIN_CONTINUE
		}
		g_rebuy[id][0]=wpnid
		if(!g_fastbuy[id])
		{
			Stock_Drop_Slot(id, 1, 1)
			cs_remove_item(id, -1, 0)
				
			cs_give_item(id, aWpnData[WpnData_Class]);
			GiveAmmo(id)
			if(!g_iAutoBuy[id]) g_iAutoBuy[id] = 1;
		} else BuyMenu(id, 1)
	}
	
	return PLUGIN_HANDLED
}
//====================================
// STOCK
//====================================
stock RegDefaultClasses(const name[], const models[], const clawmodel[], Float:gravity, Float:maxspeed, Float:knockback, usemodelindex)
{
	new filename[64]
	ArrayPushString(c_zombie_name, name);
	ArrayPushString(c_zombie_model, models);
	ArrayPushString(c_zombie_sysname, "tank");
	
	format(filename, charsmax(filename), "models/zbz/v_knife_%s.mdl", clawmodel);
	ArrayPushString(c_zombie_claws, filename);
	format(filename, charsmax(filename), "models/zbz/v_zombibomb_%s.mdl", clawmodel);
	ArrayPushString(c_zombie_zbomb, filename);
	
	ArrayPushCell(c_zombie_gravity, gravity);
	ArrayPushCell(c_zombie_maxspeed, maxspeed);
	ArrayPushCell(c_zombie_knockback, knockback);
	ArrayPushCell(c_zombie_usemodelindex, usemodelindex);
	ArrayPushCell(c_zombie_level, 1);
	ArrayPushCell(c_zombie_disablesound, 0);
	
	g_class_count++
	return g_class_count - 1;
}
stock SetZombieModel(id, ClassID)
{
	new playermodel[256], indexed, aSkinData[SkinData], classname[32];
	indexed = ArrayGetCell(c_zombie_usemodelindex, ClassID)
	ArrayGetString(c_zombie_sysname, ClassID, classname, 31);
	
	if(GetSkinActive(id, ClassID) == -1)
	{
		ArrayGetString(c_zombie_model, ClassID, playermodel, charsmax(playermodel))
	} else {
		ArrayGetArray(ZSkinAddons, GetSkinActive(id, ClassID), aSkinData);
		format(playermodel, 255, "%s", aSkinData[SkinData_Model]);
	}
	pl_set_user_custom_model(id, 1, playermodel, indexed)
	CheckZombieHand(id)
}
stock CheckZombieHand(id)
{
	new skinactive, clawmodel[128], aSkinData[SkinData], model[64]; 
	skinactive=GetSkinActive(id, g_zombieclass[id])
	
	cs_get_user_model(id, model, charsmax(model))
	if(skinactive != -1)
	{
		ArrayGetArray(ZSkinAddons, skinactive, aSkinData);
		if(!equal(model, aSkinData[SkinData_Model])) 
		{
			goto DefaultHand
		} else {
			if(get_user_weapon(id) == CSW_KNIFE)
			{
				format(clawmodel, 127, "models/zbz/v_knife_%s.mdl", aSkinData[SkinData_ClawModel])
			} else if((1<<get_user_weapon(id)) & CSWPN_NADE) {
				format(clawmodel, 127, "models/zbz/v_zombibomb_%s.mdl", aSkinData[SkinData_ClawModel])
			}
		}
	} else {
		DefaultHand:
		if(get_user_weapon(id) == CSW_KNIFE)
		{
			ArrayGetString(c_zombie_claws, g_zombieclass[id], clawmodel, charsmax(clawmodel))
		} else if((1<<get_user_weapon(id)) & CSWPN_NADE) {
			ArrayGetString(c_zombie_zbomb, g_zombieclass[id], clawmodel, charsmax(clawmodel))
		}
	}
	set_pev(id, pev_weaponmodel2, ((1<<get_user_weapon(id)) & CSWPN_NADE) ? "models/zbz/p_zombibomb.mdl" : "")
	set_pev(id, pev_viewmodel2, clawmodel)
}
stock SetSkinActive(id, iSkin)
{
	new zClass = GetSkinZombieClassIndex(iSkin)
	if(zClass == -1)
		return;
	
	new aSkinData[SkinData]
	for(new x = 0; x < ArraySize(ZSkinAddons); x ++ )
	{
		ArrayGetArray(ZSkinAddons, x, aSkinData);
		if(x != iSkin && GetSkinZombieClassIndex(x) == zClass && g_iUsedSkin[id] & (1 << x))
			g_iUsedSkin[id] &= ~(1 << x)
	}
	g_iUsedSkin[id] |= (1 << iSkin)
}
stock isSkinActive(id, iSkin)
{
	if (g_iUsedSkin[id] & (1 << iSkin)) return 1
	return 0;
}
stock GetSkinActive(id, zClass)
{
	new aSkinData[SkinData]
	for(new x = 0; x < ArraySize(ZSkinAddons); x ++ )
	{
		ArrayGetArray(ZSkinAddons, x, aSkinData);
		if(GetSkinZombieClassIndex(x) == zClass && isSkinActive(id, x))
			return x;
	}
	return -1;
}
stock GetSkinZombieClassIndex(iSkin)
{
	if(!ArraySize(ZSkinAddons) || iSkin > ArraySize(ZSkinAddons)) return -1;
	new szSysName[32], aSkinData[SkinData]; ArrayGetArray(ZSkinAddons, iSkin, aSkinData);
	
	for(new x=0;x<g_class_count;x++)
	{
		ArrayGetString(c_zombie_sysname, x, szSysName, 31)
		if(equal(aSkinData[SkinData_sysname], szSysName))
			return x;
	}
	return -1;
}
stock ResetBalance()
{
	for(new id = 0; id < get_maxplayers(); id ++ )
	{
		if(!is_user_connected(id))
			continue;
			
		g_iBalance[BALANCE_ISZOMBIE][id] = 0
		g_iBalance[BALANCE_ISHERO][id] = 0;
	}
}
stock ShowVirusStatusMessage(mode=0)
{
	for(new id = 0; id < get_maxplayers(); id ++ )
	{
		if(!is_user_connected(id) || is_user_bot(id))
			continue;
		
		set_dhudmessage(200, 140, 0, -1.0, 0.2, 0, 0.0, 4.0, 0.5, 0.5);
		if(mode) show_dhudmessage(id, "The virus has been detoxified. This zombie cannot revive when killed");
		else show_dhudmessage(id, "Zombies will continue to revive until exposed to virus detoxification.");
	}
}
stock ShowChoosedZbMessage()
{
	for(new id = 0; id < get_maxplayers(); id ++ )
	{
		if(!is_user_connected(id) || is_user_bot(id) || !is_user_alive(id) || !g_choosedzb[id] || g_choosedhr[id])
			continue;
		
		set_dhudmessage(200, 140, 0, -1.0, 0.2, 0, 0.0, 4.0, 0.5, 0.5);
		show_dhudmessage(id, "Zombie transformation nearly complete! Go, infect the humans!");
	}
}

stock InitializeMakeRandomZombie()
{	
	new id, alive_count = GetAliveCount()
	new iMaxZombies = floatround(alive_count * c_zombie_ratio, floatround_ceil)
	
	// Randomly turn iMaxZombies players into zombies
	while (get_choosed_alive() < iMaxZombies)
	{
		// Choose random Player
		id = GetRandomAlive(random_num(1, alive_count))
		
		// Dead or already a zombie
		if (!is_user_alive(id) || g_zombie[id] || g_choosedzb[id] || g_iBalance[BALANCE_ISZOMBIE][id])
			continue;
		
		// set as first zombie
		g_choosedzb[id] = 1
	}
}
stock InitializeMakeRandomHero()
{	
	if(!c_enable_hero)
		return;
		
	if(!GetHeroMutationNum())
		return;
		
	new id, alive_count = GetAliveCount()
	new iMaxHeroes = min(floatround(alive_count * 0.085, floatround_ceil), GetHeroMutationNum());
	
	while (get_hero_alive() < iMaxHeroes)
	{
		// Choose random Player
		id = GetRandomAlive(random_num(1, alive_count))
		
		// Dead or already a hero/sidekick
		if (!is_user_alive(id) || g_zombie[id] || g_choosedzb[id] || g_choosedhr[id] || g_iHero[id] || g_iBalance[BALANCE_ISHERO][id])
			continue;
		
		// ready as hero/sidekick
		g_choosedhr[id] = 1;
	}
}
stock CheckMakeRandomZombie()
{
	new iTotal
	for(new id = 0; id < get_maxplayers(); id ++ )
	{
		if(!is_user_connected(id) || !is_user_alive(id) || !g_choosedzb[id] || g_choosedhr[id])
			continue;
		
		g_rage[RAGE_LEVEL][id] = 1
		g_rage[RAGE_STAT][id] = 0
		pev(id, pev_origin, g_vLastOrigin[id])
		ExecuteForward(g_iForward[0], fwResult, id, 0);
		MakeZombie(id)
		g_choosedzb[id] = 0;
		g_iBalance[BALANCE_ISZOMBIE][id] = 1;
		iTotal ++
	}
	
	// make random zombie if choosed player disconnect or die
	if(!iTotal)
	{
		new id, alive_count = GetAliveCount()
		new iMaxZombies = floatround(alive_count * c_zombie_ratio, floatround_ceil)
		
		// Randomly turn iMaxZombies players into zombies
		while (get_zombie_alive() < iMaxZombies)
		{
			// Choose random Player
			id = GetRandomAlive(random_num(1, alive_count))
			
			// Dead or already a zombie
			if (!is_user_alive(id) || g_zombie[id] || g_iBalance[BALANCE_ISZOMBIE][id] || g_choosedhr[id])
				continue;
			
			// set as first zombie
			g_rage[RAGE_LEVEL][id] = 1
			pev(id, pev_origin, g_vLastOrigin[id])
			ExecuteForward(g_iForward[0], fwResult, id, 0);
			MakeZombie(id)
			g_choosedzb[id] = 0;
			g_iBalance[BALANCE_ISZOMBIE][id] = 1;
		}
	}
}
stock CheckMakeHero()
{
	if(!c_enable_hero)
		return;
		
	if(!GetHeroMutationNum())
		return;
		
	for(new id = 0; id < get_maxplayers(); id ++ )
	{
		if(!is_user_connected(id) || !is_user_alive(id) || !g_choosedhr[id])
			continue;
		
		MakeHero(id, random_num(0,1))
		g_choosedhr[id] = 0;
		g_iBalance[BALANCE_ISHERO][id] = 1;
	}
}
stock GetHeroMutationNum()
{
	static iTotal; iTotal=0;
	for(new id = 0; id<get_maxplayers(); id++)
		if(pev_valid(id) && is_user_connected(id) && !g_zombie[id] && !g_choosedzb[id] && !g_iBalance[BALANCE_ISHERO][id]) iTotal++
		
	return iTotal;
}
stock Check_Force_EndRound()
{
	if(g_EndRound || get_player_count() <= 1) return
	
	if(g_NewRound && g_RoundStatus == ROUND_RUNNING)
	{
		if(g_RoundTime > 0)
		{
			if(!get_human_alive())
			{
				play_sound(0, "zombi/win_zombie.wav")
				g_team_score[1] ++
				
				RemoveAllSupply()
				RemoveAllTaskRespawn()
				ResetVipStatus()
				SetScore(1, 3)
				SetScore(2, 1)
				
				send_center_text(c_escape_mode ? "Escape Failed!" : "Zombie Taken out the World!", 5.0, {200, 90, 90}, 0)
				rg_round_end(5.0, WINSTATUS_TERRORISTS, ROUND_TERRORISTS_WIN, c_escape_mode ? "Escape Failed!" : "Zombie Taken out the World!", "zombi/win_zombie.wav")
				g_SupplySpawn = 0
				g_Virus = 0
				g_EndRound = 1
				g_RoundStatus = ROUND_ENDING
			}
			if(!get_zombie_alive() && !(CheckRespawningZombie() && !c_escape_mode))
			{
				g_team_score[2] ++
				
				EndRoundCharaNoise()
				RemoveAllSupply()
				RemoveAllTaskRespawn()
				SetScore(2, 3)
				SetScore(1, 1)
				
				ResetVipStatus()
				send_center_text("All zombie has been eliminated!", 5.0, {168,204,238}, 0)
				rg_round_end(5.0, WINSTATUS_CTS, ROUND_CTS_WIN, "All zombie has been eliminated!", "zombi/win_human.wav")
				g_SupplySpawn = 0
				g_Virus = 0
				g_EndRound = 1
				g_RoundStatus = ROUND_ENDING
			}
			
		}
		else
		{
			if(get_human_alive() && !c_escape_mode)
			{
				EndRoundCharaNoise()
				SetScore(2, 3)
				SetScore(1, 1)
				rg_round_end(5.0, WINSTATUS_CTS, ROUND_CTS_WIN, c_escape_mode ?  "Escape Success!" : "All Humans has been Survived!", "zombi/win_human.wav")
				g_team_score[2] ++
			}
			else
			{
				if(c_escape_mode) KillAllHuman()
				SetScore(1, 1)
				SetScore(1, 3)
				rg_round_end(5.0, WINSTATUS_TERRORISTS, ROUND_TERRORISTS_WIN, c_escape_mode ? "Escape Failed!" : "Zombie Taken out the World!", "zombi/win_zombie.wav")
				g_team_score[1] ++
			}
			RemoveAllSupply()
			RemoveAllTaskRespawn()
			ResetVipStatus()
			g_SupplySpawn = 0
			g_Virus = 0
			g_EndRound = 1
			g_RoundStatus = ROUND_ENDING
		}
	}
}
stock ResetVipStatus()
{
	for(new id = 0; id<get_maxplayers(); id++)
	{
		if(!pev_valid(id) || !is_user_connected(id) || !(get_user_flags(id) & ADMIN_LEVEL_E || get_pcvar_num(cvar_force_vip))) continue;
		g_iVipUser[id] = 1;
	}
}
stock SetScore(team = 0, amount = 1)
{
	for(new id = 0; id<get_maxplayers(); id++)
	{
		if(!pev_valid(id) || !is_user_connected(id) || team != get_user_team(id)) continue;
		set_pev(id, pev_frags, pev(id, pev_frags) + float(amount))
		update_player_score(id)
	}
}
stock RemoveAllTaskRespawn()
{
	for(new id = 0; id<get_maxplayers(); id++)
	{
		if(!pev_valid(id) || !is_user_connected(id)) continue;
		if(task_exists(id + TASK_RESPAWN)) remove_task(id + TASK_RESPAWN)
	}
}
stock KillAllHuman()
{
	for(new id = 0; id<get_maxplayers(); id++)
	{
		if(!pev_valid(id) || !is_user_connected(id) || !is_user_alive(id) || g_zombie[id]) continue;
		user_kill(id)
	}
}
stock EndRoundCharaNoise()
{
	for(new id = 0; id<get_maxplayers(); id++)
	{
		if(!pev_valid(id) || !is_user_connected(id) || !is_user_alive(id) || g_zombie[id]) continue;
		pl_play_voice(id, 1);
	}
}
stock CheckRespawningZombie()
{
	new iTotal = 0
	for(new id = 0; id<get_maxplayers(); id++)
	{
		if(!pev_valid(id) || !is_user_connected(id) || is_user_alive(id) || !g_zombie[id]) continue;
		
		if(task_exists(id + TASK_RESPAWN)) iTotal ++
	}
	return iTotal;
}
stock AnalyzeEscapeTriggerHurt()
{
	new pEnt = -1
	while((pEnt = engfunc(EngFunc_FindEntityByString, pEnt, "classname", "trigger_hurt")) != 0)
	{
		if(!pev_valid(pEnt) || pev(pEnt, pev_dmg) < 5000.0 || !(pev(pEnt, pev_spawnflags) & SF_TRIGGER_HURT_START_OFF))
			continue;
		set_pev(pEnt, pev_dmg, 100000.0 * get_pcvar_float(cvar_ze_hpmult))	
	}
}	
stock AnalyzeEscapeBreakable()
{
	new pEnt = -1
	while((pEnt = engfunc(EngFunc_FindEntityByString, pEnt, "classname", "func_breakable")) != 0)
	{
		if(!pev_valid(pEnt) || pev(pEnt, pev_spawnflags) & SF_BREAK_TRIGGER_ONLY)
			continue;
		set_pev(pEnt, pev_renderamt, 255.0)
		set_pev(pEnt, pev_rendermode, kRenderTransAdd)
		set_pev(pEnt, pev_renderfx, kRenderFxPulseSlowWide);
		set_pev(pEnt, pev_spawnflags, pev(pEnt, pev_spawnflags) &~ SF_BREAK_TOUCH)
	}
}
stock Check_HasPrevious_Buy(id)
{
	if(g_rebuy[id][0] != -1 && g_rebuy[id][1] != -1) return 1
	return 0
}
stock CheckSupplyPoint(Float:vOrigin[3])
{
	new pEnt = -1
	while((pEnt = engfunc(EngFunc_FindEntityInSphere, pEnt, vOrigin, 150.0)) != 0)
	{
		if(!isSupplyBox(pEnt)) continue;
		
		return 0;
	}
	return 1;
}
stock Strip_All(id)
{
	const INVALID_BPAMMO_WPN = (1<<0)|(1<<2)|(1<<6)|(1<<29)
	for(new i = 0; i<=CSW_P90; i++)
		if(!((1<<i) & INVALID_BPAMMO_WPN)) cs_set_user_bpammo(id, i, 0)
		
	Stock_Drop_Slot(id, 1, 1)
	Stock_Drop_Slot(id, 2, 1)
	Stock_Drop_Slot(id, 4, 1)
}
stock ItemPickHandler(id, itemid=0)
{
	if(itemid == EXTRAITEM_AMMO)
	{
		if(!g_zombie[id] && is_user_alive(id))
		{
			GiveAmmo(id)
			GiveAmmo(id, 1)
		}
	}
	if(itemid == EXTRAITEM_FROST)
	{
		if(!g_zombie[id] && !user_has_weapon(id, CSW_FLASHBANG) && is_user_alive(id))
		{
			fm_give_item(id, "weapon_flashbang") 
			if(g_iHasItem[id] & (1<<EXTRAITEM_AMMO)) cs_set_user_bpammo(id, CSW_FLASHBANG, 3)
		}
	}
	if(itemid == EXTRAITEM_VACCINE)
	{
		if(!g_zombie[id] && !user_has_weapon(id, CSW_SMOKEGRENADE) && is_user_alive(id))
		{
			fm_give_item(id, "weapon_smokegrenade") 
			if(g_iHasItem[id] & (1<<EXTRAITEM_AMMO)) cs_set_user_bpammo(id, CSW_FLASHBANG, 3)
		}
	}
}
stock GiveAmmo(id, slot=0)
{
	if(!is_user_alive(id) || g_zombie[id]) return
	
	static weapons[32], num, i, weaponid
	num = 0
	get_user_weapons(id, weapons, num)
	
	for (i = 0; i < num; i++)
	{
		weaponid = weapons[i]
		if(g_iHasItem[id] & (1<<EXTRAITEM_AMMO))
		{
			if (!slot && ((1<<weaponid) & PRIMARY_WEAPONS_BIT_SUM)) cs_set_user_bpammo(id, weaponid, 250)
			else if (slot&& ((1<<weaponid) & SECONDARY_WEAPONS_BIT_SUM)) cs_set_user_bpammo(id, weaponid, 250)
		} else {
			if (!slot && ((1<<weaponid) & PRIMARY_WEAPONS_BIT_SUM)) cs_set_user_bpammo(id, weaponid, Weapon_Bpammo[weaponid])
			else if (slot&& ((1<<weaponid) & SECONDARY_WEAPONS_BIT_SUM)) cs_set_user_bpammo(id, weaponid, Weapon_Bpammo[weaponid])
		}
	}
	
}
stock give_additional_item(id)
{
	if(g_zombie[id])
		return;
		
	new szItem[32]
	for(new i=0; i < ArraySize(AutoItem); i ++ )
	{
		ArrayGetString(AutoItem, i, szItem, 31)
		cs_give_item(id, szItem);
	}
	
	if(user_has_weapon(id, CSW_HEGRENADE))
		cs_set_user_bpammo(id, CSW_HEGRENADE, 2)
	if(g_iHasItem[id] & (1<<EXTRAITEM_FROST) && !user_has_weapon(id, CSW_FLASHBANG))
	{
		fm_give_item(id, "weapon_flashbang")
		if(g_iHasItem[id] & (1<<EXTRAITEM_AMMO))
			cs_set_user_bpammo(id, CSW_FLASHBANG, 3)
	}
	if(g_iHasItem[id] & (1<<EXTRAITEM_VACCINE) && !user_has_weapon(id, CSW_SMOKEGRENADE))
	{
		fm_give_item(id, "weapon_smokegrenade")
		if(g_iHasItem[id] & (1<<EXTRAITEM_AMMO))
			cs_set_user_bpammo(id, CSW_SMOKEGRENADE, 3)
	}

	ExecuteForward(g_iForward[7], fwResult, id);
	cs_set_user_armor(id, c_human_armor, CS_ARMOR_VESTHELM)
	if(pev(id, pev_health) < float(c_human_health)) set_pev(id, pev_health, float(c_human_health))
}

stock auto_give_item(id, advanced=0)
{
	if(!is_user_alive(id) || g_zombie[id])
		return;
		
	Stock_Drop_Slot(id, 1, 1)
	Stock_Drop_Slot(id, 2, 1)
	Stock_Drop_Slot(id, 4, 1)
	cs_remove_item(id, -1, 0)
	cs_remove_item(id, -1, 1)
	cs_remove_item(id, -1, 2)
	cs_remove_item(id, -1, 3)
	
	if(advanced)
	{
		RandomizeWeapon(id, 3, 2)
		RandomizeWeapon(id, 2, 2)
		RandomizeWeapon(id, 1, 2)
		RandomizeWeapon(id, 0, 2)
	} else {
		RandomizeWeapon(id, 3, 1)
		RandomizeWeapon(id, 2, 1)
		RandomizeWeapon(id, 1, 1)
		RandomizeWeapon(id, 0, 1)
	}
	
	GiveAmmo(id)
	GiveAmmo(id, 1)
	
	give_additional_item(id)
}
stock bot_auto_give_item(id)
{
	if(!is_user_alive(id) || g_zombie[id])
		return;
	Stock_Drop_Slot(id, 1, 1)
	Stock_Drop_Slot(id, 2, 1)
	cs_remove_item(id, -1, 0)
	cs_remove_item(id, -1, 1)
		
	if(random(5) == 3)
	{
		RandomizeWeapon(id, 0, 2)
		RandomizeWeapon(id, 1, 2)
	} else {
		RandomizeWeapon(id, 0, 1)
		RandomizeWeapon(id, 1, 1)
	}
	
	give_additional_item(id)
}

stock CheckSelectedWeapon(id)
{
	new item
	for(new x = 0; x < 4; x++)
	{
		item = GetRandomDefaultWeapon(id, x)
		if(g_rebuy[id][x] == -1) g_rebuy[id][x] = item
	}
}
stock GetRandomDefaultWeapon(id, slot=0)
{
	if(!is_user_alive(id) || g_zombie[id])
		return -1;
		
	new itemid, aWpnData[WpnData], fix=0
	itemid = -1
	while(fix == 0)
	{
		if(slot==2) {
			itemid = random(ArraySize(MeleeWPN))
			ArrayGetArray(MeleeWPN, itemid, aWpnData);
		} else if(slot==1) {
			itemid = random(ArraySize(SecWPN))
			ArrayGetArray(SecWPN, itemid, aWpnData);
		} else if(slot==3) {
			itemid = random(ArraySize(NadeWPN))
			ArrayGetArray(NadeWPN, itemid, aWpnData);
		} else {
			itemid = random(ArraySize(PrimWPN))
			ArrayGetArray(PrimWPN, itemid, aWpnData);
		}
		
		if(!HasLimitedWeapon(id, itemid, slot))
			continue;
			
		fix = 1
	}	
	
	return itemid
}
stock RandomizeWeapon(id, slot=0, grade=0)
{
	if(!is_user_alive(id) || g_zombie[id])
		return;

	new itemid, aWpnData[WpnData], fix=0
	while(fix == 0)
	{
		if(slot==2) {
			itemid = random(ArraySize(MeleeWPN))
			ArrayGetArray(MeleeWPN, itemid, aWpnData);
		} else if(slot==1) {
			itemid = random(ArraySize(SecWPN))
			ArrayGetArray(SecWPN, itemid, aWpnData);
		} else if(slot==3) {
			itemid = random(ArraySize(NadeWPN))
			ArrayGetArray(NadeWPN, itemid, aWpnData);
		} else {
			itemid = random(ArraySize(PrimWPN))
			ArrayGetArray(PrimWPN, itemid, aWpnData);
		}
		
		if(aWpnData[WpnData_Grade] > grade)
			continue;
		
		cs_give_item(id, aWpnData[WpnData_Class])
		if(!user_has_weapon(id, CSW_HEGRENADE) && slot==3)
				fm_give_item(id, "weapon_hegrenade")
		fix = 1
	}	
	GiveAmmo(id, slot)
}
stock give_previous_item(id)
{
	if(!is_user_alive(id) || g_zombie[id])
		return;
		
	new aWpnData[WpnData], iGrade
	iGrade = (g_iHero[id] == 1) ? WPNGRADE_PREMIUM : (g_iHero[id] != 2 ? WPNGRADE_NORMAL : WPNGRADE_UNIQUE)
	
	if(g_rebuy[id][3] != -1)
	{
		Stock_Drop_Slot(id, 4, 1);
		cs_remove_item(id, -1, 3)
		ArrayGetArray(NadeWPN, g_rebuy[id][3], aWpnData)
		if(GetWeaponStatus(id, g_rebuy[id][3], 3, iGrade))
		{
			cs_give_item(id, aWpnData[WpnData_Class]);
			if(!user_has_weapon(id, CSW_HEGRENADE))
				fm_give_item(id, "weapon_hegrenade")
		}
	}
	if(g_rebuy[id][2] != -1)
	{
		cs_remove_item(id, -1, 2)
		ArrayGetArray(MeleeWPN, g_rebuy[id][2], aWpnData)
		if(GetWeaponStatus(id, g_rebuy[id][2], 2, iGrade))
		{
			cs_give_item(id, aWpnData[WpnData_Class]);
		}
	}
	if(g_rebuy[id][1] != -1)
	{
		Stock_Drop_Slot(id, 2, 1);
		cs_remove_item(id, -1, 1)
		ArrayGetArray(SecWPN, g_rebuy[id][1], aWpnData)
		if(GetWeaponStatus(id, g_rebuy[id][1], 1, iGrade))
		{
			cs_give_item(id, aWpnData[WpnData_Class]);
			GiveAmmo(id, 1)
		}
	}
	if(g_rebuy[id][0] != -1)
	{
		Stock_Drop_Slot(id, 1, 1);
		cs_remove_item(id, -1, 0)
		ArrayGetArray(PrimWPN, g_rebuy[id][0], aWpnData)
		if(GetWeaponStatus(id, g_rebuy[id][0], 0, iGrade))
		{
			cs_give_item(id, aWpnData[WpnData_Class]);
			GiveAmmo(id)
		}
		
	}
	give_additional_item(id)
}
stock GetWeaponStatus(id, index, slot=0, grade=0)
{
	new aWpnData[WpnData]; ArrayGetArray(slot?(slot==1?SecWPN:(slot==3?NadeWPN:MeleeWPN)):PrimWPN, index, aWpnData);
	
	if(aWpnData[WpnData_Grade] > grade && !HasLimitedWeapon(id, index, slot))
		return 0;
	
	return 1;
}
stock HasLimitedWeapon(id, iWpn, slot=0, herocheck=1)
{
	new aWpnData[WpnData]; ArrayGetArray(slot?(slot==1?SecWPN:(slot==3?NadeWPN:MeleeWPN)):PrimWPN, iWpn, aWpnData);
	
	if(aWpnData[WpnData_Grade] == 0) return 1;
	
	if(get_pcvar_num(cvar_unlock_wpn) >= aWpnData[WpnData_Grade]) return 1;

	if(herocheck)
	{
		if(g_iHero[id] == 2 && aWpnData[WpnData_Grade] == 1) return 1;
		else if(g_iHero[id] == 1) return 1;
	}
	
	if(g_iHasWpn[slot][id] & (1<< iWpn)) return 1;
	
	return 0;
}
stock DecodingReward(id)
{
	new Float:flRandomChance, iSigned = 0;
	if(g_iDecodingCount[0][id] + 1 >= c_decoder_guarantee[0])
	{
		if(!GetRandomItems(id, 1))
		{
			colored_print(id, ">x01[>x04Decoder>x01] You Obtained >x04%i>x01 Guarantee Point", SPARK_UNI);
			g_iSparkPoint[id] += SPARK_UNI;
			play_sound(id, "gachapon/open_weapon_item_top.wav")
		}
		g_iDecodingCount[0][id] = 0;
		return;
	}
	if(g_iDecodingCount[1][id] + 1 >= c_decoder_guarantee[1])
	{
		if(!GetRandomItems(id, 2))
		{
			colored_print(id, ">x01[>x04Decoder>x01] You Obtained >x04%i>x01 Guarantee Point", SPARK_PRE);
			g_iSparkPoint[id] += SPARK_PRE;
			play_sound(id, "gachapon/open_weapon_item_top_sss.wav")
		}
		g_iDecodingCount[1][id] = 0;
		return;
	}

	while(iSigned == 0)
	{
		flRandomChance = random_float(0.0, c_decoder_chance);
		
		if(flRandomChance > c_decoder_rate[0])
		{
			DecoderRandomItem(id)

			g_iDecodingCount[0][id]++
			g_iDecodingCount[1][id]++
			iSigned = 1
			break;
		} 
		else if(flRandomChance < c_decoder_rate[0])
		{
			if(flRandomChance < c_decoder_rate[1])
			{
				if(!GetRandomItems(id, 2))
				{
					colored_print(id, ">x01[>x04Decoder>x01] You Obtained >x04%i>x01 Guarantee Point", SPARK_PRE);
					g_iSparkPoint[id] += SPARK_PRE;
					play_sound(id, "gachapon/open_weapon_item_top_sss.wav")
				}
				g_iDecodingCount[0][id]++
				g_iDecodingCount[1][id] = 0;
				iSigned = 1
				break;
			}
			if(!GetRandomItems(id, 1))
			{
				colored_print(id, ">x01[>x04Decoder>x01] You Obtained >x04%i>x01 Guarantee Point", SPARK_UNI);
				g_iSparkPoint[id] += SPARK_UNI;
				play_sound(id, "gachapon/open_weapon_item_top.wav")
			}
			g_iDecodingCount[0][id] = 0;
			g_iDecodingCount[1][id]++
			iSigned = 1
			break;
		}
	}
}
stock DecoderRandomItem(id)
{
	new szNotice[256], iValue
	switch(random_num(0, 20))
	{
		case 4: 
		{
			iValue = random_num(1000, 2000)
			cs_set_user_money(id, cs_get_user_money(id) + iValue)
			format(szNotice, charsmax(szNotice), "You obtained Money $>x04%i>x01", iValue);
		}
		case 7:
		{
			iValue = random_num(1,3);
			g_iDecoder[id] += iValue
			format(szNotice, charsmax(szNotice), "You obtained extra >x04%ix Decoder>x01", iValue);
		}
		
		case 10:
		{
			iValue = random_num(1, 100)
			format(szNotice, charsmax(szNotice), "You Obtained >x04%i>x01 Guarantee Point", iValue);
			g_iSparkPoint[id] += iValue;
		}
		case 13:
		{
			if(!ArraySize(ZSkinAddons) || hasAllSkin(id)) goto DefaultItem
			else {
				DecodingSkin(id);
				play_sound(id, "gachapon/open_weapon_item_top.wav")
				return;
			}
		}
		case 15:
		{
			iValue = random_num(1, 50)
			format(szNotice, charsmax(szNotice), "You Obtained >x04%i>x01 Guarantee Point", iValue);
			g_iSparkPoint[id] += iValue;
		}
		case 17:
		{
			if(is_user_alive(id))
			{
				iValue = g_zombie[id] ? random_num(300, 600) : random_num(50, 100)
				set_pev(id, pev_health, pev(id, pev_health) + float(iValue))
				format(szNotice, charsmax(szNotice), "You obtained extra >x04%i HP>x01", iValue);
			} else goto DefaultItem
		}

		default:
		{
			DefaultItem:
			iValue = random_num(100, 500)
			cs_set_user_money(id, cs_get_user_money(id) + iValue)
			format(szNotice, charsmax(szNotice), "You obtained Money $>x04%i>x01", iValue);
		}
	}
	g_iSparkPoint[id] += SPARK_NOR
	colored_print(id, ">x01[>x04Decoder>x01] %s", szNotice);
}
stock hasAllWeapons(id, grade=0)
{
	new ItemCount, InvenCount, aWpnData[WpnData]

	if(ArraySize(PrimWPN))
	{
		for(new y=0;y<ArraySize(PrimWPN);y++)
		{
					ArrayGetArray(PrimWPN, y, aWpnData);
					if(aWpnData[WpnData_Grade] == grade) ItemCount++
					if(g_iHasWpn[0][id] & (1<<y)) InvenCount++
		}
	}
	if(ArraySize(SecWPN))
	{
		for(new y=0;y<ArraySize(SecWPN);y++)
		{
					ArrayGetArray(SecWPN, y, aWpnData);
					if(aWpnData[WpnData_Grade] == grade) ItemCount++
					if(g_iHasWpn[1][id] & (1<<y)) InvenCount++
		}
	}
	if(ArraySize(MeleeWPN))
	{
		for(new y=0;y<ArraySize(MeleeWPN);y++)
		{
					ArrayGetArray(MeleeWPN, y, aWpnData);
					if(aWpnData[WpnData_Grade] == grade) ItemCount++
					if(g_iHasWpn[2][id] & (1<<y)) InvenCount++
		}
	}
	if(ArraySize(NadeWPN))
	{
		for(new y=0;y<ArraySize(NadeWPN);y++)
		{
					ArrayGetArray(SecWPN, y, aWpnData);
					if(aWpnData[WpnData_Grade] == grade) ItemCount++
					if(g_iHasWpn[3][id] & (1<<y)) InvenCount++
		}
	}
	
	return (InvenCount >= ItemCount)
}
stock GetItemCount(iSlot=0, grade=0)
{
	new ItemCount, aWpnData[WpnData]
	switch(iSlot)
	{
		case 1: 
		{
			if(ArraySize(SecWPN))
			{
				for(new y=0;y<ArraySize(SecWPN);y++)
				{
					ArrayGetArray(SecWPN, y, aWpnData);
					if(aWpnData[WpnData_Grade] == grade) ItemCount++
				}
			}
		}
		case 2: 
		{
			if(ArraySize(MeleeWPN))
			{
				for(new y=0;y<ArraySize(MeleeWPN);y++)
				{
					ArrayGetArray(MeleeWPN, y, aWpnData);
					if(aWpnData[WpnData_Grade] == grade) ItemCount++
				}
			}
		}
		case 3:
		{
			if(ArraySize(NadeWPN))
			{
				for(new y=0;y<ArraySize(NadeWPN);y++)
				{
					ArrayGetArray(NadeWPN, y, aWpnData);
					if(aWpnData[WpnData_Grade] == grade) ItemCount++
				}
			}
		}
		default: 
		{
			if(ArraySize(PrimWPN))
			{
				for(new y=0;y<ArraySize(PrimWPN);y++)
				{
					ArrayGetArray(PrimWPN, y, aWpnData);
					if(aWpnData[WpnData_Grade] == grade) ItemCount++
				}
			}
		}
	}

	return ItemCount
}
stock GetRandomItems(id, grade=0)
{
	if(hasAllWeapons(id, grade))
		return 0;

	new sig, y, x, szName[64], sWpnName[64],szNotice[256], szGrade[32], aWpnData[WpnData];
	get_user_name(id, szName, 63);
	switch(grade)
	{
		case 1: szGrade = "Unique";
		case 2: szGrade = "Premium";
		default: szGrade = "Normal";
	}

	while(sig==0)
	{
		x = random_num(0,3)
		switch(x)
		{
			case 1: 
			{
				if(!ArraySize(SecWPN) || !GetItemCount(x, grade)) continue;

				y = random_num(0, ArraySize(SecWPN)-1)
				ArrayGetArray(SecWPN, y, aWpnData);
			}
			case 2: 
			{
				if(!ArraySize(MeleeWPN) || !GetItemCount(x, grade)) continue;

				y = random_num(0, ArraySize(MeleeWPN)-1)
				ArrayGetArray(MeleeWPN, y, aWpnData);
			}
			case 3:
			{
				if(!ArraySize(NadeWPN) || !GetItemCount(x, grade)) continue;

				y = random_num(0, ArraySize(NadeWPN)-1)
				ArrayGetArray(NadeWPN, y, aWpnData);
			}
			default: 
			{
				if(!ArraySize(PrimWPN) || !GetItemCount(x, grade)) continue;

				y = random_num(0, ArraySize(PrimWPN)-1)
				ArrayGetArray(PrimWPN, y, aWpnData);
			}
		}
		if(aWpnData[WpnData_Grade] == grade)
		{
			if(!HasLimitedWeapon(id, y, x, 0))
			{
				copy(sWpnName, 63, aWpnData[WpnData_Class])
				replace(sWpnName, 63, "weapon_", "")
				strtoupper(sWpnName);
				format(sWpnName, 63, "%L", LANG_SERVER, sWpnName);
				format(szNotice, charsmax(szNotice), ">x03%s>x01 has obtained %s item >x04%s>x01", szName, szGrade, sWpnName);
				play_sound(id, grade == 2 ? "gachapon/open_weapon_item_top_sss.wav" : "gachapon/open_weapon_item_top.wav")
				colored_print(0, ">x01[>x04Decoder>x01] %s", szNotice);
				g_iHasWpn[x][id] |= (1<<y);
				sig=1
				break;
			} else {
				sig = 2
				break;
			}
		} 
	}
	return (sig==1)
}
stock hasAllSkin(id)
{
	if(!ArraySize(ZSkinAddons))
		return 0;
	
	if(get_pcvar_num(cvar_unlock_allskin))
		return 1;
		
	new iTotal = 0
	for(new x = 0 ; x < ArraySize(ZSkinAddons); x ++ )
	{
		if(g_iHasSkin[id] & (1<<x))
			iTotal ++
	}
	
	if(iTotal >= ArraySize(ZSkinAddons)) return 1;
	return 0;
}
stock DecodingSkin(id)
{
	if(!ArraySize(ZSkinAddons) || hasAllSkin(id) || get_pcvar_num(cvar_unlock_allskin))
		return;
	
	new iSigned, Item, aSkinData[SkinData], szName[64], szNotice[256]
	get_user_name(id, szName, 63);
	while(iSigned != 1)
	{
		Item = random_num(0, ArraySize(ZSkinAddons)-1)
		if(g_iHasSkin[id] & (1<<Item) && !get_pcvar_num(cvar_unlock_allskin)) continue;
		
		ArrayGetArray(ZSkinAddons, Item, aSkinData)
		g_iHasSkin[id] |= (1<<Item)
		iSigned=1
		format(szNotice, charsmax(szNotice), ">x03%s>x01 has obtained >x04%s Skin>x01", szName, aSkinData[SkinData_name]);
		colored_print(0, ">x01[>x04Decoder>x01] %s", szNotice);
	}
}
stock BotGetRandomZombieClass()
{
	new iRandom
	iRandom = random_num(0, g_class_count-1)
	
	return iRandom
}	

stock Stock_Drop_Slot(id, iSlot, Strip) 
{
	new weapons[32], num = 0
	get_user_weapons(id, weapons, num)
	
	for(new i = 0; i < num; i++)
	{
		new slot = Stock_Get_Wpn_Slot(weapons[i])
		if(iSlot == slot)
		{
			static wname[32]
			get_weaponname(weapons[i], wname, charsmax(wname))
			if(Strip)rg_remove_item(id, wname, true)
			else rg_drop_item(id, wname)
		}
	}
}
stock Normalize(Float:fIn[3], Float:fOut[3], Float:fMul)
{
	new Float:fLen = xs_vec_len(fIn)
	xs_vec_copy(fIn, fOut)
	
	fOut[0] /= fLen, fOut[1] /= fLen, fOut[2] /= fLen
	fOut[0] *= fMul, fOut[1] *= fMul, fOut[2] *= fMul
}

stock Stock_Get_Wpn_Slot(iWpn)
{
	if(PRIMARY_WEAPONS_BIT_SUM & (1<<iWpn)) return 1
	else if(SECONDARY_WEAPONS_BIT_SUM & (1<<iWpn)) return 2
	else if(iWpn == CSW_KNIFE) return 3
	else if(iWpn == CSW_HEGRENADE) return 4
	else if(iWpn == CSW_FLASHBANG) return 4
	else if(iWpn == CSW_SMOKEGRENADE) return 4
	else if(iWpn == CSW_C4) return 5
	return 6 //FLASHBANG SMOKEBANG
}
stock GetMaxHealth(id)
{
	if(!g_zombie[id]) return c_human_health
	
	new Float:flMaxHp = float(c_zombie_health[g_rage[RAGE_LEVEL][id]])
	if(c_escape_mode) flMaxHp *= get_pcvar_float(cvar_ze_hpmult)
	
	return floatround(flMaxHp)
}
stock SetKarma(id, Amount)
{
	if(g_iKarma[1][id] >= 3)
		return;
	
	g_iKarma[0][id] += Amount
	while(g_iKarma[0][id] >= MAX_KARMA)
	{
		g_iKarma[1][id] ++
		g_iKarma[0][id] = g_iKarma[1][id] >= 3 ? 0 : max(0, g_iKarma[0][id] - MAX_KARMA)	
	}
}

stock SetRage(id, Amount)
{
	if(g_rage[RAGE_LEVEL][id] >= 2 )
		return;
	
	g_rage[RAGE_STAT][id] += Amount
	while(g_rage[RAGE_STAT][id] >= MAX_RAGE)
	{
		g_rage[RAGE_STAT][id] = 0
		g_rage[RAGE_LEVEL][id] ++
			
		if(g_rage[RAGE_LEVEL][id] > 0)
		{
			new Float:hp = float(c_zombie_health[g_rage[RAGE_LEVEL][id]])
			set_pev(id, pev_health, hp);
			set_pev(id, pev_frags, pev(id, pev_frags) + 1.0)
		}
		set_pev(id, pev_frags, pev(id, pev_frags) + 1.0)
		update_player_score(id)
	}
}
stock FindClosestHuman(id, Float:flRadius)
{
	new iTotal, Float:vOrigin[3], Float:vExtOrigin[3];
	pev(id, pev_origin, vOrigin);
	
	for(new x = 0; x < get_maxplayers(); x ++ )
	{
		if( !pev_valid(x) || !is_user_connected(x) || !is_user_alive(x) || g_zombie[x] || x==id )
			continue;
			
		pev(x, pev_origin, vExtOrigin);
		if(vector_distance(vExtOrigin, vOrigin) <= flRadius)
			iTotal ++
	}
	return iTotal
}
stock IncreaseHumanMorale()
{
	for(new x = 0; x < get_maxplayers(); x ++ )
	{
		if( !is_user_connected(x) || !is_user_alive(x) || g_zombie[x] )
			continue;
			
		SetMorale(x, g_morale[x]+1, 1)
	}
}
stock SetMorale(id, Level, Effect)
{		
	g_morale[id] = clamp(Level, 1, 13);
	set_rendering(id, kRenderFxGlowShell, GetMoraleColor(g_morale[id], 0), GetMoraleColor(g_morale[id], 1), GetMoraleColor(g_morale[id], 2), kRenderNormal)
	
	if(Effect)
	{
		new Float:vOrigin[3]; pev(id, pev_origin, vOrigin)
		
		set_dhudmessage(255, 255, 0, -1.0, 0.25, 0, 6.0, 1.0, 0.0, 0.5)
		show_dhudmessage(id, "Morale Boost Stage %i", g_morale[id])
		
		play_sound(id, "zombi/levelup.wav")
	}
}
stock Float:GetMoraleDamage(Level)
{
	new Float:flDamage
	switch(Level)
	{
		case 1: flDamage = 1.1
		case 2: flDamage = 1.2
		case 3: flDamage = 1.3
		case 4: flDamage = 1.4
		case 5: flDamage = 1.5
		case 6: flDamage = 1.6
		case 7: flDamage = 1.7
		case 8: flDamage = 1.8
		case 9: flDamage = 1.9
		case 10: flDamage = 2.0
		case 11: flDamage = 2.1
		case 12: flDamage = 2.2
		case 13: flDamage = 2.3
		default: flDamage = 1.0
	}
	return flDamage;	
}
stock GetMoraleColor(level, num)
{
	static color[3]
	switch (level)
	{
		case 1: color = {0,177,0}
		case 2: color = {0,177,0}
		case 3: color = {0,177,0}
		case 4: color = {137,191,20}
		case 5: color = {137,191,20}
		case 6: color = {250,229,0}
		case 7: color = {250,229,0}
		case 8: color = {243,127,1}
		case 9: color = {243,127,1}
		case 10: color = {255,3,0}
		case 11: color = {127,40,208}
		case 12: color = {127,40,208}
		case 13: color = {127,40,208}
		default: color = {0,177,0}
	}
	
	return color[num]
}

stock play_message_sound(id, const sound[])
{
	if(g_flLastAnnounce > get_gametime())
		return;
	
	g_flLastAnnounce = get_gametime() + 2.1
	
	client_cmd(id, "spk ^"%s^"", sound)
}
stock play_sound(id, const sound[])
{
	if (equal(sound[strlen(sound)-4], ".mp3"))
		client_cmd(id, "mp3 play ^"sound/%s^"", sound)
	else
		client_cmd(id, "spk ^"%s^"", sound)
}

stock play_mp3_loop(id, const sound[])
{
	if (equal(sound[strlen(sound)-4], ".mp3"))
		client_cmd(id, "mp3 loop ^"sound/%s^"", sound)
	else
		client_cmd(id, "spk ^"%s^"", sound)
}


stock send_center_text(szText[], Float:duration, color[3], team)
{
	for(new id = 0; id<get_maxplayers(); id++)
	{
		if(!pev_valid(id) || is_user_bot(id) || !is_user_connected(id)|| (get_user_team(id) != team && team)) continue;
		
		set_hudmessage(color[0], color[1], color[1], -1.0, 0.3, 0, 0.0, duration, 0.5, 0.5);
		ShowSyncHudMsg(id, g_hud_sync[1], "%s", szText)
		client_cmd(id, "spk vox/msg.wav")
	}
}
stock fix_number(number, reserved, textarg[], len)
{
	new numstr[32]
	if(reserved == 2)
	{
		if (number<0) format(numstr, charsmax(numstr), "0")
		else if (number<10) format(numstr, charsmax(numstr), "0%d", number)
		else format(numstr, charsmax(numstr), "%d", number)
	}
	else if(reserved == 3)
	{
		if (number<0) format(numstr, charsmax(numstr), "0")
		else if (number<10) format(numstr, charsmax(numstr), "00%d", number)
		else if (number<100) format(numstr, charsmax(numstr), "0%d", number)
		else format(numstr, charsmax(numstr), "%d", number)
	}
	else if(reserved >= 4)
	{
		if (number<0) format(numstr, charsmax(numstr), "0")
		else if (number<10) format(numstr, charsmax(numstr), "000%d", number)
		else if (number<100) format(numstr, charsmax(numstr), "00%d", number)
		else if (number<1000) format(numstr, charsmax(numstr), "0%d", number)
		else format(numstr, charsmax(numstr), "%d", number)
	}
	else format(numstr, charsmax(numstr), "%d", number)
	
	format(textarg, len, "%s", numstr)
	return 1
}
stock colored_print(target, const message[], any:...)
{
	static buffer[512], msg_SayText = 0
	if( !msg_SayText ) msg_SayText = get_user_msgid("SayText")
	
	if (!target)
	{
		static player, maxplayers, argscount
		maxplayers = get_maxplayers()
		argscount = numargs()
		
		for (player = 1; player <= maxplayers; player++)
		{
			if (!is_user_connected(player))
				continue;
			
			static arg_index, changed_args[20], changedcount	
			changedcount = 0
			
			for (arg_index = 2; arg_index < argscount; arg_index++)
			{
				if (getarg(arg_index) == LANG_PLAYER && arg_index + 1 < argscount)
				{
					static lang_key[64], arg_subindex
					arg_subindex = 0
					while ((lang_key[arg_subindex] = getarg(arg_index + 1, arg_subindex++))) {}
					if (GetLangTransKey(lang_key) != TransKey_Bad)
					{
						setarg(arg_index, 0, player)
						changed_args[changedcount++] = arg_index
						arg_index++
					}
				}
			}
			
			vformat(buffer, charsmax(buffer), message, 3)
			replace_all(buffer, charsmax(buffer), ">x04", "^x04")
			replace_all(buffer, charsmax(buffer), ">x03", "^x03")
			replace_all(buffer, charsmax(buffer), ">x01", "^x01")
			replace_all(buffer, charsmax(buffer), "!g", "^x04")
			replace_all(buffer, charsmax(buffer), "!t", "^x03")
			replace_all(buffer, charsmax(buffer), "!d", "^x01")
		
			message_begin(MSG_ONE_UNRELIABLE, msg_SayText, _, player)
			write_byte(player)
			write_string(buffer)
			message_end()
			
			for (arg_index = 0; arg_index < changedcount; arg_index++)
				setarg(changed_args[arg_index], 0, LANG_PLAYER)
		}
	} else {
		vformat(buffer, charsmax(buffer), message, 3)
		
		replace_all(buffer, charsmax(buffer), ">x04", "^x04")
		replace_all(buffer, charsmax(buffer), ">x03", "^x03")
		replace_all(buffer, charsmax(buffer), ">x01", "^x01")
		replace_all(buffer, charsmax(buffer), "!g", "^x04")
		replace_all(buffer, charsmax(buffer), "!t", "^x03")
		replace_all(buffer, charsmax(buffer), "!d", "^x01")
		
		message_begin(MSG_ONE, msg_SayText, _, target)
		write_byte(target)
		write_string(buffer)
		message_end()
	}
}
stock get_player_count()
{
	new iTotal=0;
	for(new id = 0; id<get_maxplayers(); id++)
		if(pev_valid(id) && is_user_connected(id) && get_user_team(id) !=3 && get_user_team(id) !=0) iTotal++
		
	return iTotal;
}
stock get_human_alive()
{
	new iTotal=0;
	for(new id = 0; id<get_maxplayers(); id++)
		if(pev_valid(id) && is_user_alive(id) && !g_zombie[id] && get_user_team(id) == 2) iTotal++
		
	return iTotal;
}
stock GetRandomAlive(target_index)
{
	new iAlive, id
	
	for (id = 1; id <= get_maxplayers(); id++)
	{
		if (is_user_alive(id))
			iAlive++
		
		if (iAlive == target_index)
			return id;
	}
	
	return -1;
}
stock GetHudLoc(ent,const Float:origin[3],Float:hudpos[2])
{
	if(!is_user_connected(ent))
		return 0;

	static Float:origin2[3]
	origin2[0] = origin[0]
	origin2[1] = origin[1]
	origin2[2] = origin[2]

	static Float:ent_origin[3]

	pev(ent,pev_origin,ent_origin)

	static Float:ent_angles[3]

	pev(ent,pev_v_angle,ent_angles)

	origin2[0] -= ent_origin[0]
	origin2[1] -= ent_origin[1]
	origin2[2] -= ent_origin[2]

	new Float:v_length
	v_length = vector_length(origin2)

	static Float:aim_vector[3]
	aim_vector[0] = origin2[0] / v_length
	aim_vector[1] = origin2[1] / v_length
	aim_vector[2] = origin2[2] / v_length

	static Float:new_angles[3]
	vector_to_angle(aim_vector,new_angles)

	new_angles[0] *= -1

	if(new_angles[1]>180.0) new_angles[1] -= 360.0
	if(new_angles[1]<-180.0) new_angles[1] += 360.0
	if(new_angles[1]==180.0 || new_angles[1]==-180.0) new_angles[1]=-179.999999

	if(new_angles[0]>180.0) new_angles[0] -= 360.0
	if(new_angles[0]<-180.0) new_angles[0] += 360.0
	if(new_angles[0]==90.0) new_angles[0]=89.999999
	else if(new_angles[0]==-90.0) new_angles[0]=-89.999999

	new Float:fov
	pev(ent,pev_fov,fov)

	if(!fov)
		fov = 90.0

	if(floatabs(ent_angles[0] - new_angles[0]) <= fov/2 && floatabs((180.0 - floatabs(ent_angles[1])) - (180.0 - floatabs(new_angles[1]))) <= fov/2)
	{
		hudpos[1] = 1 - ( ( (ent_angles[0] - new_angles[0]) + fov/2 ) / fov )
		hudpos[0] = ( (ent_angles[1] - new_angles[1]) + fov/2 ) / fov
	}
	else
		return 0;

	return 1;
}
stock SetUserUnstuck(id)
{
	if(!is_user_alive(id)) return;
	
	static Float:vOrigin[3], Float:vMins[3], Float:vVec[3], iHull, o;
	pev(id, pev_origin, vOrigin);
	iHull = pev(id, pev_flags) & FL_DUCKING ? HULL_HEAD : HULL_HUMAN
	
	if (!is_hull_vacant(vOrigin, iHull) && pev(id, pev_movetype) != MOVETYPE_NOCLIP && !(pev(id,pev_solid) & SOLID_NOT)) 
	{
		pev(id, pev_mins, vMins)
		vVec[2] = vOrigin[2]
		for (o=0; o < sizeof szOffsetSize; ++o)
		{
			vVec[0] = vOrigin[0] - vMins[0] * szOffsetSize[o][0]
			vVec[1] = vOrigin[1] - vMins[1] * szOffsetSize[o][1]
			vVec[2] = vOrigin[2] - vMins[2] * szOffsetSize[o][2]
			if (is_hull_vacant(vVec, iHull)) 
			{
				engfunc(EngFunc_SetOrigin, id, vVec)
				set_pev(id,pev_velocity,{0.0,0.0,0.0})
				o = sizeof szOffsetSize
			}
		}
	}
}
stock GetSupplyCount()
{
	new pEnt, iTotal=0;
	pEnt = -1
	while(( pEnt = engfunc(EngFunc_FindEntityByString, pEnt, "classname", "zombiezsupply")) != 0 )
	{
		if(!isSupplyBox(pEnt)) continue;
		
		iTotal ++
	}
		
	return iTotal;
}
stock RemoveAllSupply()
{
	new pEnt = -1
	while(( pEnt = engfunc(EngFunc_FindEntityByString, pEnt, "classname", "zombiezsupply")) != 0 )
	{
		if(!isSupplyBox(pEnt)) continue;
		
		engfunc(EngFunc_RemoveEntity, pEnt);
	}
}
stock isGrenade(iEnt)
{
	if (!pev_valid(iEnt)) return 0;
	
	new szClassname[32]
	pev(iEnt, pev_classname, szClassname, charsmax(szClassname))
	if (equal(szClassname, "grenade")) return 1;
	return 0;
}
stock isBreakable(iEnt)
{
	if (!pev_valid(iEnt)) return 0;
	
	new szClassname[32]
	pev(iEnt, pev_classname, szClassname, charsmax(szClassname))

	if (equal(szClassname, "func_breakable") || equal(szClassname, "func_pushable")) return 1;
	return 0;
}
stock isTrigger(iEnt)
{
	if (!pev_valid(iEnt)) return 0;
	
	new szClassname[32]
	pev(iEnt, pev_classname, szClassname, charsmax(szClassname))
	if (equal(szClassname, "trigger_multiple")) return 1;
	return 0;
}
stock isSupplyBox(iEnt)
{
	if (!pev_valid(iEnt)) return 0;
	
	new szClassname[32]
	pev(iEnt, pev_classname, szClassname, charsmax(szClassname))
	if (equal(szClassname, "zombiezsupply")) return 1;
	return 0;
}
stock Stock_MakeKnockback(iEnt, Float:fEntOrigin[3], Float:fPoint[3], Float:fDistance, Float:fDamage)
{
	new Float:fTime = floatdiv(fDistance, fDamage)
	new Float:fVelocity[3], Float:fEntVelocity[3];
	pev(iEnt, pev_velocity, fEntVelocity);
	fVelocity[0] = floatdiv((fEntOrigin[0] - fPoint[0]), fTime)
	fVelocity[1] = floatdiv((fEntOrigin[1] - fPoint[1]), fTime)
	fVelocity[2] = floatdiv((fEntOrigin[2] - fPoint[2]), fTime)
	xs_vec_add(fEntVelocity, fVelocity, fVelocity);
	fVelocity[2] += 100.0
	set_pev(iEnt, pev_velocity, fVelocity)
	return 1
}

stock get_hero_alive()
{
	new iTotal=0;
	for(new id = 0; id<get_maxplayers(); id++)
		if(is_user_connected(id) && is_user_alive(id) && !g_zombie[id] && g_choosedhr[id]) iTotal++
		
	return iTotal;
}
stock get_choosed_alive()
{
	new iTotal=0;
	for(new id = 0; id<get_maxplayers(); id++)
		if(is_user_connected(id) && is_user_alive(id) && g_choosedzb[id]) iTotal++
		
	return iTotal;
}
stock get_zombie_alive()
{
	new iTotal=0;
	for(new id = 0; id<get_maxplayers(); id++)
		if(is_user_connected(id) && is_user_alive(id) && g_zombie[id]) iTotal++
		
	return iTotal;
}

stock GetAliveCount()
{
	new iAlive, id
	
	for (id = 1; id <= get_maxplayers(); id++)
	{
		if (is_user_alive(id))
			iAlive++
	}
	
	return iAlive;
}
stock ResetValuePlayer()
{
	for(new id = 0; id<get_maxplayers(); id++)
	{
		if(!pev_valid(id) || !is_user_connected(id)) continue;
		
		if(get_user_team(id)==3 || get_user_team(id)==0)
			continue;
			
		rg_set_user_team(id, TEAM_CT)
		pl_reset_user_model_index(id)
		pl_reset_user_model(id)
		pl_set_user_sound(id, 0)
		
		g_iHero[id] = 0;
		g_zombie[id] = 0;
		g_respawnzb[id] = 0;
		
		
		if(get_user_weapon(id) == CSW_KNIFE)
			set_pev(id, pev_viewmodel2, "models/v_knife.mdl");
		
		cs_set_user_armor(id, c_human_armor, CS_ARMOR_VESTHELM)
		set_pev(id, pev_health, float(c_human_health))
		set_pev(id, pev_gravity, c_human_gravity)
		set_pev(id, pev_maxspeed, g_oldmaxspeed[id])
		
		remove_task(id+TASK_RANDOM_WEAPON)
		remove_task(id+TASK_RESPAWN)
	}
}

stock HookEnt(ent, Float:VicOrigin[3], Float:speed, type)
{
	static Float:fl_Velocity[3]
	static Float:EntOrigin[3], Float:vEntVelocity[3]
	
	pev(ent, pev_origin, EntOrigin)
	static Float:distance_f
	distance_f = get_distance_f(EntOrigin, VicOrigin)
	
	new Float:fl_Time = distance_f / speed
	
	if(type == 1)
	{
		fl_Velocity[0] = ((VicOrigin[0] - EntOrigin[0]) / fl_Time) * 1.5
		fl_Velocity[1] = ((VicOrigin[1] - EntOrigin[1]) / fl_Time) * 1.5
		fl_Velocity[2] = (VicOrigin[2] - EntOrigin[2]) / fl_Time		
	} else if(type == 2) {
		fl_Velocity[0] = ((EntOrigin[0] - VicOrigin[0]) / fl_Time) * 1.5
		fl_Velocity[1] = ((EntOrigin[1] - VicOrigin[1]) / fl_Time) * 1.5
		fl_Velocity[2] = (EntOrigin[2] - VicOrigin[2]) / fl_Time
	}
	
	new ducking = pev(ent, pev_flags) & (FL_DUCKING | FL_ONGROUND) == (FL_DUCKING | FL_ONGROUND)
	
	if(ducking) xs_vec_mul_scalar(fl_Velocity, 0.25, fl_Velocity)
	pev(ent, pev_velocity, vEntVelocity)
	xs_vec_add(vEntVelocity, fl_Velocity, fl_Velocity)
	entity_set_vector(ent, EV_VEC_velocity, fl_Velocity)
}

stock ZBombSlapAngle(id)
{
	new Float:vAngle[3];
	pev(id, pev_punchangle, vAngle)
	vAngle[0] += (random(5)>3) ? -20.0 : 20.0;
	vAngle[1] += (random(5)>3) ? -20.0 : 20.0;
	set_pev(id, pev_punchangle, vAngle)
}

stock MsgBarTime(iPlayer, iBarScale) 
{
	message_begin(MSG_ONE, get_user_msgid("BarTime"), _, iPlayer)
	write_short(iBarScale)
	message_end()
}
stock update_player_score(id)
{
	// Update scoreboard with attacker and victim info
	message_begin(MSG_BROADCAST, get_user_msgid("ScoreInfo"))
	write_byte(id) // id
	write_short(pev(id, pev_frags)) // frags
	write_short(cs_get_user_deaths(id)) // deaths
	write_short(0) // class?
	write_short(get_user_team(id)) // team
	message_end()
}
stock set_player_light(id, const LightStyle[])
{
	message_begin(MSG_ONE, SVC_LIGHTSTYLE, .player = id)
	write_byte(0)
	write_string(LightStyle)
	message_end()
}

stock is_weapon_entity(iEnt)
{
	if(!pev_valid(iEnt)) return 0;
	
	// dont check knife and grenade
	new szClassName[33];
	pev(iEnt, pev_classname, szClassName, 32);
	if(equal(szClassName, "weaponbox") || equal(szClassName, "armoury_entity") || equal(szClassName, "weapon_shield") || 
		equal(szClassName, "weapon_ak47") || equal(szClassName, "weapon_m4a1") || equal(szClassName, "weapon_sg552") || 
		equal(szClassName, "weapon_aug") || equal(szClassName, "weapon_galil") || equal(szClassName, "weapon_famas") ||
		equal(szClassName, "weapon_ump45") || equal(szClassName, "weapon_scout") || equal(szClassName, "weapon_awp") ||
		equal(szClassName, "weapon_g3sg1") || equal(szClassName, "weapon_sg550") || equal(szClassName, "weapon_mp5navy") ||
		equal(szClassName, "weapon_mac10") || equal(szClassName, "weapon_p90") || equal(szClassName, "weapon_tmp") || 
		equal(szClassName, "weapon_m249") || equal(szClassName, "weapon_m3") || equal(szClassName, "weapon_xm1014") ||
		equal(szClassName, "weapon_p228") || equal(szClassName, "weapon_usp") || equal(szClassName, "weapon_deagle") || 
		equal(szClassName, "weapon_glock18") || equal(szClassName, "weapon_elites") || equal(szClassName, "weapon_fiveseven"))
		return 1;
	return 0
}
stock is_using_default_weapon(id)
{
	if(!is_user_connected(id) || !is_user_alive(id))
		return 0;

	new szModel[128]; pev(id, pev_viewmodel2, szModel, charsmax(szModel))
	replace_all(szModel, charsmax(szModel), "models/v_", "")
	replace_all(szModel, charsmax(szModel), ".mdl", "")

	new szDefModel[][] = { "ak47","m4a1","famas","aug","galil","m249","knife","sg550","g3sg1","mp5","p90","ump45","deagle","mac10","tmp","sg552","awp",
		"p228","scout","usp","glock18","fiveseven","elite","xm1014","m3" }

	for(new x=0;x<sizeof(szDefModel);x++)
	{
		if(equal(szModel, szDefModel[x]))
			return 1;
	}

	return 0;
}
stock cs_set_user_nvg_active(id, active)
{
	// Toggle NVG message
	message_begin(MSG_ONE, g_MsgNVGToggle, _, id)
	write_byte(active) // toggle
	message_end()
}
// Fix Dead Attrib on scoreboard
stock FixDeadAttrib(id)
{
	message_begin(MSG_BROADCAST, get_user_msgid("ScoreAttrib"))
	write_byte(id) // id
	write_byte(0) // attrib
	message_end()
}
//==========================
// random spawn
//==========================

// Place user at a random spawn
stock do_random_spawn(id, csdmspawns = true)
{
	new hull, spawn_index, current_index
	
	// Get whether the player is crouching
	hull = (pev(id, pev_flags) & FL_DUCKING) ? HULL_HEAD : HULL_HUMAN
	
	// Use CSDM spawns?
	if (csdmspawns && g_SpawnCountCSDM)
	{
		// Choose random spawn to start looping at
		spawn_index = random_num(0, g_SpawnCountCSDM - 1)
		
		// Try to find a clear spawn
		for (current_index = spawn_index + 1; /*no condition*/; current_index++)
		{
			// Start over when we reach the end
			if (current_index >= g_SpawnCountCSDM) current_index = 0
			
			// Fetch spawn data: origin
			static Float:spawndata[3]
			spawndata[0] = g_spawns_csdm[current_index][SPAWN_DATA_ORIGIN_X]
			spawndata[1] = g_spawns_csdm[current_index][SPAWN_DATA_ORIGIN_Y]
			spawndata[2] = g_spawns_csdm[current_index][SPAWN_DATA_ORIGIN_Z]
			
			// Free spawn space?
			if (is_hull_vacant(spawndata, hull))
			{
				// Engfunc_SetOrigin is used so ent's mins and maxs get updated instantly
				engfunc(EngFunc_SetOrigin, id, spawndata)
				
				// Fetch spawn data: angles
				spawndata[0] = g_spawns_csdm[current_index][SPAWN_DATA_ANGLES_X]
				spawndata[1] = g_spawns_csdm[current_index][SPAWN_DATA_ANGLES_Y]
				spawndata[2] = g_spawns_csdm[current_index][SPAWN_DATA_ANGLES_Z]
				set_pev(id, pev_angles, spawndata)
				
				// Fetch spawn data: view angles
				spawndata[0] = g_spawns_csdm[current_index][SPAWN_DATA_V_ANGLES_X]
				spawndata[1] = g_spawns_csdm[current_index][SPAWN_DATA_V_ANGLES_Y]
				spawndata[2] = g_spawns_csdm[current_index][SPAWN_DATA_V_ANGLES_Z]
				set_pev(id, pev_v_angle, spawndata)
				
				break;
			}
			
			// Loop completed, no free space found
			if (current_index == spawn_index) break;
		}
	}
	else if (g_SpawnCountRegular)
	{
		// Choose random spawn to start looping at
		spawn_index = random_num(0, g_SpawnCountRegular - 1)
		
		// Try to find a clear spawn
		for (current_index = spawn_index + 1; /*no condition*/; current_index++)
		{
			// Start over when we reach the end
			if (current_index >= g_SpawnCountRegular) current_index = 0
			
			// Fetch spawn data: origin
			static Float:spawndata[3]
			spawndata[0] = g_spawns_regular[current_index][SPAWN_DATA_ORIGIN_X]
			spawndata[1] = g_spawns_regular[current_index][SPAWN_DATA_ORIGIN_Y]
			spawndata[2] = g_spawns_regular[current_index][SPAWN_DATA_ORIGIN_Z]
			
			// Free spawn space?
			if (is_hull_vacant(spawndata, hull))
			{
				// Engfunc_SetOrigin is used so ent's mins and maxs get updated instantly
				engfunc(EngFunc_SetOrigin, id, spawndata)
				
				// Fetch spawn data: angles
				spawndata[0] = g_spawns_regular[current_index][SPAWN_DATA_ANGLES_X]
				spawndata[1] = g_spawns_regular[current_index][SPAWN_DATA_ANGLES_Y]
				spawndata[2] = g_spawns_regular[current_index][SPAWN_DATA_ANGLES_Z]
				set_pev(id, pev_angles, spawndata)
				
				// Fetch spawn data: view angles
				spawndata[0] = g_spawns_regular[current_index][SPAWN_DATA_V_ANGLES_X]
				spawndata[1] = g_spawns_regular[current_index][SPAWN_DATA_V_ANGLES_Y]
				spawndata[2] = g_spawns_regular[current_index][SPAWN_DATA_V_ANGLES_Z]
				set_pev(id, pev_v_angle, spawndata)
				
				break;
			}
			
			// Loop completed, no free space found
			if (current_index == spawn_index) break;
		}
	}
}

// Checks if a space is vacant (credits to VEN)
stock is_hull_vacant(Float:origin[3], hull)
{
	engfunc(EngFunc_TraceHull, origin, origin, 0, hull, 0, 0)
	
	if (!get_tr2(0, TR_StartSolid) && !get_tr2(0, TR_AllSolid) && get_tr2(0, TR_InOpen))
		return true;
	
	return false;
}


// Collect random spawn points
stock load_spawns()
{
	// Check for CSDM spawns of the current map
	new cfgdir[32], mapname[32], filepath[100], linedata[64]
	get_configsdir(cfgdir, charsmax(cfgdir))
	get_mapname(mapname, charsmax(mapname))
	formatex(filepath, charsmax(filepath), "%s/csdm/%s.spawns.cfg", cfgdir, mapname)
	
	// Load CSDM spawns if present
	if (file_exists(filepath))
	{
		new csdmdata[10][6], file = fopen(filepath,"rt")
		
		while (file && !feof(file))
		{
			fgets(file, linedata, charsmax(linedata))
			
			// invalid spawn
			if(!linedata[0] || str_count(linedata,' ') < 2) continue;
			
			// get spawn point data
			parse(linedata,csdmdata[0],5,csdmdata[1],5,csdmdata[2],5,csdmdata[3],5,csdmdata[4],5,csdmdata[5],5,csdmdata[6],5,csdmdata[7],5,csdmdata[8],5,csdmdata[9],5)
			
			// origin
			g_spawns_csdm[g_SpawnCountCSDM][SPAWN_DATA_ORIGIN_X] = floatstr(csdmdata[0])
			g_spawns_csdm[g_SpawnCountCSDM][SPAWN_DATA_ORIGIN_Y] = floatstr(csdmdata[1])
			g_spawns_csdm[g_SpawnCountCSDM][SPAWN_DATA_ORIGIN_Z] = floatstr(csdmdata[2])
			
			// angles
			g_spawns_csdm[g_SpawnCountCSDM][SPAWN_DATA_ANGLES_X] = floatstr(csdmdata[3])
			g_spawns_csdm[g_SpawnCountCSDM][SPAWN_DATA_ANGLES_Y] = floatstr(csdmdata[4])
			g_spawns_csdm[g_SpawnCountCSDM][SPAWN_DATA_ANGLES_Z] = floatstr(csdmdata[5])
			
			// view angles
			g_spawns_csdm[g_SpawnCountCSDM][SPAWN_DATA_V_ANGLES_X] = floatstr(csdmdata[7])
			g_spawns_csdm[g_SpawnCountCSDM][SPAWN_DATA_V_ANGLES_Y] = floatstr(csdmdata[8])
			g_spawns_csdm[g_SpawnCountCSDM][SPAWN_DATA_V_ANGLES_Z] = floatstr(csdmdata[9])
			
			// increase spawn count
			g_SpawnCountCSDM++
			if (g_SpawnCountCSDM >= sizeof g_spawns_csdm) break;
		}
		if (file) fclose(file)
	}
	else
	{
		// Collect regular spawns
		collect_spawns_ent("info_player_start")
		collect_spawns_ent("info_player_deathmatch")
	}
}

// Collect spawn points from entity origins
stock collect_spawns_ent(const classname[])
{
	new Float:data[3]
	new ent = -1
	while ((ent = engfunc(EngFunc_FindEntityByString, ent, "classname", classname)) != 0)
	{
		// get origin
		pev(ent, pev_origin, data)
		g_spawns_regular[g_SpawnCountRegular][SPAWN_DATA_ORIGIN_X] = data[0]
		g_spawns_regular[g_SpawnCountRegular][SPAWN_DATA_ORIGIN_Y] = data[1]
		g_spawns_regular[g_SpawnCountRegular][SPAWN_DATA_ORIGIN_Z] = data[2]
		
		// angles
		pev(ent, pev_angles, data)
		g_spawns_regular[g_SpawnCountRegular][SPAWN_DATA_ANGLES_X] = data[0]
		g_spawns_regular[g_SpawnCountRegular][SPAWN_DATA_ANGLES_Y] = data[1]
		g_spawns_regular[g_SpawnCountRegular][SPAWN_DATA_ANGLES_Z] = data[2]
		
		// view angles
		pev(ent, pev_v_angle, data)
		g_spawns_regular[g_SpawnCountRegular][SPAWN_DATA_V_ANGLES_X] = data[0]
		g_spawns_regular[g_SpawnCountRegular][SPAWN_DATA_V_ANGLES_Y] = data[1]
		g_spawns_regular[g_SpawnCountRegular][SPAWN_DATA_V_ANGLES_Z] = data[2]
		
		// increase spawn count
		g_SpawnCountRegular++
		if (g_SpawnCountRegular >= sizeof g_spawns_regular) break;
	}
}

// Stock by (probably) Twilight Suzuka -counts number of chars in a string
stock str_count(const str[], searchchar)
{
	new count, i, len = strlen(str)
	
	for (i = 0; i <= len; i++)
	{
		if(str[i] == searchchar)
			count++
	}
	
	return count;
}

stock load_supply_spawn()
{
	new path[128], linedata[64], maps[64];get_mapname(maps, 63);
	format(path, 127, "maps/data/%s.supply", maps);
	
	if(!file_exists(path))
	{
		return 0;
	}
	
	new csdmdata[10][6], file = fopen(path,"rt")
		
	while (file && !feof(file))
	{
		fgets(file, linedata, charsmax(linedata))
			
		// invalid spawn
		if(!linedata[0] || str_count(linedata,' ') < 2) continue;
			
		// get spawn point data
		parse(linedata,csdmdata[0],5,csdmdata[1],5,csdmdata[2],5,csdmdata[3],5,csdmdata[4],5,csdmdata[5],5,csdmdata[6],5,csdmdata[7],5,csdmdata[8],5,csdmdata[9],5)
			
		// origin
		g_spawns_box[g_SpawnCountBox][SPAWN_DATA_ORIGIN_X] = floatstr(csdmdata[0])
		g_spawns_box[g_SpawnCountBox][SPAWN_DATA_ORIGIN_Y] = floatstr(csdmdata[1])
		g_spawns_box[g_SpawnCountBox][SPAWN_DATA_ORIGIN_Z] = floatstr(csdmdata[2])
		
		// increase spawn count
		g_SpawnCountBox++
		if (g_SpawnCountBox >= sizeof g_spawns_box) break;
	}
	if (file) fclose(file)
	return 1;
}
/* AMXX-Studio Notes - DO NOT MODIFY BELOW HERE
*{\\ rtf1\\ ansi\\ deff0{\\ fonttbl{\\ f0\\ fnil Tahoma;}}\n\\ viewkind4\\ uc1\\ pard\\ lang1033\\ f0\\ fs16 \n\\ par }
*/
