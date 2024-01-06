#include <amxmodx>
#include <amxmisc>
#include <cstrike>
#include <xs>
#include <fakemeta>
#include <engine>
#include <hamsandwich>
#include <nvault>
#include <reapi>

new setting_file[] = "music.txt"

new g_fwSpawn,  g_iFreeze
new g_iBotMenuData[2][33]
new g_iMenuData[4][33]
const OFFSET_CSMENUCODE = 205
#define MENU_PAGE_ITEMS g_menu_data[id]
new g_menu_data[33], g_musicdata[33]
new Float:flBuyTime, Array:ExtMenuItem
new cvar[8]

#define START_EXP	800

new g_pDataMenu[33]
new Array:g_MusicTitle, Array:g_MusicPath

new g_iExperience[33],g_iNextExperience[33], g_iLevel[33];
new iVault, iVaultBots, g_ShowInfo[33];

const PRIMARY_WEAPONS_BIT_SUM = (1<<CSW_SCOUT)|(1<<CSW_XM1014)|(1<<CSW_UMP45)|(1<<CSW_SG550)|(1<<CSW_GALIL)|(1<<CSW_FAMAS)|(1<<CSW_AWP)|(1<<CSW_MP5NAVY)|(1<<CSW_M249)|(1<<CSW_M3)|(1<<CSW_M4A1)|(1<<CSW_TMP)|(1<<CSW_G3SG1)|(1<<CSW_SG552)|(1<<CSW_AK47)|(1<<CSW_P90)|(1<<CSW_AUG)|(1<<CSW_MAC10)
const SECONDARY_WEAPONS_BIT_SUM = (1<<CSW_P228)|(1<<CSW_ELITE)|(1<<CSW_FIVESEVEN)|(1<<CSW_USP)|(1<<CSW_GLOCK18)|(1<<CSW_DEAGLE)

const CSWPN_PISTOL = (1<<CSW_USP)|(1<<CSW_GLOCK18)|(1<<CSW_P228)|(1<<CSW_DEAGLE)|(1<<CSW_FIVESEVEN)|(1<<CSW_ELITE)
const CSWPN_SHOTGUN = (1<<CSW_XM1014)|(1<<CSW_M3)
const CSWPN_SMG = (1<<CSW_MP5NAVY)|(1<<CSW_TMP)|(1<<CSW_MAC10)|(1<<CSW_UMP45)|(1<<CSW_P90)
const CSWPN_RIFLE = (1<<CSW_GALIL)|(1<<CSW_FAMAS)|(1<<CSW_AK47)|(1<<CSW_M4A1)|(1<<CSW_SG552)|(1<<CSW_AUG)
const CSWPN_SNIPER = (1<<CSW_SCOUT)|(1<<CSW_AWP)|(1<<CSW_SG550)|(1<<CSW_G3SG1)
const CSWPN_MG = CSW_M249
const CSWPN_NADE = (1<<CSW_HEGRENADE)|(1<<CSW_FLASHBANG)|(1<<CSW_SMOKEGRENADE)

new const WPNName[][] = { "", "P-250", "", "Steyr Scout", "High-Explosive Grenade", "Beneli M-1014", "C-4 Plastique", "Ingram Mac-10", "Steyr Aug A3 M1",  "Smoke Grenade", 
	"Dual M-9",  "FN-57", "H&K UMP-45", "SIG-550 Commando", "IWI Galil ACE", "Famas G2", "H&K USP-45", "Glock-17", "AI AWM", "MP-5 NAVY", 
	"FN M-249", "Beneli Supernova", "Colt M4A1 Carbine", "MP-9", "H&K G-3", "Stun Grenade", "Desert Eagle 50AE", "SIG-556", "Kalashnikov AK-47", 
	"Seal Knife", "FN P-90" }
	
new const Weapon_AmmoType[][] = { "", "ammo_357sig", "", "ammo_762nato", "", "ammo_buckshot", "", "ammo_45acp", "ammo_556nato", "", "ammo_9mm", "ammo_57mm", "ammo_45acp",
			"ammo_556nato", "ammo_556nato", "ammo_556nato", "ammo_45acp", "ammo_9mm", "ammo_338magnum", "ammo_9mm", "ammo_556natobox", "ammo_buckshot",
			"ammo_556nato", "ammo_9mm", "ammo_762nato", "", "ammo_50ae", "ammo_556nato", "ammo_762nato", "", "ammo_57mm" }

new const Weapon_AmmoSize[CSW_P90+1] = { -1,  4, -1, 3,  1,  4, 1, 9, 3, 1, 4, 2, 9, 3, 3, 3, 9, 4, 3, 4, 7, 4 , 3, 4, 3, 2, 5, 3, 3, -1, 2 }
new const Additional_Item[][] = { "weapon_c4", "item_armor", "item_assaultsuit", "item_thighpack", "item_nvgs"}
new const Additional_Item_Name[][] = { "C-4 Plastique Bomb", "Kevlar Vest", "Kevlar + Helmet", "Bomb Defusal Kit", "Nightvision" }

enum _:CustomItemData
{
	ItemName[64],
	ItemCost,
	ItemSlot,
	ItemPlugin,
	ItemFuncID,
	ItemSysName[64]
};
enum _:CustomItemSlot
{
	ItemSlot_Temp,
	ItemSlot_Pistol,
	ItemSlot_Shotgun,
	ItemSlot_Smg,
	ItemSlot_Rifle,
	ItemSlot_Sniper,
	ItemSlot_MG,
	ItemSlot_Nade,
	ItemSlot_Melee,
	ItemSlot_Equip,
	ItemSlot_Custom
}

new iTotal_Items, Array:Custom_Items; 
new g_iForwardHUD, fwResult, g_iForwardRemoveItem, g_iForwardRoundFreeze, g_iForwardRoundEnd
new g_iForwardSpawn, g_iForwardKill, g_iForwardClientCmd, g_iForwardRoundStart

//zbot nav
new ismaking, marking, placename, editingnav, placeedit, placemod
new PlaceList[][] = 
{
	"BombsiteA",		
	"BombsiteB",		
	"BombsiteC",		
	"Hostages",		
	"HostageRescueZone",		
	"VipRescueZone",		
	"CTSpawn",		
	"TSpawn",		
	"Bridge",		
	"Middle",		
	"House",		
	"Apartment",	
	"Apartments",		
	"Market",		
	"Sewers",		
	"Tunnel",		
	"Ducts",		
	"Village",		
	"Roof",		
	"Upstairs",		
	"Downstairs",		
	"Basement",		
	"Crawlspace",		
	"Kitchen",		
	"Inside",		
	"Outside",		
	"Tower",		
	"WineCellar",		
	"Garage",		
	"Courtyard",		
	"Water",		
	"FrontDoor",		
	"BackDoor",		
	"SideDoor",	
	"BackWay",		
	"FrontYard",		
	"BackYard",		
	"SideYard",		
	"Lobby",		
	"Vault",		
	"Elevator",		
	"DoubleDoors",		
	"SecurityDoors",		
	"LongHall",		
	"SideHall",		
	"FrontHall",		
	"BackHall",		
	"MainHall",		
	"FarSide",		
	"Windows",		
	"Window",		
	"Attic",		
	"StorageRoom",		
	"ProjectorRoom",		
	"MeetingRoom",		
	"ConferenceRoom",		
	"ComputerRoom",		
	"BigOffice",	
	"LittleOffice",		
	"Dumpster",	
	"Airplane",		
	"Underground",		
	"Bunker",		
	"Mines",		
	"Front",		
	"Back",		
	"Rear",		
	"Side",		
	"Ramp",		
	"Underpass",		
	"Overpass",		
	"Stairs",		
	"Ladder",		
	"Gate",		
	"GateHouse",		
	"LoadingDock",		
	"GuardHouse",		
	"Entrance",		
	"VendingMachines",		
	"Loft",		
	"Balcony",		
	"Alley",		
	"BackAlley",		
	"SideAlley",		
	"FrontRoom",		
	"BackRoom",	
	"SideRoom",		
	"Crates",		
	"Truck",		
	"Bedroom",		
	"FamilyRoom",		
	"Bathroom",		
	"LivingRoom",	
	"Den",		
	"Office",		
	"Atrium",		
	"Entryway",		
	"Foyer",		
	"Stairwell",		
	"Fence",		
	"Deck",		
	"Porch",		
	"Patio",		
	"Wall"
}

