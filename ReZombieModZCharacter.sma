#include <amxmodx>
#include <amxmisc>
#include <cstrike>
#include <csm>
#include <fakemeta>
#include <hamsandwich>
#include <zombiemodlimited>
#include <reapi>

#define fm_find_ent_by_class(%1,%2) engfunc(EngFunc_FindEntityByString, %1, "classname", %2)

new const SETTING_FILE[] = "zbz_playerclass.ini"

#define MAXRADIO 23
new const RADIO_FOLDER[2][] = {"/", "/woman"}
new const RADIO_MESSEAGE[MAXRADIO][] = {
	"COVERME", "TAKEPOINT", "POSITION", "REGROUP", "FOLLOWME", "HITASSIST", "GO", "FALLBACK", "STICKTOG", "GETINPOS", "STORMFRON",
	"REPORTIN", "AFFIRM", "ROGER", "ENEMYSPOT","BACKUP", "CLEAR", "INPOS", "REPRTINGIN","BLOW", "NEGATIVE", "ENEMYDOWN", "FIREINHOLE"
}
new const RADIO_FILE[MAXRADIO][] = {
	"ct_coverme","takepoint","position","regroup","followme","fireassis","com_go","fallback","sticktog","com_getinpos","stormfront","com_reportin","ct_affirm",
	"roger","ct_enemys","ct_backup","clear","ct_inpos","ct_reportingin","blow","negative","enemydown","ct_fireinhole"
}
// CS Teams
enum
{
	FM_CS_TEAM_UNASSIGNED = 0,
	FM_CS_TEAM_T,
	FM_CS_TEAM_CT,
	FM_CS_TEAM_SPECTATOR
}
// sound female
new const SOUND_F_BHIT[3][] = { "player/f_bhit_flesh-1.wav",
			"player/f_bhit_flesh-2.wav",
			"player/f_bhit_flesh-3.wav"}
new const SOUND_F_DIE[4][] = { "player/f_die1.wav",
			"player/f_die2.wav",
			"player/f_die3.wav",
			"player/f_death6.wav"}
new const SOUND_F_HS[3][] = { "player/f_headshot1.wav",
			"player/f_headshot2.wav",
			"player/f_headshot3.wav"}
			

new const SOUND_CUSTOM_BHIT[3][] = { "hit_flesh-1.wav",
			"hit_flesh-2.wav",
			"hit_flesh-3.wav"}
new const SOUND_FCUSTOM_BHIT[3][] = { "f_hit_flesh-1.wav",
			"f_hit_flesh-2.wav",
			"f_hit_flesh-3.wav"}
			
new const SOUND_CUSTOM_DIE[2][] = { "die1.wav",
			"die2.wav"}
new const SOUND_CUSTOM_HS[2][] = { "headshot1.wav",
			"headshot2.wav"}

new g_dir_model[64] = "models/player/%s/%s.mdl"
new autoselect[] = "autoselect"

new g_set_model_index, g_modelindex_default, g_sound[33], g_custommodel[33][64], g_costume_enable
new cvar_enable, cvar_renderer, cvar_radio_disable

enum
{
	SECTION_NAME = 0,
	SECTION_MODEL,
	SECTION_TEAM,
	SECTION_SEX,
	SECTION_RADIO,
	SECTION_VOX,
	SECTION_SOUND,
	SECTION_USE,
	SECTION_COSTUME
}
const OFFSET_LINUX = 5
const OFFSET_MODELINDEX = 491

const MAX_PLAYER = 128
new c_class_name[MAX_PLAYER][32]
new c_class_model[MAX_PLAYER][32]
new c_class_model_index[MAX_PLAYER]
new c_class_sex[MAX_PLAYER]
new c_class_team[MAX_PLAYER]
new c_class_used[MAX_PLAYER]
new c_class_radio[MAX_PLAYER]
new c_class_sound[MAX_PLAYER]
new c_class_vox[MAX_PLAYER]
new c_class_costume[MAX_PLAYER][4][128]

new c_count_t,c_count_ct, c_total_class

new g_class_ctname[MAX_PLAYER][32]
new g_class_trname[MAX_PLAYER][32]
new g_class_ctmodel[MAX_PLAYER][32]
new g_class_trmodel[MAX_PLAYER][32]

new g_defclass[33], g_targetmenu[33], g_revenge[33], Float:g_flLastSpeech[33], g_attacking[33]
new g_random_class
new Array:FavCT, Array:FavTER
new Array:VoxSection[11]
enum
{
	CLASSVOICE_ROUNDSTART,
	CLASSVOICE_ROUNDWIN,
	CLASSVOICE_ROUNDLOSE,
	CLASSVOICE_HEADSHOT,
	CLASSVOICE_MELEE,
	CLASSVOICE_REVENGE,
	CLASSVOICE_PLANTING,
	CLASSVOICE_GRENADE,
	CLASSVOICE_EVOLUTION,
	CLASSVOICE_SKILLSPRINT,
	CLASSVOICE_SKILLHS
}

new const WEAPON_NAME[][] = { "", "weapon_p228", "", "weapon_scout", "weapon_hegrenade", "weapon_xm1014", "weapon_c4", "weapon_mac10",
			"weapon_aug", "weapon_smokegrenade", "weapon_elite", "weapon_fiveseven", "weapon_ump45", "weapon_sg550",
			"weapon_galil", "weapon_famas", "weapon_usp", "weapon_glock18", "weapon_awp", "weapon_mp5navy", "weapon_m249",
			"weapon_m3", "weapon_m4a1", "weapon_tmp", "weapon_g3sg1", "weapon_flashbang", "weapon_deagle", "weapon_sg552",
			"weapon_ak47", "weapon_knife", "weapon_p90"
}

