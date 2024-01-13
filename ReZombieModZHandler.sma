#include <amxmodx>
#include <amxmisc>
#include <fakemeta>
#include <cstrike>
#include <csm>
#include <zombiemodlimited>
#include <hamsandwich>
#include <fakemeta_util>
#include <reapi>
#include <explosion>

enum
{
	MUT_RAPIDMONEY,	// 0
	MUT_DOUBLEJUMP,
	MUT_KANGAROO,
	MUT_ICARUS,
	MUT_HERO,
	MUT_CHEETAH,	//5
	MUT_REGENUP,
	MUT_COOPERATIVES,
	MUT_SIXSENSE,
	MUT_CRITICALSTRIKE,
	MUT_BOMBER,	//10
	MUT_RAPIDNADE,	
	MUT_EXPLOSIVEROUND,	
	MUT_INCBULLET,
	MUT_FIREBALL,
	MUT_PENETRATE,	//15
	MUT_INVISIBLERELOAD,	
	MUT_RAPIDRELOAD,	
	MUT_LONGJUMP,
	MUT_HPUP,		
	MUT_MONEYPOWER,	//20
	MUT_BOXER,	
	MUT_BOOSTER,
	MUT_VACCINE,
	MUT_FROST,	
	MUT_DROPFALL,	//25
	MUT_SPECIALIST,
	MUT_DASHCROUCH,	
	MUT_REVENGE,
	MUT_CONTACT,
	MUT_MAMOOTH,	//30
	MUT_STEELHEAD,	
	MUT_ENHANCLAW,	
	MUT_STEELSKIN,
	MUT_RESSURECT,
	MUT_STEELARMOR,	//35
	MUT_REGENBOMB,
	MUT_ADAPTATION,
	MUT_BOMBHARDENING,
	MUT_REINFORCE,
	MUT_INTELECTUAL,	//40
	MUT_HOMINGNADE,
	MUT_GRENADEPACK,
	MUT_HEALPARTY,
	MUT_ELITIST,
	MUT_IMMORTALITY,	//45
	MUT_LUCKY,
	MUT_DEMOLITION,
	MUT_INFECTIONBOMB,
	MUT_POISON,
	MUT_CRIMSON,	//50
	MUT_DISCOUNT,
	MUT_EARLYACCESS
}

new const szMutationName[][] = 
{
	"MUT_RAPIDMONEY",	// 0
	"MUT_DOUBLEJUMP",
	"MUT_KANGAROO",
	"MUT_ICARUS",
	"MUT_HERO",
	"MUT_CHEETAH",	//5
	"MUT_REGENUP",
	"MUT_COOPERATIVES",
	"MUT_SIXSENSE",
	"MUT_CRITICALSTRIKE",
	"MUT_BOMBER",	//10
	"MUT_RAPIDNADE",	
	"MUT_EXPLOSIVEROUND",	
	"MUT_INCBULLET",
	"MUT_FIREBALL",
	"MUT_PENETRATE",	//15
	"MUT_INVISIBLERELOAD",	
	"MUT_RAPIDRELOAD",	
	"MUT_LONGJUMP",
	"MUT_HPUP",		
	"MUT_MONEYPOWER",	//20
	"MUT_BOXER",	
	"MUT_BOOSTER",
	"MUT_VACCINE",
	"MUT_FROST",	
	"MUT_DROPFALL",	//25
	"MUT_SPECIALIST",
	"MUT_DASHCROUCH",	
	"MUT_REVENGE",
	"MUT_CONTACT",
	"MUT_MAMOOTH",	//30
	"MUT_STEELHEAD",	
	"MUT_ENHANCLAW",	
	"MUT_STEELSKIN",
	"MUT_RESSURECT",
	"MUT_STEELARMOR",	//35
	"MUT_REGENBOMB",
	"MUT_ADAPTATION",
	"MUT_BOMBHARDENING",
	"MUT_REINFORCE",
	"MUT_INTELECTUAL",	//40
	"MUT_HOMINGNADE",
	"MUT_GRENADEPACK",
	"MUT_HEALPARTY",
	"MUT_ELITIST",
	"MUT_IMMORTALITY",	//45
	"MUT_LUCKY",
	"MUT_DEMOLITION",
	"MUT_INFECTIONBOMB",
	"MUT_POISON",
	"MUT_CRIMSON",	//50
	"MUT_DISCOUNT",
	"MUT_EARLYACCESS"
}

new iMutTeams[] = { 0 , 0 , 0 , 0 , 0 , 0 , 0 , 0 , 2 , 2 , 2 , 2 , 2 , 2 , 2 , 2 , 2 , 2 , 2 , 0 , 2 , 2 , 2 , 2 , 2 , 2 , 2 , 1 , 1 , 1 , 1 , 1 , 1 , 1 , 1 , 1 , 1 , 1 , 1 , 1 , 0 , 0 , 2 , 1 , 2 , 0 , 0 , 2 , 1, 1, 2, 0, 0}
new const szMutationInfo[][] = 
{
	"MUT_RAPIDMONEY_DESC",	// 0
	"MUT_DOUBLEJUMP_DESC",
	"MUT_KANGAROO_DESC",
	"MUT_ICARUS_DESC",
	"MUT_HERO_DESC",
	"MUT_CHEETAH_DESC",	//5
	"MUT_REGENUP_DESC",
	"MUT_COOPERATIVES_DESC",
	"MUT_SIXSENSE_DESC",
	"MUT_CRITICALSTRIKE_DESC",
	"MUT_BOMBER_DESC",	//10
	"MUT_RAPIDNADE_DESC",	
	"MUT_EXPLOSIVEROUND_DESC",	
	"MUT_INCBULLET_DESC",
	"MUT_FIREBAL_DESCL",
	"MUT_PENETRATE_DESC",	//15
	"MUT_INVISIBLERELOAD_DESC",	
	"MUT_RAPIDRELOAD_DESC",	
	"MUT_LONGJUMP_DESC",
	"MUT_HPUP_DESC",		
	"MUT_MONEYPOWER_DESC",	//20
	"MUT_BOXER_DESC",	
	"MUT_BOOSTER_DESC",
	"MUT_VACCINE_DESC",
	"MUT_FROST_DESC",	
	"MUT_DROPFALL_DESC",	//25
	"MUT_SPECIALIST_DESC",
	"MUT_DASHCROUCH_DESC",	
	"MUT_REVENGE_DESC",
	"MUT_CONTACT_DESC",
	"MUT_MAMOOTH_DESC",	//30
	"MUT_STEELHEAD_DESC",	
	"MUT_ENHANCLAW_DESC",	
	"MUT_STEELSKIN_DESC",
	"MUT_RESSURECT_DESC",
	"MUT_STEELARMOR_DESC",	//35
	"MUT_REGENBOMB_DESC",
	"MUT_ADAPTATION_DESC",
	"MUT_BOMBHARDENING_DESC",
	"MUT_REINFORCE_DESC",
	"MUT_INTELECTUAL_DESC",	//40
	"MUT_HOMINGNADE_DESC",
	"MUT_GRENADEPACK_DESC",
	"MUT_HEALPARTY_DESC",
	"MUT_ELITIST_DESC",
	"MUT_IMMORTALITY_DESC",	//45
	"MUT_LUCKY_DESC",
	"MUT_DEMOLITION_DESC",
	"MUT_INFECTIONBOMB_DESC",
	"MUT_POISON_DESC",
	"MUT_CRIMSON_DESC",	//50
	"MUT_DISCOUNT_DESC",
	"MUT_EARLYACCESS_DESC"
}
new g_iNumMutations[2][33], g_iHasMutations[33][53], g_Jump[33], g_JumpNum[33], g_iHoldingJump[33], Float:g_flJumpTime[33], Float:g_flLastLeap[3][33], g_iManual[33];
new g_iTraceDmg[33], g_iLastHitGroup[33], g_SteelSkin[33], Float:g_flSteelSkinTime[33], Float:g_flIncBulletTime[33][33], g_IncBulletNum[33][33], g_iGrenData[33][4], g_szGrenModel[33][128];
new Float:g_flLastMamooth[33], Float:g_flLastFB[33], Float:g_flLastExpBullet[33], Float:g_flLastBoxing[33], g_Frozen[33], Float:g_flFrozenTime[33], Float:g_flLastReceivedBomb[33]
new Float:g_flSenseTime[33], Float:g_flCritical[33], g_iUsedSkill[2][33], Float:g_flSkillTime[2][33], Float:g_flHealTime[33], g_iHealStat[33], Float:g_flBotUseMut[33], g_GrenMode[33]
new Float:g_flGrenadeTime[3][33], g_iGrenadeNum[3][33], Float:g_flOldMaxSpeed[33], g_iStartDucking[33], Float:g_flLastBomb, Float:flNadeTime[33], g_iLeapMana[33];
new Float:g_flSmokeTime[8192], Float:g_flDamageAreaTime[2][8192], g_isProtected[33], Float:g_flProtectedTime[33], g_iHadReset[33], Float:g_flLastPoison[33], g_iLeapFlags[33]
new g_Hud[5],cvar_max_reset, cvar_reset_cost, zBot

enum 
{
	GRENDATA_IMPULSE,
	GRENDATA_IUSER2,
	GRENDATA_IUSER3,
	GRENDATA_BODY
}
enum
{
	GRENMODE_NORMAL,
	GRENMODE_HOMING,
	GRENMODE_LASERTRIP,
	GRENMODE_SPY
}

new const szGrenMode[4][] = { "Normal" , "Homing" , "Laser Trip" , "Motion" }
enum _:SKILL
{
	SKILL_SPRINT,
	SKILL_DEADLYSHOT
}
new const szSkillStat[3][] = { "Used", "Ready", "Activated" }

#define FIREBALL_MODEL	"models/zbz/ef_fireball.mdl"
#define MARKBOMB_MODEL	"models/zbz/bunkerbuster_target.mdl"
#define BOMB_MODEL		"models/zbz/bunkerbuster.mdl"
#define FROGBOMB_MODEL	"models/zbz/w_zombibomb.mdl"

#define LEAP_SPEED			650.0
#define LEAP_MAXMANA		1000
#define LEAP_RECHARGERATE	10
#define LEAP_MANA			300
#define LEAP_MANA_ESCAPE	900
#define LEAP_RECHARGEINTERVAL	0.05
#define LEAP_INTERVAL		1.0
#define LEAP_LANDINGJETS_MANA	100

#define LEAP_FLAG_NOTREADY	(1<<0)
#define LEAP_FLAG_INAIR	(1<<1)

new const ZBombBounceSound[2][] = { "zombi/zombi_bomb_bounce_1.wav" , "zombi/zombi_bomb_bounce_2.wav"}

const CSWPN_SILENT	= ((1<<CSW_USP)|(1<<CSW_M4A1))
const CSWPN_NOTREMOVE = (1<<CSW_SMOKEGRENADE)|(1<<CSW_FLASHBANG)|(1<<CSW_C4)
const DONT_CHECK_WEAPONS_BITSUM = (1<<0)|(1<<2)|(1<<CSW_XM1014)|(1<<CSW_M3)|(1<<CSW_KNIFE)
const WEAPON_SHOTGUN = (1<<CSW_XM1014)|(1<<CSW_M3)
const CSWPN_UNNAMED = (1<<0)|(1<<2)
const CSWPN_SMG = (1<<CSW_MP5NAVY)|(1<<CSW_TMP)|(1<<CSW_MAC10)|(1<<CSW_UMP45)|(1<<CSW_P90)
const CSWPN_NOCLIP = (1<<CSW_KNIFE)|(1<<CSW_HEGRENADE)|(1<<CSW_FLASHBANG)|(1<<CSW_SMOKEGRENADE)|(1<<CSW_C4)
const DAMAGE_NOBUFF = (DMG_BURN)|(DMG_NERVEGAS)|(DMG_RADIATION)|(DMG_CRUSH)|(1<<24)
const CSWPN_NADE= (1<<CSW_SMOKEGRENADE)|(1<<CSW_FLASHBANG)|(1<<CSW_HEGRENADE)

const CSWPN_PISTOL = (1<<CSW_USP)|(1<<CSW_GLOCK18)|(1<<CSW_P228)|(1<<CSW_DEAGLE)|(1<<CSW_FIVESEVEN)|(1<<CSW_ELITE)
const CSWPN_SNIPER = (1<<CSW_SCOUT)|(1<<CSW_AWP)|(1<<CSW_SG550)|(1<<CSW_G3SG1)

new Float:flWeaponMaxSpeed[]={250.0, 250.0, 0.0, 260.0, 250.0, 240.0, 250.0, 250.0, 240.0, 250.0, 250.0, 250.0, 250.0, 
			210.0, 240.0, 240.0, 250.0, 250.0, 210.0, 250.0, 220.0, 230.0, 230.0, 250.0, 210.0, 250.0, 250.0, 235.0, 221.0, 250.0, 245.0}
new const WEAPON_NAME[][] = { "", "weapon_p228", "", "weapon_scout", "weapon_hegrenade", "weapon_xm1014", "weapon_c4", "weapon_mac10",
			"weapon_aug", "weapon_smokegrenade", "weapon_elite", "weapon_fiveseven", "weapon_ump45", "weapon_sg550",
			"weapon_galil", "weapon_famas", "weapon_usp", "weapon_glock18", "weapon_awp", "weapon_mp5navy", "weapon_m249",
			"weapon_m3", "weapon_m4a1", "weapon_tmp", "weapon_g3sg1", "weapon_flashbang", "weapon_deagle", "weapon_sg552",
			"weapon_ak47", "weapon_knife", "weapon_p90"
}

native cs_zb_is_defending(id)
forward fw_CSZB_ZombiBomb_Explode(Ent, Attacker)
//###############################################
// PLUGINS
//###############################################
public plugin_precache()
{
	engfunc(EngFunc_PrecacheModel, FIREBALL_MODEL);
	engfunc(EngFunc_PrecacheModel, MARKBOMB_MODEL);
	engfunc(EngFunc_PrecacheModel, BOMB_MODEL);
	engfunc(EngFunc_PrecacheModel, FROGBOMB_MODEL);
	
	for(new x = 0; x < sizeof( ZBombBounceSound ); x ++ )
		engfunc(EngFunc_PrecacheSound, ZBombBounceSound[x]);
		
	engfunc(EngFunc_PrecacheModel, "models/zbz/frozen.mdl");
	engfunc(EngFunc_PrecacheModel, "models/zbz/zombiezclaw.mdl");
	engfunc(EngFunc_PrecacheModel, "models/zbz/zombiezwingfx.mdl");
	engfunc(EngFunc_PrecacheModel, "models/zbz/spit.mdl");

	engfunc(EngFunc_PrecacheModel, "sprites/frostexp_1.spr");
	engfunc(EngFunc_PrecacheModel, "sprites/frostexp_2.spr");
	engfunc(EngFunc_PrecacheModel, "sprites/ef_coilmg.spr");
	engfunc(EngFunc_PrecacheModel, "sprites/zbt_invincibility.spr");
	engfunc(EngFunc_PrecacheModel, "sprites/flame_burn01.spr");
	engfunc(EngFunc_PrecacheModel, "sprites/gas_smoke1.spr")
	engfunc(EngFunc_PrecacheModel, "sprites/spr_boomer.spr");

	engfunc(EngFunc_PrecacheSound, "deathmatch/jumpmod_long1.wav");
	engfunc(EngFunc_PrecacheSound, "deathmatch/jumpmod_fall.wav");
	engfunc(EngFunc_PrecacheSound, "deathmatch/jumpmod_deny.wav");
	engfunc(EngFunc_PrecacheSound, "deathmatch/jumpmod_ready.wav");
	engfunc(EngFunc_PrecacheSound, "deathmatch/jumpmod_boost2.wav");
	engfunc(EngFunc_PrecacheSound, "deathmatch/jet_flyby1.wav");
	engfunc(EngFunc_PrecacheSound, "weapons/stormgiant_hit1.wav");
	engfunc(EngFunc_PrecacheSound, "weapons/frostnova.wav");
	engfunc(EngFunc_PrecacheSound, "weapons/bunkerbuster_explosion_1st.wav");
	engfunc(EngFunc_PrecacheSound, "weapons/mine_deploy.wav");
	engfunc(EngFunc_PrecacheSound, "zombi/firezombi_splat1.wav")
	
}
public plugin_init()
{
	register_forward(FM_Think, "fw_Think");
	register_forward(FM_Touch, "fw_Touch");
	register_forward(FM_SetModel, "fw_SetModel");
	register_forward(FM_AddToFullPack, "fw_addToFullPack", 1)
	
	RegisterHam(Ham_Touch, "grenade", "fw_Grenade_Touch")
	RegisterHam(Ham_Think, "grenade", "fw_Grenade_Think")
	RegisterHam(Ham_Killed, "player", "HamF_Killed")
	RegisterHam(Ham_TakeDamage, "player", "HamF_TakeDamage")
	RegisterHam(Ham_TraceAttack, "player", "HamF_TraceAttack")

	register_clcmd("say /mutation", "clcmd_mutation");
	register_clcmd("say /show_mutation", "clcmd_showmutation");
	register_clcmd("say_team /mutation", "clcmd_mutation");
	register_clcmd("say_team /show_mutation", "clcmd_showmutation");
	register_clcmd("say /resetmutation", "clcmd_resetmutation");
	register_clcmd("say_team /resetmutation", "clcmd_resetmutation");
	
	register_clcmd("testmutation", "clcmd_testmutation")
	register_clcmd("resetmutation", "clcmd_resetmutation");
	register_clcmd("mutation", "clcmd_mutation");
	register_clcmd("show_mutation", "clcmd_showmutation");
	register_clcmd("deadly", "clcmd_skillhumanskilldeadly")
	register_clcmd("sprint", "clcmd_skillhumanskillsprint")
	
	cvar_max_reset = register_cvar("mp_zombie_mutation_resetlimit", "50")
	cvar_reset_cost = register_cvar("mp_zombie_mutation_resetcost", "25000")
	
	for(new x = 0; x < sizeof(g_Hud); x ++)
		g_Hud[x] = CreateHudSyncObj();
		
	for(new i = 1; i <= CSW_P90; i++)
	{
		if(WEAPON_NAME[i][0])
		{
			if(!(CSWPN_NOTREMOVE & (1<<i))) 
			{
				RegisterHam(Ham_Weapon_PrimaryAttack, WEAPON_NAME[i], "HamF_Weapon_PrimaryAttack")
				RegisterHam(Ham_CS_Item_GetMaxSpeed, WEAPON_NAME[i], "HamF_Item_MaxSpeed")
			}
		}
	}	
	RegisterHookChain(RG_CBaseEntity_FireBullets, "OnFireBullets_Pre")
}
//###############################################
// NATIVE
//###############################################
public plugin_natives()
{
	register_native("cs_zb_get_skill_status", "native_skill_status", 1);
	register_native("cs_zb_set_auto_mutating", "native_set_auto_mutating", 1);
	register_native("cs_zb_get_auto_mutating", "native_get_auto_mutating", 1);
	register_native("cs_zb_get_reset_mutating_count", "native_get_count_mutating", 1);
	register_native("cs_zb_get_reset_mutating_max", "native_get_max_mutating", 1);
	register_native("cs_zb_get_reset_mutating_cost", "native_get_cost_mutating", 1);
}
public native_skill_status(index, skill)
{
	if(!is_user_connected(index) || !is_user_alive(index) || cs_zb_is_zombie(index)) return 0;
	
	return g_iUsedSkill[skill][index]
}
public native_set_auto_mutating(index, active)
{
	if(!is_user_connected(index)) return;
	
	g_iManual[index] = active;
}
public native_get_auto_mutating(index)
{
	if(!is_user_connected(index)) return 0;
	
	return g_iManual[index];
}
public native_get_count_mutating(index)
{
	if(!is_user_connected(index)) return 0;

	return g_iHadReset[index]
}
public native_get_max_mutating()
{
	return get_pcvar_num(cvar_max_reset)
}
public native_get_cost_mutating()
{
	return get_pcvar_num(cvar_reset_cost)
}
//###############################################
// ZBOT
//###############################################
public RegHamBot(id)
{
	RegisterHamFromEntity(Ham_Killed, id, "HamF_Killed")
	RegisterHamFromEntity(Ham_TakeDamage, id, "HamF_TakeDamage")
	RegisterHamFromEntity(Ham_TraceAttack, id, "HamF_TraceAttack")
}
//###############################################
// CLIENT
//###############################################
public client_putinserver(id)
{
	if(!zBot && is_user_bot(id) && get_cvar_num("bot_quota"))
	{
		zBot = 1
		set_task(0.1, "RegHamBot", id)
	}
	
	for(new x = 0 ; x < sizeof(szMutationName); x ++ )
	{
		g_iHasMutations[id][x] = 0;
	}

	g_iHadReset[id] = 0;
	g_iNumMutations[0][id] = max(1, GetHighestLevel() - 3);
	
	g_iTraceDmg[id] = 0;
	g_GrenMode[id] = 0;
	for(new x = 0 ; x < 4; x ++ )
		g_iGrenData[id][x] = 0;
	
	g_szGrenModel[id] = ""
}
public client_disconnected(id)
{
	for(new x = 0 ; x < sizeof(szMutationName); x ++ )
	{
		g_iHasMutations[id][x] = 0;
	}
	ResetIncBullet(id)
	
	g_iNumMutations[0][id] = 0;
	g_iNumMutations[1][id] = 0;
	
	g_iStartDucking[id] = 0;
	g_iUsedSkill[0][id] = 0;
	g_iUsedSkill[1][id] = 0;
	g_iHadReset[id] = 0;
	g_GrenMode[id] = 0;
	g_iManual[id] = 0;
	g_iTraceDmg[id] = 0;
	ClearModdedGrenade(id)
	
	for(new x = 0 ; x < 4; x ++ )
		g_iGrenData[id][x] = 0;
	
	g_szGrenModel[id] = ""
}