public plugin_init() 
{
	register_plugin("Server Miscellaneous", "1.7.1R", "csbtedhan")
	
	register_event("HLTV", "event_round_freeze", "a", "1=0", "2=0")
	register_logevent("event_newRound", 2, "1=Round_Start")
	register_logevent("event_roundEnd", 2, "1=Round_End")
	
	unregister_forward(FM_Spawn, g_fwSpawn)
	register_forward(FM_SetModel, "fw_SetModel")
	register_forward(FM_ClientCommand, "fw_ClientCommand")
	
	RegisterHookChain(RG_CBasePlayer_Spawn, "fw_PlayerSpawn_Post", 1)
	RegisterHookChain(RG_CBasePlayer_Killed, "fw_PlayerKilled", 1)
	
	RegisterHam(Ham_Touch, "weapon_shield", "fw_TouchShield")
	RegisterHam(Ham_Touch, "trigger_multiple", "fw_TouchClip")	
	RegisterHam(Ham_Touch, "trigger_once", "fw_TouchClip")	
	
	cvar[0] = register_cvar("sv_admin_cmd_msg", "1")
	cvar[1] = register_cvar("sv_respawn", "0")
	cvar[2] = register_cvar("sv_protection", "0")
	cvar[3] = register_cvar("sv_respawn_time", "3")
	cvar[5] = register_cvar("mp_free_item", "0")
	cvar[6] = register_cvar("mp_weaponbox_time", "-1.0")
	
	register_concmd("adminmenu", "admin_menu", _, "Admin menu", 0)
	register_concmd("botmenu", "bot_menu",  _, "Admin menu", 0)
	register_concmd("playermenu", "player_main_menu",  _, "Admin menu", 0)
	register_concmd("remove_entity", "remove_ent",  _, "Admin menu", 0)
	register_concmd("cs_give_exp", "CMD_GiveEXP", _, "<Name> <EXP Amount>", 0)
	register_concmd("cs_remove_exp", "CMD_RemoveEXP", _, "<Name> <EXP Amount>", 0)	
	
	register_clcmd("buy_customitem", "clcmd_buycustomitem")
	
	register_clcmd("+showmyinfo", "Cmd_ShowInfo")
	register_clcmd("-showmyinfo", "Cmd_ShowInfoEnd")

	server_cmd("sv_maxvelocity 9999")	
	server_cmd("sv_maxspeed 9999")	
	server_cmd("bot_allow_shield 0")
	
	flBuyTime = get_gametime() + (get_cvar_float("mp_buytime") * 60)
	
	g_iForwardHUD = CreateMultiForward("fw_CSHUD", ET_CONTINUE, FP_CELL)
	g_iForwardRemoveItem  = CreateMultiForward("fw_Remove_Item", ET_CONTINUE, FP_CELL, FP_CELL, FP_CELL)
	g_iForwardSpawn = CreateMultiForward("fw_CSPlayer_Spawn", ET_IGNORE, FP_CELL)
	g_iForwardKill = CreateMultiForward("fw_CSPlayer_Kill", ET_IGNORE, FP_CELL, FP_CELL)
	g_iForwardClientCmd = CreateMultiForward("fw_CSClient_Command", ET_IGNORE, FP_CELL, FP_STRING)
	g_iForwardRoundFreeze = CreateMultiForward("fw_CSNew_Round", ET_IGNORE)
	g_iForwardRoundStart = CreateMultiForward("fw_CSRoundStart", ET_IGNORE)
	g_iForwardRoundEnd = CreateMultiForward("fw_CSRoundEnd", ET_IGNORE)
	
	iVault = nvault_open("csm_data")
	iVaultBots = nvault_open("bot_csm_data")
	register_forward(FM_Touch, "fw_Touch")
}

public plugin_precache()
{
	Custom_Items = ArrayCreate(CustomItemData);
	ExtMenuItem = ArrayCreate(128, 1);
	
	// create temp
	if(!iTotal_Items)
	{
		new aItemData[CustomItemData];
		aItemData[ItemName] = "Temp Item"
		aItemData[ItemSysName] = "tempitem"
		ArrayPushArray(Custom_Items, aItemData)
		iTotal_Items++
	}
	
	g_MusicTitle = ArrayCreate(512, 1)
	g_MusicPath = ArrayCreate(512, 1)
	
	load_config()

	g_fwSpawn = register_forward(FM_Spawn, "fw_Spawn")
}

public plugin_natives()
{
	register_library("csm");
	register_native("cs_register_custom_item", "native_register_custom_item")
	register_native("cs_set_user_exp", "native_set_user_exp", 1)
	register_native("cs_get_user_exp", "native_get_user_exp", 1)
	register_native("cs_set_user_level", "native_get_user_level", 1)
	register_native("cs_get_user_level", "native_get_user_level", 1)
	register_native("cs_get_custom_itemid", "native_custom_itemid", 1)
	register_native("cs_force_buy_custom_item", "native_force_buy", 1)
	register_native("cs_remove_item", "native_remove_item", 1)
	register_native("cs_get_custom_item_slot", "native_item_slot", 1)
	register_native("cs_give_item", "native_give_item", 1)
	register_native("cs_is_round_freeze", "native_get_round_freeze", 1)
	register_native("cs_is_map_param", "native_map_param", 1)
	register_native("cs_misc_add_menuitem", "native_add_menu", 1)
}

public load_config()
{
	new path[256]
	format(path, charsmax(path), "%s", setting_file)
	
	if (!file_exists(path))
	{
		new error[100]
		formatex(error, charsmax(error), "Cannot load customization file %s!", path)
		set_fail_state(error)
		return;
	}
	
	new linedata[1386], key[512], value[960], file
	file = fopen(path, "rt")
	
	while (file && !feof(file))
	{
		fgets(file, linedata, charsmax(linedata))
		replace(linedata, charsmax(linedata), "^n", "")
		if (!linedata[0] || linedata[0] == ';'  || linedata[0] == '/') continue;
		strtok(linedata, key, charsmax(key), value, charsmax(value), '=')
		
		if(key[0] && value[0])
		{
			ArrayPushString(g_MusicTitle, key)
			ArrayPushString(g_MusicPath, value)
		}
	}
	if (file) fclose(file)
}

//=================================
// Natives
//=================================
public native_register_custom_item(iPlugin, iParams)
{
	new aItemData[CustomItemData]
	    
	get_string(1, aItemData[ItemName], charsmax(aItemData[ItemName]));
	    
	aItemData[ItemCost] = get_param(2);
	aItemData[ItemSlot] = get_param(3);
	
	aItemData[ItemPlugin] = iPlugin;
	    
	new szHandler[32]
	get_string(4, szHandler, charsmax(szHandler));
	aItemData[ItemFuncID] = get_func_id(szHandler, iPlugin);
	get_string(5, aItemData[ItemSysName], charsmax(aItemData[ItemSysName]));
	    
	ArrayPushArray(Custom_Items, aItemData);
	iTotal_Items++;
	    
	return (iTotal_Items - 1);
}
public native_set_user_exp(id, iAmount)
{
	if(!is_user_connected(id)) 
		return;
		
	g_iExperience[id] = iAmount
	Check_Player(id);
}
public native_get_user_exp(id)
{
	if(!is_user_connected(id)) 
		return 0;
	
	return g_iExperience[id]
}

public native_set_user_level(id, NewLevel)
{
	if(!is_user_connected(id)) 
		return 0;
	
	g_iLevel[id] = NewLevel
	
	return 1
}
public native_get_user_level(id)
{
	if(!is_user_connected(id)) 
		return 0;
	
	return g_iLevel[id]
}
public native_custom_itemid(const szName[])
{
	param_convert(1);
	
	new aItemData[CustomItemData]
	for(new i = 0; i<iTotal_Items; i++)
	{
		ArrayGetArray(Custom_Items, i, aItemData);
		if(equali(szName, aItemData[ItemSysName]))
			return i;
	}
	return -1;
}
public native_item_slot(itemid)
{
	if(itemid< 0 || itemid > iTotal_Items-1) return 0
	
	new aItemData[CustomItemData]
	ArrayGetArray(Custom_Items, itemid, aItemData);
	if(isPrimaryItem(aItemData[ItemSlot])) return 1;
	else if(isSecondaryItem(aItemData[ItemSlot])) return 2;
	else if(isMeleeItem(aItemData[ItemSlot])) return 3;
	else if(isNadeItem(aItemData[ItemSlot])) return 4;
	
	return 5
	
}
public native_force_buy(id, itemid, check, admin)
{
	if(!is_user_connected(id))
		return;
		
	GiveCustomItem(id, itemid, check, admin)
}
public native_remove_item(id, item, slot)
{
	if(!is_user_connected(id))
		return;
	
	ExecuteForward(g_iForwardRemoveItem, fwResult, id, item, slot);
}
public native_get_round_freeze(id)
{
	return g_iFreeze
}
public native_give_item(id, const szItem[])
{
	param_convert(2)
	new szCustom[32]
	format(szCustom, 31, "%s", szItem);
	replace(szCustom, 31, "weapon_", "")
	replace(szCustom, 31, "item_", "")
	replace(szCustom, 31, "ammo_", "")
	
	if(GetCustomItemid(szCustom) != -1) GiveCustomItem(id, GetCustomItemid(szCustom), 0, 1)
	else
	{
		if(containi(szItem, "weapon_") != -1) 
		{
			new wpnid = get_weaponid(szItem);
			Stock_Drop_Slot(id, Stock_Get_Wpn_Slot(wpnid), 0);
		}
		GivePlayerItem(id, szItem);
	}
}
public native_map_param(index)
	return (get_user_team(index) == CheckInfoMapParam() || CheckInfoMapParam()==3)
public native_add_menu(const szTitle[], const szCmd[])
{
	param_convert(1);
	param_convert(2);
	
	new szStrings[128]
	format(szStrings, charsmax(szStrings), "%s,%s", szTitle, szCmd);
	ArrayPushString(ExtMenuItem, szStrings);
}
//=================================
// Reg
//=================================
public client_putinserver(id)
{
	if(!is_user_bot(id))
	{
		remove_task(id+5500)
		set_task(0.1, "task_draw_hud", id+5500,_,_,"b");
	}
}