const CSWPN_NOTREMOVE = (1<<CSW_SMOKEGRENADE)|(1<<CSW_FLASHBANG)|(1<<CSW_C4)

public plugin_init()
{
	register_event("HLTV", "event_round_start", "a", "1=0", "2=0")
	register_forward(FM_EmitSound, "fw_EmitSound")
	register_forward(FM_CmdStart, "fw_CmdStart")
	register_forward(FM_AddToFullPack, "fw_addToFullPack", 1)
	
	cvar_enable = register_cvar("bot_customclass", "1")
	cvar_renderer = register_cvar("mp_renderer_check", "0")
	cvar_radio_disable = register_cvar("mp_disable_radio", "0")
	
	for(new i = 1; i <= CSW_P90; i++)
	{
		if(WEAPON_NAME[i][0])
		{
			if(!(CSWPN_NOTREMOVE & (1<<i))) 
			{
				RegisterHam(Ham_Weapon_PrimaryAttack, WEAPON_NAME[i], "HamF_Weapon_PrimaryAttack")
				RegisterHam(Ham_Weapon_PrimaryAttack, WEAPON_NAME[i], "HamF_Weapon_PrimaryAttack_Post", 1)
				RegisterHam(Ham_Weapon_SecondaryAttack, WEAPON_NAME[i], "HamF_Weapon_PrimaryAttack")
				RegisterHam(Ham_Weapon_SecondaryAttack, WEAPON_NAME[i], "HamF_Weapon_PrimaryAttack_Post", 1)
			}
		}
	}	
	
	register_message(get_user_msgid("SendAudio"), "message_SendAudio")
	register_event("DeathMsg", "event_DeathMsg", "a")
	
	register_clcmd("pl_choose_player", "cmd_choose_player")
	register_clcmd("pl_classmenu", "ClientClassMenu")
	register_concmd("pl_set_class", "PlayerMenu", _, "Player class Menu", 0)
	cs_misc_add_menuitem("Player Classes", "pl_set_class")
}
public plugin_precache()
{
	FavCT = ArrayCreate(64, 1)
	FavTER = ArrayCreate(64, 1)
	for (new i = 0; i < 11; i++)
		VoxSection[i] = ArrayCreate(64, 1)
		
	load_config()
	for (new i = 0; i <= 2; i++)
	{
		engfunc(EngFunc_PrecacheSound, SOUND_F_BHIT[i])
		engfunc(EngFunc_PrecacheSound, SOUND_F_HS[i])
	}
	for (new i = 0; i <= 3; i++)
		engfunc(EngFunc_PrecacheSound, SOUND_F_DIE[i])
	
	g_modelindex_default = engfunc(EngFunc_PrecacheModel, "models/player/urban/urban.mdl")
}