//###############################################
// CLIENT COMMAND & INFO
//###############################################

public clcmd_resetmutation(id)
{
	if(g_iHadReset[id] >= get_pcvar_num(cvar_max_reset))
	{
		client_print(id, print_center, "You only have %i chance to reset mutation on this map!", get_pcvar_num(cvar_max_reset))
		return;
	}
	if(cs_get_user_money(id) < get_pcvar_num(cvar_reset_cost))
	{
		client_print(id, print_center, "Reset mutation for $%i !", get_pcvar_num(cvar_reset_cost))
		return;
	}
	cs_set_user_money(id, cs_get_user_money(id) - get_pcvar_num(cvar_reset_cost))
	
	for(new x = 0 ; x < sizeof(szMutationName); x ++ )
	{
		g_iHasMutations[id][x] = 0;
	}
	ResetIncBullet(id)
	ResetHandlerData(id)
	
	client_print(id, print_center, "Your mutation has been Re-Claimed!")
	
	if(is_user_alive(id))
	{
		if(user_has_weapon(id, CSW_FLASHBANG)) rg_remove_item(id, "weapon_flashbang", true)
		if(user_has_weapon(id, CSW_SMOKEGRENADE)) rg_remove_item(id,"weapon_smokegrenade", true)
	}
	g_iNumMutations[0][id] = cs_zb_get_level(id);
	g_iNumMutations[1][id] = 0;
	
	g_iHadReset[id] ++
	
	g_GrenMode[id] = 0;
	g_iStartDucking[id] = 0;
	g_iUsedSkill[0][id] = 0;
	g_iUsedSkill[1][id] = 0;
}
public clcmd_mutation(id)
{
	if(!is_user_alive(id) ) 
		return 0;
	
	if(!g_iManual[id] && g_iNumMutations[0][id] > 0)
	{
		client_print(id, print_center, "Manual Mutation Mode");
		g_iManual[id] = 1;
	}	
	AchieveRandomMutation(id);
	return 1;
}
public clcmd_showmutation(id)
{
	new Txt[256], Data[2], iMenu
	
	format(Txt, charsmax(Txt), "\wMutation List [\y%i\w]", g_iNumMutations[1][id])
	iMenu = menu_create(Txt, "MutationInfoHandler")
	for(new x = 0 ; x < sizeof(szMutationName); x ++ )
	{
		if(!g_iHasMutations[id][x] || iMutTeams[x] != 0) continue;
		
		format(Txt, charsmax(Txt), "[ALL] %L", LANG_PLAYER, szMutationName[x]);
		
		Data[0] = x
		menu_additem(iMenu, Txt, Data);
	}
	for(new x = 0 ; x < sizeof(szMutationName); x ++ )
	{
		if(!g_iHasMutations[id][x] || iMutTeams[x] != 2) continue;
		
		format(Txt, charsmax(Txt), "[\yHuman\w] %L", LANG_PLAYER, szMutationName[x]);
		
		Data[0] = x
		menu_additem(iMenu, Txt, Data);
	}
	for(new x = 0 ; x < sizeof(szMutationName); x ++ )
	{
		if(!g_iHasMutations[id][x] || iMutTeams[x] != 1) continue;
		
		format(Txt, charsmax(Txt), "[\rZombie\w] %L", LANG_PLAYER, szMutationName[x]);
		
		Data[0] = x
		menu_additem(iMenu, Txt, Data);
	}
	set_pdata_int(id, 205, 0);
	menu_display(id, iMenu);
}
public MutationInfoHandler(id, menuid, item)
{
	if (item == MENU_EXIT)
	{
		menu_destroy(menuid)
		return;
	}
	
	new data[32], dummy
	menu_item_getinfo(menuid, item, dummy, data, charsmax(data), _, _, dummy)
	
	MutationInfoDisplay(id, data[0])
}
public MutationInfoDisplay(id, mutindex)
{
	new Txt[256], iMenu
	
	format(Txt, charsmax(Txt), "\w[\r%L\w]", LANG_PLAYER, szMutationName[mutindex]);
	iMenu = menu_create(Txt, "MutationDisplayInfoHandler")
	format(Txt, charsmax(Txt), "%L", LANG_PLAYER, szMutationInfo[mutindex]);
	menu_additem(iMenu, Txt, "")
	
	set_pdata_int(id, 205, 0);
	menu_display(id, iMenu);
}
public MutationDisplayInfoHandler(id, menuid, item)
{
	menu_destroy(menuid)
}
public clcmd_testmutation(id)
{
	if(!get_cvar_num("mp_zombie_admin_testmode"))
		return 0;
		
	new Txt[256], Data[2], iMenu
	
	format(Txt, charsmax(Txt), "\w%L [\y%i\w]", LANG_PLAYER, "MUTATION_TEST", g_iNumMutations[1][id])
	iMenu = menu_create(Txt, "TestMutationHandler")
	for(new x = 0 ; x < sizeof(szMutationName); x ++ )
	{
		if(iMutTeams[x] == 1) format(Txt, charsmax(Txt), "[\rZombie\w] %L [%s]", LANG_PLAYER, szMutationName[x], g_iHasMutations[id][x] ? "\rActivated\w" : "\dDisabled\w");
		else if(iMutTeams[x] == 2) format(Txt, charsmax(Txt), "[\yHuman\w] %L [%s]", LANG_PLAYER, szMutationName[x], g_iHasMutations[id][x] ? "\rActivated\w" : "\dDisabled\w");
		else format(Txt, charsmax(Txt), "[ALL] %L [%s]", LANG_PLAYER, szMutationName[x], g_iHasMutations[id][x] ? "\rActivated\w" : "\dDisabled\w");
		
		Data[0] = x
		menu_additem(iMenu, Txt, Data);
	}
	set_pdata_int(id, 205, 0);
	menu_display(id, iMenu);
	return 1;
}
public TestMutationHandler(id, menuid, item)
{
	if (item == MENU_EXIT || !get_cvar_num("mp_zombie_admin_testmode"))
	{
		menu_destroy(menuid)
		return;
	}
	
	new data[32], dummy
	menu_item_getinfo(menuid, item, dummy, data, charsmax(data), _, _, dummy)
	
	g_iHasMutations[id][data[0]] = 1 - g_iHasMutations[id][data[0]]
	if(g_iHasMutations[id][data[0]] == 0) {
		DeachieveHandler(id, data[0])
		cs_zb_set_level(id, cs_zb_get_level(id)-1)
	} else {
		AchieveHandler(id, data[0])
		cs_zb_set_level(id, cs_zb_get_level(id)+1)
	}
	clcmd_testmutation(id)
}
public clcmd_skillhumanskilldeadly(id)
{
	if(!is_user_alive(id) || cs_zb_is_zombie(id) || !g_iHasMutations[id][MUT_SPECIALIST])
		return;
	if(cs_zb_get_round_status() != ROUND_RUNNING)
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
	if(!is_user_alive(id) || cs_zb_is_zombie(id) || !g_iHasMutations[id][MUT_SPECIALIST])
		return;
	if(cs_zb_get_round_status() != ROUND_RUNNING)
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

//###############################################
// RAGE
//###############################################

public OnFireBullets_Pre( id, cShots, Float:vecSrc[3],  Float:vecDirShooting[3], Float:vecSpread[3], Float:flDistance, iBulletType, iTracerFreq, iDamage, pevAttacker)
{
	if(get_user_weapon(id) != CSW_M3 || get_user_weapon(id) != CSW_XM1014 || !g_iHasMutations[id][MUT_PENETRATE])
		return
	
	xs_vec_mul_scalar(vecSpread, 0.1, vecSpread)
	SetHookChainArg(5, ATYPE_VECTOR, vecSpread)
}

//###############################################
// FAKEMETA
//###############################################

public fw_addToFullPack(es, e, ent, host, hostflags, player, pSet)
{
	if(!pev_valid(host))
		return FMRES_IGNORED;
		
	new id = pev(host, pev_iuser2)
	if(!pev_valid(id) || !(pev_valid(id) && pev(host, pev_iuser1) == 4)) id = host
	
	
	if(isIgnoreOwner(ent))
	{
		new iOwner = pev(ent, pev_owner)
		if(id == iOwner)
		{
			set_es(es, ES_Effects, get_es(es, ES_Effects) | EF_NODRAW)
		}
		
	}
	return FMRES_IGNORED;
}
public fw_SetModel(Ent , const Model[])
{
	if(!pev_valid(Ent)) 
		return FMRES_IGNORED
	static szClass[32]
	pev(Ent, pev_classname, szClass, 31);
	if(!equal(szClass, "grenade"))
		return FMRES_IGNORED
	
	static id; id = pev(Ent, pev_owner)
	if(!pev_valid(id) || !is_user_connected(id))
		return FMRES_IGNORED;
		
	if(Model[7] == 'w' && Model[8] == '_' && Model[9] == 'h' && Model[10] == 'e')
	{
		set_pev(Ent, pev_gamestate, g_GrenMode[id])
		
		if(!cs_zb_is_zombie(id))
		{
			set_pev(Ent, pev_iuser4, 2000);
			if(g_iHasMutations[id][MUT_RAPIDNADE])
			{
				g_iGrenadeNum[0][id] += 3
				g_flGrenadeTime[0][id] = get_gametime() + 1.0;
			}
		}
	}
	if(!cs_zb_is_zombie(id))
	{
		if(Model[7] == 'w' && Model[8] == '_' && Model[9] == 'f' && Model[10] == 'l')
		{
			set_pev(Ent, pev_gamestate, g_GrenMode[id])
			set_pev(Ent, pev_iuser4, 2001);
			if(g_iHasMutations[id][MUT_RAPIDNADE])
			{
				g_iGrenadeNum[1][id] += 3
				g_flGrenadeTime[1][id] = get_gametime() + 1.0;
			}
		}
		if(Model[7] == 'w' && Model[8] == '_' && Model[9] == 's' && Model[10] == 'm')
		{
			set_pev(Ent, pev_gamestate, g_GrenMode[id])
			set_pev(Ent, pev_iuser4, 2002);
			set_pev(Ent, pev_fuser2, get_gametime()+1.7)
			set_pev(Ent, pev_dmgtime, get_gametime()+20.7)
			if(g_iHasMutations[id][MUT_RAPIDNADE])
			{
				g_iGrenadeNum[2][id] += 3
				g_flGrenadeTime[2][id] = get_gametime() + 1.0;
			}
		}
	}
	return FMRES_IGNORED;
}
public fw_Think(Ent)
{
	if(!pev_valid(Ent)) 
		return;

	static szClass[32]
	pev(Ent, pev_classname, szClass, 31);
	if(equal(szClass, "bomb_mark"))
	{
		BombThink(Ent);
	}
	if(equal(szClass, "zombiezclaw"))
	{
		engfunc(EngFunc_RemoveEntity, Ent);	
	}
	if(equal(szClass, "zombiezglow"))
	{
		static Float:flFrame, szModel[64]; 
		pev(Ent, pev_model, szModel, 63);
		pev(Ent, pev_frame, flFrame);
		
		if(flFrame >= engfunc(EngFunc_ModelFrames, szModel))
			set_pev(Ent, pev_frame, 0.0);
			
		set_pev(Ent, pev_frame, flFrame + 1.0);
		if(get_gametime() >= pev(Ent, pev_dmgtime))
		{
			engfunc(EngFunc_RemoveEntity, Ent);
			return;
		}
		set_pev(Ent, pev_nextthink, get_gametime() + 0.05);
	}
	if(isSpit(Ent)) SpitThink(Ent)
	if(equal(szClass, "zombiezdamage"))
		VaccineDamaging(Ent)
	if(equal(szClass, "zombiezinfectdamage"))
		InfectionDamaging(Ent)
	if(isSmoke(Ent))
		SmokeThink(Ent)
	
	
}

public fw_Touch(Ent, Ptd)
{
	if(!pev_valid(Ent)) 
		return;

	static szClass[32]
	pev(Ent, pev_classname, szClass, 31);
	if(equal(szClass, "bunker_bomb"))
	{
		BombHit(Ent);
		engfunc(EngFunc_RemoveEntity, Ent);
	}
	if(equal(szClass, "zombiezfireball"))
	{
		FireBall_Impact(Ent)
		engfunc(EngFunc_RemoveEntity, Ent);
	}
	if(pev_valid(Ptd) && is_user_alive(Ptd) && is_user_alive(Ent))
	{
		if(cs_zb_is_zombie(Ent) && !cs_zb_is_zombie(Ptd) && g_iHasMutations[Ent][MUT_CONTACT])
		{
			if(g_flLastPoison[Ent] <= get_gametime())
			{
				ExecuteHamB(Ham_TakeDamage, Ptd, Ent, Ent, cs_zb_is_defending(Ptd) ? 50.0 : 1000.0, DMG_BULLET);
				g_flLastPoison[Ent] = get_gametime() + 1.0;
			}
		}
	}
	if(isSpit(Ent)) SpitImpact(Ent, Ptd)
}
//###############################################
// HAM
//###############################################

public HamF_Item_MaxSpeed(Ent)
{
	if(!pev_valid(Ent)) 
		return HAM_IGNORED;
		
	if(GetHamReturnStatus() == HAM_SUPERCEDE)
		return HAM_IGNORED;
		
	new id = get_pdata_cbase(Ent, 41, 4);
	if(get_pdata_cbase(id, 373) != Ent || !is_user_alive(id))
		return HAM_IGNORED;
		
	if((1 << get_pdata_int(Ent, 43, 4)) & CSWPN_SNIPER)
		return HAM_IGNORED;
	if(cs_zb_is_zombie(id))
		return HAM_IGNORED;
	
	new Float:flSpeed, Float:flMulSpeed
	flSpeed = flWeaponMaxSpeed[get_pdata_int(Ent, 43, 4)]
	if(g_iHasMutations[id][MUT_CHEETAH])
		flMulSpeed = cs_zb_is_escape_mode() ? 1.5 : 1.1;
	if(g_iHasMutations[id][MUT_BOOSTER] && (1 << get_pdata_int(Ent, 43, 4)) & CSWPN_SMG)
	{
		flMulSpeed = cs_zb_is_escape_mode() ? 1.51 : 1.11;
	}
	if(flMulSpeed > 0.0)
	{
		SetHamReturnFloat(floatmin(320.0, flSpeed * flMulSpeed));
		return HAM_SUPERCEDE;
	}
	return HAM_IGNORED;
}
public fw_Grenade_Think(Ent)
{
	if(!pev_valid(Ent)) 
		return HAM_IGNORED;
		
		
	static id; id = pev(Ent, pev_owner)
	if(!pev_valid(id))
		return HAM_IGNORED;
		
	if(cs_zb_is_zombie(id) && pev(Ent, pev_iuser1) == 477 && pev(Ent, pev_iuser4) == 2003)
	{
		engfunc(EngFunc_RemoveEntity, Ent)
		return HAM_IGNORED;
	}
			
	static Float:vOrigin[3]; pev(Ent, pev_origin, vOrigin);
	if(pev(Ent, pev_gamestate) == GRENMODE_HOMING && pev(Ent, pev_iuser4) != 2002)
	{
		set_pev(Ent, pev_euser2, cs_zb_is_zombie(id))
		
		message_begin(MSG_BROADCAST, SVC_TEMPENTITY)
		write_byte(123)
		engfunc(EngFunc_WriteCoord, vOrigin[0]);
		engfunc(EngFunc_WriteCoord, vOrigin[1]);
		engfunc(EngFunc_WriteCoord, vOrigin[2]);
		write_short(1)
		write_short(engfunc(EngFunc_ModelIndex, "sprites/gas_smoke1.spr"))
		write_byte(1)
		write_byte(8|1)
		write_byte(10)
		message_end()
		
		HomingNade(Ent)
	}
	else if (pev(Ent, pev_gamestate) == GRENMODE_LASERTRIP && pev(Ent, pev_movetype) == 0)
	{
		if(!TripNadesThink(Ent) && pev(Ent, pev_euser3) != 1)
		{
			set_pev(Ent, pev_dmgtime, get_gametime()+999.0)
			if(pev(Ent, pev_iuser4) == 2002 && pev(Ent, pev_iuser3)!=1)
				set_pev(Ent, pev_fuser2, get_gametime() + 999.0)
				
			set_pev(Ent, pev_nextthink, get_gametime())
			return HAM_SUPERCEDE;
		} else {
			if(pev(Ent, pev_euser3) != 1)
			{
				if(pev(Ent, pev_iuser4) != 2002) set_pev(Ent, pev_dmgtime, 0.0)
				if(pev(Ent, pev_iuser4) == 2002 && pev(Ent, pev_iuser3)!=1)
					set_pev(Ent, pev_fuser2, 0.0)
					
				set_pev(Ent, pev_euser3, 1)
				set_pev(Ent, pev_nextthink, get_gametime())
				
				new iBeam = pev(Ent, pev_euser4);
				if(pev_valid(iBeam)) engfunc(EngFunc_RemoveEntity, iBeam);
			}
		}
	}
	else if (pev(Ent, pev_gamestate) == GRENMODE_SPY)
	{
		if(!SpyNadesGetEnemys(Ent, id) && pev(Ent, pev_euser3) != 1)
		{
			set_pev(Ent, pev_dmgtime, get_gametime()+999.0)
			if(pev(Ent, pev_iuser4) == 2002 && pev(Ent, pev_iuser3)!=1)
				set_pev(Ent, pev_fuser2, get_gametime() + 999.0)
				
			set_pev(Ent, pev_nextthink, get_gametime())
			return HAM_SUPERCEDE;
		} else {
			if(pev(Ent, pev_euser3) != 1)
			{
				if(pev(Ent, pev_iuser4) != 2002) set_pev(Ent, pev_dmgtime, 0.0)
				if(pev(Ent, pev_iuser4) == 2002 && pev(Ent, pev_iuser3)!=1)
					set_pev(Ent, pev_fuser2, 0.0)
					
				set_pev(Ent, pev_euser3, 1)
				set_pev(Ent, pev_nextthink, get_gametime())
			}
		}
	}
	
	if(pev(Ent, pev_iuser4) == 2000 && get_gametime() >= pev(Ent, pev_dmgtime))
	{
		if(g_iHasMutations[id][MUT_BOMBER] && random(20) >= 15 && !cs_zb_is_zombie(id) && g_flLastBomb <= get_gametime())
		{
			MarkTheTarget(id, vOrigin);
			g_flLastBomb = get_gametime() + 3.0
		}
		
		set_pev(Ent, pev_iuser4, 0);
		if(pev(Ent, pev_iuser1) == 477 && pev(Ent, pev_impulse) == 0)
		{
			HEGrenadeExplode(Ent)
			return HAM_IGNORED;
		}
	}
	if(pev(Ent, pev_iuser4) == 2001 && get_gametime() >= pev(Ent, pev_dmgtime))
	{
		FrostExplode(vOrigin);
		engfunc(EngFunc_RemoveEntity, Ent);
		return HAM_SUPERCEDE;
	}
	if(pev(Ent, pev_iuser4) == 2002)
	{
		if(!(pev(Ent, pev_gamestate) == GRENMODE_LASERTRIP && pev(Ent, pev_movetype) == MOVETYPE_NONE) && pev(Ent, pev_iuser3)!=1)
			set_pev(Ent, pev_nextthink, get_gametime() + 0.1);
			
		if(pev(Ent, pev_fuser2) <= get_gametime())
		{
			if((pev(Ent, pev_flags) & FL_ONGROUND && pev(Ent, pev_gamestate) == 0) || pev(Ent, pev_gamestate) != 0)
			{
				if(pev(Ent, pev_iuser3) != 1)
				{
					NitroNadeSmoking(Ent);
					set_pev(Ent, pev_fuser1, get_gametime() + 15.0)
					set_pev(Ent, pev_iuser3, 1)
				}
			}
			
			if(pev(Ent, pev_fuser1) <= get_gametime() && pev(Ent, pev_iuser3) == 1)
			{
				engfunc(EngFunc_RemoveEntity, Ent);
				return HAM_SUPERCEDE;
			}
		}
	}
	if((pev(Ent, pev_iuser1) == 477 || pev(Ent, pev_iuser1) == 476))
	{
		set_pev(Ent, pev_nextthink, get_gametime() + 0.1);
	}
	return HAM_IGNORED;
}

public fw_Grenade_Touch(Ent, iPtd)
{
	if(!pev_valid(Ent)) 
		return HAM_IGNORED;
		
	if(pev(Ent, pev_gamestate) == GRENMODE_LASERTRIP && pev(Ent, pev_movetype) != MOVETYPE_NONE)
	{
		if(TripNadesImpact(Ent, iPtd))
		{
			set_pev(Ent, pev_velocity, Float:{0.0, 0.0, 0.0})
			return HAM_IGNORED;
		}
	}
	if(pev(Ent, pev_iuser1) == 476)
	{
		new Float:vecVelocity[3]
		pev(Ent, pev_velocity, vecVelocity)
		xs_vec_mul_scalar(vecVelocity, 0.4, vecVelocity)
		set_pev(Ent, pev_velocity, vecVelocity)
		
		if(vector_length(vecVelocity) > 150.0)
			emit_sound(Ent, CHAN_WEAPON, ZBombBounceSound[random(1)], 1.0, 0.8, 0, random_num(94, 102))
		
	}
	else if(pev(Ent, pev_iuser1) == 477)
	{
		new Float:vecVelocity[3]
		pev(Ent, pev_velocity, vecVelocity)
		xs_vec_mul_scalar(vecVelocity, 0.4, vecVelocity)
		set_pev(Ent, pev_velocity, vecVelocity)
		
		if(vector_length(vecVelocity) > 150.0)
			emit_sound(Ent, CHAN_WEAPON, pev(Ent, pev_iuser4) == 2000 ? "weapons/he_bounce-1.wav" : "weapons/grenade_hit1.wav", 1.0, 0.8, 0, random_num(94, 102))
		
	}
	return HAM_IGNORED;
}
public HamF_Weapon_PrimaryAttack(Ent)
{
	if(!pev_valid(Ent)) 
		return;
		
	new Id = get_pdata_cbase(Ent, 41, 4);
	if(get_pdata_cbase(Id, 373) != Ent)
		return
		
	new iWpnId = get_pdata_int(Ent, 43, 4);
	
	if(!cs_zb_is_zombie(Id))
	{
		if(g_iHasMutations[Id][MUT_FIREBALL])
		{
			if(((1 << iWpnId) & CSWPN_SNIPER) && g_flLastFB[Id] <= get_gametime() && get_pdata_int(Ent, 51, 4) > 0)
			{
				ShootFireBall(Id)
				g_flLastFB[Id] = get_gametime() + 2.0
			}
		}
		if(g_iHasMutations[Id][MUT_EXPLOSIVEROUND] && g_flLastExpBullet[Id] <= get_gametime() && get_pdata_int(Ent, 51, 4) > 0 &&
			!((1<<iWpnId) & CSWPN_NOCLIP))
		{
			MakeExplosiveRound(Id)
			g_flLastExpBullet[Id]= get_gametime() + random_float(1.0, 3.0);
		}
		if(g_iHasMutations[Id][MUT_RAPIDRELOAD] && get_pdata_int(Ent, 51, 4) > 0 && cs_get_user_bpammo(Id, iWpnId) > 0 &&
			!((1<<iWpnId) & CSWPN_NOCLIP))
		{
			if((1<<iWpnId) & CSWPN_PISTOL && get_pdata_int(Ent, 64, 4) > 0)
				return;
				
			if(pev(Ent, pev_euser4) > 0) set_pdata_int(Ent, 51, get_pdata_int(Ent, 51, 4)+pev(Ent, pev_euser4), 4);
			else {
				if(!(pev(Ent, pev_iuser4) & (1<<10))) set_pdata_int(Ent, 51, get_pdata_int(Ent, 51, 4)+1, 4);
			}

			if(!(pev(Ent, pev_iuser4) & (1<<10)))
				cs_set_user_bpammo(Id, iWpnId, cs_get_user_bpammo(Id, iWpnId) - 1);
		}
	}
}
public HamF_TraceAttack(victim, attacker, Float:flDamage, Float:vDir[3], tr, damagetype)
{
	if(!is_user_connected(victim) || !is_user_connected(attacker))
		return HAM_IGNORED;
	
	g_iTraceDmg[attacker] = 1;
	if(pev(victim, pev_takedamage) <= 0.0)
		return HAM_IGNORED;
	
	new iHitGroup
	if(cs_zb_is_zombie(victim))
	{
		iHitGroup = get_tr2(tr, TR_iHitgroup)
		if(g_iUsedSkill[SKILL_DEADLYSHOT][attacker] == 2 && iHitGroup != HIT_HEAD)
		{
			set_tr2(tr, TR_iHitgroup, HIT_HEAD);
			ExecuteHamB(Ham_TraceAttack, victim, attacker, flDamage, vDir, tr, damagetype)
			return HAM_SUPERCEDE;
		}
		g_iLastHitGroup[victim] = iHitGroup
	}
	return HAM_IGNORED;
}
public HamF_TakeDamage(victim, inflictor, attacker, Float:flDamage, damagetype)
{
	if(!is_user_connected(victim))
		return HAM_IGNORED;
	
	if(pev(victim, pev_takedamage) <= 0.0)
		return HAM_IGNORED;
	
	if(cs_zb_is_escape_mode() && (isTriggerHurt(inflictor) || isTriggerHurt(attacker)))
		return HAM_IGNORED;
	
	if(g_iHasMutations[victim][MUT_LONGJUMP] && !cs_zb_is_zombie(victim) && (damagetype & DMG_FALL) && g_iLeapMana[victim] >= LEAP_LANDINGJETS_MANA)
	{
		g_iLeapMana[victim] = max(0, g_iLeapMana[victim] - LEAP_LANDINGJETS_MANA)
		g_flLastLeap[1][victim] = get_gametime() + LEAP_INTERVAL
	
		if(g_iLeapMana[victim] < LEAP_MANA)
		{
			g_iLeapFlags[victim] |= LEAP_FLAG_NOTREADY
			engfunc(EngFunc_EmitSound, victim, CHAN_ITEM, "deathmatch/jumpmod_deny.wav", 1.0, 0.8, 0, 100);
		}
	
		new Float:vOrigin[3]; pev(victim, pev_origin, vOrigin)
		engfunc(EngFunc_EmitAmbientSound, victim, vOrigin, "deathmatch/jumpmod_fall.wav", 1.0, 0.8, 0, 100);
		
		message_begin(MSG_BROADCAST, SVC_TEMPENTITY)
		write_byte(123)
		engfunc(EngFunc_WriteCoord, vOrigin[0]);
		engfunc(EngFunc_WriteCoord, vOrigin[1]);
		engfunc(EngFunc_WriteCoord, vOrigin[2]-30.0);
		write_short(50)
		write_short(engfunc(EngFunc_ModelIndex, "sprites/gas_smoke1.spr"))
		write_byte(15)
		write_byte(8|1|16)
		write_byte(30)
		message_end()
		
		return HAM_SUPERCEDE
	}
	if(!is_user_connected(attacker))
		return HAM_IGNORED;
		
	g_iHoldingJump[victim] = 0;
	g_iHealStat[victim] = 0;
	g_flHealTime[victim] = get_gametime() + cs_zb_is_zombie(victim) ? 10.0 : 3.5;
	
	new Float:flModDamage; flModDamage = flDamage
	if(cs_zb_is_zombie(attacker) && !cs_zb_is_zombie(victim))
	{
		if(g_iHasMutations[victim][MUT_IMMORTALITY] && !g_isProtected[victim] && !cs_zb_is_escape_mode() && damagetype & DMG_BULLET)
		{
			set_pev(victim, pev_takedamage, 0.0);
			g_isProtected[victim] = 1;
			g_flProtectedTime[victim] = get_gametime() + 3.0;
			return HAM_SUPERCEDE;	
		}
		if(g_iHasMutations[victim][MUT_CRIMSON])
		{
			flModDamage *= 0.5;
		}
	}
	
	if(cs_zb_is_zombie(victim) && !cs_zb_is_zombie(attacker))
	{
		if(g_iHasMutations[victim][MUT_STEELHEAD] && g_iLastHitGroup[victim] == HIT_HEAD)
			flModDamage *= 0.3;
		
		if(g_iHasMutations[victim][MUT_REGENBOMB] && g_flLastReceivedBomb[victim] <= get_gametime())
		{
			GiveZombiBomb(victim)
			g_flLastReceivedBomb[victim] = get_gametime() + 6.0;
		}
		if(g_iHasMutations[victim][MUT_STEELSKIN] && !g_SteelSkin[victim] && g_flSteelSkinTime[victim] <= get_gametime() && pev(victim, pev_takedamage) > 0.0 && !cs_zb_is_escape_mode())
		{
			set_pev(victim, pev_takedamage, 0.0);
			g_SteelSkin[victim] = 1;
			g_flSteelSkinTime[victim] = get_gametime() + 1.5;
		}
		
		if(damagetype & DMG_BULLET)
		{
			if(g_iHasMutations[attacker][MUT_INCBULLET])
			{
				g_IncBulletNum[attacker][victim] = min(5, (g_IncBulletNum[attacker][victim] + random_num(1, 3)));
			}
		}
		if(g_iHasMutations[attacker][MUT_CRITICALSTRIKE] && g_flCritical[attacker] <= get_gametime() && random(20) == 10)
		{
			flModDamage *= 4.0;
			g_flCritical[attacker] = get_gametime() + 5.0;
		}
		if(g_iHasMutations[attacker][MUT_DROPFALL] && pev(victim, pev_movetype) == MOVETYPE_FLY)
		{
			set_pev(victim, pev_movetype, MOVETYPE_WALK)
			engclient_cmd(victim, "+jump;wait;-jump")
		}
		if(g_iHasMutations[attacker][MUT_MONEYPOWER])
			flModDamage += float(cs_get_user_money(attacker))*0.004
		if(g_iHasMutations[attacker][MUT_RAPIDMONEY])
		{
			rg_add_account(attacker, floatround(flModDamage * 0.15))
		}
		if(g_iHasMutations[victim][MUT_RAPIDMONEY])
		{
			rg_add_account(victim, floatround(flModDamage * 0.1))
		}
		if(g_iHasMutations[attacker][MUT_ELITIST])
		{
			flModDamage += (10 * float(GetZombieTotal()))
		}	
		if(g_iUsedSkill[SKILL_DEADLYSHOT][attacker] == 2 && !g_iTraceDmg[attacker])
			flModDamage *= 3.0;
	}
	
	if(g_iTraceDmg[attacker]) g_iTraceDmg[attacker] = 0
	if(damagetype & (1<<24) && !cs_zb_is_zombie(attacker)) 
	{
		if(g_iHasMutations[attacker][MUT_DEMOLITION])
			SetHamParamFloat(4, flDamage * 25.0);
		else SetHamParamFloat(4, flDamage * 6.0);
		return HAM_HANDLED;
	}
	
	if(flModDamage != flDamage && !(damagetype & DAMAGE_NOBUFF))
	{
		SetHamParamFloat(4, flModDamage);
		return HAM_HANDLED;
	}
	return HAM_IGNORED;
}
public HamF_Killed(victim, attacker, shouldgib)
{
	if(!pev_valid(victim))
		return HAM_IGNORED;
		
	ResetIncBullet(victim)
	RemoveFrozenIce(victim);
	RemoveIcarusWing(victim);
	ResetVictimIncBullet(victim)
	g_Frozen[victim] = 0;
	g_iHoldingJump[victim] = 0
	for(new x = 0; x < 3; x ++ )
		g_iGrenadeNum[x][victim] = 0
	
	if(!cs_zb_is_zombie(victim))
		return HAM_IGNORED;
	
	if(g_iHasMutations[victim][MUT_IMMORTALITY] && !g_isProtected[victim] && !cs_zb_is_escape_mode())
	{
		set_pev(victim, pev_health, cs_zb_get_user_maxhealth(victim) * 0.1)
		set_pev(victim, pev_takedamage, 0.0);
		g_isProtected[victim] = 1;
		g_flProtectedTime[victim] = get_gametime() + 2.0;
		return HAM_SUPERCEDE;	
	}
	
	if(g_iHasMutations[victim][MUT_INFECTIONBOMB])
	{
		InfectionArea(victim)
	}
	g_iStartDucking[victim] = 0;
	
	if(g_iHasMutations[victim][MUT_REVENGE] && pev_valid(attacker) && is_user_alive(attacker) && !cs_zb_is_zombie(attacker))
	{
		new Float:vOrigin[3];
		pev(attacker, pev_origin, vOrigin);
		ThrowCustomZBomb(victim, vOrigin);
	}
	return HAM_IGNORED;
}
//###############################################
// Z Forward
//###############################################
public client_command(id)
{
	new cmd[32]
	if (read_argv(0, cmd, 31) > 30) return 0
	if(equal(cmd, "showbriefing"))
	{
		clcmd_showmutation(id)
		return 1;
	}
	else if(equal(cmd, "radio1") && g_iNumMutations[0][id] > 0)
	{
		clcmd_mutation(id)
		return 1;
	}
	else if(equal(cmd, "cl_autobuy") || equal(cmd, "autobuy"))
	{
		clcmd_skillhumanskilldeadly(id)
		return 1;
	}
	else if(equal(cmd, "cl_rebuy") || equal(cmd, "rebuy"))
	{
		clcmd_skillhumanskillsprint(id)
		return 1;
	}
	return 0
}

public fw_CSZB_HumanNade_Post(Ent, Owner)
{
	if(!pev_valid(Ent)) return;
	
	pev(Ent, pev_model, g_szGrenModel[Owner], 127)
	g_iGrenData[Owner][GRENDATA_IMPULSE] = pev(Ent, pev_impulse)
	g_iGrenData[Owner][GRENDATA_IUSER2] = pev(Ent, pev_iuser2)
	g_iGrenData[Owner][GRENDATA_IUSER3] = pev(Ent, pev_iuser3)
	g_iGrenData[Owner][GRENDATA_BODY] = pev(Ent, pev_body)
}
public fw_CSNew_Round()
{
	RemoveSpecificEntity("bunker_bomb")
	RemoveSpecificEntity("zombiezfireball")
	RemoveSpecificEntity("bomb_mark")
	RemoveSpecificEntity("grenade")
	RemoveSpecificEntity("beam")
	RemoveSpecificEntity("zombie3zsmoke")
	RemoveSpecificEntity("zombezdamage")
}
public fw_CSHUD(id)
{
	if(!is_user_alive(id) || is_user_bot(id))
		return;
	
	new message[3][101], fixednum[3][32]
		
	if(g_iNumMutations[0][id] > 0)
	{
		fix_number(g_iNumMutations[0][id], 2, fixednum[0], 31)
		fix_number(cs_zb_get_level(id), 2, fixednum[1], 31)
		
		format(message[1], 100, "[Z] MUTATIONS: %s/%s", fixednum[0], fixednum[1])
		set_hudmessage(128, 255, 0, 0.06, 0.7, 0, 0.0, 0.5, 0.0, 0.0);
		ShowSyncHudMsg(id, g_Hud[0], "%s", message[1])
	}
	
	
		
	if(is_user_alive(id) && !cs_zb_is_zombie(id))
	{
		if(g_iHasMutations[id][MUT_LONGJUMP])
		{
			new current_morale = clamp((((g_iLeapMana[id] ) * 10) / LEAP_MAXMANA), 0, 10)
			new PowerUp[32], PowerDown[32], ManaNeed = cs_zb_is_escape_mode() ? LEAP_MANA_ESCAPE : LEAP_MANA
			for(new i = 0; i < current_morale; i++)
				formatex(PowerUp, sizeof(PowerUp), "%s||", PowerUp)
			for(new i = 10; i > current_morale; i--)
				formatex(PowerDown, sizeof(PowerDown), "%s==", PowerDown)
				
			format(message[0], 255, "JETS ENERGY [%s] ^n[%s%s]", (g_iLeapMana[id] < ManaNeed) ? "NOT READY" : "READY" , PowerUp, PowerDown)
			set_hudmessage(255, 140, 0, 0.02, 0.88, 0, 0.0, 0.5, 0.0, 0.0)
			ShowSyncHudMsg(id, g_Hud[4], "%s", message[0])
		}
		if(g_iHasMutations[id][MUT_SPECIALIST])
		{
			format(message[0], 100, "[F1] DEADLYSHOT: %s^n[F2] SPRINT: %s", szSkillStat[g_iUsedSkill[SKILL_DEADLYSHOT][id]], szSkillStat[g_iUsedSkill[SKILL_SPRINT][id]])
			
			set_hudmessage(128, 255, 0, -1.0, 0.25, 0, 0.0, 0.5, 0.0, 0.0);
			ShowSyncHudMsg(id, g_Hud[2], "%s", message[0])
		}
	}
}
public fw_CSZB_OnStartRound(id)
{
	g_iUsedSkill[SKILL_SPRINT][id] = 1;
	g_iUsedSkill[SKILL_DEADLYSHOT][id] = 1;
	flNadeTime[id] = get_gametime() + 15.0;
	
	g_isProtected[id] = 0
	
	ResetIncBullet(id)
	if(g_iHasMutations[id][MUT_RAPIDMONEY])
		rg_add_account(id, 2000);
}
public fw_CSZB_OnSpawn(id)
{
	g_Frozen[id] = 0;
	g_Jump[id] = 0;
	g_isProtected[id] = 0
	g_iLeapMana[id] = LEAP_MAXMANA
	g_iLeapFlags[id] = 0
	ResetIncBullet(id)
	RemoveFrozenIce(id);
	RemoveIcarusWing(id);
	ResetVictimIncBullet(id)
	ClearModdedGrenade(id)
	
	flNadeTime[id] = get_gametime() + 15.0;
	
	for(new x = 0; x < 3; x ++ )
		g_iGrenadeNum[x][id] = 0
}
public fw_CSZB_OnEquip(id)
{
	if(!cs_zb_is_zombie(id))
	{
		flNadeTime[id] = get_gametime() + 15.0;
		
		if(g_iHasMutations[id][MUT_HPUP])
			set_pev(id, pev_health, float(cs_zb_get_user_maxhealth(id)) * (cs_zb_get_user_hero(id) == 1 ? 4.0 : 2.2));
		if(g_iHasMutations[id][MUT_FROST] && !user_has_weapon(id, CSW_FLASHBANG))
			fm_give_item(id, "weapon_flashbang")
		if(g_iHasMutations[id][MUT_VACCINE] && !user_has_weapon(id, CSW_SMOKEGRENADE))
			fm_give_item(id, "weapon_smokegrenade")
	}
}
public fw_CSZB_BoltImpact(id)
{
	if(cs_zb_get_user_hero(id) == 1)
		return 2
	return 0
}
public fw_CSZB_Infected(id, attacker)
{
	if(g_iHasMutations[attacker][MUT_HEALPARTY])
	{
		static Float:flMaxHp, Float:flHp;
		for(new x = 0; x < get_maxplayers(); x ++ )
		{
			if( !pev_valid(x) || !is_user_connected(x) || !is_user_alive(x) || !cs_zb_is_zombie(x) )
				continue;
			pev(x, pev_health, flHp)
			flMaxHp = float(cs_zb_get_user_maxhealth(x))
			set_pev(x, pev_health, floatmin(flMaxHp, flHp + (flMaxHp * 0.085)));
		}
	}
	g_isProtected[id] = 0
	g_iUsedSkill[0][id] = 0;
	g_iUsedSkill[1][id] = 0;
	ClearModdedGrenade(id)
	for(new x = 0; x < 3; x ++ )
		g_iGrenadeNum[x][id] = 0
	ResetIncBullet(id)
}
public fw_CSZB_OnLevelUp(id)
{
	if(g_iNumMutations[1][id] >= sizeof(szMutationName))
		return;
	
	g_iNumMutations[0][id] ++
	
	if(is_user_bot(id)) AchieveRandomMutation(id);
}
public fw_CSZB_OnPreThink(id)
{
	if(!is_user_alive(id))
		return;
		
	static iButton, iOldButtons;
	iButton = pev(id, pev_button);
	iOldButtons = pev(id, pev_oldbuttons);
	
	if(!cs_zb_is_zombie(id))
	{
		if(g_Frozen[id]) 
		{
			g_Frozen[id] = 0;
			RemoveFrozenIce(id)
		}
		
		if(g_iHasMutations[id][MUT_INCBULLET]) IncBulletDamage(id);
		if(g_iHasMutations[id][MUT_BOXER])
		{
			new pEnt = get_pdata_cbase(id, 373);

			if(pev_valid(pEnt) && get_pdata_int(pEnt, 43, 4) == CSW_KNIFE && ((iButton & IN_ATTACK) || (iButton & IN_ATTACK2)))
			{
				if(get_pdata_float(id, 83) <= 0.0 && get_pdata_float(pEnt, 46, 4) <= 0.0 && g_flLastBoxing[id] <= get_gametime())
				{
					DoBoxing(id);
					g_flLastBoxing[id] = get_gametime() + 0.65;
				}
			}
		}
		if(g_iHasMutations[id][MUT_SIXSENSE])
		{
			if(FindInfectedHuman(id) && g_flSenseTime[id] <= get_gametime() && !cs_zb_is_choosedzb(id))
			{
				set_hudmessage(200, 140, 0, -1.0, 0.2, 0, 0.0, 1.0, 0.0, 0.0)
				ShowSyncHudMsg(id, g_Hud[3], "Zombie mutation detected nearby!");
				g_flSenseTime[id] = get_gametime() + 1.0
			}
			if(FindPoisonSkin(id) && g_flSenseTime[id] <= get_gametime() && !cs_zb_is_zombie(id))
			{
				set_hudmessage(200, 140, 0, -1.0, 0.2, 0, 0.0, 1.0, 0.0, 0.0)
				ShowSyncHudMsg(id, g_Hud[3], "Careful! Poison Skin detected!");
				g_flSenseTime[id] = get_gametime() + 1.0
			}
		}
		
		if(g_iHasMutations[id][MUT_INVISIBLERELOAD])
		{
			static pEnt; pEnt = get_pdata_cbase(id, 373);
			if(pev_valid(pEnt) && !((1<<get_pdata_int(pEnt, 41, 4)) & CSWPN_NOCLIP) && get_pdata_int(pEnt, 54, 4) && pev(id, pev_rendermode) != kRenderTransAlpha)
			{
				set_pev(id, pev_rendermode, kRenderTransAlpha);
				set_pev(id, pev_renderamt, 0.0);
			} else set_pev(id, pev_rendermode, kRenderNormal);
		}
		if(g_iHasMutations[id][MUT_GRENADEPACK])
		{
			if(flNadeTime[id] <= get_gametime())
			{
				if(!user_has_weapon(id, CSW_HEGRENADE)) fm_give_item(id, "weapon_hegrenade");
				flNadeTime[id] = get_gametime() + 15.0;
			}
		}
		if(g_iUsedSkill[SKILL_SPRINT][id] == 2)
		{
			set_pev(id, pev_maxspeed, cs_zb_is_escape_mode() ? 450.0 : 420.0);
		}
		for(new x = 0; x < 2; x ++ )
		{
			if(g_iUsedSkill[x][id] == 2 && g_flSkillTime[x][id] <= get_gametime())
			{
				g_iUsedSkill[x][id] = 0;
				if(x == SKILL_SPRINT) set_pev(id, pev_maxspeed, g_flOldMaxSpeed[id])
			}
		}
	} else {
		if(g_Frozen[id])
		{
			new Float:vOrigin[3]; pev(id, pev_vuser4, vOrigin);
			set_pev(id, pev_origin, vOrigin);
			set_pev(id, pev_velocity, Float:{0.0, 0.0, 0.0})
			set_pdata_float(id, 83, 0.1);
			if(g_flFrozenTime[id] <= get_gametime())
			{
				set_pev(id, pev_takedamage, 2.0);
				g_Frozen[id] = 0;
				cs_zb_set_user_unstuck(id)
				RemoveFrozenIce(id)
			}
		}
		if(g_iHasMutations[id][MUT_MAMOOTH] && fm_get_speed(id) <= 150 && fm_get_speed(id) > 0 && g_flLastMamooth[id] <= get_gametime())
		{
			set_pev(id, pev_armorvalue, pev(id, pev_armorvalue) + 100.0);
			g_flLastMamooth[id] = get_gametime() + 3.0;
		}
		
		if(g_iHasMutations[id][MUT_ENHANCLAW])
		{
			new pEnt = get_pdata_cbase(id, 373);
			if(pev_valid(pEnt) && get_pdata_int(pEnt, 43, 4) == CSW_KNIFE && ((iButton & IN_ATTACK) || (iButton & IN_ATTACK2)))
			{
				if(get_pdata_float(id, 83) <= 0.0 && get_pdata_float(pEnt, 46, 4) <= 0.0 && g_flLastBoxing[id] <= get_gametime())
				{
					DoEnchanClaw(id);
					g_flLastBoxing[id] = get_gametime() + 0.15;
				}
			}
		}
		if(g_iHasMutations[id][MUT_DASHCROUCH])
		{
			if(IsDucking(id) && !g_iStartDucking[id])
			{
				g_iStartDucking[id] = 1;
				pev(id, pev_maxspeed, g_flOldMaxSpeed[id]);
				set_pev(id, pev_maxspeed, 430.0);
			} 
			if(g_iStartDucking[id]) set_pev(id, pev_maxspeed, 430.0);
			
			if(!IsDucking(id) && g_iStartDucking[id])
			{
				g_iStartDucking[id] = 0;
				set_pev(id, pev_maxspeed, g_flOldMaxSpeed[id])
			}
		}
	}
	if(g_flProtectedTime[id] <= get_gametime() && g_isProtected[id] == 1)
	{
		set_pev(id, pev_takedamage, 2.0);
		g_isProtected[id] = 2;
	}
	if(g_SteelSkin[id] == 1 && g_flSteelSkinTime[id] <= get_gametime())
	{
		set_pev(id, pev_takedamage, 2.0);
		g_SteelSkin[id] = 0;
		g_flSteelSkinTime[id] = get_gametime() + random_float(10.0, 40.0);
	}
	if(g_iHasMutations[id][MUT_HOMINGNADE])
	{
		if((1<<get_user_weapon(id)) & CSWPN_NADE)
		{
			if(iButton & IN_ATTACK2 && !(iOldButtons & IN_ATTACK2))
			{
				g_GrenMode[id]++
				if(g_GrenMode[id] > GRENMODE_SPY) g_GrenMode[id] = 0
				client_print(id, print_center, "Mode: %s", szGrenMode[g_GrenMode[id]])
			}
		}
	}
	if(g_iHasMutations[id][MUT_DOUBLEJUMP])
	{
		if((iButton & IN_JUMP) && !(pev(id, pev_flags) & FL_ONGROUND) && !(iOldButtons & IN_JUMP))
		{
			if(g_JumpNum[id] < 1)
			{
				g_Jump[id] = 1
				g_JumpNum[id]++
			}
		}
	}
	
	if((iButton & IN_JUMP) && !(iOldButtons & IN_JUMP) && (pev(id, pev_flags) & FL_ONGROUND))
	{
		g_JumpNum[id] = 0
		if(g_iHasMutations[id][MUT_KANGAROO])
		{
			new Float:velocity[3]; pev(id, pev_velocity, velocity);
			velocity[2] = 320.0;
			set_pev(id, pev_velocity, velocity);
			KangarooGlow(id)
		}
	}
	
	if(g_iHasMutations[id][MUT_ICARUS])
	{
		if(iButton & IN_JUMP && iOldButtons & IN_JUMP)
		{
			if(!g_iHoldingJump[id])
			{
				g_iHoldingJump[id] = 1;
				g_flJumpTime[id] = get_gametime() + 0.5;
			}
			if(g_iHoldingJump[id] == 1 && g_flJumpTime[id] <= get_gametime())
			{
				MakeIcarusWing(id)
				g_iHoldingJump[id] = 2;
			}
		} else {
			g_iHoldingJump[id] = 0;
			RemoveIcarusWing(id)
		}
	}
	
	if(g_iHasMutations[id][MUT_REGENUP])
	{
		static Float:flMaxHp, Float:flHp, Float:flDelay;
		pev(id, pev_health, flHp)
		flMaxHp = float(cs_zb_get_user_maxhealth(id))
		
		if(g_iHasMutations[id][MUT_HPUP] && !cs_zb_is_zombie(id)) flMaxHp *= (cs_zb_get_user_hero(id) == 1 ? 4.0 : 2.2);
		
		if(fm_get_speed(id) <= 50 && g_flHealTime[id] <= get_gametime() &&  g_iHealStat[id] == 0 && flHp < flMaxHp)
		{
			flDelay = cs_zb_is_zombie(id) ? 6.0 : 2.0;
			
			g_iHealStat[id] = 1;
			g_flHealTime[id] = get_gametime() + flDelay;
		}
		if( g_flHealTime[id] <= get_gametime() && g_iHealStat[id] == 1&& flHp < flMaxHp)
		{
			set_pev(id, pev_health, floatmin(flMaxHp, flHp + (flMaxHp * 0.15)));
			g_flHealTime[id] = get_gametime() + 1.0;
			
			play_sound(id, "player/heartbeat2.wav");
			
			if(flHp >= flMaxHp)
			{
				flDelay = cs_zb_is_zombie(id) ? 10.0 : 3.5;
				
				g_iHealStat[id] = 0;
				g_flHealTime[id] = get_gametime() + flDelay;
			}
				
		}
	}
	
	if(is_user_bot(id) && g_flBotUseMut[id] <= get_gametime() && g_iNumMutations[0][id] > 0)
	{
		AchieveRandomMutation(id)
		g_flBotUseMut[id] = get_gametime() + 0.5
	}
	else if(!g_iManual[id] && g_flBotUseMut[id] <= get_gametime() && g_iNumMutations[0][id] > 0)
	{
		AchieveRandomMutation(id)
		g_flBotUseMut[id] = get_gametime() + 1.5
	}
	if(g_iHasMutations[id][MUT_LONGJUMP] && !cs_zb_is_zombie(id))
	{
		static Float:velocity[3], Float:vOrigin[3], iManaNeed;
		pev(id, pev_velocity, velocity)
		pev(id, pev_origin, vOrigin)
		
		iManaNeed = cs_zb_is_escape_mode() ? LEAP_MANA_ESCAPE : LEAP_MANA
		if(g_flLastLeap[1][id] <= get_gametime())
		{
			g_iLeapMana[id] = min(LEAP_MAXMANA, g_iLeapMana[id] + LEAP_RECHARGERATE)
			if(g_iLeapFlags[id] & LEAP_FLAG_NOTREADY && g_iLeapMana[id] >= iManaNeed)
			{
				engfunc(EngFunc_EmitSound, id, CHAN_ITEM, "deathmatch/jumpmod_ready.wav", 1.0, 0.8, 0, 100);
				g_iLeapFlags[id] &= ~LEAP_FLAG_NOTREADY
			}
				
			g_flLastLeap[1][id] = get_gametime() + LEAP_RECHARGEINTERVAL
		}
			
		if(!(pev(id, pev_flags) & FL_ONGROUND) && g_flLastLeap[0][id] > get_gametime() && g_flLastLeap[2][id] <= get_gametime())
		{
			new Float:vOrigin[3]; pev(id, pev_origin, vOrigin)
			message_begin(MSG_BROADCAST, SVC_TEMPENTITY)
			write_byte(123)
			engfunc(EngFunc_WriteCoord, vOrigin[0]);
			engfunc(EngFunc_WriteCoord, vOrigin[1]);
			engfunc(EngFunc_WriteCoord, vOrigin[2]);
			write_short(5)
			write_short(engfunc(EngFunc_ModelIndex, "sprites/gas_smoke1.spr"))
			write_byte(1)
			write_byte(8|1)
			write_byte(10)
			message_end()
			
			g_flLastLeap[2][id] = get_gametime() + 0.055
		}
		if(pev(id, pev_flags) & FL_ONGROUND && g_iLeapFlags[id] & LEAP_FLAG_INAIR && g_flLastLeap[0][id] <= get_gametime())
			g_iLeapFlags[id] &= ~LEAP_FLAG_INAIR
			
		if((iButton & (IN_FORWARD|IN_BACK|IN_MOVELEFT|IN_MOVERIGHT)) && !(iOldButtons & (IN_FORWARD|IN_BACK|IN_MOVELEFT|IN_MOVERIGHT)) && (g_iLeapFlags[id] & LEAP_FLAG_INAIR) && 
			vector_length(velocity) >= 250.0 && !(pev(id, pev_flags) & FL_ONGROUND))
		{
			if(g_flLastLeap[0][id] > get_gametime())
				engfunc(EngFunc_EmitAmbientSound, id, vOrigin, "deathmatch/jumpmod_boost2.wav", 1.0, 0.8, 0, 100);
				
			g_iLeapFlags[id] &= ~LEAP_FLAG_INAIR
		}
		
		if (!(iButton & (IN_JUMP | IN_DUCK) == (IN_JUMP | IN_DUCK)))
			return;
		if(g_iLeapMana[id] < iManaNeed)
		{
			if(g_flLastLeap[0][id] <= get_gametime())
			{
				g_iLeapFlags[id] |= LEAP_FLAG_NOTREADY
				engfunc(EngFunc_EmitSound, id, CHAN_ITEM, "deathmatch/jumpmod_deny.wav", 1.0, 0.8, 0, 100);
				g_flLastLeap[0][id] = get_gametime() + LEAP_INTERVAL
				g_flLastLeap[1][id] = get_gametime() + LEAP_INTERVAL
			}
			return;
		}
		if (!(pev(id, pev_flags) & FL_ONGROUND) || vector_length(velocity) < 60.0 || g_flLastLeap[0][id] > get_gametime())
			return;
			
		g_flLastLeap[0][id] = get_gametime() + LEAP_INTERVAL
		g_flLastLeap[1][id] = get_gametime() + LEAP_INTERVAL
		g_iLeapMana[id] = max(0, g_iLeapMana[id] - iManaNeed)
			
		if(g_iLeapMana[id] < iManaNeed)
		{
			g_iLeapFlags[id] |= LEAP_FLAG_NOTREADY
			engfunc(EngFunc_EmitSound, id, CHAN_ITEM, "deathmatch/jumpmod_deny.wav", 1.0, 0.8, 0, 100);
		}
		if(!(iOldButtons & IN_FORWARD))
			Stock_SetNewVelocity(LEAP_SPEED+200.0, velocity, velocity)
		else velocity_by_aim(id, floatround(LEAP_SPEED), velocity)
		velocity[2] = 320.0
		set_pev(id, pev_velocity, velocity)
		
		g_iLeapFlags[id] |= LEAP_FLAG_INAIR
				
		engfunc(EngFunc_EmitAmbientSound, id, vOrigin, "deathmatch/jumpmod_long1.wav", 1.0, 0.8, 0, 100);
			
	}
}
public fw_CSZB_OnPostThink(id)
{
	if(!is_user_alive(id))
		return;
		
	static Float:velocity[3], Float:v_angle[3], Float:direction[3];
	
	if(g_iHasMutations[id][MUT_DOUBLEJUMP] && g_Jump[id])
	{
		pev(id, pev_velocity, velocity);
		velocity[2] = g_iHasMutations[id][MUT_KANGAROO] ? 320.0 : 270.0;
		set_pev(id, pev_velocity, velocity);
		if(g_iHasMutations[id][MUT_KANGAROO])
			KangarooGlow(id);
			
		g_Jump[id] = 0;
	}
	if(g_iHasMutations[id][MUT_ICARUS] && g_iHoldingJump[id] == 2)
	{
		pev(id, pev_v_angle, v_angle)
		v_angle[0] = 0.0;
		engfunc(EngFunc_MakeVectors, v_angle);
		global_get(glb_v_forward, direction);
		xs_vec_mul_scalar(direction, 400.0, velocity);
		velocity[2] = -100.0;
		set_pev(id, pev_velocity, velocity);
		
		if((pev(id, pev_flags) & FL_ONGROUND) || pev(id, pev_waterlevel) != 0)
		{
			g_iHoldingJump[id] = 0
		}
	}
	if(g_iHasMutations[id][MUT_RAPIDNADE])
	{
		for(new x = 0; x < 3; x ++ )
		{
			if(g_iGrenadeNum[x][id] > 0 && g_flGrenadeTime[x][id] <= get_gametime())
			{
				ThrowAdditionalGrenade(id, x);
				g_iGrenadeNum[x][id] --
				g_flGrenadeTime[x][id] = get_gametime() + 1.0
			}
		}
	}
}
public fw_CSZB_ZombiBomb_Explode(Ent, Attacker)
{
	static Float:vOrigin[3]
	if(g_iHasMutations[Attacker][MUT_POISON])
	{
		pev(Ent, pev_origin, vOrigin)
		Spit(vOrigin, Attacker)
	}
}
//###############################################
// SPECIAL MUTATIONS
//###############################################
// Poison Bomb
public Spit(Float:vOrigin[3], Attacker)
{
	new pEnt, Float:pOrigin[3], Float:vAngle[3], Float:vVelocity[3];

	for(new x=0; x<10;x++)
	{
		pOrigin[0] = vOrigin[0] + random_float(-50.0, 50.0)
		pOrigin[1] = vOrigin[1] + random_float(-50.0, 50.0)
		pOrigin[2] = vOrigin[2] + random_float(-50.0, 50.0)

		pEnt = engfunc(EngFunc_CreateNamedEntity, engfunc(EngFunc_AllocString, "info_target"))
		set_pev(pEnt, pev_origin, vOrigin);
		set_pev(pEnt, pev_classname, "frogbomb_spit")
		engfunc(EngFunc_SetModel, pEnt, "models/zbz/spit.mdl");
		set_pev(pEnt, pev_owner, Attacker);
		set_pev(pEnt, pev_movetype, 6);
		set_pev(pEnt, pev_solid, SOLID_TRIGGER);
		set_pev(pEnt, pev_gravity, 0.6)
		set_pev(pEnt, pev_rendermode, kRenderTransAdd);
		set_pev(pEnt, pev_renderamt, 255.0);
		set_pev(pEnt, pev_mins, Float:{-1.0, -1.0, -1.0}, Float:{1.0, 1.0, 1.0})
			
		vVelocity[0] = random_float(-780.0, 780.0);
		vVelocity[1] = random_float(-780.0, 780.0);
		vVelocity[2] = random_float(-780.0, 780.0);
		set_pev(pEnt, pev_velocity, vVelocity);
		vector_to_angle(vVelocity, vAngle);
		set_pev(pEnt, pev_angles, vAngle);
			
		message_begin(MSG_BROADCAST, SVC_TEMPENTITY)
		write_byte(TE_BEAMFOLLOW)
		write_short(pEnt)
		write_short(engfunc(EngFunc_ModelIndex, "sprites/laserbeam.spr"))
		write_byte(2)
		write_byte(1)
		write_byte(100)
		write_byte(255)
		write_byte(100)
		write_byte(255)
		message_end()
			
		set_pev(pEnt, pev_nextthink, get_gametime())
	}
	
}
public SpitThink(Ent)
{
	if(!isSpit(Ent)) return;
	
	new Float:vVelocity[3], Float:vAngle[3];
	pev(Ent, pev_velocity, vVelocity);
	vector_to_angle(vVelocity, vAngle)
	set_pev(Ent, pev_angles, vAngle);
	
	set_pev(Ent, pev_nextthink, get_gametime()+0.01)
}
public SpitImpact(Ent, Id)
{
	if(!isSpit(Ent)) return;
	
	new Float:vOrigin[3], pevAttacker = pev(Ent, pev_owner);
	pev(Ent, pev_origin, vOrigin);
	
	message_begin(MSG_BROADCAST, SVC_TEMPENTITY)
	write_byte(3)
	engfunc(EngFunc_WriteCoord, vOrigin[0])
	engfunc(EngFunc_WriteCoord, vOrigin[1])
	engfunc(EngFunc_WriteCoord, vOrigin[2])
	write_short(engfunc(EngFunc_ModelIndex, "sprites/spr_boomer.spr"))
	write_byte(random(4)+3)
	write_byte(30)
	write_byte(14)
	message_end()
	
	message_begin(MSG_BROADCAST, SVC_TEMPENTITY)
	write_byte(104)
	engfunc(EngFunc_WriteCoord, vOrigin[0])
	engfunc(EngFunc_WriteCoord, vOrigin[1])
	engfunc(EngFunc_WriteCoord, vOrigin[2])
	write_byte(engfunc(EngFunc_DecalIndex, "{spit1"))
	write_short(pev_valid(Id) ? Id : 0)
	message_end()
	
	engfunc(EngFunc_EmitAmbientSound, 0, vOrigin, "zombi/firezombi_splat1.wav", 1.0, 0.8, 0, 100);
	Stock_RadiusDamage(pevAttacker, Ent, vOrigin, 80.0, 100.0, 0.0);

	engfunc(EngFunc_RemoveEntity, Ent)
}
// Cluster Grenade
public ThrowAdditionalGrenade(id, iType)
{
	new Ent, Float:vPlayerOrigin[3], Float:vUp[3];
	pev(id, pev_origin, vPlayerOrigin)
	pev(id, pev_view_ofs, vUp);
	xs_vec_add(vPlayerOrigin, vUp, vPlayerOrigin);
	
	Ent = engfunc(EngFunc_CreateNamedEntity, engfunc(EngFunc_AllocString, "grenade"))
	set_pev(Ent, pev_origin, vPlayerOrigin);
	set_pev(Ent, pev_owner, id);
	set_pev(Ent, pev_movetype, 10);
	set_pev(Ent, pev_solid, SOLID_BBOX);
	set_pev(Ent, pev_gravity, 0.6);
	set_pev(Ent, pev_iuser1, 477)
	set_pev(Ent, pev_nextthink, get_gametime());
	set_pev(Ent, pev_dmgtime, get_gametime() + 2.0);
	set_pev(Ent, pev_gamestate, g_GrenMode[id])
	
	engfunc(EngFunc_SetSize, Ent, Float:{-1.0, -1.0, -1.0}, Float:{1.0, 1.0, 1.0})
	
	switch(iType)
	{
		case 1: {
			set_pev(Ent, pev_iuser4, 2001)
			engfunc(EngFunc_SetModel, Ent, "models/w_flashbang.mdl");
		}
		case 2: {
			set_pev(Ent, pev_iuser4, 2002)
			engfunc(EngFunc_SetModel, Ent, "models/w_smokegrenade.mdl");
			set_pev(Ent, pev_fuser2, get_gametime()+1.7)
			set_pev(Ent, pev_dmgtime, get_gametime()+20.7)
		}
		default: {
			set_pev(Ent, pev_iuser4, 2000)
			engfunc(EngFunc_SetModel, Ent, "models/w_hegrenade.mdl");
			if(g_iGrenData[id][GRENDATA_IMPULSE] != 0)
			{
				engfunc(EngFunc_SetModel, Ent, g_szGrenModel[id]);
				set_pev(Ent, pev_impulse, g_iGrenData[id][GRENDATA_IMPULSE])
				set_pev(Ent, pev_iuser2, g_iGrenData[id][GRENDATA_IUSER2])
				set_pev(Ent, pev_iuser3, g_iGrenData[id][GRENDATA_IUSER3])
				set_pev(Ent, pev_body, g_iGrenData[id][GRENDATA_BODY])
			}
		}
	}
	new Float:vVelocity[3], Float:pVelocity[3], Float:vAngle[3]
	velocity_by_aim(id, 800, vVelocity)
	pev(id, pev_velocity, pVelocity);
	vVelocity[2] += 120.0;
	xs_vec_add(vVelocity, pVelocity, vVelocity);
	set_pev(Ent, pev_velocity, vVelocity);
	vector_to_angle(vVelocity, vAngle)
	set_pev(Ent, pev_angles, vAngle)
	
}
public HEGrenadeExplode(Ent)
{
	if(!pev_valid(Ent)) return;
	
	new Float:vVelocity[3], Float:vOrigin[3], pevAttacker = pev(Ent, pev_owner);
	pev(Ent, pev_origin, vOrigin);
	pev(Ent, pev_velocity, vVelocity)
	
	GrenadeExplosion(vOrigin, vVelocity)
	
	Stock_RadiusDamage(pevAttacker, Ent, vOrigin, 100.0, 350.0, 0.0, 1);
	
	engfunc(EngFunc_RemoveEntity, Ent);
}
// Trip Nades
public TripNadesImpact(Ent, Id)
{
	new Float:vDir[3], Float:vNorm[3], Float:vOrigin[3], Float:vEnd[3], Float:vVelocity[3], Float:flFraction, Float:vAngle[3];
	pev(Ent, pev_origin, vOrigin);
	
	if(engfunc(EngFunc_PointContents, vOrigin) == CONTENTS_SKY || is_user_connected(Id))
		return 0;
		
	pev(Ent, pev_velocity, vVelocity);
	Stock_SetNewVelocity(100.0, vVelocity, vVelocity);
	xs_vec_add(vOrigin, vVelocity, vEnd);
	
	engfunc(EngFunc_TraceLine, vOrigin, vEnd, 0, Ent, 0);
	get_tr2(0, TR_flFraction, flFraction);
	
	new Float:color[3];
	switch(pev(Ent, pev_iuser4))
	{
		case 2001: color = Float:{100.0, 100.0, 255.0}
		case 2002: color = Float:{224.0, 224.0, 255.0}
		case 2003: color = Float:{200.0, 140.0, 0.0}
		default: color = Float:{255.0, 0.0, 0.0}
	}
	
	if(flFraction < 1.0)
	{
		get_tr2(0, TR_vecPlaneNormal, vNorm);
		xs_vec_mul_scalar(vNorm, 8192.0, vDir);
		xs_vec_add(vOrigin, vDir, vEnd);
		
		vector_to_angle(vDir, vAngle);
		set_pev(Ent, pev_angles, vAngle);
		set_pev(Ent, pev_movetype, MOVETYPE_NONE);
		set_pev(Ent, pev_dmgtime, get_gametime() + 999.0);
		
		engfunc(EngFunc_TraceLine, vOrigin, vEnd, IGNORE_GLASS|IGNORE_MONSTERS, Ent, 0);
		get_tr2(0, TR_vecEndPos, vEnd);
		set_pev(Ent, pev_vuser4, vEnd);
		
		new iBeam = Stock_DrawBeam(vOrigin, vEnd, color)
		set_pev(Ent, pev_euser4, iBeam);
		
		engfunc(EngFunc_EmitSound, Ent, CHAN_WEAPON, "weapons/mine_deploy.wav", 1.0, 0.8, 0, 100);
		return 1;
	}
	return 0;
}
public TripNadesThink(Ent)
{
	new Float:vOrigin[3], Float:vEnd[3], Float:flFraction, pEnt
	pev(Ent, pev_origin, vOrigin);
	pev(Ent, pev_vuser4, vEnd);
	
	engfunc(EngFunc_TraceLine, vOrigin, vEnd, IGNORE_GLASS, Ent, 0);
	get_tr2(0, TR_vecEndPos, vEnd);
	get_tr2(0, TR_flFraction, flFraction);
	pEnt = get_tr2(0, TR_pHit);
	
	new Id = pev(Ent, pev_owner)
	if(pev_valid(pEnt))
	{
		if(is_user_connected(pEnt) && get_user_team(pEnt) != get_user_team(Id) && pEnt != Id)
		{
			return 1;
		}
	}
	
	return 0;
}
// Spy Nades
public SpyNadesGetEnemys(Ent, Id)
{
	new Float:vOrigin[3], Float:pOrigin[3], pEnt;
	pev(Ent, pev_origin, vOrigin);
	
	pEnt = -1
	while((pEnt = engfunc(EngFunc_FindEntityInSphere, pEnt, vOrigin, 150.0)) != 0)
	{
		if(!pev_valid(pEnt)) continue;
		
		pev(pEnt, pev_origin, pOrigin)
		if(is_user_alive(pEnt) && get_user_team(Id) != get_user_team(pEnt) && pEnt != Id && isClearLine(vOrigin, pOrigin))
			return 1;
	}
	return 0;
}
// Homing Nade
public HomingNade(Ent)
{
	static Float:vOrigin[3], Float:vVelocity[3], Float:vDir[3], Float:vTarget[3];
	pev(Ent, pev_origin, vOrigin);
	
	static iTarget; iTarget = FindClosestEnemy(Ent, pev(Ent, pev_euser2))
	if(pev_valid(iTarget) && is_user_alive(iTarget))
	{
		pev(iTarget, pev_origin, vTarget);
		xs_vec_sub(vTarget, vOrigin, vDir);
		xs_vec_normalize(vDir, vDir);
		xs_vec_mul_scalar(vDir, 800.0, vDir);
		
		pev(Ent, pev_velocity, vVelocity);
		xs_vec_add(vVelocity, vDir, vVelocity);
		if(vector_length(vVelocity) > 800.0) vVelocity = vDir
		set_pev(Ent, pev_velocity, vVelocity);
	}
}
// Zombie Bomb
public ThrowCustomZBomb(id, Float:vTarget[3])
{
	new Ent, Float:vPlayerOrigin[3], Float:vUp[3];
	pev(id, pev_origin, vPlayerOrigin)
	pev(id, pev_view_ofs, vUp);
	xs_vec_add(vPlayerOrigin, vUp, vPlayerOrigin);
	
	Ent = engfunc(EngFunc_CreateNamedEntity, engfunc(EngFunc_AllocString, "grenade"))
	set_pev(Ent, pev_origin, vPlayerOrigin);
	set_pev(Ent, pev_owner, id);
	set_pev(Ent, pev_movetype, 10);
	set_pev(Ent, pev_solid, SOLID_BBOX);
	set_pev(Ent, pev_gravity, 0.6);
	set_pev(Ent, pev_iuser1, 476)
	set_pev(Ent, pev_iuser4, 2003)
	set_pev(Ent, pev_nextthink, get_gametime());
	set_pev(Ent, pev_dmgtime, get_gametime() + 1.5);
	
	engfunc(EngFunc_SetModel, Ent, FROGBOMB_MODEL);
	engfunc(EngFunc_SetSize, Ent, Float:{-1.0, -1.0, -1.0}, Float:{1.0, 1.0, 1.0})
	
	new Float:vVelocity[3]
	xs_vec_sub(vTarget, vPlayerOrigin, vVelocity);
	xs_vec_normalize(vVelocity, vVelocity);
	xs_vec_mul_scalar(vVelocity, vector_distance(vTarget, vPlayerOrigin) * 2.0, vVelocity);
	vVelocity[2] += (vector_distance(vTarget, vPlayerOrigin) * 0.25)
	
	set_pev(Ent, pev_velocity, vVelocity);
}
// Frost Explode
public FrostExplode(Float:vOrigin[3])
{
	message_begin(MSG_BROADCAST, SVC_TEMPENTITY);
	write_byte( TE_EXPLOSION );
	engfunc(EngFunc_WriteCoord, vOrigin[0])
	engfunc(EngFunc_WriteCoord, vOrigin[1])
	engfunc(EngFunc_WriteCoord, vOrigin[2]+20.0)
	write_short(engfunc(EngFunc_ModelIndex, "sprites/frostexp_1.spr"))
	write_byte(15);
	write_byte(30);
	write_byte(14);
	message_end();
	
	engfunc(EngFunc_EmitAmbientSound, 0 , vOrigin, "weapons/frostnova.wav", 1.0, 0.8, 0, 100);
	
	static pEnt, Float:pOrigin[3];
	pEnt = -1
	while((pEnt = engfunc(EngFunc_FindEntityInSphere, pEnt, vOrigin, 250.0)) != 0 )
	{
		if(!pev_valid(pEnt) || !is_user_alive(pEnt) || !cs_zb_is_zombie(pEnt))
			continue;
				
		pev(pEnt, pev_origin, pOrigin);
		
		message_begin(MSG_BROADCAST, SVC_TEMPENTITY);
		write_byte( TE_EXPLOSION );
		engfunc(EngFunc_WriteCoord, vOrigin[0])
		engfunc(EngFunc_WriteCoord, vOrigin[1])
		engfunc(EngFunc_WriteCoord, vOrigin[2])
		write_short(engfunc(EngFunc_ModelIndex, "sprites/frostexp_2.spr"))
		write_byte(15);
		write_byte(30);
		write_byte(14);
		message_end();
	
		set_pev(pEnt, pev_takedamage, 0.0)
		set_pev(pEnt, pev_vuser4, pOrigin);
		MakeFrozenIce(pEnt)
		g_Frozen[pEnt] = 1;
		g_flFrozenTime[pEnt] = get_gametime() + 3.0;
	}
	
}
// Vaccine Nade
public NitroNadeSmoking(ent)
{
	if(!pev_valid(ent))
		return;
		
	static Float:vel[3]
	vel[0] = random_float(-200.0, 200.0)
	vel[1] = random_float(-200.0, 200.0)
	vel[2] = random_float(240.0, 270.0)
					
	set_pev(ent, pev_velocity, vel)
	set_pev(ent, pev_iuser3, 1)
	set_pev(ent, pev_fuser1, get_gametime() + 15.0)
				
	new Float:origin[3], Float:color[3], Float:pos[3], Float:flAngle, pevAttacker = pev(ent, pev_owner)
	pev(ent, pev_origin, origin)
	
	if(!cs_zb_is_zombie(pevAttacker))
	{
		new pEnt = engfunc(EngFunc_CreateNamedEntity, engfunc(EngFunc_AllocString, "info_target"))
		set_pev(pEnt, pev_origin, origin);
		set_pev(pEnt, pev_classname, "zombiezdamage")
		set_pev(pEnt, pev_fuser1, 350.0);
		set_pev(pEnt, pev_fuser2, 50.0);
		set_pev(pEnt, pev_owner, pevAttacker);
		set_pev(pEnt, pev_nextthink, get_gametime())
		g_flDamageAreaTime[0][pEnt] = get_gametime() + 15.0;
		g_flDamageAreaTime[1][pEnt] = get_gametime();
	}
	
	emit_sound(ent, CHAN_STATIC, "weapons/sg_explode.wav", 1.0, 0.6, 0, 100)
	for(new i=0;i<6;i++)
	{
		get_spherical_coord(origin, 50.0, flAngle, 0.0, pos);
		flAngle += 60.0;
		color = Float:{180.0, 230.0, 255.0}
		MakeSmoke(pos, color, 15.0, 0.1, 3.1)
	}
}
public VaccineDamaging(Ent)
{
	if(!pev_valid(Ent))
		return;
	
	new pevAttacker = pev(Ent, pev_owner)
	new Float:vOrigin[3]; pev(Ent, pev_origin, vOrigin);
	
	if(g_flDamageAreaTime[0][Ent] <= get_gametime() || cs_zb_is_zombie(pevAttacker))
	{
		engfunc(EngFunc_RemoveEntity, Ent)
		return;
	}
	set_pev(Ent, pev_nextthink, get_gametime())
	
	if(g_flDamageAreaTime[1][Ent] > get_gametime())
		return;
	
	g_flDamageAreaTime[1][Ent] = get_gametime() + 1.0;
	static Float:pOrigin[3];
	for(new id = 0; id < get_maxplayers(); id++)
	{
		if(!is_user_connected(id) || !is_user_alive(id) || !cs_zb_is_zombie(id) || id == pevAttacker)
			continue;
		
		pev(id, pev_origin, pOrigin);
		if(vector_distance(pOrigin, vOrigin) <= 350.0 && isClearLine(pOrigin, vOrigin))
		{
			if(pev(id, pev_takedamage) > 0.0)
				ExecuteHamB(Ham_TakeDamage, id, Ent, pevAttacker, 200.0, DMG_NERVEGAS)
		}
	}
}
public InfectionArea(id)
{
	if(!cs_zb_is_zombie(id))
		return
		
	new Float:origin[3], Float:pos[3], Float:flAngle, Float:color[3]
	pev(id, pev_origin, origin)
	
	new pEnt = engfunc(EngFunc_CreateNamedEntity, engfunc(EngFunc_AllocString, "info_target"))
	set_pev(pEnt, pev_origin, origin);
	set_pev(pEnt, pev_classname, "zombiezinfectdamage")
	set_pev(pEnt, pev_owner, id);
	set_pev(pEnt, pev_nextthink, get_gametime())
	g_flDamageAreaTime[0][pEnt] = get_gametime() + 10.0;
	g_flDamageAreaTime[1][pEnt] = get_gametime();
	
	for(new i=0;i<6;i++)
	{
		get_spherical_coord(origin, 50.0, flAngle, 0.0, pos);
		flAngle += 60.0;
		color = Float:{0.0, 255.0, 0.0}
		MakeSmoke(pos, color, 10.0, 0.1, 3.1)
	}
}
public InfectionDamaging(Ent)
{
	if(!pev_valid(Ent))
		return;
	
	new pevAttacker = pev(Ent, pev_owner)
	new Float:vOrigin[3]; pev(Ent, pev_origin, vOrigin);
	
	if(g_flDamageAreaTime[0][Ent] <= get_gametime() || !cs_zb_is_zombie(pevAttacker))
	{
		engfunc(EngFunc_RemoveEntity, Ent)
		return;
	}
	set_pev(Ent, pev_nextthink, get_gametime())
	
	if(g_flDamageAreaTime[1][Ent] > get_gametime())
		return;

	g_flDamageAreaTime[1][Ent] = get_gametime() + 0.5;
	static Float:pOrigin[3];
	for(new id = 0; id < get_maxplayers(); id++)
	{
		if(!is_user_connected(id) || !is_user_alive(id) || cs_zb_is_zombie(id) || id == pevAttacker)
			continue;
		
		pev(id, pev_origin, pOrigin);
		if(vector_distance(pOrigin, vOrigin) <= 170.0 && isClearLine(pOrigin, vOrigin))
		{
			if(pev(id, pev_takedamage) > 0.0)
				ExecuteHamB(Ham_TakeDamage, id, Ent, pevAttacker, (350.0 - floatmul(350.0, floatdiv(vector_distance(pOrigin, vOrigin), 170.0))), DMG_CLUB)
		}
	}
}
public SmokeThink(Ent)
{
	if(!isSmoke(Ent))
		return;
		
	set_pev(Ent, pev_nextthink, get_gametime())
	
	new Float:flTemp, Float:flMaxScale, Float:flScale;
	pev(Ent, pev_scale, flScale);
	pev(Ent, pev_fuser2, flMaxScale);
	pev(Ent, pev_fuser1, flTemp);
	set_pev(Ent, pev_scale, floatmin(flMaxScale, flScale + floatabs(flTemp - get_gametime())));
	
	if(g_flSmokeTime[Ent] <= get_gametime())
	{
		if(pev(Ent, pev_iuser1) != 1)
		{
			set_pev(Ent, pev_iuser1, 1)
			g_flSmokeTime[Ent] = get_gametime() + 0.6;
		} else {
			engfunc(EngFunc_RemoveEntity, Ent);
			return;
		}
	}
	if(pev(Ent, pev_iuser1) == 1) set_pev(Ent, pev_renderamt, floatmin(255.0, floatmax(0.0, (g_flSmokeTime[Ent]-get_gametime())*255.0)))
	
}
// Explosive Bullets
public MakeExplosiveRound(id)
{
	static Float:vOrigin[3], Float:vPlayerOrigin[3], Float:vUp[3];
	pev(id, pev_origin, vPlayerOrigin)
	pev(id, pev_view_ofs, vUp);
	xs_vec_add(vPlayerOrigin, vUp, vPlayerOrigin);
	
	static Float:vDir[3], Float:vAngle[3];
	pev(id, pev_v_angle, vAngle);
	engfunc(EngFunc_MakeVectors, vAngle);
	global_get(glb_v_forward, vDir);
	xs_vec_mul_scalar(vDir, 8192.0, vDir);
	xs_vec_add(vDir, vPlayerOrigin, vOrigin);
	
	engfunc(EngFunc_TraceLine, vPlayerOrigin, vOrigin, 0, id, 0);
	get_tr2(0, TR_vecEndPos, vOrigin);
	
	message_begin(MSG_BROADCAST, SVC_TEMPENTITY);
	write_byte( TE_EXPLOSION );
	engfunc(EngFunc_WriteCoord, vOrigin[0])
	engfunc(EngFunc_WriteCoord, vOrigin[1])
	engfunc(EngFunc_WriteCoord, vOrigin[2])
	write_short(engfunc(EngFunc_ModelIndex, "sprites/zerogxplode.spr"))
	write_byte(5);
	write_byte(30);
	write_byte(TE_EXPLFLAG_NOPARTICLES);
	message_end();
	
	new Float:vEntOrigin[3], Float:fDamage, Float:fDist, pEnt = -1
	while((pEnt = engfunc(EngFunc_FindEntityInSphere, pEnt, vOrigin, 150.0)) != 0)
	{
		if(!pev_valid(pEnt) || pEnt == id) continue;
		
		if(is_user_alive(pEnt) && !cs_zb_is_zombie(pEnt))
			continue;
			
		pev(pEnt, pev_origin, vEntOrigin);
		fDist = vector_distance(vEntOrigin, vOrigin);
		fDamage = 150.0 - floatmul(150.0, floatdiv(fDist, 150.0))
		
		if(isBreakable(pEnt) && fDamage <= 0.0) fDamage = floatdiv(150.0, 2.0)
		
		if(fDamage > 0.0 && pev(pEnt, pev_health) > 0.0)
			ExecuteHamB(Ham_TakeDamage, pEnt, id, id, fDamage, isBreakable(pEnt) ? DMG_BLAST : DMG_CLUB);
	}
}
// Kangaroo Effect
public KangarooGlow(id)
{
	static Ent; Ent = engfunc(EngFunc_CreateNamedEntity, engfunc(EngFunc_AllocString, "info_target"))
	set_pev(Ent, pev_owner, id);
	
	engfunc(EngFunc_SetModel, Ent, "sprites/zbt_invincibility.spr");
	set_pev(Ent, pev_renderamt, 255.0);
	set_pev(Ent, pev_rendermode, kRenderTransAdd);
	set_pev(Ent, pev_animtime, get_gametime());
	set_pev(Ent, pev_frame, 0.0);
	set_pev(Ent, pev_classname, "zombiezglow");
	set_pev(Ent, pev_aiment, id);
	set_pev(Ent, pev_nextthink, get_gametime());
	set_pev(Ent, pev_dmgtime, get_gametime() + 1.0);
	set_pev(Ent, pev_movetype, MOVETYPE_FOLLOW);
}
// Icarus Wing
public MakeIcarusWing(id)
{
	static Ent; Ent = engfunc(EngFunc_CreateNamedEntity, engfunc(EngFunc_AllocString, "info_target"))
	set_pev(Ent, pev_owner, id);
	
	engfunc(EngFunc_SetModel, Ent, "models/zbz/zombiezwingfx.mdl");
	set_pev(Ent, pev_renderamt, 255.0);
	set_pev(Ent, pev_rendermode, kRenderTransAdd);
	set_pev(Ent, pev_animtime, get_gametime());
	set_pev(Ent, pev_frame, 0.0);
	set_pev(Ent, pev_classname, "zombiezwing");
	set_pev(Ent, pev_aiment, id);
	set_pev(Ent, pev_movetype, MOVETYPE_FOLLOW);
	
}
public RemoveIcarusWing(id)
{
	static pEnt; pEnt = -1
	while((pEnt = engfunc(EngFunc_FindEntityByString, pEnt, "classname", "zombiezwing")) != 0)
	{
		if(pev_valid(pEnt) && pev(pEnt, pev_aiment) == id) engfunc(EngFunc_RemoveEntity, pEnt);
	}
}

// Enhance Claw
public DoEnchanClaw(id)
{
	static Float:vPlayerOrigin[3], Float:vUp[3], Float:vOrigin[3];
	pev(id, pev_origin, vPlayerOrigin)
	pev(id, pev_view_ofs, vUp);
	xs_vec_add(vPlayerOrigin, vUp, vPlayerOrigin);

	static Float:vDir[3], Float:vAngle[3], Float:vDist[3], Ent;
	pev(id, pev_v_angle, vAngle);
	engfunc(EngFunc_MakeVectors, vAngle);
	global_get(glb_v_forward, vDir);
	xs_vec_mul_scalar(vDir, 130.0, vDist);
	xs_vec_add(vDist, vPlayerOrigin, vOrigin);
	
	Ent = engfunc(EngFunc_CreateNamedEntity, engfunc(EngFunc_AllocString, "info_target"))
	set_pev(Ent, pev_owner, id);
	
	engfunc(EngFunc_SetModel, Ent, "models/zbz/zombiezclaw.mdl");
	set_pev(Ent, pev_renderamt, 255.0);
	set_pev(Ent, pev_rendermode, kRenderTransAdd);
	set_pev(Ent, pev_animtime, get_gametime());
	set_pev(Ent, pev_frame, 0.0);
	set_pev(Ent, pev_classname, "zombiezclaw");
	set_pev(Ent, pev_nextthink, get_gametime() + 0.8);
	vAngle[0] *= -1.0
	set_pev(Ent, pev_angles, vAngle)
	
	new tr = create_tr2();
	
	engfunc(EngFunc_TraceLine, vPlayerOrigin, vOrigin, 0, id, tr);
	get_tr2(tr, TR_vecEndPos, vOrigin);
	
	set_pev(Ent, pev_origin, vOrigin);
	
	new pHit = get_tr2(tr, TR_pHit);
	
	if(pev_valid(pHit) && !cs_zb_is_zombie(id) && is_user_alive(pHit))
	{
		rg_multidmg_clear();
		ExecuteHamB(Ham_TraceAttack, pHit, id, 150.0, vDir, tr, DMG_BULLET);
		rg_multidmg_apply(id, id);
	}
	
	free_tr2(tr);
}
// Boxer
public DoBoxing(id)
{
	static Float:vPlayerOrigin[3], Float:vUp[3], Float:vOrigin[3];
	pev(id, pev_origin, vPlayerOrigin)
	pev(id, pev_view_ofs, vUp);
	xs_vec_add(vPlayerOrigin, vUp, vPlayerOrigin);

	static Float:vDir[3], Float:vAngle[3];
	pev(id, pev_v_angle, vAngle);
	engfunc(EngFunc_MakeVectors, vAngle);
	global_get(glb_v_forward, vDir);
	xs_vec_mul_scalar(vDir, 130.0, vDir);
	xs_vec_add(vDir, vPlayerOrigin, vOrigin);
	
	engfunc(EngFunc_TraceLine, vPlayerOrigin, vOrigin, 0, id, 0);
	get_tr2(0, TR_vecEndPos, vOrigin);
	
	message_begin(MSG_BROADCAST, SVC_TEMPENTITY);
	write_byte( TE_EXPLOSION );
	engfunc(EngFunc_WriteCoord, vOrigin[0])
	engfunc(EngFunc_WriteCoord, vOrigin[1])
	engfunc(EngFunc_WriteCoord, vOrigin[2])
	write_short(engfunc(EngFunc_ModelIndex, "sprites/ef_coilmg.spr"))
	write_byte(5);
	write_byte(10);
	write_byte(14);
	message_end();
	
	engfunc(EngFunc_EmitAmbientSound, 0, vOrigin, "weapons/stormgiant_hit1.wav", 1.0, 0.8, 0, 100);
	
	new tr=create_tr2();
	
	new Float:vEntOrigin[3], Float:vEnd[3], Float:vVel[3], Float:vEntVel[3], pEnt = -1
	while((pEnt = engfunc(EngFunc_FindEntityInSphere, pEnt, vPlayerOrigin, 160.0)) != 0)
	{
		if(!pev_valid(pEnt) || pEnt == id) continue;
		
		if(is_user_alive(pEnt) && !cs_zb_is_zombie(pEnt))
			continue;
		if(pev(pEnt, pev_takedamage) <= 0.0)
			continue;
		
		pev(pEnt, pev_origin, vEntOrigin);
		if(!Stock_isInFOV(id, vEntOrigin, 1, 120.0))
			continue;
			
		xs_vec_sub(vEntOrigin, vPlayerOrigin, vDir);
		xs_vec_normalize(vDir, vDir);
		xs_vec_mul_scalar(vDir, 10.0, vVel);
		xs_vec_add(vEntOrigin, vVel, vEnd);
		
		engfunc(EngFunc_TraceLine, vPlayerOrigin, vEnd, 0, id, tr);
		get_tr2(tr, TR_vecEndPos, vEnd);
		
		rg_multidmg_clear();
		ExecuteHamB(Ham_TraceAttack, pEnt, id, 150.0, vDir, tr, DMG_BULLET);
		rg_multidmg_apply(id, id)
		
		if(is_user_alive(pEnt))
		{
			xs_vec_mul_scalar(vDir, 1700.0, vVel);
			pev(pEnt, pev_velocity, vEntVel);
			if(IsDucking(pEnt)) xs_vec_mul_scalar(vVel, 0.35, vVel);
			xs_vec_add(vVel, vEntVel, vEntVel);
			set_pev(pEnt, pev_velocity, vEntVel);
		}
	}
	free_tr2(tr);
}
// Fireball
public ShootFireBall(id)
{
	static Ent, Float:vOrigin[3], Float:vVelocity[3], Float:vUp[3];
	pev(id, pev_origin, vOrigin);
	pev(id, pev_view_ofs, vUp);
	xs_vec_add(vOrigin, vUp, vOrigin);
	
	Ent = engfunc(EngFunc_CreateNamedEntity, engfunc(EngFunc_AllocString, "info_target"))
	set_pev(Ent, pev_origin, vOrigin);
	set_pev(Ent, pev_owner, id);
	set_pev(Ent, pev_movetype, 10);
	set_pev(Ent, pev_solid, SOLID_BBOX);
	set_pev(Ent, pev_classname, "zombiezfireball")
	
	engfunc(EngFunc_SetModel, Ent, FIREBALL_MODEL);
	engfunc(EngFunc_SetSize, Ent, Float:{-1.0, -1.0, -1.0}, Float:{1.0, 1.0, 1.0})
	
	velocity_by_aim(id, 2000, vVelocity);
	set_pev(Ent, pev_velocity, vVelocity);
}
public FireBall_Impact(Ent)
{
	static Float:vVelocity[3], Float:vOrigin[3]; pev(Ent, pev_origin, vOrigin);
	
	pev(Ent, pev_velocity, vVelocity)
	GrenadeExplosion(vOrigin, vVelocity)
	
	Stock_RadiusDamage(pev(Ent, pev_owner), Ent, vOrigin, 900.0, 250.0, 350.0);
	
}
// Air Support
public MarkTheTarget(id, Float:vOrigin[3])
{
	if(!is_user_connected(id) || cs_zb_is_zombie(id))
		return;
	
	static Float:vTargetOrigin[3];
	vTargetOrigin = vOrigin;
	vTargetOrigin[2] -= 1337.0
	
	engfunc(EngFunc_TraceLine, vOrigin, vTargetOrigin, 0, id, 0);
	get_tr2(0, TR_vecEndPos, vTargetOrigin);
	
	static pEnt; pEnt = engfunc(EngFunc_CreateNamedEntity, engfunc(EngFunc_AllocString, "info_target"))
	engfunc(EngFunc_SetModel, pEnt, MARKBOMB_MODEL);
	set_pev(pEnt, pev_classname, "bomb_mark");
	set_pev(pEnt, pev_origin, vTargetOrigin);
	set_pev(pEnt, pev_owner, id);
	set_pev(pEnt, pev_framerate, 1.0);
	set_pev(pEnt, pev_animtime, get_gametime());
	set_pev(pEnt, pev_nextthink, get_gametime() + 5.0);
	
	vTargetOrigin[2] += 1000.0
	engfunc(EngFunc_EmitAmbientSound, 0, vTargetOrigin, "deathmatch/jet_flyby1.wav", 1.0, 0.1, 0, 100);
}

public BombThink(iEnt)
{
	static Float:vecOrigin[3];
	pev(iEnt, pev_origin, vecOrigin);
	
	static Float:vecVelocity[3], Float:vecStart[3], Float:vecEnd[3], Float:vecTarget[3], Float:vecNorm[3];
	vecEnd = vecOrigin
	vecTarget = vecOrigin
	vecEnd[2] += 1337.0
		
	engfunc(EngFunc_TraceLine, vecOrigin, vecEnd, IGNORE_GLASS, iEnt, 0);
	get_tr2(0, TR_vecEndPos, vecStart);
	get_tr2(0, TR_vecPlaneNormal, vecNorm);
	xs_vec_mul_scalar(vecNorm, 5.0, vecVelocity);
	xs_vec_add(vecStart, vecVelocity, vecStart);
			
	vecStart[0] += random_float(-100.0, 100.0);
	vecStart[1] += random_float(-100.0, 100.0);
	vecTarget[2] = vecStart[2];
	engfunc(EngFunc_TraceLine, vecTarget, vecStart, IGNORE_GLASS, iEnt, 0);
	get_tr2(0, TR_vecEndPos, vecStart);
	get_tr2(0, TR_vecPlaneNormal, vecNorm);
		
	if( (engfunc(EngFunc_PointContents, vecStart) == CONTENTS_SKY || get_tr2(0,TR_flFraction) == 1.0) )
	{
		vecEnd = vecStart
		xs_vec_mul_scalar(vecNorm, 5.0, vecVelocity);
		xs_vec_add(vecStart, vecVelocity, vecStart);
		xs_vec_sub(vecOrigin, vecStart, vecVelocity);
		xs_vec_normalize(vecVelocity, vecVelocity);
		DropBomb(vecStart, vecVelocity, pev(iEnt, pev_owner));
		set_pev(iEnt, pev_iuser1, pev(iEnt, pev_iuser1) - 1)
		engfunc(EngFunc_RemoveEntity, iEnt);
		return;
	}
}

public DropBomb(Float:vecOrigin[3], Float:vecDir[3], iAttacker)
{
	new iEnt = engfunc(EngFunc_CreateNamedEntity, engfunc(EngFunc_AllocString, "info_target"));
	dllfunc(DLLFunc_Spawn, iEnt);
	
	static Float:vecAngle[3]
	
	engfunc(EngFunc_SetModel, iEnt, BOMB_MODEL);
	set_pev(iEnt, pev_classname, "bunker_bomb");
	set_pev(iEnt, pev_modelindex, engfunc(EngFunc_ModelIndex, BOMB_MODEL));
	set_pev(iEnt, pev_origin, vecOrigin);
	set_pev(iEnt, pev_movetype, MOVETYPE_FLY);
	set_pev(iEnt, pev_nextthink, get_gametime());
	set_pev(iEnt, pev_solid, 2);
	set_pev(iEnt, pev_owner, iAttacker);
	
	xs_vec_mul_scalar(vecDir, 4500.0, vecDir);
	set_pev(iEnt, pev_velocity, vecDir);
	vector_to_angle(vecDir, vecAngle);
	set_pev(iEnt, pev_angles, vecAngle);
}
public BombHit(iEnt)
{
	static Float:vecOrigin[3], Float:vecPull[3],pevAttacker;
	pev(iEnt, pev_origin, vecOrigin)
	pevAttacker = pev(iEnt, pev_owner);
	Stock_GetExplosionOrigin(iEnt, vecOrigin, vecPull, 130.0);
	
	new pPlayer = -1
	while( (pPlayer = engfunc(EngFunc_FindEntityInSphere, pPlayer, vecOrigin, 3000.0)) !=0 )
	{
		if( !is_user_alive(pPlayer) ) continue;
				
		message_begin(MSG_ONE, get_user_msgid("ScreenShake"), _, pPlayer)
		write_short(255<<14)
		write_short(4<<10)
		write_short(255<<14)
		message_end()
	}
	message_begin(MSG_BROADCAST, SVC_TEMPENTITY)
	write_byte(3)
	engfunc(EngFunc_WriteCoord, vecPull[0])
	engfunc(EngFunc_WriteCoord, vecPull[1])
	engfunc(EngFunc_WriteCoord, vecPull[2] + 20.0)
	write_short(engfunc(EngFunc_ModelIndex, "sprites/fexplo.spr"))
	write_byte(175)
	write_byte(10)
	write_byte(TE_EXPLFLAG_NOSOUND)
	message_end()
	
	message_begin(MSG_BROADCAST, SVC_TEMPENTITY)
	write_byte(3)
	engfunc(EngFunc_WriteCoord, vecPull[0] + random_float(-512.0, 512.0))
	engfunc(EngFunc_WriteCoord, vecPull[1] + random_float(-512.0, 512.0))
	engfunc(EngFunc_WriteCoord, vecPull[2] + 20.0)
	write_short(engfunc(EngFunc_ModelIndex, "sprites/fexplo.spr"))
	write_byte(175)
	write_byte(10)
	write_byte(TE_EXPLFLAG_NOSOUND)
	message_end()
	
	message_begin(MSG_BROADCAST, SVC_TEMPENTITY)
	write_byte(3)
	engfunc(EngFunc_WriteCoord, vecPull[0] + random_float(-128.0, 128.0))
	engfunc(EngFunc_WriteCoord, vecPull[1] + random_float(-128.0, 128.0))
	engfunc(EngFunc_WriteCoord, vecPull[2] + random_float(60.0, 75.0))
	write_short(engfunc(EngFunc_ModelIndex, "sprites/eexplo.spr"))
	write_byte(175)
	write_byte(10)
	write_byte(TE_EXPLFLAG_NOSOUND)
	message_end()
	
	engfunc(EngFunc_EmitAmbientSound, 0, vecOrigin, "weapons/bunkerbuster_explosion_1st.wav", 1.0, 0.2, 0, 100);
	
	if(!cs_zb_is_zombie(pevAttacker))
		Stock_RadiusDamage(pevAttacker, iEnt, vecOrigin, 10000.0, 1200.0, 500.0);
}

//###############################################
// STOCK
//###############################################
stock GrenadeExplosion(Float:vecOrigin[3], Float:vecVelocity[3] = {0.0, 0.0, 0.0})
{
	CSGrenadeExplosion(vecOrigin, 1,1, vecVelocity);
}
stock ClearModdedGrenade(Id)
{
	static iBeam, pEnt; pEnt = -1
	while((pEnt = engfunc(EngFunc_FindEntityByString, pEnt, "classname", "grenade")) != 0)
	{
		if(pev_valid(pEnt) && pev(pEnt, pev_owner) == Id && pev(pEnt, pev_gamestate) != 0) 
		{
			iBeam = pev(pEnt, pev_euser4)
			if(pev_valid(iBeam)) engfunc(EngFunc_RemoveEntity, iBeam)
			engfunc(EngFunc_RemoveEntity, pEnt);
		}
	}	
	
}
stock MakeSmoke(Float:vOrigin[3], Float:vColor[3], Float:flTime, Float:flSize, Float:flMaxSize)
{
	static pEnt; pEnt = engfunc(EngFunc_CreateNamedEntity, engfunc(EngFunc_AllocString, "info_target"))
	
	set_pev(pEnt, pev_origin, vOrigin);
	set_pev(pEnt, pev_classname, "zombie3zsmoke");
	engfunc(EngFunc_SetModel, pEnt, "sprites/gas_puff_01.spr")
	set_pev(pEnt, pev_rendermode, kRenderTransAlpha);
	set_pev(pEnt, pev_rendercolor, vColor)
	set_pev(pEnt, pev_renderamt, 255.0);
	set_pev(pEnt, pev_iuser1, 0);
	
	set_pev(pEnt, pev_scale, flSize);
	set_pev(pEnt, pev_fuser2, flMaxSize);
	set_pev(pEnt, pev_fuser1, get_gametime());
	set_pev(pEnt, pev_nextthink, get_gametime())
	
	g_flSmokeTime[pEnt] = get_gametime() + flTime
	static Float:vAngle[3]; vAngle[2] = random_float(-90.0, 90.0)
	set_pev(pEnt, pev_angles, vAngle);
}
stock MakeFrozenIce(id)
{
	static Float:vOrigin[3]
	static pEnt; pEnt = engfunc(EngFunc_CreateNamedEntity, engfunc(EngFunc_AllocString, "info_target"))
	
	pev(id, pev_origin, vOrigin);
	vOrigin[2] -= 36.0
	set_pev(pEnt, pev_origin, vOrigin);
	engfunc(EngFunc_SetModel, pEnt, "models/zbz/frozen.mdl");
	set_pev(pEnt, pev_classname, "zombifrozen");
	set_pev(pEnt, pev_body, 1);
	set_pev(pEnt, pev_owner, id);
}
stock RemoveFrozenIce(id)
{
	static pEnt = -1
	while(( pEnt = engfunc(EngFunc_FindEntityByString, pEnt, "classname", "zombifrozen")) != 0)
		if(pev_valid(pEnt) && pev(pEnt, pev_owner) == id) engfunc(EngFunc_RemoveEntity, pEnt);
}

stock IncBulletDamage(id)
{
	for(new x=0; x<get_maxplayers(); x++)
	{
		if(!pev_valid(x) || !is_user_alive(x) || x== id || !cs_zb_is_zombie(x) || g_IncBulletNum[id][x] <= 0 || g_flIncBulletTime[id][x] > get_gametime())
			continue;
		ExecuteHamB(Ham_TakeDamage, x, id, id, 110.0, DMG_BURN);
		g_IncBulletNum[id][x] --
		g_flIncBulletTime[id][x] = get_gametime() + 1.0;
		MakeBurnIncendiary(x)
	}
}
stock ResetIncBullet(id)
{
	for(new x=0; x<get_maxplayers(); x++)
	{
		if(!pev_valid(x) || !is_user_connected(x))
			continue;
		g_IncBulletNum[id][x] = 0
	}
}
stock ResetVictimIncBullet(id)
{
	for(new x=0; x<get_maxplayers(); x++)
	{
		if(!pev_valid(x) || !is_user_connected(x))
			continue;
		g_IncBulletNum[x][id] = 0
	}
}
stock MakeBurnIncendiary(id)
{
	static Ent; Ent = engfunc(EngFunc_CreateNamedEntity, engfunc(EngFunc_AllocString, "info_target"))
	set_pev(Ent, pev_owner, id);
	
	engfunc(EngFunc_SetModel, Ent, "sprites/flame_burn01.spr");
	set_pev(Ent, pev_renderamt, 255.0);
	set_pev(Ent, pev_rendermode, kRenderTransAdd);
	set_pev(Ent, pev_animtime, get_gametime());
	set_pev(Ent, pev_frame, 0.0);
	set_pev(Ent, pev_scale, 1.0);
	set_pev(Ent, pev_classname, "zombiezglow");
	set_pev(Ent, pev_aiment, id);
	set_pev(Ent, pev_nextthink, get_gametime());
	set_pev(Ent, pev_dmgtime, get_gametime() + 1.0);
	set_pev(Ent, pev_movetype, MOVETYPE_FOLLOW);
}
stock GiveZombiBomb(id)
{
	if(!is_user_alive(id) || !cs_zb_is_zombie(id)) 
		return;
	
	if(!user_has_weapon(id, CSW_HEGRENADE))
		cs_give_item(id, "weapon_hegrenade")
	else cs_set_user_bpammo(id, CSW_HEGRENADE, cs_get_user_bpammo(id, CSW_HEGRENADE) + 1);
}
stock FindInfectedHuman(id)
{
	new Float:vOrigin[3], pEnt;
	pev(id, pev_origin, vOrigin);
	
	pEnt = -1
	while((pEnt = engfunc(EngFunc_FindEntityInSphere, pEnt, vOrigin, 250.0)) != 0)
	{
		if(pev_valid(pEnt) && is_user_alive(pEnt) && cs_zb_is_choosedzb(pEnt) && pEnt != id)
			return 1;
	}
	return 0;
}
stock FindPoisonSkin(id)
{
	new Float:vOrigin[3], pEnt;
	pev(id, pev_origin, vOrigin);
	
	pEnt = -1
	while((pEnt = engfunc(EngFunc_FindEntityInSphere, pEnt, vOrigin, 350.0)) != 0)
	{
		if(pev_valid(pEnt) && is_user_alive(pEnt) && cs_zb_is_zombie(pEnt) && pEnt != id && g_iHasMutations[pEnt][MUT_CONTACT])
			return 1;
	}
	return 0;
}
stock FindClosestHuman(id, Float:flRadius)
{
	new iTotal, Float:vOrigin[3], Float:vExtOrigin[3];
	pev(id, pev_origin, vOrigin);
	
	for(new x = 0; x < get_maxplayers(); x ++ )
	{
		if( !pev_valid(x) || !is_user_connected(x) || !is_user_alive(x) || cs_zb_is_zombie(x) || x==id)
			continue;
			
		pev(x, pev_origin, vExtOrigin);
		if(vector_distance(vExtOrigin, vOrigin) <= flRadius)
			iTotal ++
	}
	return iTotal
}
stock GetZombieTotal()
{
	new iTotal
	for(new x = 0; x < get_maxplayers(); x ++ )
	{
		if( !pev_valid(x) || !is_user_connected(x) || !is_user_alive(x) || !cs_zb_is_zombie(x) )
			continue;
	
		iTotal ++
	}
	return iTotal
}
stock FindClosestEnemy(Ent, Team=0)
{
	new iTarget, Float:vOrigin[3], Float:vExtOrigin[3], Float:flDist, Float:flMinDist;
	pev(Ent, pev_origin, vOrigin);
	for(new x = 0; x < get_maxplayers(); x ++ )
	{
		if( !pev_valid(x) || !is_user_connected(x) || !is_user_alive(x) || x==pev(Ent, pev_owner))
			continue;
			
		if((Team == 1 && cs_zb_is_zombie(x)) || (Team == 0 && !cs_zb_is_zombie(x)))
			continue;
			
		pev(x, pev_origin, vExtOrigin);
		flDist = vector_distance(vOrigin, vExtOrigin)
		if((!flMinDist || flDist < flMinDist) && flDist <= 450.0 && isClearLine(vExtOrigin, vOrigin))
		{
			flMinDist = flDist
			iTarget = x
		}
	}
	return iTarget
}
stock isClearLine(Float:vOrigin1[3], Float:vOrigin2[3])
{
	new Float:flFraction;
	engfunc(EngFunc_TraceLine, vOrigin1, vOrigin2, IGNORE_MONSTERS|IGNORE_GLASS, 0, 0);
	get_tr2(0, TR_flFraction, flFraction)
	
	if (flFraction < 1.0) return 0;

	return 1;
}

stock isSpit(iEnt)
{
	if (!pev_valid(iEnt)) return 0;
	
	new szClassname[32]
	pev(iEnt, pev_classname, szClassname, charsmax(szClassname))
	if (equal(szClassname, "frogbomb_spit")) return 1;
	return 0;
}
stock get_spherical_coord(const Float:ent_origin[3], Float:redius, Float:level_angle, Float:vertical_angle, Float:origin[3])
{
	new Float:length
	length  = redius * floatcos(vertical_angle, degrees)
	origin[0] = ent_origin[0] + length * floatcos(level_angle, degrees)
	origin[1] = ent_origin[1] + length * floatsin(level_angle, degrees)
	origin[2] = ent_origin[2] + redius * floatsin(vertical_angle, degrees)
}
stock AchieveRandomMutation(id)
{
	new iSigned, index
	if(!is_user_alive(id) || g_iNumMutations[0][id] <= 0 || g_iNumMutations[1][id] >= sizeof(szMutationName))
		return;
		
	play_sound(id, "player/zombiez_mutation.wav")
	pl_play_voice(id, 8)
	g_iNumMutations[0][id] --
	
	new Float:flYaw, Float:vOrigin[3], Float:pOrigin[3];
	pev(id, pev_origin, vOrigin);
	for(new x=0; x<4;x++)
	{
		get_spherical_coord(vOrigin, 15.0, flYaw, 0.0, pOrigin);
		MakeSmoke(pOrigin, Float:{0.0, 190.0, 0.0}, 0.5, 0.1, 0.5);
		flYaw += 90.0
	}
	iSigned = 1
	while(iSigned > 0)
	{
		index = random_num(MUT_RAPIDMONEY, MUT_EARLYACCESS)
		if(g_iHasMutations[id][index])
			continue;
		
		if(cs_zb_get_level(id) >= 20 && !g_iHasMutations[id][MUT_RESSURECT])
			index=MUT_RESSURECT
		if(cs_zb_get_level(id) >= 25 && !g_iHasMutations[id][MUT_SPECIALIST])
			index=MUT_SPECIALIST

		g_iHasMutations[id][index] = 1
		g_iNumMutations[1][id]++
		AchieveHandler(id, index)
		
		if(!is_user_bot(id))
		{
			if(iMutTeams[index] == 1) 
			{
				set_dhudmessage(255, 0, 0, -1.0, 0.74, 0, 0.0, 1.0, 0.0, 0.5)
			}
			else if(iMutTeams[index] == 2)
			{
				set_dhudmessage(0, 0, 255, -1.0, 0.74, 0, 0.0, 1.0, 0.0, 0.5)
			} else {
				set_dhudmessage(0, 255, 0, -1.0, 0.74, 0, 0.0, 1.0, 0.0, 0.5)
			}
			show_dhudmessage(id, "%L", LANG_PLAYER, szMutationName[index])
		}
		iSigned --
	}
}	
stock AchieveHandler(id, index)
{
	if(!cs_zb_is_zombie(id))
	{
		if(index == MUT_FROST && !user_has_weapon(id, CSW_FLASHBANG))
			fm_give_item(id, "weapon_flashbang")
		if(index == MUT_VACCINE && !user_has_weapon(id, CSW_SMOKEGRENADE))
			fm_give_item(id, "weapon_smokegrenade")
		
	}
	if(index == MUT_HPUP)
	{
		cs_zb_set_handler_data(id, HDATA_HPUP, 1);
		if(!cs_zb_is_zombie(id) && pev(id, pev_health) < float(cs_zb_get_user_maxhealth(id))*2.2)
			set_pev(id, pev_health, float(cs_zb_get_user_maxhealth(id)) * 2.2)
		else if ( cs_zb_is_zombie(id) )
			set_pev(id, pev_health, float(cs_zb_get_user_maxhealth(id)))
	}
	if(index == MUT_RESSURECT) cs_zb_set_handler_data(id, HDATA_CANRESPAWN, 1);
	if(index == MUT_HERO) cs_zb_set_handler_data(id, HDATA_HERO, 1);
	if(index == MUT_COOPERATIVES) cs_zb_set_handler_data(id, HDATA_EVOLUTION, 1);
	if(index == MUT_ADAPTATION) cs_zb_set_handler_data(id, HDATA_CHANGECLASS, 1);
	if(index == MUT_BOMBHARDENING) cs_zb_set_handler_data(id, HDATA_BOMBHARDENING, 1);
	if(index == MUT_REINFORCE) cs_zb_set_handler_data(id, HDATA_REINFORCED, 1);
	if(index == MUT_STEELARMOR) cs_zb_set_handler_data(id, HDATA_ZBARMORUP, 1);
	if(index == MUT_INTELECTUAL) cs_zb_set_handler_data(id, HDATA_INTELECTUAL, 1);
	if(index == MUT_LUCKY) cs_zb_set_handler_data(id, HDATA_LUCKY, 1);
	if(index == MUT_DISCOUNT) cs_zb_set_handler_data(id, HDATA_DISCOUNT, 1);
	if(index == MUT_EARLYACCESS) cs_zb_set_handler_data(id, HDATA_EARLYACCESS, 1);
}
stock DeachieveHandler(id, index)
{
	if(!cs_zb_is_zombie(id))
	{
		if(index == MUT_FROST && user_has_weapon(id, CSW_FLASHBANG))
			rg_remove_item(id, "weapon_flashbang", true)
		if(index == MUT_VACCINE && user_has_weapon(id, CSW_SMOKEGRENADE))
			rg_remove_item(id, "weapon_smokegrenade", true)
		
	}
	if(index == MUT_HPUP)
	{
		cs_zb_set_handler_data(id, HDATA_HPUP, 0);
		if(!cs_zb_is_zombie(id) && pev(id, pev_health) < float(cs_zb_get_user_maxhealth(id)))
			set_pev(id, pev_health, float(cs_zb_get_user_maxhealth(id)))
		else if ( cs_zb_is_zombie(id) )
			set_pev(id, pev_health, float(cs_zb_get_user_maxhealth(id)))
	}
	if(index == MUT_RESSURECT) cs_zb_set_handler_data(id, HDATA_CANRESPAWN, 0);
	if(index == MUT_HERO) cs_zb_set_handler_data(id, HDATA_HERO, 0);
	if(index == MUT_COOPERATIVES) cs_zb_set_handler_data(id, HDATA_EVOLUTION, 0);
	if(index == MUT_ADAPTATION) cs_zb_set_handler_data(id, HDATA_CHANGECLASS, 0);
	if(index == MUT_BOMBHARDENING) cs_zb_set_handler_data(id, HDATA_BOMBHARDENING, 0);
	if(index == MUT_REINFORCE) cs_zb_set_handler_data(id, HDATA_REINFORCED, 0);
	if(index == MUT_STEELARMOR) cs_zb_set_handler_data(id, HDATA_ZBARMORUP, 0);
	if(index == MUT_INTELECTUAL) cs_zb_set_handler_data(id, HDATA_INTELECTUAL, 0);
	if(index == MUT_LUCKY) cs_zb_set_handler_data(id, HDATA_LUCKY, 0);
	if(index == MUT_HOMINGNADE) g_GrenMode[id] = 0;
	if(index == MUT_DISCOUNT) cs_zb_set_handler_data(id, HDATA_DISCOUNT, 0);
	if(index == MUT_EARLYACCESS) cs_zb_set_handler_data(id, HDATA_EARLYACCESS, 0);
}
stock ResetHandlerData(id)
{
	cs_zb_set_handler_data(id, HDATA_CANRESPAWN, 0);
	cs_zb_set_handler_data(id, HDATA_HERO, 0);
	cs_zb_set_handler_data(id, HDATA_EVOLUTION, 0);
	cs_zb_set_handler_data(id, HDATA_CHANGECLASS, 0);
	cs_zb_set_handler_data(id, HDATA_BOMBHARDENING, 0);
	cs_zb_set_handler_data(id, HDATA_REINFORCED, 0);
	cs_zb_set_handler_data(id, HDATA_ZBARMORUP, 0);
	cs_zb_set_handler_data(id, HDATA_INTELECTUAL, 0);
	cs_zb_set_handler_data(id, HDATA_LUCKY, 0);
	cs_zb_set_handler_data(id, HDATA_DISCOUNT,0);
	cs_zb_set_handler_data(id, HDATA_EARLYACCESS, 0);
}
stock Stock_CreateExplosion(Float:vecOrigin[3], iSprites, iScale, iFrame, iFlags)
{
	message_begin(MSG_BROADCAST, SVC_TEMPENTITY)
	write_byte(3)
	engfunc(EngFunc_WriteCoord, vecOrigin[0])
	engfunc(EngFunc_WriteCoord, vecOrigin[1])
	engfunc(EngFunc_WriteCoord, vecOrigin[2])
	write_short(iSprites)
	write_byte(iScale)
	write_byte(iFrame)
	write_byte(iFlags)
	message_end()
	
}
stock Stock_GetExplosionOrigin(iEnt, Float:vecOrigin[3], Float:vecOut[3], Float:flPull = 76.0)
{
	static Float:vectOrigin[3], Float:vecDist[3], iTr
	pev(iEnt, pev_velocity, vecDist)
	Stock_SetNewVelocity(20.0, vecDist, vecDist)
		
	xs_vec_add(vecOrigin, vecDist, vectOrigin);
		
	engfunc(EngFunc_TraceLine, vecOrigin, vectOrigin, iTr, iEnt, iTr)
	static Float:flFraction
	get_tr2(iTr, TR_flFraction, flFraction)
	
	static Float:vecEnd[3], Float:vecPlaneNorm[3]
	get_tr2(iTr, TR_vecEndPos, vecEnd)
	get_tr2(iTr, TR_vecPlaneNormal, vecPlaneNorm)
	
	if(flFraction != 1.0)
	{
		xs_vec_mul_scalar(vecPlaneNorm, (flPull * 0.6), vecPlaneNorm)
		xs_vec_add(vecEnd, vecPlaneNorm, vecOut);
	}
	else vecOut=vecOrigin
	
	return 1
}

stock Stock_DrawBeam(Float:vStart[3], Float:vEnd[3], Float:vColor[3])
{
	new Float: flMins[3];
	new Float: flMaxs[3];
	
	static iBeamEntity; iBeamEntity = engfunc(EngFunc_CreateNamedEntity, engfunc(EngFunc_AllocString, "beam"));
	set_pev(iBeamEntity, pev_flags, pev(iBeamEntity, pev_flags) | FL_CUSTOMENTITY);
	set_pev(iBeamEntity, pev_skin, 0);
	set_pev(iBeamEntity, pev_sequence, 0);
	
	set_pev(iBeamEntity, pev_origin, vStart);
	set_pev(iBeamEntity, pev_angles, vEnd);
	set_pev(iBeamEntity, pev_modelindex, engfunc(EngFunc_ModelIndex, "sprites/laserbeam.spr"))
	set_pev(iBeamEntity, pev_scale, 6.0);
	set_pev(iBeamEntity, pev_rendercolor, vColor );
	set_pev(iBeamEntity, pev_renderamt, 255.0);
	set_pev(iBeamEntity, pev_rendermode, (pev(iBeamEntity, pev_rendermode) & 0x0F))
	
	flMins[0] = floatmin(vStart[0], vEnd[0]);
	flMins[1] = floatmin(vStart[1], vEnd[1]);
	flMins[2] = floatmin(vStart[2], vEnd[2]);
	
	flMaxs[0] = floatmax(vStart[0], vEnd[0]);
	flMaxs[1] = floatmax(vStart[1], vEnd[1]);
	flMaxs[2] = floatmax(vStart[2], vEnd[2]);
	
	xs_vec_sub(flMins, vStart, flMins);
	xs_vec_sub(flMaxs, vStart, flMaxs);
	
	set_pev(iBeamEntity, pev_mins, flMins);
	set_pev(iBeamEntity, pev_maxs, flMaxs);
	
	engfunc(EngFunc_SetSize, iBeamEntity, flMins, flMaxs);
	engfunc(EngFunc_SetOrigin, iBeamEntity, vStart);
	
	return iBeamEntity
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
stock GetHighestLevel()
{
	new HighLevel
	for(new id = 0; id<get_maxplayers(); id++)
	{
		if(!pev_valid(id) || !is_user_connected(id)) continue;
		
		if(!HighLevel || cs_zb_get_level(id) > HighLevel)
			HighLevel = cs_zb_get_level(id)
	}
	return HighLevel
}

stock GetPosition(id,Float:forw, Float:right, Float:up, Float:vStart[])
{
	new Float:vOrigin[3], Float:vAngle[3], Float:vForward[3], Float:vRight[3], Float:vUp[3]
	
	pev(id, pev_origin, vOrigin)
	pev(id, pev_view_ofs,vUp) //for player
	xs_vec_add(vOrigin,vUp,vOrigin)
	pev(id, pev_v_angle, vAngle) // if normal entity ,use pev_angles
	
	angle_vector(vAngle,ANGLEVECTOR_FORWARD,vForward) //or use EngFunc_AngleVectors
	angle_vector(vAngle,ANGLEVECTOR_RIGHT,vRight)
	angle_vector(vAngle,ANGLEVECTOR_UP,vUp)
	
	vStart[0] = vOrigin[0] + vForward[0] * forw + vRight[0] * right + vUp[0] * up
	vStart[1] = vOrigin[1] + vForward[1] * forw + vRight[1] * right + vUp[1] * up
	vStart[2] = vOrigin[2] + vForward[2] * forw + vRight[2] * right + vUp[2] * up
}	
stock Float:Stock_Adjusted_Damage(Float:fPoint[3], iEnt, ignored) 
{
	static Float:fOrigin[3],Float:fFraction,iTr
	pev(iEnt, pev_origin, fOrigin);
	engfunc(EngFunc_TraceLine, fPoint, fOrigin, DONT_IGNORE_MONSTERS, ignored, iTr)
	get_tr2(iTr, TR_flFraction, fFraction)
	if ( fFraction == 1.0 || get_tr2( iTr, TR_pHit ) == iEnt )
		return 1.0
	return 0.6
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
	set_pev(iEnt, pev_velocity, fVelocity)
	return 1
}
stock Stock_RadiusDamage(pevAttacker, pevInflictor, Float:vecOrigin[3], Float:flMaxDamage, Float:flRadius, Float:flKnockback, isHe=0)
{
	if(!pev_valid(pevAttacker)) pevAttacker = pevInflictor;
	
	new Float:fDamage, Float:fDistance, Float:vOrigin[3]
	new szClassname[64]
	
	new iVictim = -1
	while((iVictim = engfunc(EngFunc_FindEntityInSphere, iVictim, vecOrigin, flRadius)) != 0)
	{
		if(!pev_valid(iVictim)) continue;
		
		pev(iVictim, pev_origin, vOrigin);
		fDistance = get_distance_f(vecOrigin, vOrigin);
		fDamage = flMaxDamage - floatmul(flMaxDamage, floatdiv(fDistance, flRadius));
		fDamage *= Stock_Adjusted_Damage(vecOrigin, iVictim, 0);
		
		if(isHe && pevAttacker == iVictim)
		{
			ExecuteHamB(Ham_TakeDamage, iVictim, pevInflictor, pevAttacker, fDamage, (1<<24))
			continue;
		}
		
		if(pevAttacker == iVictim) continue;
		
		pev(iVictim, pev_classname, szClassname, 63);
		if(is_user_alive(iVictim) && cs_zb_is_zombie(iVictim) && flKnockback > 0.0)
		{
			new Float:punch[3]; punch[0] = -15.0
			set_pev(iVictim, pev_punchangle, punch)
			Stock_MakeKnockback(iVictim, vOrigin, vecOrigin, fDistance, flKnockback*0.5);
		}
		else if(equal(szClassname, "gib") || equal(szClassname, "weaponbox") || equal(szClassname, "grenade"))
			Stock_MakeKnockback(iVictim, vOrigin, vecOrigin, fDistance, flKnockback);
			
		if(equal(szClassname, "func_breakable") || equal(szClassname, "func_pushable"))
		{
			if(!(pev(iVictim, pev_spawnflags) & SF_BREAK_TRIGGER_ONLY) && !(pev(iVictim, pev_effects) & EF_NODRAW))
			{
				if(fDamage <= 0.0) fDamage = floatdiv(flMaxDamage, 2.0)
				if(fDamage > 0.0 && pev(iVictim, pev_health) > 0.0)ExecuteHamB(Ham_TakeDamage, iVictim, pevInflictor, pevAttacker, fDamage, DMG_BLAST);
			}
			continue;
		}
		
		Stock_TakeDamage(pevAttacker, pevInflictor, iVictim, fDamage, isHe? (1<<24) : DMG_MORTAR)
	}
	
}

stock Stock_TakeDamage(pevAttacker, pevInflictor, iVictim, Float:flDamage, bitsDamageType)
{
	if(!pev_valid(iVictim) || flDamage <= 0.0) return;
	else if(!pev_valid(pevAttacker)) pevAttacker = iVictim;
	else if(!pev_valid(pevInflictor)) pevInflictor = pevAttacker;
	
	if(pev(iVictim, pev_health) > 0.0 && pev(iVictim, pev_takedamage) > 0.0)
	{
		new teamA=get_user_team(pevAttacker);
		new teamB=get_user_team(iVictim);
		new team1=pev(pevAttacker, pev_iuser2);
		new team2=pev(iVictim, pev_iuser2);
		if(!get_cvar_num("mp_friendlyfire")) 
		{
			if(teamA==teamB && (is_user_connected(pevAttacker) && is_user_connected(iVictim))) return;
			if(team1==team2 && (!is_user_connected(pevAttacker) && !is_user_connected(iVictim))) return;
			if(teamA==team2 && (is_user_connected(pevAttacker) && !is_user_connected(iVictim))) return;
			if(team1==teamB && (!is_user_connected(pevAttacker) && is_user_connected(iVictim))) return;
		}
		
		new Float:health;pev(iVictim, pev_health, health)
		if(!(bitsDamageType & DMG_BULLET)) {
			new Float:possible = health*4.2
			if(flDamage >= possible) bitsDamageType = bitsDamageType|DMG_ALWAYSGIB
		}
		if(flDamage > 0.0) ExecuteHamB(Ham_TakeDamage, iVictim, pevInflictor, pevAttacker, flDamage, bitsDamageType);
	}
}
stock play_sound(id, const sound[])
{
	if (equal(sound[strlen(sound)-4], ".mp3"))
		client_cmd(id, "mp3 play ^"sound/%s^"", sound)
	else
		client_cmd(id, "spk ^"%s^"", sound)
}
stock isBreakable(iEnt)
{
	if (!pev_valid(iEnt)) return 0;
	
	static szClassname[32]
	pev(iEnt, pev_classname, szClassname, charsmax(szClassname))
	if (equal(szClassname, "func_breakable") || equal(szClassname, "func_pushable")) return 1;
	return 0;
}
stock isTriggerHurt(iEnt)
{
	if (!pev_valid(iEnt)) return 0;
	
	static szClassname[32]
	pev(iEnt, pev_classname, szClassname, charsmax(szClassname))
	if (equal(szClassname, "trigger_hurt")) return 1;
	return 0;
}
stock isSmoke(Ent)
{
	if(!pev_valid(Ent)) return 0;
	
	static szClassName[32]; pev(Ent, pev_classname,szClassName, 31);
	return (equal(szClassName, "zombie3zsmoke"))
}
public isIgnoreOwner(iEnt)
{
	if (!pev_valid(iEnt)) return 0;
	
	static szClassname[32]
	pev(iEnt, pev_classname, szClassname, charsmax(szClassname))
	if (equal(szClassname, "zombiezclaw") || equal(szClassname, "zombiezwing") || equal(szClassname, "zombiezglow")) return 1;
	return 0;
}
stock RemoveSpecificEntity(const szClassName[])
{
	new pEnt = -1
	while((pEnt = engfunc(EngFunc_FindEntityByString, pEnt, "classname", szClassName)) != 0)
	{
		if(!pev_valid(pEnt)) continue;
		
		engfunc(EngFunc_RemoveEntity, pEnt)
	}
}
stock Stock_isInFOV(index, const Float:vecPoint[3], use3d=0, Float:flFov=90.0) 
{
	static Float:vAngle[3], Float:vecOfs[3], Float:vecOrigin[3], Float:vecDiff[3], Float:vecNorm[3];
	pev(index, pev_view_ofs, vecOfs);
	pev(index, pev_origin, vecOrigin);
	if(use3d)
	{
		xs_vec_add(vecOrigin, vecOfs, vecOrigin);
		pev(index, pev_v_angle, vAngle);
		engfunc(EngFunc_MakeVectors, vAngle);
		global_get(glb_v_forward, vAngle);
		xs_vec_sub(vecPoint, vecOrigin, vecDiff);
	} else {
		pev(index, pev_angles, vAngle);
		engfunc(EngFunc_MakeVectors, vAngle);
		global_get(glb_v_forward, vAngle);
		xs_vec_sub(vecPoint, vecOrigin, vecDiff);
		vecDiff[2] = 0.0;
		vAngle[2] = 0.0;
	}
	xs_vec_normalize(vecDiff, vecNorm);
	static Float:flDot;
	flDot = xs_vec_dot(vecNorm, vAngle);
	if (flDot >= floatcos(flFov * M_PI / 360))
		return 1;
	return 0;
}
stock ScreenShake(id, amplitude = 4, duration = 2, frequency = 10)
{
	message_begin(MSG_ONE_UNRELIABLE, get_user_msgid("ScreenShake"), _, id)
	write_short((1<<12)*amplitude) // ??
	write_short((1<<12)*duration) // ??
	write_short((1<<12)*frequency) // ??
	message_end()
}
stock IsDucking(id)
{
	return (pev(id, pev_flags) & (FL_DUCKING | FL_ONGROUND) == (FL_DUCKING | FL_ONGROUND))
}