public client_connect(id)
{
	if(is_user_bot(id)) return
	
	Load_PlayerData(id)
}
public client_disconnected(id)
{
	if(is_user_bot(id)) return
	
	Save_PlayerData(id)
}
//=================================
// Event
//=================================
public event_round_freeze()
{
	g_iFreeze = 1
	ExecuteForward(g_iForwardRoundFreeze, fwResult)
	for(new id=0; id<get_maxplayers(); id++)
	{
		if(!is_valid_ent(id) || !is_user_connected(id)) continue;
		
		if(is_user_bot(id)) Load_BotData(id)
	}
	
	server_cmd("bot_allow_shield 0")
	remove_entity_name("gib")
	flBuyTime = get_gametime() + (get_cvar_float("mp_buytime") * 60)
}
public event_newRound()
{
	g_iFreeze = 0
	ExecuteForward(g_iForwardRoundStart, fwResult)
}	
public event_roundEnd()
{
	for(new id=0; id<get_maxplayers(); id++)
	{
		if(!is_valid_ent(id) || !is_user_connected(id)) continue;
		
		if(is_user_bot(id)) Save_BotData(id)
		else Save_PlayerData(id)
	}
	ExecuteForward(g_iForwardRoundEnd, fwResult)
}
//=================================
// Forward
//=================================

public fw_Spawn(entity)
{
	// Invalid entity
	if (!pev_valid(entity)) return FMRES_IGNORED;
	
	// Get classname
	new classname[32]
	pev(entity, pev_classname, classname, charsmax(classname))
	if(equal(classname, "game_player_equip"))
	{
		engfunc(EngFunc_RemoveEntity, entity)
		return FMRES_SUPERCEDE;
	}
	return FMRES_IGNORED;
}

public fw_TouchClip(ent, id)
{
	if (!is_user_alive(id) || !is_valid_ent(ent) || !is_valid_ent(id))
		return HAM_IGNORED;
	
	new szGlobalname[64]
	pev(ent, pev_targetname, szGlobalname, 63)
	if(equal(szGlobalname, "playerclip"))
	{
		new Float:vel[3]
		pev(id, pev_velocity, vel)
		xs_vec_mul_scalar(vel, -1.5, vel)
		set_pev(id, pev_velocity, vel)
		return HAM_SUPERCEDE
	}
	return HAM_IGNORED;
}

public fw_SetModel(ent, const model[])
{
	if(!is_valid_ent(ent)) return
	
	new szClassname[32];
	pev(ent, pev_classname, szClassname, 31)
	
	if(equal(szClassname, "weaponbox"))
	{
		if(equal(model, "models/w_backpack.mdl")) return
		if(get_pcvar_float(cvar[6]) >= 0.0) set_pev(ent, pev_nextthink, get_gametime() + get_pcvar_float(cvar[6]))
	}
}

public fw_ClientCommand(id)
{
	new arg[32]
	if (read_argv(0, arg, 31) > 31) return FMRES_IGNORED
	
	ExecuteForward(g_iForwardClientCmd, fwResult, id, arg);
	
	if(fwResult == 1) return FMRES_SUPERCEDE
	return FMRES_IGNORED
} 

public fw_PlayerSpawn_Post(id)
{
	if(!is_user_alive(id))
		return 
	
	ExecuteForward(g_iForwardSpawn, fwResult, id)
	
	if(get_pcvar_num(cvar[2])){
		new team = get_user_team(id)
		if(team == 1) set_rendering(id, kRenderFxGlowShell, 255, 0, 0, kRenderNormal, 16)
		else if(team == 2) set_rendering(id, kRenderFxGlowShell, 0, 0, 255, kRenderNormal, 16)
		else set_rendering(id, kRenderFxGlowShell, 0, 255, 0, kRenderNormal, 16)
		set_pev(id, pev_takedamage, 0.0)
		set_task(3.0, "remove_protection", id+8400)
	}
}
	
public fw_PlayerKilled(victim, attacker, shouldgib)
{
	if(!is_user_connected(victim)) return
	
	ExecuteForward(g_iForwardKill, fwResult, victim, attacker)
		
	if(is_user_connected(attacker))
		native_set_user_exp(attacker, g_iExperience[attacker] + 100)
	
	set_pev(victim, pev_iuser1, 0)
	cs_set_user_defuse(victim, 0)
	
	new Float:timer = get_pcvar_float(cvar[3])
	if(get_pcvar_num(cvar[1])){
		set_task(timer, "respawn", victim)
	}
}

public fw_TouchShield(weapon, id)
{
	// Not a player
	if (!is_user_connected(id))
		return HAM_IGNORED;
	
	engfunc(EngFunc_RemoveEntity, weapon)
	return HAM_SUPERCEDE;
}

//=================================
// Other
//=================================
public task_draw_hud(id)
{
	id-= 5500
	if(!is_user_connected(id))
	{
		remove_task(id+5500)
		return
	}
	if(!is_user_bot(id) && g_ShowInfo[id])
	{
		set_hudmessage(224, 224, 255, 0.01, 0.18, 0, 0.25, 0.25, 0.0, 0.0, 0);
		show_hudmessage(id, "Level: %i ^nExperience:%i / %i", g_iLevel[id], g_iExperience[id], g_iNextExperience[id]);
	}
	
	ExecuteForward(g_iForwardHUD, fwResult, id);
}
public respawn(id)
{
	if(!is_user_alive(id))
	{
		ExecuteHam(Ham_CS_RoundRespawn, id)
		cs_set_user_money(id, cs_get_user_money(id) + 3000)
	}
}
public remove_protection(id)
{
	id-= 8400
	if(!is_user_alive(id)) return
	
	set_rendering(id, kRenderFxNone, 0, 0, 0, kRenderNormal, 0)
	set_pev(id, pev_takedamage, 2.0)
}

//=================================
// Admin Menu
//=================================
public admin_menu(id)
{
	new menu = menu_create("\y[CS]\w Admin Player & Bots", "admin_handler")

	menu_additem(menu, "Main Player Menu", "mp")
	menu_additem(menu, "Bots Menu", "bot")
	menu_additem(menu, "Equip Management", "eq")
	menu_additem(menu, "Music Player", "mp3")
	if(ArraySize(ExtMenuItem))
	{
		new szMenu[128], szCmd[32], data[16]
		for(new i = 0; i < ArraySize(ExtMenuItem); i ++ )
		{
			ArrayGetString(ExtMenuItem, i, szMenu, 127);
			strtok(szMenu, szMenu, charsmax(szMenu), szCmd, charsmax(szCmd), ',')
			
			data[0] = i
			menu_additem(menu, szMenu, data);
		}
	}
	
	set_pdata_int(id, 205, 0)
	menu_display(id, menu)
}
public admin_handler(id, menu, item)
{
	if(item == MENU_EXIT)
	{
		menu_destroy(menu)
		return
	}
	
	new data[16], iName[11]
	new accessi, callback
	menu_item_getinfo(menu, item, accessi, data,15, iName, 10, callback)
	
	if(equal(data, "mp")) player_main_menu(id)
	else if(equal(data, "bot")) bot_menu(id)
	else if(equal(data, "eq")) AdminEquipMenu(id, 0)
	else if(equal(data, "mp3")) AdminMusicMenu(id)
	else {
		if(ArraySize(ExtMenuItem))
		{
			new szMenu[128], szCmd[32]
			ArrayGetString(ExtMenuItem, data[0], szMenu, 127);
			strtok(szMenu, szMenu, charsmax(szMenu), szCmd, charsmax(szCmd), ',')
			
			client_cmd(id, szCmd)
		} else admin_menu(id)
	}
}
//=================================
// BOT Menu
//=================================
public bot_menu(id)
{
	new menu = menu_create("\y[CS]\w ZBOT Menu", "botmenu_handler")
	new text[64], arg[32]
	
	menu_additem(menu, "Add", "0")
	menu_additem(menu, "Add Counter-Terrorist", "1")
	menu_additem(menu, "Add Terrorist", "2")
	
	switch(g_iBotMenuData[0][id])
	{
		case 0: arg = "Easy"
		case 1: arg = "Normal"
		case 2: arg = "Hard"
		case 3: arg = "Expert"
	}
	format(text, 63, "Difficulty: \r%s", arg)
	menu_additem(menu, text, "3")
	
	format(text, 63, "Quota: \y%i", g_iBotMenuData[1][id])
	menu_additem(menu, text, "4")
	menu_additem(menu, "Kill All Bot", "5")
	menu_additem(menu, "Kick All Bot", "6")
	menu_additem(menu, "Navigation Menu", "7")
	
	set_pdata_int(id, 205, 0)
	menu_display(id, menu)
}
public botmenu_handler(id, menu, item)
{
	if(item == MENU_EXIT)
	{
		menu_destroy(menu)
		return
	}
	
	new data[5], iName[11]
	new accessi, callback
	menu_item_getinfo(menu, item, accessi, data,4, iName, 10, callback)
	
	data[0] = str_to_num(data)
	switch(data[0]){
		case 0 : server_cmd("bot_add")
		case 1 : server_cmd("bot_add_ct")
		case 2 : server_cmd("bot_add_t")
		case 3 :
		{
			g_iBotMenuData[0][id] = g_iBotMenuData[0][id] > 2 ? 0 : g_iBotMenuData[0][id] + 1
			server_cmd("bot_difficulty %i", g_iBotMenuData[0][id])
		}
		case 4 :
		{
			g_iBotMenuData[1][id] = g_iBotMenuData[1][id] > 31 ? 0 : g_iBotMenuData[1][id] + 1
			server_cmd("bot_quota %d", g_iBotMenuData[1][id])
		}
		case 5: server_cmd("bot_kill")
		case 6: server_cmd("bot_quota 0")
		case 7: 
		{
			BotNavMainMenu(id)
			return;
		}
	}
	bot_menu(id)
}