public plugin_natives()
{	
	register_native("pl_set_user_custom_model", "natives_set_user_custom_model", 1)
	register_native("pl_set_user_model", "natives_set_user_model", 1)
	register_native("pl_set_user_model_index", "natives_set_user_model_index", 1)
	register_native("pl_reset_user_model", "natives_reset_user_model", 1)
	register_native("pl_reset_user_model_index", "natives_reset_user_model_index", 1)
	register_native("pl_get_user_sex", "natives_get_user_sex", 1)
	register_native("pl_create_user_sound_bhit", "natives_create_user_sound_bhit", 1)
	register_native("pl_set_user_sound", "natives_set_user_sound", 1)
	register_native("pl_get_user_sound", "natives_get_user_sound", 1)
	register_native("pl_get_user_model", "natives_get_user_model", 1)
	register_native("pl_set_game_random_class", "natives_random", 1)
	register_native("pl_play_voice", "natives_play_voice", 1)
}
new data_name[64], data_model[64], data_team, data_sound, data_sex, data_use, data_radio, data_vox, data_costume[512]
public load_config()
{
	new path[64], maps[32]
	get_mapname(maps, charsmax(maps))
	format(path, charsmax(path), "script/zombie3z/%s.class", maps);
	
	if (!file_exists(path))
		format(path, charsmax(path), "%s", SETTING_FILE)
		
	if (!file_exists(path))
	{
		new error[100]
		formatex(error, charsmax(error), "Cannot load customization file %s!", path)
		set_fail_state(error)
		return;
	}
	
	new linedata[1024], key[64], value[960], key2[64], value2[960]
	
	new file = fopen(path, "rt")
	new idplayer = 1
	while (file && !feof(file))
	{
		fgets(file, linedata, charsmax(linedata))
		replace(linedata, charsmax(linedata), "^n", "")
		if (!linedata[0] || linedata[0] == ';') continue;
		
		strtok(linedata, key2, charsmax(key2), value2, charsmax(value2), '=')
		trim(key2)
		trim(value2)
		
		if (equal(key2, "SET_MODEL_INDEX"))
		{
			g_set_model_index = str_to_num(value2)
			continue;
		}
		else if (equal(key2, "ALLOW_COSTUMES"))
		{
			g_costume_enable = str_to_num(value2)
			continue;
		}
		else if (equal(key2, "CT_FAVORITES"))
		{
			while (value2[0] != 0 && strtok(value2, key2, charsmax(key2), value2, charsmax(value2), ','))
			{
				trim(key2)
				trim(value2)
			
				format(key2, charsmax(key2), "%s", key2)
				ArrayPushString(FavCT, key2)
			}
			continue;
		}
		else if (equal(key2, "TER_FAVORITES"))
		{
			while (value2[0] != 0 && strtok(value2, key2, charsmax(key2), value2, charsmax(value2), ','))
			{
				trim(key2)
				trim(value2)
			
				format(key2, charsmax(key2), "%s", key2)
				ArrayPushString(FavTER, key2)
			}
			continue;
		}
		
		else if (equal(key2, "VOICE_ROUNDSTART"))
		{
			while (value2[0] != 0 && strtok(value2, key2, charsmax(key2), value2, charsmax(value2), ','))
			{
				trim(key2)
				trim(value2)
			
				format(key2, charsmax(key2), "%s", key2)
				ArrayPushString(VoxSection[0], key2)
			}
			continue;
		}
		else if (equal(key2, "VOICE_ROUNDWIN"))
		{
			while (value2[0] != 0 && strtok(value2, key2, charsmax(key2), value2, charsmax(value2), ','))
			{
				trim(key2)
				trim(value2)
			
				format(key2, charsmax(key2), "%s", key2)
				ArrayPushString(VoxSection[1], key2)
			}
			continue;
		}
		else if (equal(key2, "VOICE_ROUNDLOSE"))
		{
			while (value2[0] != 0 && strtok(value2, key2, charsmax(key2), value2, charsmax(value2), ','))
			{
				trim(key2)
				trim(value2)
			
				format(key2, charsmax(key2), "%s", key2)
				ArrayPushString(VoxSection[2], key2)
			}
			continue;
		}
		else if (equal(key2, "VOICE_HEADSHOTKILL"))
		{
			while (value2[0] != 0 && strtok(value2, key2, charsmax(key2), value2, charsmax(value2), ','))
			{
				trim(key2)
				trim(value2)
			
				format(key2, charsmax(key2), "%s", key2)
				ArrayPushString(VoxSection[3], key2)
			}
			continue;
		}
		else if (equal(key2, "VOICE_MELEEKILL"))
		{
			while (value2[0] != 0 && strtok(value2, key2, charsmax(key2), value2, charsmax(value2), ','))
			{
				trim(key2)
				trim(value2)
			
				format(key2, charsmax(key2), "%s", key2)
				ArrayPushString(VoxSection[4], key2)
			}
			continue;
		}
		else if (equal(key2, "VOICE_REVENGEKILL"))
		{
			while (value2[0] != 0 && strtok(value2, key2, charsmax(key2), value2, charsmax(value2), ','))
			{
				trim(key2)
				trim(value2)
			
				format(key2, charsmax(key2), "%s", key2)
				ArrayPushString(VoxSection[5], key2)
			}
			continue;
		}
		else if (equal(key2, "VOICE_PLANTING"))
		{
			while (value2[0] != 0 && strtok(value2, key2, charsmax(key2), value2, charsmax(value2), ','))
			{
				trim(key2)
				trim(value2)
			
				format(key2, charsmax(key2), "%s", key2)
				ArrayPushString(VoxSection[6], key2)
			}
			continue;
		}
		else if (equal(key2, "VOICE_GRENADEKILL"))
		{
			while (value2[0] != 0 && strtok(value2, key2, charsmax(key2), value2, charsmax(value2), ','))
			{
				trim(key2)
				trim(value2)
			
				format(key2, charsmax(key2), "%s", key2)
				ArrayPushString(VoxSection[7], key2)
			}
			continue;
		}
		else if (equal(key2, "VOICE_EVOLUTION"))
		{
			while (value2[0] != 0 && strtok(value2, key2, charsmax(key2), value2, charsmax(value2), ','))
			{
				trim(key2)
				trim(value2)
			
				format(key2, charsmax(key2), "%s", key2)
				ArrayPushString(VoxSection[8], key2)
			}
			continue;
		}
		else if (equal(key2, "VOICE_SKILLSPRINT"))
		{
			while (value2[0] != 0 && strtok(value2, key2, charsmax(key2), value2, charsmax(value2), ','))
			{
				trim(key2)
				trim(value2)
			
				format(key2, charsmax(key2), "%s", key2)
				ArrayPushString(VoxSection[9], key2)
			}
			continue;
		}
		else if (equal(key2, "VOICE_SKILLHS"))
		{
			while (value2[0] != 0 && strtok(value2, key2, charsmax(key2), value2, charsmax(value2), ','))
			{
				trim(key2)
				trim(value2)
			
				format(key2, charsmax(key2), "%s", key2)
				ArrayPushString(VoxSection[10], key2)
			}
			continue;
		}
		// Replace
		replace(linedata, charsmax(linedata), ",", "")
		replace(linedata, charsmax(linedata), "[name]", ",")
		replace(linedata, charsmax(linedata), "[model]", ",")
		replace(linedata, charsmax(linedata), "[team]", ",")
		replace(linedata, charsmax(linedata), "[gender]", ",")
		replace(linedata, charsmax(linedata), "[sound]", ",")
		replace(linedata, charsmax(linedata), "[use]", ",")
		replace(linedata, charsmax(linedata), "[customradio]", ",")
		replace(linedata, charsmax(linedata), "[voice]", ",")
		replace(linedata, charsmax(linedata), "[costume]", ",")
		
		// Get value
		strtok(linedata, key, charsmax(key), value, charsmax(value), ',')
		new i
		while (value[0] != 0 && strtok(value, key, charsmax(key), value, charsmax(value), ','))
		{
			switch (i)
			{
				case SECTION_NAME: format(data_name, charsmax(data_name), "%s", key)
				case SECTION_MODEL: format(data_model, charsmax(data_model), "%s", key)
				case SECTION_TEAM: data_team = str_to_num(key)
				case SECTION_SEX: data_sex = str_to_num(key)
				case SECTION_RADIO: data_radio = str_to_num(key)
				case SECTION_VOX: data_vox = str_to_num(key)
				case SECTION_SOUND: data_sound = str_to_num(key)
				case SECTION_USE: data_use = str_to_num(key)
				case SECTION_COSTUME: format(data_costume, charsmax(data_costume), "%s", key)
			}
			i++
		}
		
		// Set Value
		new modelurl[64]
		format(c_class_name[idplayer], 31, "%s", data_name)
		format(c_class_model[idplayer], 31, "%s", data_model)
		format(modelurl, charsmax(modelurl), g_dir_model, data_model, data_model)
		c_class_team[idplayer] = data_team
		c_class_sex[idplayer] = data_sex
		c_class_used[idplayer] = data_use
		c_class_radio[idplayer] = data_radio
		c_class_vox[idplayer] = data_vox
		c_class_sound[idplayer] = data_sound
		
		if(data_use)
		{
			if(data_sound)
			{
				for(new e = 0; e < 3; e++)
				{
					new url[128]
					format(url, charsmax(url), "player/%s/%s", data_model, data_sex ? SOUND_FCUSTOM_BHIT[e] : SOUND_CUSTOM_BHIT[e]);
					engfunc(EngFunc_PrecacheSound, url);
				}
				for(new e = 0; e < 2; e++)
				{	
					new url[128]
					format(url, charsmax(url), "player/%s/%s", data_model, SOUND_CUSTOM_DIE[e]);
					engfunc(EngFunc_PrecacheSound, url);
					
					format(url, charsmax(url), "player/%s/%s", data_model, SOUND_CUSTOM_HS[e]);
					engfunc(EngFunc_PrecacheSound, url);
				}
			}
			
			
			if(data_costume[0])
			{
				new x, url[128]
				while (data_costume[0] != 0 && strtok(data_costume, key, charsmax(key), data_costume, charsmax(data_costume), '|'))
				{
					if(x > 3) break;
					format(url, charsmax(url), "models/costumes/%s.mdl", key);
					engfunc(EngFunc_PrecacheModel, url);
					format(c_class_costume[idplayer][x], 127, "%s", url);
					x++
				}
				
			}
			if(data_vox)
			{
				new voiceurl[128], audio[64]
				for(new e=0; e<11; e ++)
				{
					if(!ArraySize(VoxSection[e]) || e == CLASSVOICE_PLANTING) continue;
					
					for(new j = 0; j < ArraySize(VoxSection[e]); j ++ )
					{
						ArrayGetString(VoxSection[e], j, audio, charsmax(audio))
						format(voiceurl, charsmax(voiceurl), "vox/%s/%s.wav", data_model, audio)
						engfunc(EngFunc_PrecacheSound, voiceurl);
					}
				}
			}
			
		
			c_class_model_index[idplayer] = engfunc(EngFunc_PrecacheModel, modelurl)
			if(data_team == 2)
			{
				copy(g_class_ctname[c_count_ct],31,data_name)
				copy(g_class_ctmodel[c_count_ct],31,data_model)
				c_count_ct ++
			}
			else if(data_team == 1)
			{
				copy(g_class_trname[c_count_t],31,data_name)
				copy(g_class_trmodel[c_count_t],31,data_model)
				c_count_t ++
			}
		}
		c_total_class = idplayer
		idplayer++
	}
	
	fclose(file)
	
}