//=================================
// Main Player Menu
//=================================
public player_main_menu(id)
{
	new menu = menu_create("\y[CS]\w Player Menu", "main_menu_handler")
	new text[64], arg[32]

	menu_additem(menu, "Send Cheats", "0")
	switch(g_iMenuData[0][id]){
		case 0: arg = "God Mode"
		case 1: arg = "No Clip"
		case 2: arg = "No Targets"
	}
	format(text, 63, "Cheats Type: \r%s", arg)
	menu_additem(menu, text, "1")
	menu_additem(menu, "Respawn a Player", "2")
	menu_additem(menu, "Kill a Player", "3")
	menu_additem(menu, "Kick a Player", "4")
	menu_additem(menu, "Teleport a Player", "5")
	
	set_pdata_int(id, 205, 0)
	menu_display(id, menu)
}
public main_menu_handler(id, menu, item)
{
	if(item == MENU_EXIT)
	{
		menu_destroy(menu)
		return
	}
	
	new data[5], iName[11]
	new accessi, callback
	menu_item_getinfo(menu, item, accessi, data,4, iName, 10, callback)
	
	data[0] = str_to_num(data)
	switch(data[0]){
		case 0 :{
			g_iMenuData[1][id] = 0
			player_menu(id)
		}
		case 1:{
			switch(g_iMenuData[0][id]){
				case 0:{
					g_iMenuData[0][id] = 1
					player_main_menu(id)
				}
				case 1:{
					g_iMenuData[0][id] = 2
					player_main_menu(id)
				}
				case 2:{
					g_iMenuData[0][id] = 0
					player_main_menu(id)
				}
			}
		}
		case 2:{
			g_iMenuData[1][id] = 1
			player_menu(id)
		}
		case 3:{
			g_iMenuData[1][id] = 2
			player_menu(id)
		}
		case 4:{
			g_iMenuData[1][id] = 3
			player_menu(id)
		}
		case 5:{
			g_iMenuData[1][id] = 4
			player_menu(id)
		}
	}
}
//=================================
// Player Menu
//=================================		
public player_menu(id)	
{
	new title[64], text[128]
	switch(g_iMenuData[1][id]){
		case 0 :{
			switch(g_iMenuData[0][id]){
				case 0: title = "Cheats God Mode"
				case 1: title = "Cheats Noclip Mode"
				case 2: title = "Cheats No Target"
			}
		}
		case 1 : title = "Respawn a Player"
		case 2 : title = "Kill a Player"
		case 3 : title = "Kick a Player"
		case 4 : title = "Teleport Player"
		default : title = "Give Items"
	}
	
	format(text, 127, "\y[CS]\w %s", title)
	new menu = menu_create(title, "player_menu_handler")
	new name[32], data[2]
	for(new i = 0; i<get_maxplayers(); i++)
	{
		if(!pev_valid(i) || !is_user_connected(i)) continue;
		
		get_user_name(i, name, 31)
		
		if(g_iMenuData[1][id] == 1)
		{
			if(is_user_alive(i)) format(text, 63, "\d%s", name)
			else format(text, 63, "%s", name)
		}
		else if(g_iMenuData[1][id] == 3)
		{
			if(i==id) format(text, 63, "\d%s", name)
			else format(text, 63, "%s", name)
		}
		else 
		{
			if(!is_user_alive(i)) format(text, 63, "\d%s", name)
			else format(text, 63, "%s", name)
		}
		
		data[0] = i
		data[1] = 0
		menu_additem(menu, text, data)
	}
	if (menu_items(menu) <= 0)
	{
		menu_destroy(menu)
		return;
	}
	
	menu_setprop(menu, MPROP_BACKNAME, "Back")
	menu_setprop(menu, MPROP_NEXTNAME, "Next")
	menu_setprop(menu , MPROP_EXIT , MEXIT_ALL)
	
	MENU_PAGE_ITEMS = min(MENU_PAGE_ITEMS, menu_pages(menu)-1)
	set_pdata_int(id, 205, 0)
	menu_display(id, menu, MENU_PAGE_ITEMS)
}
public player_menu_handler(id, menuid, item)
{
	if (item == MENU_EXIT)
	{
		MENU_PAGE_ITEMS = 0
		menu_destroy(menuid)
		return;
	}
	MENU_PAGE_ITEMS = item / 7
	
	new data[2], dummy, player
	menu_item_getinfo(menuid, item, dummy, data, charsmax(data), _, _, dummy)
	player = data[0]
	
	switch(g_iMenuData[1][id]){
		case 0:{
			switch(g_iMenuData[0][id]){
				case 0: set_godmode(player)
				case 1: set_noclip(player)
				case 2: set_notarget(player)
			}
		}
		case 1: if(!is_user_alive(player)) respawn_player(player)
		case 2: if(is_user_alive(player)) kill_player(player)
		case 3: if(player!=id) kick_player(player)
		case 4: if(is_user_alive(player)) teleport_to_aim(id, player)
		case 5: if(is_user_alive(player)) SetGiveItem(player, g_pDataMenu[id])
		case 6: {
			if(!is_user_alive(player))
			{
				player_menu(id)
				return;
			}
			new name[64], aItemData[CustomItemData], slot;
			ArrayGetArray(Custom_Items, g_pDataMenu[id], aItemData);
			GiveCustomItem(player, g_pDataMenu[id], 0, 1)
			get_user_name(player, name, 63)
			slot = aItemData[ItemSlot]
			if(!((1<<slot) & (1<<ItemSlot_Temp|1<<ItemSlot_Equip|1<<ItemSlot_Melee|1<<ItemSlot_Nade)))
				GiveAmmo(player, slot==ItemSlot_Pistol ? 1 : 0);
			
			if(get_pcvar_num(cvar[0])) colored_print(0, ">x01[>x04CS>x01] Admin has Give >x04%s>x01 to >x03%s", aItemData[ItemName], name)
		}
				
	}		
	
	player_menu(id)
}
//====================================
// ZBOT Nav manager
//====================================

public BotNavMainMenu(id)
{
	new iMenu = menu_create("ZBOT Navigation Manager", "NavMainMenuHandler");
	
	if(placemod) 
	{
		client_cmd(id, "bot_nav_toggle_place_mode 0")
		placemod = 0
	}
	menu_additem(iMenu, editingnav ? "Navigation Editor: \rEnabled" : "Navigation Editor: \rDisabled", "tog")
	
	if(editingnav)
	{
		menu_additem(iMenu, "Manage Area", "edit");
		menu_additem(iMenu, "Manage Place", "plac");
	}
	menu_additem(iMenu, "Analyze", "ana");
	menu_additem(iMenu, "Save", "save");
	
	set_pdata_int(id, 205, 0)
	menu_display(id, iMenu)
}
public BotNavEditAreaMenu(id)
{
	new iMenu = menu_create("ZBOT Manage Area", "NavMainMenuHandler");
	
	if(placemod) 
	{
		client_cmd(id, "bot_nav_toggle_place_mode 0")
		placemod = 0
	}
	
	menu_additem(iMenu, ismaking ? "End Area" : "Begin Area", "area");
	menu_additem(iMenu, "Delete Aimed Area", "del");
	menu_additem(iMenu, "Split Area", "split");
	menu_additem(iMenu, marking ? "Un Mark Aimed Area" : "Mark Aimed Area", "mark");
	if(marking)
	{
		menu_additem(iMenu, "Connect Aimed to Marked Area", "con");
		menu_additem(iMenu, "Disconnect Aimed to Marked Area", "dis");
		menu_additem(iMenu, "Merge Aimed to Marked Area", "mer");
		menu_additem(iMenu, "Order Bot go to Marked Area", "bot");
	}
	menu_additem(iMenu, "Splice Area", "splice");
	menu_additem(iMenu, "Jump Area", "jump");
	menu_additem(iMenu, "Crouch Area", "duck");
	
	set_pdata_int(id, 205, 0)
	menu_display(id, iMenu)
}

public BotNavEditPlaceMenu(id)
{
	new iMenu = menu_create("ZBOT Manage Place", "NavMainMenuHandler");
	
	if(!placemod) 
	{
		client_cmd(id, "bot_nav_toggle_place_mode 1")
		placemod = 1
	}
	new Txt[64]; format(Txt, 63, "Place Name: \r%s", PlaceList[placename])
	menu_additem(iMenu, Txt, "pname")
	menu_additem(iMenu, placeedit ? "Paint Mode: \rEnabled" : "Paint Mode: \rDisabled", "paint");
	set_pdata_int(id, 205, 0)
	menu_display(id, iMenu)
}
public BotNavPlaceMenu(id)
{
	new Data[2], iMenu = menu_create("ZBOT Place Name", "NavMainMenuHandler");
	for(new i = 0; i < sizeof(PlaceList); i ++)
	{
		Data[0] = i
		menu_additem(iMenu, PlaceList[i], Data)
	}
	set_pdata_int(id, 205, 0)
	menu_display(id, iMenu)
}
public NavMainMenuHandler(id, menuid, item)
{
	if (item == MENU_EXIT)
	{
		menu_destroy(menuid)
		return;
	}
	
	new data[32], dummy
	menu_item_getinfo(menuid, item, dummy, data, charsmax(data), _, _, dummy)
	
	//main
	if(equal(data, "tog")) 
	{
		client_cmd(id, editingnav ?"bot_nav_edit 0":"bot_nav_edit 1")
		editingnav = 1-editingnav
		BotNavMainMenu(id)
	}
	else if(equal(data, "edit")) BotNavEditAreaMenu(id);
	else if(equal(data, "plac")) BotNavEditPlaceMenu(id);
	else if(equal(data, "ana")) client_cmd(id, "bot_nav_analyze");
	else if(equal(data, "save")) client_cmd(id, "bot_nav_save");
	
	//area
	else if(equal(data, "area")) 
	{
		client_cmd(id, ismaking?"bot_nav_end_area":"bot_nav_begin_area")
		ismaking = 1-ismaking
		BotNavEditAreaMenu(id)
	}
	else if(equal(data, "del")) 
	{
		client_cmd(id, "bot_nav_delete")
		BotNavEditAreaMenu(id);
	}
	else if(equal(data, "split")) 
	{
		client_cmd(id, "bot_nav_split");
		BotNavEditAreaMenu(id)
	}
	else if(equal(data, "mark")) 
	{
		client_cmd(id, "bot_nav_mark");
		marking = 1-marking
		BotNavEditAreaMenu(id);
	}
	else if(equal(data, "con")) 
	{
		client_cmd(id, "bot_nav_connect");
		marking = 1-marking
		BotNavEditAreaMenu(id);
	}
	else if(equal(data, "dis")) 
	{
		client_cmd(id, "bot_nav_disconnect");
		marking = 1-marking
		BotNavEditAreaMenu(id);
	}
	else if(equal(data, "mer"))
	{
		client_cmd(id, "bot_nav_merge");
		marking = 1-marking
		BotNavEditAreaMenu(id);
	}
	else if(equal(data, "bot")) 
	{
		client_cmd(id, "bot_goto_mark");
		BotNavEditAreaMenu(id);
	}
	else if(equal(data, "splice")) 
	{
		client_cmd(id, "bot_nav_splice");
		BotNavEditAreaMenu(id);
	}
	else if(equal(data, "jump")) 
	{
		client_cmd(id, "bot_nav_jump");
		BotNavEditAreaMenu(id)
	}
	else if(equal(data, "duck")) 
	{
		client_cmd(id, "bot_nav_crouch");
		BotNavEditAreaMenu(id);
	}
	
	// place
	else if(equal(data, "pname")) BotNavPlaceMenu(id);
	else if(equal(data, "paint"))
	{	
		client_cmd(id, !placeedit ? "bot_nav_toggle_place_painting 1" : "bot_nav_toggle_place_painting 0");
		placeedit = 1-placeedit
		BotNavEditPlaceMenu(id);
	}
	else
	{
		placename = data[0]
		client_cmd(id, "bot_nav_use_place %s", PlaceList[data[0]]);
		BotNavEditPlaceMenu(id);
		return;
	}
}
//====================================
// Command
//====================================
public clcmd_buycustomitem(id)
{
	if(!is_user_alive(id))
		return PLUGIN_HANDLED;
	
	new arg[64], szWpn[32]
	read_argv(1, arg, 63)
	format(szWpn, 31, "weapon_%s", arg)
	
	if(cs_get_user_vip(id))
	{
		client_print(id, print_center, "#Cstrike_TitlesTXT_VIP_cant_buy")
		return PLUGIN_HANDLED;
	}
	if(get_user_team(id) == CheckInfoMapParam() || CheckInfoMapParam()==3)
	{
		if(get_user_team(id) == 1) client_print(id, print_center, "#Cstrike_TitlesTXT_Terrorist_cant_buy")
		else client_print(id, print_center, "#Cstrike_TitlesTXT_CT_cant_buy")
		return PLUGIN_HANDLED;
	}
	if(!cs_get_user_buyzone(id))
	{
		client_print(id, print_center, "You can't buy here!")
		return PLUGIN_HANDLED;
	}
	if(flBuyTime <= get_gametime())
	{
		client_print(id, print_center, "%d seconds have passed.^nYou can't buy anything now!", get_cvar_num("mp_buytime") * 60)
		return PLUGIN_HANDLED;
	}
	
	new aItemData[CustomItemData], itemid
	for(new i = 0; i<iTotal_Items; i++)
	{
		ArrayGetArray(Custom_Items, i, aItemData);
		if(equali(arg, aItemData[ItemSysName]))
		{
			itemid = i;
			break;
		}
	}
	if(!itemid) return PLUGIN_HANDLED;
	
	GiveCustomItem(id, itemid, 1)
	return PLUGIN_HANDLED;
}

public CMD_GiveEXP(id, level, cid)
{
	if (!cmd_access(id, level, cid, 2))
		return PLUGIN_HANDLED;
    
	new arg[32], exp[32]
    
	read_argv(1, arg, 31)
	read_argv(2, exp, 31)
    
	new target = cmd_target(id, arg, 0)
    
	if(!target) return PLUGIN_HANDLED;
    
	new expnum = str_to_num(exp)

	g_iExperience[target] += expnum
	Check_Player(target)
    
	return PLUGIN_HANDLED;
}

public CMD_RemoveEXP(id, level, cid)
{
	if (!cmd_access(id, level, cid, 2))
		return PLUGIN_HANDLED;
    
	new arg[32], exp[32]
    
	read_argv(1, arg, 31)
	read_argv(2, exp, 31)
    
	new target = cmd_target(id, arg, 0)
    
	if(!target) return PLUGIN_HANDLED;
    
	new expnum = str_to_num(exp)
	g_iExperience[target] = max(0, g_iExperience[target]-expnum)
	Check_Player(target)
    
	return PLUGIN_HANDLED;
}
public Cmd_ShowInfo(id)
{
	if(!is_user_bot(id)) return
	
	g_ShowInfo[id] = 1
}

public Cmd_ShowInfoEnd(id)
{
	if(!is_user_bot(id)) return
	
	g_ShowInfo[id] = 0
}
public kill_player(id)
{
	if(!is_user_alive(id)) return
	
	new name[32]
	get_user_name(id, name, 31)
	new msg = get_pcvar_num(cvar[0])
	user_kill(id)
	if(msg) colored_print(0, ">x01[>x04CS>x01] Admin has Kill %s", name)
}

public kick_player(id)
{	
	new name[32]
	get_user_name(id, name, 31)
	new msg = get_pcvar_num(cvar[0])
	new userid = get_user_userid(id)
	server_cmd("kick #%d", userid)
	if(msg) colored_print(0, ">x01[>x04CS>x01] Admin has Kick %s", name)
}

public respawn_player(id)
{
	new name[32]
	get_user_name(id, name, 31)
	new msg = get_pcvar_num(cvar[0])
	if(!is_user_alive(id))
	{
		ExecuteHam(Ham_CS_RoundRespawn, id)
		if(msg) colored_print(0, ">x01[>x04CS>x01] Admin has Respawni %s", name)
	}
}	
public set_noclip(id)
{
	if(!is_user_alive(id)) return PLUGIN_CONTINUE
	
	new name[32]
	get_user_name(id, name, 31)
	
	new msg = get_pcvar_num(cvar[0])
	new noclip = (pev(id, pev_movetype) == MOVETYPE_NOCLIP)
	if(!noclip)
	{
		set_pev(id, pev_movetype, MOVETYPE_NOCLIP)
		if(msg) colored_print(0, ">x01[>x04CS>x01] Admin has Activate Cheats Noclip for %s", name)
	} else {
		set_pev(id, pev_movetype, MOVETYPE_WALK)
		if(msg) colored_print(0, ">x01[>x04CS>x01] Admin has Deactivate Cheats Noclip for %s", name)
	}
	return PLUGIN_CONTINUE
}
public set_godmode(id)
{
	if(!is_user_alive(id)) return PLUGIN_CONTINUE
	
	new god = (pev(id, pev_takedamage) == DAMAGE_NO)
	
	new name[32]
	get_user_name(id, name, 31)
	
	new msg = get_pcvar_num(cvar[0])
	if(!god)
	{
		set_pev(id, pev_takedamage, DAMAGE_NO)
		if(msg) colored_print(0, ">x01[>x04CS>x01] Admin has Activate Cheats Godmode for %s", name)
	} else {
		set_pev(id, pev_takedamage, DAMAGE_AIM)
		if(msg) colored_print(0, ">x01[>x04CS>x01] Admin has Deactivate Cheats Godmode for %s", name)
	}
	return PLUGIN_CONTINUE
}
public set_notarget(id)
{
	if(!is_user_alive(id)) return PLUGIN_CONTINUE
	
	new notarget = get_entity_flags(id) & FL_NOTARGET
	
	new name[32]
	get_user_name(id, name, 31)
	
	new msg = get_pcvar_num(cvar[0])
	if(!notarget )
	{
		set_entity_flags(id, FL_NOTARGET, 1)
		if(msg) colored_print(0, ">x01[>x04CS>x01] Admin has Activate Cheats Notarget for %s", name)
	} else {
		set_entity_flags(id, FL_NOTARGET, 0)
		if(msg) colored_print(0, ">x01[>x04CS>x01] Admin has Deactivate Cheats Notarget for %s", name)
	}
	return PLUGIN_CONTINUE
}
public teleport_to_aim(id, target)
{
	if(!is_user_alive(target)) return
	
	new Float:origin[3]
	fm_get_aim_origin(id, origin)
	origin[2]+=37.0
	
	entity_set_origin(target, origin)
	
	new msg = get_pcvar_num(cvar[0])
	new name[32]
	get_user_name(target, name, 31)
	if(msg) colored_print(0, ">x01[>x04CS>x01] Admin has Teleport %s", name)
}