public event_round_start()
{
	server_cmd("bot_chatter radio")
	for(new id=0; id<get_maxplayers(); id++)
	{
		if(!isEnabled() || !is_user_connected(id) || !is_user_bot(id)) continue;
		
		if (!g_defclass[id]) set_player_class(id, 0)
	}
}
public fw_CSRoundStart()
{
	for(new id=0; id<get_maxplayers(); id++)
	{
		if(!isEnabled() || !is_user_connected(id) || !is_user_alive(id)) continue;
		
		playvoice(id, CLASSVOICE_ROUNDSTART)
	}
}

public client_putinserver(id)
{
	reset_value(id)
}
public fw_ClientDisconnect(id)
{
	reset_value(id)
}

public cmd_choose_player(id)
{
	if (!is_user_connected(id)) return PLUGIN_HANDLED
	
	new models[64]
	read_argv(1, models, 63)
	
	for(new i=1; i<=c_total_class; i++)
	{
		if (equali(c_class_model[i], models))
		{
				set_player_class(id, i)
				return PLUGIN_HANDLED
		}
	}

	// auto select class
	if (equali(models, autoselect))
	{
		new idplayer = get_random_class(get_user_team(id))
		if (idplayer) set_player_class(id, idplayer)
	}

	
	return PLUGIN_HANDLED
}
public HamF_Weapon_PrimaryAttack(iEnt)
{
	if(!pev_valid(iEnt)) return
	static id
	id = get_pdata_cbase(iEnt,41,4)
	if(!pev_valid(id)) return
	
	g_attacking[id] = 1
}