public remove_ent(id)
{
	new arg[32]
	read_argv(1, arg, 31)
	
	remove_entity_name(arg)
}
//=================================
// EQUIP ADMIN MENU
//=================================
public AdminEquipMenu(id, type)
{
	new iMenuEquip = menu_create("Equipment Management", "AdminEquipHandler")
	switch(type)
	{
		case 1:
		{
			menu_additem(iMenuEquip, "Pistols", "101")
			menu_additem(iMenuEquip, "Shotguns", "102")
			menu_additem(iMenuEquip, "Sub-Machine Guns", "103")
			menu_additem(iMenuEquip, "Rifles", "104")
			menu_additem(iMenuEquip, "Snipers", "105")
			menu_additem(iMenuEquip, "Machine Guns", "106")
			menu_additem(iMenuEquip, "Grenade", "107")
			menu_additem(iMenuEquip, "Melee", "108")
			menu_additem(iMenuEquip, "Ammo", "109")
			menu_additem(iMenuEquip, "Equipment", "110")
		}
		case 2: buildEquipWeaponMenu(iMenuEquip, 0)
		case 3: buildEquipWeaponMenu(iMenuEquip, 1)
		case 4: buildEquipWeaponMenu(iMenuEquip, 2)
		case 5: buildEquipWeaponMenu(iMenuEquip, 3)
		case 6: buildEquipWeaponMenu(iMenuEquip, 4)
		case 7: buildEquipWeaponMenu(iMenuEquip, 5)
		case 8: buildEquipWeaponMenu(iMenuEquip, 6)
		case 9: buildEquipWeaponMenu(iMenuEquip, 7)
		case 10: buildEquipItemMenu(iMenuEquip)
		case 11:
		{
			menu_additem(iMenuEquip, "Primary Ammo", "111")
			menu_additem(iMenuEquip, "Secondary Ammo", "112")
		}
		default:
		{
			menu_additem(iMenuEquip, "Give to Self", "301")
			menu_additem(iMenuEquip, "Give to Other Player", "302")
			menu_additem(iMenuEquip, "Give Equip Ammo", "303")
		}
	}
	set_pdata_int(id, 205, 0)
	menu_display(id, iMenuEquip, 0)
	
}
public buildEquipWeaponMenu(iMenuEquip, type)
{
	new iMenuDataWpn[2], aItemData[CustomItemData]
	// register extra items
	if(iTotal_Items)
	{
		for(new i = 0; i<iTotal_Items; i++)
		{
			ArrayGetArray(Custom_Items, i, aItemData)
			iMenuDataWpn[0] = i
			iMenuDataWpn[1] = 1
			switch(type)
			{
				case 1: if(aItemData[ItemSlot] == ItemSlot_Shotgun) menu_additem(iMenuEquip, aItemData[ItemName], iMenuDataWpn)	
				case 2: if(aItemData[ItemSlot] == ItemSlot_Smg) menu_additem(iMenuEquip, aItemData[ItemName], iMenuDataWpn)		
				case 3: if(aItemData[ItemSlot] == ItemSlot_Rifle) menu_additem(iMenuEquip, aItemData[ItemName], iMenuDataWpn)	
				case 4: if(aItemData[ItemSlot] == ItemSlot_Sniper) menu_additem(iMenuEquip, aItemData[ItemName], iMenuDataWpn)	
				case 5: if(aItemData[ItemSlot] == ItemSlot_MG) menu_additem(iMenuEquip, aItemData[ItemName], iMenuDataWpn)	
				case 6: if(aItemData[ItemSlot] == ItemSlot_Nade) menu_additem(iMenuEquip, aItemData[ItemName], iMenuDataWpn)
				case 7: if(aItemData[ItemSlot] == ItemSlot_Melee) menu_additem(iMenuEquip, aItemData[ItemName], iMenuDataWpn)
				default: if(aItemData[ItemSlot] == ItemSlot_Pistol) menu_additem(iMenuEquip, aItemData[ItemName], iMenuDataWpn)	
			}
			
		}
	}
	// default item
	for(new i=0; i<=CSW_P90; i++)
	{
		iMenuDataWpn[0] = i
		iMenuDataWpn[1] = 0
		switch(type)
		{
			case 1: if((1<<i) & CSWPN_SHOTGUN) menu_additem(iMenuEquip, WPNName[i], iMenuDataWpn)
			case 2: if((1<<i) & CSWPN_SMG) menu_additem(iMenuEquip, WPNName[i], iMenuDataWpn)
			case 3: if((1<<i) & CSWPN_RIFLE) menu_additem(iMenuEquip, WPNName[i], iMenuDataWpn)
			case 4: if((1<<i) & CSWPN_SNIPER) menu_additem(iMenuEquip, WPNName[i], iMenuDataWpn)
			case 5: if(i == CSW_M249) menu_additem(iMenuEquip, WPNName[i], iMenuDataWpn)
			case 6: if((1<<i) & CSWPN_NADE) menu_additem(iMenuEquip, WPNName[i], iMenuDataWpn)
			case 7: if(i == CSW_KNIFE) menu_additem(iMenuEquip, WPNName[i], iMenuDataWpn)
			default: if((1<<i) & CSWPN_PISTOL) menu_additem(iMenuEquip, WPNName[i], iMenuDataWpn)
		}
	}
	
}

public buildEquipItemMenu(iMenuEquip)
{
	new iMenuDataWpn[2], aItemData[CustomItemData]
	if(iTotal_Items)
	{
		for(new i = 0; i<iTotal_Items; i++)
		{
			ArrayGetArray(Custom_Items, i, aItemData)
			iMenuDataWpn[0] = i
			iMenuDataWpn[1] = 1
			if(aItemData[ItemSlot] == ItemSlot_Equip) menu_additem(iMenuEquip, aItemData[ItemName], iMenuDataWpn)	
		}
	}
	
	for(new i=0; i<sizeof(Additional_Item); i++)
	{
		iMenuDataWpn[0] = i+31
		iMenuDataWpn[1] = 0
		menu_additem(iMenuEquip, Additional_Item_Name[i], iMenuDataWpn)
	}
	
}
public AdminEquipHandler(id, menu, item)
{
	if(item < 0) return PLUGIN_CONTINUE
	
	new cmd[6], iName[64]
	new saccess, callback, aItemData[CustomItemData], slot
	
	menu_item_getinfo(menu, item, saccess, cmd, 5, iName, 63, callback)
	
	new name[64]; get_user_name(id, name, 63)
	
	if(cmd[1] == 1)
	{
		if(g_iMenuData[1][id] >= 5)
		{
			g_iMenuData[1][id] = 6
			g_pDataMenu[id] = cmd[0]
			player_menu(id)
		} else {
			ArrayGetArray(Custom_Items, cmd[0], aItemData);
			GiveCustomItem(id, cmd[0], 0, 1)
			slot = aItemData[ItemSlot]
			if(!((1<<slot) & (1<<ItemSlot_Temp|1<<ItemSlot_Equip|1<<ItemSlot_Melee|1<<ItemSlot_Nade)))
				GiveAmmo(id, slot==ItemSlot_Pistol ? 1 : 0);
			if(get_pcvar_num(cvar[0])) colored_print(0, ">x01[>x04CS>x01] Admin has Give Weapon >x04%s>x01 to >x03%s", aItemData[ItemName], name)
		}
		return PLUGIN_HANDLED
	}
	if(cmd[0] >= 1 && cmd[0] <= 30) // weapon
	{
		if(g_iMenuData[1][id] >= 5)
		{
			g_pDataMenu[id] = cmd[0]
			player_menu(id)
		}
		else
		{
			new sWpnName[32]
			get_weaponname(cmd[0], sWpnName, 31)
			Stock_Drop_Slot(id, Stock_Get_Wpn_Slot(cmd[0]), 0)
			GivePlayerItem(id, sWpnName)
			GiveAmmo(id, Stock_Get_Wpn_Slot(cmd[0]) - 1)
			strtoupper(sWpnName)
			if(get_pcvar_num(cvar[0])) colored_print(0, ">x01[>x04CS>x01] Admin has Give Weapon >x04%L>x01 to >x03%s", LANG_SERVER, sWpnName, name)
		}
	}
	if(cmd[0] >= 31 && cmd[0] <= 36)
	{
		if(g_iMenuData[1][id] >= 5)
		{
			g_pDataMenu[id] = cmd[0]
			player_menu(id)
		}
		else {
			GivePlayerItem(id,  Additional_Item[cmd[0]-31])
			if(get_pcvar_num(cvar[0])) colored_print(0, ">x01[>x04CS>x01] Admin has Give Weapon >x04%s>x01 to >x03%s", Additional_Item_Name[cmd[0]-31], name)
		}
	}
	
	new choice = str_to_num(cmd)
	switch(choice)
	{
		case 101: AdminEquipMenu(id, 2)
		case 102: AdminEquipMenu(id, 3)
		case 103: AdminEquipMenu(id, 4)
		case 104: AdminEquipMenu(id, 5)
		case 105: AdminEquipMenu(id, 6)
		case 106: AdminEquipMenu(id, 7)
		case 107: AdminEquipMenu(id, 8)
		case 108: AdminEquipMenu(id, 9)
		case 109: AdminEquipMenu(id, 11)
		case 110: AdminEquipMenu(id, 10)
		case 111:
		{
			if(g_iMenuData[1][id] >= 5)
			{
				g_pDataMenu[id] = choice
				player_menu(id)
			}
			else {
				GiveAmmo(id, 0)
				if(get_pcvar_num(cvar[0])) colored_print(0, ">x01[>x04CS>x01] Admin has Give >x04Primary Ammo>x01 to >x03%s", name)
			}
		}
		case 112:
		{
			if(g_iMenuData[1][id] >= 5)
			{
				g_pDataMenu[id] = choice
				player_menu(id)
			}
			else {
				GiveAmmo(id, 1)
				if(get_pcvar_num(cvar[0])) colored_print(0, ">x01[>x04CS>x01] Admin has Give >x04Secondary Ammo>x01 to >x03%s", name)
			}
		}
		case 301: 
		{
			AdminEquipMenu(id, 1)
			g_iMenuData[1][id] = 0
		}
		case 302: 
		{
			AdminEquipMenu(id, 1)
			g_iMenuData[1][id] = 5
		}
		case 303:
		{
			GiveAmmo(id, 0)
			GiveAmmo(id, 1)
			GiveEquipment(id)
			if(get_pcvar_num(cvar[0])) colored_print(0, ">x01[>x04CS>x01] Admin has Give >x04Equipment>x01 to >x03%s", name)
		}
	}
	return PLUGIN_HANDLED
}