public HamF_Weapon_PrimaryAttack_Post(iEnt)
{
	if(!pev_valid(iEnt)) return
	static id
	id = get_pdata_cbase(iEnt,41,4)
	if(!pev_valid(id)) return
	
	g_attacking[id] = 0
}
public event_DeathMsg()
{
	static id, weapon[32], victim, headshot
	id = read_data(1)
	victim = read_data(2)
	headshot = read_data(3)
	
	if (!is_user_connected(id) || !is_user_connected(victim) || id==victim) return;
	
	read_data(4, weapon, charsmax(weapon))
	if(headshot && g_attacking[id]) playvoice(id, CLASSVOICE_HEADSHOT);
	if (equal(weapon, "knife") && g_attacking[id]) playvoice(id, CLASSVOICE_MELEE);
	if (equal(weapon, "grenade")) playvoice(id, CLASSVOICE_GRENADE);
	if (victim == g_revenge[id]) 
	{
		playvoice(id, CLASSVOICE_REVENGE);
		g_revenge[id] = 0
	}
	
	g_revenge[victim] = id
}
public fw_CSPlayer_Spawn(id)
{
	if(g_custommodel[id][0]) return;
	
	if (!g_defclass[id]) set_player_class(id, 0)
}
public fw_CmdStart(id, uc_handle, seed)
{
	if(!is_user_alive(id))
		return FMRES_IGNORED	
	if(get_user_weapon(id) != CSW_C4 || get_user_team(id) != 1)
		return FMRES_IGNORED
		
	if(!(cs_get_user_mapzones(id) & CS_MAPZONE_BOMBTARGET))
		return FMRES_IGNORED
		
	new CurButton;CurButton = get_uc(uc_handle, UC_Buttons)
		
	if(CurButton & IN_ATTACK && !(pev(id, pev_oldbuttons) & IN_ATTACK))
	{
		playvoice(id, CLASSVOICE_PLANTING);
	}
	
	return  FMRES_IGNORED
}
// Replace Radio
public message_SendAudio(msg_id, msg_dest, msg_entity)
{
	// get value
	new audio[128], audio_f[8], id, sex, classid, model[32]
	
	id = get_msg_arg_int(1)	
	classid = get_class_id(id)
	
	get_msg_arg_string(2, audio, charsmax(audio))
	if(equal(audio[9], "generic_reload"))
		return PLUGIN_HANDLED
	
	for(new i=0; i<get_maxplayers(); i++)
	{
		if(!isEnabled() || !is_user_connected(i) || !is_user_alive(i)) continue;
		if(equal(audio[7], "terwin"))
		{
			if(get_user_team(i) == 1) playvoice(i, CLASSVOICE_ROUNDWIN)
			if(get_user_team(i) == 2) playvoice(i, CLASSVOICE_ROUNDLOSE)
		}
		if(equal(audio[7], "ctwin"))
		{
			if(get_user_team(i) == 2) playvoice(i, CLASSVOICE_ROUNDWIN)
			if(get_user_team(i) == 1) playvoice(i, CLASSVOICE_ROUNDLOSE)
		}
	}
	if(g_sound[id]==1 || get_pcvar_num(cvar_radio_disable)) return PLUGIN_HANDLED
	sex = (classid ? c_class_sex[classid] : 0)
	if(c_class_radio[classid] && g_sound[id]!=2) sex = (sex == 1) ? 3:2
	if(is_user_connected(id)) cs_get_user_model(id, model, 31);
	else format(model, 31, "urban");
	
	format(audio_f, charsmax(audio_f), "%s", audio)
	
	// replace sound radio 1 - 3
	new check, radio_new[64]
	for (new i=0; i<23; i++)
	{
		if( equal(audio[7], RADIO_MESSEAGE[i]))
		{
			format(radio_new, charsmax(radio_new), "%s", get_urlsound_radio(RADIO_FILE[i], sex, model))
			check = 1
		}
	}
	
	// replace sound radio other
	if (equal(audio_f, "%!MRAD_") && !check)
	{
		// radio one
		replace(audio, charsmax(audio), "%!MRAD_", "")
		strtolower(audio)
		format(radio_new, charsmax(radio_new), "%s", get_urlsound_radio(audio, sex, model))
		
		// radio all
		if (!id)
		{
			send_radio_all(audio)
			return PLUGIN_HANDLED
		}
	}
	
	// replace radio
	if (file_exists(get_fullurl_radio(radio_new))) set_msg_arg_string(2, radio_new)
	
	return PLUGIN_CONTINUE
}
public fw_addToFullPack(es, e, ent, host, hostflags, player, pSet)
{
	if(!get_pcvar_num(cvar_renderer) || !pev_valid(host))
		return FMRES_IGNORED;
		
	new id = pev(host, pev_iuser2)
	if(!pev_valid(id) || !(pev_valid(id) && pev(host, pev_iuser1) == 4)) id = host
	
	if(isCostume(ent))
	{
		new iOwner = pev(ent, pev_aiment)
		if((id == iOwner && !cs_zb_get_user_thirdperson(iOwner)) || (pev(iOwner, pev_deadflag) & DEAD_DEAD || pev(iOwner, pev_deadflag) & DEAD_DISCARDBODY))
		{
			set_es(es, ES_Effects, get_es(es, ES_Effects) |  EF_NODRAW)
		}
		
	}
	return FMRES_IGNORED;
}
public fw_CSHUD(id)
{
	if(!is_user_alive(id)) return
	
	set_costume_render(id)
}
public fw_EmitSound(id, channel, const sample[], Float:volume, Float:attn, flags, pitch)
{
	if (!is_user_connected(id) || g_sound[id]==1)
		return FMRES_IGNORED;

	new sex, classid
	classid = get_class_id(id)
	sex = (classid ? c_class_sex[classid] : 0)
	new sound[128]
	
	if(c_class_sound[classid] && g_sound[id] != 2)
	{
		for (new i = 0; i <= 2; i++)
		{
			format(sound, charsmax(sound), "%s", SOUND_F_BHIT[i])
			replace(sound, charsmax(sound), "player/f_", "player/")
			if (equal(sample, sound))
			{
				format(sound, charsmax(sound), "player/%s/%s", c_class_model[classid], sex ? SOUND_FCUSTOM_BHIT[i] : SOUND_CUSTOM_BHIT[i]);
				emit_sound(id, channel, sound, volume, attn, flags, pitch)
				return FMRES_SUPERCEDE;
			}
		}
		if (equal(sample, "player/die1.wav") || equal(sample, "player/die2.wav") || equal(sample, "player/die3.wav") || equal(sample, "player/death6.wav"))
		{
			format(sound, charsmax(sound), "player/%s/%s", c_class_model[classid], SOUND_CUSTOM_DIE[random_num(0, 1)]);
			emit_sound(id, channel, sound, volume, attn, flags, pitch)
			return FMRES_SUPERCEDE;
		}
		if (equal(sample, "player/headshot1.wav") || equal(sample, "player/headshot2.wav") || equal(sample, "player/headshot3.wav"))
		{
			format(sound, charsmax(sound), "player/%s/%s", c_class_model[classid], SOUND_CUSTOM_HS[random_num(0, 1)]);
			emit_sound(id, channel, sound, volume, attn, flags, pitch)
			return FMRES_SUPERCEDE;
		}
	}
	if (sex == 0) return FMRES_IGNORED;
	
	for (new i = 0; i <= 2; i++)
	{
		// Hit
		format(sound, charsmax(sound), "%s", SOUND_F_BHIT[i])
		replace(sound, charsmax(sound), "player/f_", "player/")
		if (equal(sample, sound))
		{
			emit_sound(id, channel, SOUND_F_BHIT[i], volume, attn, flags, pitch)
			return FMRES_SUPERCEDE;
		}
		// Die
		format(sound, charsmax(sound), "%s", SOUND_F_DIE[i])
		replace(sound, charsmax(sound), "player/f_", "player/")
		if (equal(sample, sound))
		{
			emit_sound(id, channel, SOUND_F_DIE[i], volume, attn, flags, pitch)
			return FMRES_SUPERCEDE;
		}
		// Headshot
		format(sound, charsmax(sound), "%s", SOUND_F_HS[i])
		replace(sound, charsmax(sound), "player/f_", "player/")
		if (equal(sample, sound))
		{
			emit_sound(id, channel, SOUND_F_HS[i], volume, attn, flags, pitch)
			return FMRES_SUPERCEDE;
		}
	}
	if (equal(sample, "player/death6.wav"))
	{
		emit_sound(id, channel, SOUND_F_DIE[3], volume, attn, flags, pitch)
		return FMRES_SUPERCEDE;
	}
	return FMRES_IGNORED;
}
public ClientSetRandomClass(id)
{
	if(!is_user_connected(id)) 
		return 0;
		
	if(!g_defclass[id]) set_player_class(id, 0)
	return 1;
}
public ClientClassMenu(id)
{
	if(!is_user_connected(id) || cs_zb_is_zombie(id)) 
		return
	
	new iData[2], szTxt[64]
	new iMenu = menu_create("Class Selection", "ClientClassMenuHandler")
	
	for(new i = 1; i <= c_total_class; i ++ )
	{
		if(!c_class_used[i] || (c_class_team[i] != get_user_team(id) && !g_random_class)) continue;
		
		format(szTxt, 63, "Name: \r%s \wClassid: \y%d", c_class_name[i], i);
		
		iData[0] = i
		menu_additem(iMenu, szTxt, iData);
	}
	set_pdata_int(id, 205, 0)
	menu_display(id, iMenu, 0)
}

public ClientClassMenuHandler(id, menuid, item)
{
	if (item == MENU_EXIT || cs_zb_is_zombie(id))
	{
		menu_destroy(menuid)
		return;
	}
	
	new data[2], dummy, classid
	menu_item_getinfo(menuid, item, dummy, data, charsmax(data), _, _, dummy)
	classid = data[0]
	
	set_player_class(id, classid)
	menu_destroy(menuid)
}
public PlayerMenu(id)
{
	new iData[2], szTxt[64], szMdl[32], szName[32], iMenu = menu_create("Set Player Class", "PlayerMenuHandler")
	
	for(new i = 0; i < get_maxplayers(); i ++ )
	{
		if(!pev_valid(i) || !is_user_connected(i) || get_user_team(i) == 3) continue;
		
		get_user_name(i, szName, 31);
		cs_get_user_model(i, szMdl, 31);
		format(szTxt, 63, "%s \r%s", szName, szMdl);
		
		iData[0] = i
		menu_additem(iMenu, szTxt, iData);
	}
	set_pdata_int(id, 205, 0)
	menu_display(id, iMenu, 0)
}

public PlayerMenuHandler(id, menuid, item)
{
	if (item == MENU_EXIT)
	{
		menu_destroy(menuid)
		return;
	}
	
	new data[2], dummy, player
	menu_item_getinfo(menuid, item, dummy, data, charsmax(data), _, _, dummy)
	player = data[0]
	
	g_targetmenu[id] = player
	ClassMenu(id)
	menu_destroy(menuid)
}