public SetGiveItem(id, dataid)
{
	new name[64]; get_user_name(id, name, 63)
	if(dataid >= 1 && dataid <= 30) // weapon
	{
		new sWpnName[32]
		get_weaponname(dataid, sWpnName, 31)
		
		Stock_Drop_Slot(id, Stock_Get_Wpn_Slot(dataid), 0)
		GivePlayerItem(id, sWpnName)
		GiveAmmo(id, Stock_Get_Wpn_Slot(dataid) == 1 ? 0 : 1)
		
		if(equal(sWpnName, "weapon_c4"))
		{
			cs_set_user_plant(id, 1, 1)
			if(get_user_team(id) == 1) set_pev(id, pev_body, 1)
		}
		
		strtoupper(sWpnName)
		if(get_pcvar_num(cvar[0])) colored_print(0, ">x01[>x04CS>x01] Admin has Give Weapon >x04%L>x01 to >x03%s", LANG_SERVER, sWpnName, name)
	}
	if(dataid >= 31 && dataid <= 37)
	{
		if(dataid-31 == 5) cs_set_user_nvg(id)
		else GivePlayerItem(id,  Additional_Item[dataid-31]) // additional equipment
		if(get_pcvar_num(cvar[0])) colored_print(0, ">x01[>x04CS>x01] Admin has Give >x04%s>x01 to >x03%s", Additional_Item_Name[dataid-31], name)
	}
	if(dataid == 111) 
	{
		GiveAmmo(id, 0)
		if(get_pcvar_num(cvar[0])) colored_print(0, ">x01[>x04CS>x01] Admin has Give >x04Primary Ammo>x01 to >x03%s", name)
	}
	if(dataid == 112) 
	{
		GiveAmmo(id, 1)
		if(get_pcvar_num(cvar[0])) colored_print(0, ">x01[>x04CS>x01] Admin has Give >x04Secondary Ammo>x01 to >x03%s", name)
	}
}

//==================================
// music menu
//==================================
public AdminMusicMenu(id)
{
	new iMenuMusic = menu_create("Music Play", "AdminMusicHandler")
	menu_additem(iMenuMusic, "Select Track", "1")
	
	static TextMenu[32],TextMenu2[32]
	TextMenu2 = g_musicdata[id] ? "Looping" : "Once"
	format(TextMenu, 31, "Playing Type: \y%s", TextMenu2)
	menu_additem(iMenuMusic, TextMenu, "2")
	menu_additem(iMenuMusic, "Stop Music", "3")
	
	set_pdata_int(id, 205, 0)
	menu_display(id, iMenuMusic, 0)
}
public AdminMusicHandler(id, menu, item)
{
	if (item == MENU_EXIT)
	{
		menu_destroy(menu)
		return;
	}
	
	new cmd[2], iName[64]
	new saccess, callback
	
	menu_item_getinfo(menu, item, saccess, cmd, 1, iName, 63, callback)
	
	new choice = str_to_num(cmd)
	switch(choice)
	{
		case 1: AdminMusicTrackMenu(id)
		case 2:
		{	
			g_musicdata[id] = 1-g_musicdata[id]
			AdminMusicMenu(id)
		}
		case 3:
		{
			client_cmd(id, "mp3 stop")
			AdminMusicMenu(id)
		}
	}
}
public AdminMusicTrackMenu(id)
{
	new iMenuMusic = menu_create("Select Music Track", "AdminMusicTrackHandler")
	
	new Titles[128], data[2]
	for(new i = 0; i<ArraySize(g_MusicTitle); i++)
	{
		ArrayGetString(g_MusicTitle, i, Titles, 127)
		data[0] = i
		menu_additem(iMenuMusic, Titles, data)
	}
	set_pdata_int(id, 205, 0)
	menu_display(id, iMenuMusic, 0)
}

public AdminMusicTrackHandler(id, menu, item)
{
	if (item == MENU_EXIT)
	{
		menu_destroy(menu)
		return;
	}
	
	new cmd[2], iName[64]
	new saccess, callback
	
	menu_item_getinfo(menu, item, saccess, cmd, 1, iName, 63, callback)
	
	new Path[512]
	ArrayGetString(g_MusicPath, cmd[0], Path,511)
	if(g_musicdata[id]) client_cmd(id, "mp3 loop %s", Path)
	else client_cmd(id, "mp3 play %s", Path)
	AdminMusicTrackMenu(id)
}