public ClassMenu(id)
{
	if(!is_user_connected(g_targetmenu[id])) return;
	
	new iData[2], szTxt[64], szName[32]
	get_user_name(g_targetmenu[id], szName, 31);
	
	format(szTxt, 63, "Set Class for %s", szName);
	new iMenu = menu_create(szTxt, "ClassMenuHandler")
	
	for(new i = 1; i <= c_total_class; i ++ )
	{
		if(!c_class_used[i] || (c_class_team[i] != get_user_team(g_targetmenu[id]) && !g_random_class)) continue;
		
		format(szTxt, 63, "Model: \r%s \wClassid: \y%d", c_class_model[i], i);
		
		iData[0] = i
		menu_additem(iMenu, szTxt, iData);
	}
	set_pdata_int(id, 205, 0)
	menu_display(id, iMenu, 0)
}
public ClassMenuHandler(id, menuid, item)
{
	if (item == MENU_EXIT)
	{
		menu_destroy(menuid)
		return;
	}
	
	new data[2], dummy, classid
	menu_item_getinfo(menuid, item, dummy, data, charsmax(data), _, _, dummy)
	classid = data[0]
	
	set_player_class(g_targetmenu[id], classid)
	PlayerMenu(id)
	menu_destroy(menuid)
}
//=====================================
stock set_player_class(id, classid)
{
	new team = get_user_team(id)
	if (!classid)
	{
		if(is_user_bot(id)) classid = get_random_class(team)
		else {
			new szModel[32]
			if(team == 1 && ArraySize(FavTER)) ArrayGetString(FavTER, random(ArraySize(FavTER)), szModel, 31)
			else if(team == 2 && ArraySize(FavCT)) ArrayGetString(FavCT, random(ArraySize(FavCT)), szModel, 31)
			else format(szModel, 31, "%s", c_class_model[get_random_class(team)])
			classid = get_class_index(szModel)
		}
	}
	
	else if (team!=c_class_team[classid] && !g_random_class)
	{
		fm_cs_set_user_team(id, c_class_team[classid])
		if (is_user_alive(id)) user_kill(id)
	}

	set_player_model(id,classid)
}
stock set_player_model(id, classid)
{
	g_defclass[id] = classid
	set_user_model(id, c_class_model[classid])
	set_costumes(id)
}
stock set_user_model(id, model[])
{
	if (!is_user_connected(id) || !model[0]) return;
	
	rg_set_user_model(id, model, g_set_model_index ? true : false)
}
stock set_user_model_index(id, model_index)
{
	fm_cs_set_user_model_index(id, model_index)
}
stock reset_user_model(id)
{
	if (!is_user_connected(id)) return;
	
	if (!g_defclass[id]) g_defclass[id] = get_random_class(get_user_team(id))
	set_player_model(id, g_defclass[id])
}
stock get_random_class(team)
{
	new n_player_idplayer[MAX_PLAYER], total, idrandom
	for (new i=1; i<=c_total_class; i++)
	{
		if(!c_class_used[i]) continue; 
		
		if (c_class_team[i] == team || g_random_class)
		{
			n_player_idplayer[total+1] = i
			total++
		}
	}
	if (total) idrandom = n_player_idplayer[random_num(1, total)]
	
	return idrandom
}
stock reset_value(id)
{
	g_sound[id] = 0
}
stock PlayEmitSound(id, type, const sound[])
{
	emit_sound(id, type, sound, 1.0, ATTN_NORM, 0, PITCH_NORM)
}

stock get_urlsound_radio(filename[], sex, model[])
{
	new audio[128], path[128]
	if(sex >= 2 && model[0])
	{
		copy(audio, 127, filename);
		replace(audio, 127, "ct_", "");
		replace(audio, 127, "com_", "");
		replace(audio, 127, "getinpos", "position");
		if(equal(audio, "fireinhole")) format(audio, charsmax(audio), "fireinhole%d", random_num(1,3))
		else if(equal(audio, "bombpl")) format(audio, charsmax(audio), "bombplanting")
		else if(equal(audio, "bombdef")) format(audio, charsmax(audio), "bombdefusing")
		else if(equal(audio, "clear")&&random(1)==1) format(audio, charsmax(audio), "allclear")
		else if(equal(audio, "blow")) format(audio, charsmax(audio), "getout%d", random_num(1,2))
		else if(equal(audio, "backup")) format(audio, charsmax(audio), "fireassis%d", random_num(1,2))
		else if(equal(audio, "sticktog")) format(audio, charsmax(audio), "staytogether%d", random_num(1,2))
		else if(equal(audio, "inpos")) format(audio, charsmax(audio), "arrived%d", random_num(1,2))
		else if(equal(audio, "affirm")) format(audio, charsmax(audio), "roger%d", random_num(1,2))
		else if(equal(audio, "reportingin")) format(audio, charsmax(audio), "roger%d", random_num(1,2))
		else if(equal(audio, "locknload") || equal(audio, "letsgo") || equal(audio, "moveout")) format(audio, charsmax(audio), "go%d", random_num(1,2))
		else format(audio, charsmax(audio), "%s%d", audio, random_num(1,2))
		
		format(audio, charsmax(audio), "radio/%s/%s.wav", model, audio)
		format(path, charsmax(audio), "sound/%s", audio)
		if(file_exists(path)) return audio
	}
	
	if(sex > 1)
	{
		if(sex == 2) sex = 0
		if(sex == 3) sex = 1
	}
	format(audio, charsmax(audio), "radio%s/%s.wav", RADIO_FOLDER[sex], filename)
	
	return audio
}
stock send_radio_all(audio[])
{
	for (new id = 1; id < 33; id++)
	{
		if (!is_user_connected(id)) continue;
		
		new model[32], sex = c_class_sex[get_class_id(id)]
		cs_get_user_model(id, model, 31);
		if(c_class_radio[get_class_id(id)]) sex = (sex == 1) ? 3:2
		
		message_begin(MSG_ONE, get_user_msgid("SendAudio"), _, id)
		write_byte(0)
		write_string(get_urlsound_radio(audio, sex, model))
		write_short(100)
		message_end()
	}
}
stock get_fullurl_radio(file[])
{
	new audio[64]
	format(audio, charsmax(audio), "sound/%s", file)
	
	return audio
}

stock fm_cs_set_user_team(id, team)
{
	cs_set_user_team(id, team, 0)
}
stock fm_cs_set_user_model_index(id, value)
{
	if (!value) return;
	set_pdata_int(id, OFFSET_MODELINDEX, value, OFFSET_LINUX)
}
stock isEnabled()
	return get_pcvar_num(cvar_enable)

stock get_class_id(index)
{
	if(!pev_valid(index) || !is_user_connected(index)) return 0
	
	if(g_defclass[index]) 
		return g_defclass[index]
	
	new szModel[32]
	cs_get_user_model(index, szModel, 31)
	
	for(new i = 1; i <= c_total_class; i ++ )
	{
		if(equal(szModel, c_class_model[i]))
			return i;
	}
	return 0;
}