//====================================
// STOCK
//====================================
stock CheckInfoMapParam()
{
	new iEnt 
	iEnt = engfunc(EngFunc_FindEntityByString, -1, "classname", "info_map_parameters")
	if(!pev_valid(iEnt)) return 0;
	new Val[3]
	get_keyvalue(iEnt, "buying", Val, charsmax(Val))
	
	return str_to_num(Val)
}
stock Check_Player(id)
{
	// new player
	if(!g_iLevel[id])
	{
		g_iLevel[id] = 1;
		g_iExperience[id] = 0;
		g_iNextExperience[id] = START_EXP;
		return;
	}
	while(g_iExperience[id] >= g_iNextExperience[id])
	{
		g_iLevel[id] ++
		g_iExperience[id] = 0;
		g_iNextExperience[id] = min(50000, (START_EXP*2) * g_iLevel[id]);
	}
}
stock Check_HasPrevious_Buy(id)
{
	if(g_rebuy[id][0] || g_rebuy[id][1]) return 1
	return 0
}
stock GiveBotRandomItem(id, iSlot = 0)
{
	for(new i = 1; i<iTotal_Items*3; i++)
	{
		new aItemData[CustomItemData], ItemID = random_num(1, iTotal_Items)
		ArrayGetArray(Custom_Items, ItemID, aItemData)
		
		if(!iSlot && !isPrimaryItem(aItemData[ItemSlot]))
			continue;
		if(iSlot == 1 && !isSecondaryItem(aItemData[ItemSlot]))
			continue;
		if(iSlot == 2 && !isMeleeItem(aItemData[ItemSlot]))
			continue;
		if(iSlot == 3 && !isNadeItem(aItemData[ItemSlot]))
			continue;
			
		GiveCustomItem(id, ItemID)
		break
	}
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

stock GetCustomItemid(const szName[])
{
	new aItemData[CustomItemData]
	for(new i = 0; i<iTotal_Items; i++)
	{
		ArrayGetArray(Custom_Items, i, aItemData);
		if(equali(szName, aItemData[ItemSysName]))
			return i;
	}
	return -1;
}
stock GiveCustomItem(id, itemid, check = 1, admin = 0)
{
	if(itemid > iTotal_Items) 
		return;
	
	new aItemData[CustomItemData]
	ArrayGetArray(Custom_Items, itemid, aItemData)
	
	if(!admin)
	{
		if(cs_get_user_money(id) < aItemData[ItemCost] && !get_pcvar_num(cvar[5]) && check)
		{
			client_print(id, print_center, "#Cstrike_TitlesTXT_Not_Enough_Money")
			return;
		}
	
		if(!get_pcvar_num(cvar[5]) && check) 
			cs_set_user_money(id, cs_get_user_money(id) - aItemData[ItemCost])
	}
	
	if(aItemData[ItemSlot] == ItemSlot_Melee) 
		ExecuteForward(g_iForwardRemoveItem, fwResult, id, -1, 2);
		
	callfunc_begin_i(aItemData[ItemFuncID], aItemData[ItemPlugin]);
	callfunc_push_int(id);
	callfunc_end();
}
stock SlotAlready(id, slot=0)
{
	if(!is_user_alive(id)) return 0
	
	static weapons[32], num, i, weaponid
	num = 0
	get_user_weapons(id, weapons, num)
	for (i = 0; i < num; i++)
	{
		weaponid = weapons[i]
		if ((!slot && ((1<<weaponid) & PRIMARY_WEAPONS_BIT_SUM)) || (slot&& ((1<<weaponid) & SECONDARY_WEAPONS_BIT_SUM))) 
			return 1;
	}
	
	return 0;
}
stock GiveAmmo(id, slot=0)
{
	if(!is_user_alive(id)) return
	
	static weapons[32], num, i, weaponid
	num = 0
	get_user_weapons(id, weapons, num)
	
	for (i = 0; i < num; i++)
	{
		weaponid = weapons[i]
		if (!slot && ((1<<weaponid) & PRIMARY_WEAPONS_BIT_SUM)) for(new j = 0; j<Weapon_AmmoSize[weaponid]*2; j++) GivePlayerItem(id, Weapon_AmmoType[weaponid])
		else if (slot&& ((1<<weaponid) & SECONDARY_WEAPONS_BIT_SUM)) for(new j = 0; j<Weapon_AmmoSize[weaponid]*2; j++) GivePlayerItem(id, Weapon_AmmoType[weaponid])
	}
	
}
stock GiveEquipment(id)
{
	GivePlayerItem(id, "item_assaultsuit")
	if(get_user_team(id) == 2) GivePlayerItem(id, "item_thighpack")
	cs_set_user_nvg(id, 1)
	if(!is_user_bot(id))
	{
		GivePlayerItem(id, "weapon_hegrenade")		
		GivePlayerItem(id, "weapon_flashbang")
		GivePlayerItem(id, "weapon_flashbang")
		GivePlayerItem(id, "weapon_smokegrenade")
	}
	else BotGrenade(id)
	set_pev(id, pev_health, 100.0)
}

stock GivePlayerItem(iIndex, const szItem[]) 
{
	if (!equal(szItem, "weapon_", 7) && !equal(szItem, "ammo_", 5) && !equal(szItem, "item_", 5))
		return 0;
		
	new iEnt = engfunc(EngFunc_CreateNamedEntity, engfunc(EngFunc_AllocString, szItem))
	if (!pev_valid(iEnt))
		return 0;

	new Float:vecOrigin[3];
	pev(iIndex, pev_origin, vecOrigin);
	set_pev(iEnt, pev_origin, vecOrigin);
	set_pev(iEnt, pev_spawnflags, pev(iEnt, pev_spawnflags) | SF_NORESPAWN);
	dllfunc(DLLFunc_Spawn, iEnt);

	new iSolid = pev(iEnt, pev_solid);
	dllfunc(DLLFunc_Touch, iEnt, iIndex);
	if (pev(iEnt, pev_solid) != iSolid)
		return iEnt;

	engfunc(EngFunc_RemoveEntity, iEnt);

	return -1;
}
stock isRegistered(wpnid, Slot=0)
{
	new szWpnName[64], iId
	if(Slot)
	{
		for(new i=0; i<ArraySize(SecWPN); i++)
		{
			ArrayGetString(SecWPN, i, szWpnName, charsmax(szWpnName))
			iId = get_weaponid(szWpnName)
			if(wpnid == iId) return 1;
		}
	} else {
		for(new i=0; i<ArraySize(PrimWPN); i++)
		{
			ArrayGetString(PrimWPN, i, szWpnName, charsmax(szWpnName))
			iId = get_weaponid(szWpnName)
			if(wpnid == iId) return 1;
		}
	}
	return 0;
}
stock isPrimaryItem(Item_Slot)
{
	if(Item_Slot != ItemSlot_Temp && Item_Slot != ItemSlot_Melee && Item_Slot != ItemSlot_Pistol && Item_Slot != ItemSlot_Nade && Item_Slot != ItemSlot_Custom)
		return 1;
		
	return 0
}
stock isSecondaryItem(Item_Slot)
{
	if(Item_Slot != ItemSlot_Pistol)
		return 0;
		
	return 1
}
stock isMeleeItem(Item_Slot)
{
	if(Item_Slot != ItemSlot_Melee)
		return 0;
		
	return 1
}
stock isNadeItem(Item_Slot)
{
	if(Item_Slot != ItemSlot_Nade)
		return 0;
		
	return 1
}
stock fm_get_aim_origin(index, Float:origin[3]) {
	new Float:start[3], Float:view_ofs[3];
	pev(index, pev_origin, start);
	pev(index, pev_view_ofs, view_ofs);
	xs_vec_add(start, view_ofs, start);

	new Float:dest[3];
	pev(index, pev_v_angle, dest);
	engfunc(EngFunc_MakeVectors, dest);
	global_get(glb_v_forward, dest);
	xs_vec_mul_scalar(dest, 9999.0, dest);
	xs_vec_add(start, dest, dest);

	engfunc(EngFunc_TraceLine, start, dest, 0, index, 0);
	get_tr2(0, TR_vecEndPos, origin);

	return 1;
}

stock ham_strip_weapon(id,weapon[])
{
	if(!equal(weapon,"weapon_",7)) return 0;
	
	new wId = get_weaponid(weapon);
	if(!wId) return 0;
	
	new wEnt;
	while((wEnt = engfunc(EngFunc_FindEntityByString, wEnt, "classname", weapon)) && pev(wEnt, pev_owner) != id) {}
	if(!wEnt) return 0;
	
	new iTmp;
	if(get_user_weapon(id, iTmp, iTmp) == wId) ExecuteHamB(Ham_Weapon_RetireWeapon, wEnt);
	
	if(!ExecuteHamB(Ham_RemovePlayerItem, id, any:wEnt)) return 0;
	
	ExecuteHamB(Ham_Item_Kill, wEnt);
	set_pev(id, pev_weapons, pev(id, pev_weapons) & ~(1<<wId));
	
	return 1;
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
			if(Strip)ham_strip_weapon(id, wname)
			else engclient_cmd(id, "drop", wname)
		}
	}
}
stock sendItemPickupMsg(id, const item_name[])
{
	message_begin(MSG_ONE, get_user_msgid("ItemPickup"), _, id)
	write_string(item_name)
	message_end()
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
	return 6 
}
stock BotGrenade(id)
{
	switch(random(6))
	{
		case 0: GivePlayerItem(id, "weapon_hegrenade")
		case 3: GivePlayerItem(id, "weapon_flashbang")
		case 5: GivePlayerItem(id, "weapon_smokegrenade")
	}
}

stock colored_print(target, const message[], any:...)
{
	new text[512]
	vformat(text, charsmax(text), message, 3)
	format(text, charsmax(text), "%s", text)
	
	replace_all(text, charsmax(text), ">x04", "^x04")
	replace_all(text, charsmax(text), ">x03", "^x03")
	replace_all(text, charsmax(text), ">x01", "^x01")
	
	if(!target)
	{
		for(new id=0; id<get_maxplayers(); id++)
		{
			if(!pev_valid(id) || !is_user_connected(id)) continue;
			
			message_begin(MSG_ONE, get_user_msgid("SayText"), {0,0,0}, id)
			write_byte(id)
			write_string(text)
			message_end()
		}
	} else {
		message_begin(MSG_ONE, get_user_msgid("SayText"), {0,0,0}, target)
		write_byte(target)
		write_string(text)
		message_end()
	}
}

stock Save_PlayerData(id)
{
	if(is_user_bot(id)) return;
	
	new AuthID[35];
	get_user_authid(id, AuthID, 34)

	new vaultkey[64], vaultdata[256];
	 
	format(vaultkey, 63, "%s-Data", AuthID)
	format(vaultdata, 255, "%i#%i#%i#", g_iExperience[id], g_iLevel[id], g_iNextExperience[id])
	nvault_set(iVault, vaultkey, vaultdata)
}

stock Load_PlayerData(id)
{
	if(is_user_bot(id)) return;
	
	new AuthID[35];
	get_user_authid(id, AuthID, 34)

	new vaultkey[64], vaultdata[256];
	format(vaultkey, 63, "%s-Data",AuthID)
	format(vaultdata, 255, "%i#%i#%i#", g_iExperience[id], g_iLevel[id], g_iNextExperience[id])
	nvault_get(iVault, vaultkey, vaultdata, 255)

	replace_all(vaultdata, 255, "#", " ")

	new playerxp[32], playerlevel[32], playernext[32]

	parse(vaultdata, playerxp, 31, playerlevel, 31, playernext, 31)

	g_iExperience[id] = str_to_num(playerxp)
	g_iLevel[id] = str_to_num(playerlevel)
	g_iNextExperience[id] = str_to_num(playernext)
	
	if(!g_iLevel[id])
	{
		g_iLevel[id] = 1;
		g_iExperience[id] = 0;
		g_iNextExperience[id] = START_EXP;
	}
}

stock Save_BotData(id)
{
	if(!is_user_bot(id)) return;
	
	new AuthID[35];
	get_user_name(id, AuthID, 34)

	new vaultkey[64], vaultdata[256];
	 
	format(vaultkey, 63, "%s-Data", AuthID)
	format(vaultdata, 255, "%i#%i#%i#", g_iExperience[id], g_iLevel[id], g_iNextExperience[id])
	nvault_set(iVaultBots, vaultkey, vaultdata)
}

stock Load_BotData(id)
{
	if(!is_user_bot(id)) return;
	
	new AuthID[35];
	get_user_authid(id, AuthID, 34)

	new vaultkey[64], vaultdata[256];
	format(vaultkey, 63, "%s-Data",AuthID)
	format(vaultdata, 255, "%i#%i#%i#", g_iExperience[id], g_iLevel[id], g_iNextExperience[id])
	nvault_get(iVaultBots, vaultkey, vaultdata, 255)

	replace_all(vaultdata, 255, "#", " ")

	new playerxp[32], playerlevel[32], playernext[32]

	parse(vaultdata, playerxp, 31, playerlevel, 31, playernext, 31)

	g_iExperience[id] = str_to_num(playerxp)
	g_iLevel[id] = str_to_num(playerlevel)
	g_iNextExperience[id] = str_to_num(playernext)
	
	if(!g_iLevel[id])
	{
		g_iLevel[id] = 1;
		g_iExperience[id] = 0;
		g_iNextExperience[id] = START_EXP;
	}
}
/* AMXX-Studio Notes - DO NOT MODIFY BELOW HERE
*{\\ rtf1\\ ansi\\ deff0{\\ fonttbl{\\ f0\\ fnil Tahoma;}}\n\\ viewkind4\\ uc1\\ pard\\ lang1057\\ f0\\ fs16 \n\\ par }
*/