stock get_class_index(szModel[])
{
	for(new i = 1; i <= c_total_class; i ++ )
	{
		if(equal(szModel, c_class_model[i]))
			return i;
	}
	return 0;
}
stock playvoice(id, section)
{
	if(g_sound[id] || !is_user_alive(id) || g_flLastSpeech[id] > get_gametime() || section == CLASSVOICE_PLANTING) return;
	
	new voiceurl[128], audio[32]
	if(c_class_vox[get_class_id(id)] )
	{
		ArrayGetString(VoxSection[section], random(ArraySize(VoxSection[section])), audio, charsmax(audio))
			
		format(voiceurl, charsmax(voiceurl), "sound/vox/%s/%s.wav", c_class_model[get_class_id(id)], audio)
		if(file_exists(voiceurl))
		{
			format(voiceurl, charsmax(voiceurl), "vox/%s/%s.wav", c_class_model[get_class_id(id)], audio)
			engfunc(EngFunc_EmitSound, id, CHAN_VOICE, voiceurl, 1.0, 0.9, 0, 100);
			g_flLastSpeech[id] = get_gametime() + 1.0;
		}
	}
}
stock set_costumes(id)
{
	if(!is_user_connected(id)) return;	
	
	unset_costumes(id)
	if(!g_costume_enable) return;
	
	for(new i = 0; i<4; i ++)
	{
		if(c_class_costume[get_class_id(id)][i][0])
		{
			make_costumes(id, c_class_costume[get_class_id(id)][i]);
		}
	}
	set_costume_render(id)
}
stock make_costumes(id, model[])
{
	new iEnt = engfunc(EngFunc_CreateNamedEntity, engfunc(EngFunc_AllocString, "info_target"))	

	set_pev(iEnt, pev_movetype, MOVETYPE_FOLLOW)
	
	set_pev(iEnt, pev_aiment, id)
	set_pev(iEnt, pev_classname, "info_player_costume")
	set_pev(iEnt, pev_rendermode, kRenderNormal)
	engfunc(EngFunc_SetModel, iEnt, model)
	set_pev(iEnt, pev_body, 0)
	set_pev(iEnt, pev_sequence, 0)
	set_pev(iEnt, pev_animtime, get_gametime())
	set_pev(iEnt, pev_framerate, 1.0)
}

stock set_costume_render(id)
{
	new Float:flAmt, RenderMode, RenderFX
	pev(id, pev_renderamt, flAmt);
	RenderMode = pev(id, pev_rendermode);
	RenderFX = pev(id, pev_renderfx);
	
	new iEnt = -1
	while ((iEnt = fm_find_ent_by_class(iEnt,"info_player_costume")) != 0)
	{
		if(!pev_valid(iEnt) || pev(iEnt, pev_aiment) != id) continue;
		
		set_pev(iEnt, pev_renderamt, flAmt);
		set_pev(iEnt, pev_rendermode, RenderMode);
		set_pev(iEnt, pev_renderfx, RenderFX);
	}
}
stock unset_costumes(id)
{
	new iEnt = -1
	while ((iEnt = fm_find_ent_by_class(iEnt,"info_player_costume")) != 0)
	{
		if(!pev_valid(iEnt) || pev(iEnt, pev_aiment) != id) continue;
		
		engfunc(EngFunc_RemoveEntity, iEnt);
	}
}
stock isCostume(Entity)
{
	if( !pev_valid(Entity) ) return 0;
	
	static szClassName[32]; pev( Entity , pev_classname , szClassName , 31 );
	return ( equal( szClassName , "info_player_costume" ) )
}
// ######################## NATIVE ########################
public natives_play_voice(id, type)
{
	playvoice(id, type)
}
public natives_random(on)
{
	g_random_class = on
}
public natives_get_user_sex(id)
{
	new classid = get_class_id(id)
	if(classid) return c_class_sex[classid]
	
	return 0;
}
public natives_set_user_model(id, model[])
{
	param_convert(2)
	set_user_model(id, model)
	return 1;
}

public natives_set_user_custom_model(id, active, model[], indexed)
{
	param_convert(3)
	
	if(active)
	{
		unset_costumes(id)
		format(g_custommodel[id], 63, "%s", model)
		rg_set_user_model(id, model, indexed ? true : false)
	} else {
		g_custommodel[id] = ""
	}
	return 1;
}
public natives_get_user_model(id, model[], len)
{
	param_convert(2)
	
	new classid = get_class_id(id)
	
	if(cs_get_user_vip(id))
		format(model, len, c_class_sex[classid] == 1 ? "vip2" : "vip");
	else cs_get_user_model(id, model, len)
	return 1;
}
public natives_reset_user_model(id)
{
	reset_user_model(id)
	return 1;
}
public natives_set_user_model_index(id, modelindex)
{
	set_user_model_index(id, modelindex)
	return 1;
}
public natives_reset_user_model_index(id)
{
	set_user_model_index(id, g_modelindex_default)
	return 1;
}
public natives_create_user_sound_bhit(id)
{
	new sound[64]
	if (c_class_sex[get_class_id(id)] == 1) format(sound, charsmax(sound), "player/f_bhit_flesh-%i.wav", random_num(1, 3))
	else format(sound, charsmax(sound), "player/bhit_flesh-%i.wav", random_num(1, 3))
	PlayEmitSound(id, CHAN_VOICE, sound)
}
public natives_set_user_sound(index, disabled)
{
	if(!is_user_connected(index)) return
	
	g_sound[index] = disabled
}

public natives_get_user_sound(index)
{
	if(!is_user_connected(index)) return 0
	
	return g_sound[index]
}
/* AMXX-Studio Notes - DO NOT MODIFY BELOW HERE
*{\\ rtf1\\ ansi\\ deff0{\\ fonttbl{\\ f0\\ fnil Tahoma;}}\n\\ viewkind4\\ uc1\\ pard\\ lang1057\\ f0\\ fs16 \n\\ par }
*/
