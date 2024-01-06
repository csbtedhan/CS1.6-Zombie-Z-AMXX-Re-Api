#include <amxmodx>
#include <engine>
#include <fakemeta_util>
#include <hamsandwich>
#include <cstrike>
#include <zombiemodlimited>
#include <reapi>
#include <csm>

#define PLUGIN "AMXX Wondercannon"
#define VERSION "1.0"
#define AUTHOR "Asdian, csbtedhan"

// Data Config
#define P_WONDERCANNON "models/zbz/wpn/p_wondercannon_txt.mdl"
#define V_WONDERCANNON "models/zbz/wpn/v_wondercannon_axi.mdl"
#define W_WONDERCANNON "models/zbz/wpn/w_primgroup1.mdl"
#define S_WONDERCANNON "models/zbz/wpn/bomb_wondercannon.mdl"
#define S2_WONDERCANNON "models/zbz/wpn/ef_wondercannon_area.mdl"

#define WONDERCANNON_MF "sprites/muzzleflash111.spr"
#define WONDERCANNON_MF2_L "sprites/muzzleflash113.spr"
#define WONDERCANNON_MF2_R "sprites/muzzleflash109.spr"

#define MODEL_W_OLD "models/w_p90.mdl"
#define SOUND_FIRE "weapons/wondercannon-1.wav"
#define SOUND_FIRE2 "weapons/wondercannon_comd_shoot.wav"
#define SOUND_EXP "weapons/wondercannon_bomd_exp.wav"
#define SOUND_EXP2 "weapons/wondercannon_bomd_exp2.wav"
#define SOUND_RDY "weapons/wondercannon_cmod_charging.wav"
#define SOUND_BOMBDROP "weapons/wondercannon_comd_drop.wav"

#define WCB_PRIMCLASS "wc_bomb"
#define WCB_SECCLASS "wcbomb_efx"

#define CSW_WONDERCANNON CSW_P90
#define weapon_wondercannon "weapon_p90"

#define WEAPON_CODE 01172020
#define WEAPON_EVENT "events/p90.sc"

enum _:NewAnim
{
	WONDERCANNON_IDLE_M = 0,
	WONDERCANNON_RELOAD,
	WONDERCANNON_DRAW,
	WONDERCANNON_SHOOT1,
	WONDERCANNON_SHOOT2,
	WONDERCANNON_SHOOT3,
	WONDERCANNON_BMOD_ON,
	WONDERCANNON_CMOD_START,
	WONDERCANNON_CMOD_IDLE,
	WONDERCANNON_CMOD_SHOOT
}

// Weapon Config
#define DAMAGE 70
#define ACCURACY 75 // 0 - 100 ; -1 Default
#define CLIP 30
#define SPEED 0.66
#define RECOIL 1.5
#define RELOAD_TIME 2.03

#define BOMB_MAX 3
#define BOMB_RAD 350.0
#define BOMB_MAXDAMAGE 7600.0

// MACROS
#define Get_BitVar(%1,%2) (%1 & (1 << (%2 & 31)))
#define Set_BitVar(%1,%2) %1 |= (1 << (%2 & 31))
#define UnSet_BitVar(%1,%2) %1 &= ~(1 << (%2 & 31))

new g_Had_Base, g_Clip[33], g_OldWeapon[33], Float:g_Recoil[33][3], Float:g_fast[33], g_FukSubVic, g_Vic[33], Float:g_fAnimTimer[33][BOMB_MAX][2]
new g_Bomb_Num[33], g_iEnt[33][BOMB_MAX], g_BombAct[33][BOMB_MAX], g_iEntSeq[33]
new Float:g_cache_frame_mf, Float:g_cache_frame_mf2[2], g_cache_exp[4], g_SpraySpr, g_DropSpr, g_cache_beam
new g_Event_Base, g_SmokePuff_SprId, cvar_hand

// Safety
new g_IsConnected, g_IsAlive, g_PlayerWeapon[33]

new const func_traceattack[][] = { "worldspawn", "func_breakable", "func_wall", "func_door", "func_door_rotating", "func_plat", "func_rotating"}

public plugin_init()
{
	register_plugin(PLUGIN, VERSION, AUTHOR)
	
	// Safety
	Register_SafetyFunc()
	
	// Event
	register_event("HLTV", "fw_CSNew_Round", "a", "1=0", "2=0")
	register_event("CurWeapon", "Event_CurWeapon", "be", "1=1")
	register_message(get_user_msgid("DeathMsg"), "message_DeathMsg")
	
	
	// Forward
	register_forward(FM_UpdateClientData, "fw_UpdateClientData_Post", 1)
	register_forward(FM_PlaybackEvent, "fw_PlaybackEvent")
	register_forward(FM_SetModel, "fw_SetModel")
	register_forward(FM_AddToFullPack, "Fw_AddToFullPack_Post", 1);
	
	// Ham
	RegisterHam(Ham_Item_Deploy, weapon_wondercannon, "fw_Item_Deploy_Post", 1)	
	RegisterHam(Ham_Item_AddToPlayer, weapon_wondercannon, "fw_Item_AddToPlayer_Post", 1)
	RegisterHam(Ham_Weapon_WeaponIdle, weapon_wondercannon, "fw_Weapon_WeaponIdle_Post", 1)
	RegisterHam(Ham_Item_PostFrame, weapon_wondercannon, "fw_Item_PostFrame")	
	RegisterHam(Ham_Weapon_Reload, weapon_wondercannon, "fw_Weapon_Reload")
	RegisterHam(Ham_Weapon_Reload, weapon_wondercannon, "fw_Weapon_Reload_Post", 1)	
	RegisterHam(Ham_Weapon_PrimaryAttack, weapon_wondercannon, "fw_Weapon_PrimaryAttack")
	RegisterHam(Ham_Weapon_PrimaryAttack, weapon_wondercannon, "fw_Weapon_PrimaryAttack_Post", 1)
	
	for(new i = 0; i < sizeof(func_traceattack); i++)
		RegisterHam(Ham_TraceAttack, func_traceattack[i], "fw_TraceAttack_World")
	
	RegisterHam(Ham_TraceAttack, "player", "fw_TraceAttack_Player")	
	RegisterHam(Ham_Think, "env_sprite", "fw_MF_Think")
	RegisterHam(Ham_Think, "info_target", "fw_Think")
	RegisterHam(Ham_Touch, "info_target", "fw_GrenadeTouch")
	RegisterHam(Ham_TakeDamage, "player", "fw_TakeDamage")
	
	// Cache
	register_clcmd("weapon_wondercannon", "hook_weapon")
	cs_register_custom_item("Heaven Splitter", 6250, 9, "Get_Base", "wondercannon")
	cvar_hand = get_cvar_pointer("cl_righthand")
}
public hook_weapon(id) engclient_cmd(id, weapon_wondercannon)

public buy_ammo(id)
{
	if(!is_alive(id))
		return
	if(get_user_weapon(id) != CSW_WONDERCANNON && !Get_BitVar(g_Had_Base, id))
		return
	if(g_Bomb_Num[id])
		return
	
	update_specialammo(id, g_Bomb_Num[id], 0)
	g_Bomb_Num[id] = BOMB_MAX
	
	update_specialammo(id, g_Bomb_Num[id], 1)
}

public plugin_precache()
{
	precache_model(P_WONDERCANNON)
	precache_model(V_WONDERCANNON)
	precache_model(W_WONDERCANNON)
	precache_model(S_WONDERCANNON)
	precache_model(S2_WONDERCANNON)
	
	precache_sound(SOUND_FIRE)
	precache_sound(SOUND_FIRE2)
	precache_sound(SOUND_EXP)
	precache_sound(SOUND_EXP2)
	precache_sound(SOUND_RDY)
	precache_sound(SOUND_BOMBDROP)
	
	g_SmokePuff_SprId = engfunc(EngFunc_PrecacheModel, "sprites/wall_puff1.spr")
	register_forward(FM_PrecacheEvent, "fw_PrecacheEvent_Post", 1)
	
	g_cache_beam = precache_model("sprites/ef_wondercannon_chain.spr")
	precache_model("sprites/ef_wondercannon_bomb_set.spr")
	
	for(new i = 0; i < 4; i++)
	{
		new spr[4][64]
		format(spr[i], 63, "sprites/ef_wondercannon_hit%d.spr", i + 1)
		
		g_cache_exp[i] = precache_model(spr[i])
	}
	
	g_SpraySpr = precache_model("sprites/bloodspray.spr")
	g_DropSpr = precache_model("sprites/blood.spr")
}

public message_DeathMsg(msg_id, msg_dest, msg_ent)
{
	new szWeapon[64]
	get_msg_arg_string(4, szWeapon, charsmax(szWeapon))
	
	if (strcmp(szWeapon, "p90"))
		return PLUGIN_CONTINUE
	
	new id = get_msg_arg_int(1)
	new iEntity = get_pdata_cbase(id, 373)
	
	if (!pev_valid(iEntity) || get_pdata_int(iEntity, 43, 4) != CSW_WONDERCANNON || !Get_BitVar(g_Had_Base, id))
		return PLUGIN_CONTINUE

	set_msg_arg_string(4, "wondercannon")
	return PLUGIN_CONTINUE
}

public fw_CSNew_Round()
{
	new pEntity = -1
	while((pEntity = engfunc(EngFunc_FindEntityByString, pEntity, "classname", WCB_PRIMCLASS)) != 0)
	{
		if(!pev_valid(pEntity)) continue;
		engfunc(EngFunc_RemoveEntity, pEntity)
	}
}

public fw_PrecacheEvent_Post(type, const name[])
{
	if(equal(WEAPON_EVENT, name)) g_Event_Base = get_orig_retval()		
}

public Fw_AddToFullPack_Post(esState, iE, iEnt, iHost, iHostFlags, iPlayer, pSet)
{
	if (!pev_valid(iEnt))
		return;
	if (pev(iEnt, pev_flags) & FL_KILLME) 
		return;

	new classname[32], iOwner;
	pev(iEnt, pev_classname, classname, 31);
	iOwner = pev(iEnt, pev_owner)
	
	if (equal(classname,WCB_SECCLASS))
	{
		if (iHost != iOwner) set_es(esState, ES_Effects, (get_es(esState, ES_Effects) | EF_NODRAW));
	}
}

public client_disconnected(id) Safety_Disconnected(id)

public fw_Remove_Item(i, item, slot)
{
	if(slot == 0) Remove_Base(i, 1)
}
public Get_Base(id)
{	
	Stock_Drop_Slot(id, 1)
	
	Remove_Base(id, 0)
	
	Set_BitVar(g_Had_Base, id)
	fm_give_item(id, weapon_wondercannon)
	
	
	update_specialammo(id, g_Bomb_Num[id], 0)
	g_Bomb_Num[id] = BOMB_MAX
	//Set_ExtraAmmo(id, g_Bomb_Num[id])
	update_specialammo(id, g_Bomb_Num[id], 1)
	
	RemoveUserBomb(id)
	
	// Clip & Ammo
	static Ent; Ent = fm_get_user_weapon_entity(id, CSW_WONDERCANNON)
	if(pev_valid(Ent)) cs_set_weapon_ammo(Ent, CLIP)
	
	engfunc(EngFunc_MessageBegin, MSG_ONE_UNRELIABLE, get_user_msgid("CurWeapon"), {0, 0, 0}, id)
	write_byte(1)
	write_byte(CSW_WONDERCANNON)
	write_byte(CLIP)
	message_end()
}

public Remove_Base(id, all)
{
	if(all)
	{
		UnSet_BitVar(g_Had_Base, id)
		//mdcsohud_resetwpnhud(id, CSW_WONDERCANNON)
	}
	
	UnSet_BitVar(g_FukSubVic, id)
	g_Vic[id] = 0
	
	for(new i = 0; i < BOMB_MAX; i++)
		g_BombAct[id][i] = 0
	
	RemoveUserBomb(id)
}

public Event_CurWeapon(id)
{
	static CSWID; CSWID = read_data(2)
	
	if((CSWID == CSW_WONDERCANNON && g_OldWeapon[id] != CSW_WONDERCANNON) && Get_BitVar(g_Had_Base, id))
	{
		 Draw_NewWeapon(id, CSWID)
	} else if((CSWID == CSW_WONDERCANNON && g_OldWeapon[id] == CSW_WONDERCANNON) && Get_BitVar(g_Had_Base, id)) {
		static Ent; Ent = fm_get_user_weapon_entity(id, CSW_WONDERCANNON)
		if(!pev_valid(Ent))
		{
			g_OldWeapon[id] = get_user_weapon(id)
			return
		}
		
		set_pdata_float(Ent, 46, SPEED, 4)
		set_pdata_float(Ent, 47, SPEED, 4)
	} else if(CSWID != CSW_WONDERCANNON && g_OldWeapon[id] == CSW_WONDERCANNON) {
		Draw_NewWeapon(id, CSWID)
	}
	
	g_OldWeapon[id] = get_user_weapon(id)
}

public Draw_NewWeapon(id, CSW_ID)
{
	if(CSW_ID == CSW_WONDERCANNON)
	{
		static ent
		ent = fm_get_user_weapon_entity(id, CSW_WONDERCANNON)
		
		if(pev_valid(ent) && Get_BitVar(g_Had_Base, id))
			set_pev(ent, pev_effects, pev(ent, pev_effects) &~ EF_NODRAW)
	} else {
		static ent
		ent = fm_get_user_weapon_entity(id, CSW_WONDERCANNON)
		
		if(pev_valid(ent)) set_pev(ent, pev_effects, pev(ent, pev_effects) | EF_NODRAW) 			
	}
	
}
public fw_UpdateClientData_Post(id, sendweapons, cd_handle)
{
	if(!is_alive(id))
		return FMRES_IGNORED	
	if(get_user_weapon(id) == CSW_WONDERCANNON && Get_BitVar(g_Had_Base, id))
		set_cd(cd_handle, CD_flNextAttack, get_gametime() + 0.001) 
	
	return FMRES_HANDLED
}

public fw_PlaybackEvent(flags, invoker, eventid, Float:delay, Float:origin[3], Float:angles[3], Float:fparam1, Float:fparam2, iParam1, iParam2, bParam1, bParam2)
{
	if (!is_connected(invoker))
		return FMRES_IGNORED	
	if(get_player_weapon(invoker) != CSW_WONDERCANNON || !Get_BitVar(g_Had_Base, invoker))
		return FMRES_IGNORED
	if(eventid != g_Event_Base)
		return FMRES_IGNORED
	
	engfunc(EngFunc_PlaybackEvent, flags | FEV_HOSTONLY, invoker, eventid, delay, origin, angles, fparam1, fparam2, iParam1, iParam2, bParam1, bParam2)
	emit_sound(invoker, CHAN_WEAPON, SOUND_FIRE, VOL_NORM, ATTN_NORM, 0, PITCH_NORM)
	
	new Ent = get_pdata_cbase(invoker, 373)
	if(!pev_valid(Ent)) return FMRES_IGNORED
	
	Set_WeaponAnim(invoker, random_num(WONDERCANNON_SHOOT1, WONDERCANNON_SHOOT3))
	//MakeMuzzleFlash(invoker, Ent, 1, WONDERCANNON_MF, 0)
	//MakeMuzzleFlash(invoker, Ent, 2, get_pcvar_num(cvar_hand) ? WONDERCANNON_MF2_R : WONDERCANNON_MF2_L, 1)
	return FMRES_SUPERCEDE
}

public fw_SetModel(entity, model[])
{
	if(!pev_valid(entity))
		return FMRES_IGNORED
	
	static Classname[32]
	pev(entity, pev_classname, Classname, sizeof(Classname))
	
	if(!equal(Classname, "weaponbox"))
		return FMRES_IGNORED
	
	static iOwner
	iOwner = pev(entity, pev_owner)
	
	if(equal(model, MODEL_W_OLD))
	{
		static weapon; weapon = find_ent_by_owner(-1, weapon_wondercannon, entity)
		
		if(!pev_valid(weapon))
			return FMRES_IGNORED;
		
		if(Get_BitVar(g_Had_Base, iOwner))
		{
			//mdcsohud_resetwpnhud(iOwner, CSW_WONDERCANNON)
			
			set_pev(weapon, pev_impulse, WEAPON_CODE)
			engfunc(EngFunc_SetModel, entity, W_WONDERCANNON)
			set_pev(entity, pev_body, 10)

			Remove_Base(iOwner, 1)
			
			return FMRES_SUPERCEDE
		}
	}

	return FMRES_IGNORED;
}

public fw_Item_Deploy_Post(Ent)
{
	if(pev_valid(Ent) != 2)
		return
	static Id; Id = get_pdata_cbase(Ent, 41, 4)
	
	if(get_pdata_cbase(Id, 373) != Ent)
		return
	if(!Get_BitVar(g_Had_Base, Id))
		return
	
	set_pev(Id, pev_viewmodel2, V_WONDERCANNON)
	set_pev(Id, pev_weaponmodel2, P_WONDERCANNON)
	Set_WeaponAnim(Id, WONDERCANNON_DRAW)
	
	//Set_WpnList(Id)
	//Set_ExtraAmmo(Id, Get_ExtraAmmo(Id))
	update_specialammo(Id, g_Bomb_Num[Id], 1)
	
	set_pdata_string(Id, (492) * 4, "m249", -1 , 20)
	
	static iClip; iClip = get_pdata_int(Ent, 51, 4)
	
	set_pev(Ent, pev_iuser2, 0)
	set_pev(Ent, pev_iuser1, 0)
	
	engfunc(EngFunc_MessageBegin, MSG_ONE_UNRELIABLE, get_user_msgid("CurWeapon"), {0, 0, 0}, Id)
	write_byte(1)
	write_byte(CSW_WONDERCANNON)
	write_byte(iClip)
	message_end()
}

public fw_Item_AddToPlayer_Post(Ent, id)
{
	if(!pev_valid(Ent))
		return HAM_IGNORED
		
	if(pev(Ent, pev_impulse) == WEAPON_CODE)
	{
		Set_BitVar(g_Had_Base, id)
	
		//mdcsohud_regwpnhud(id, CSW_WONDERCANNON, "weapon_wondercannon")
	
		set_pev(Ent, pev_impulse, 0)
	}
	
	return HAM_IGNORED	
}

public fw_Item_PostFrame(ent)
{
	static id; id = pev(ent, pev_owner)
	if(!is_user_alive(id))
		return HAM_IGNORED
	if(!Get_BitVar(g_Had_Base, id))
		return HAM_IGNORED	
	
	static Float:flNextAttack; flNextAttack = get_pdata_float(id, 83, 5)
	static bpammo; bpammo = cs_get_user_bpammo(id, CSW_WONDERCANNON)
	
	static iClip; iClip = get_pdata_int(ent, 51, 4)
	static fInReload; fInReload = get_pdata_int(ent, 54, 4)
	
	if(fInReload && flNextAttack <= 0.0)
	{
		static temp1
		temp1 = min(CLIP - iClip, bpammo)

		set_pdata_int(ent, 51, iClip + temp1, 4)
		cs_set_user_bpammo(id, CSW_WONDERCANNON, bpammo - temp1)		
		
		set_pdata_int(ent, 54, 0, 4)
		fInReload = 0
	}		
	
	WE_Desperado(id, ent, iClip,bpammo,pev(id, pev_button))
	return HAM_IGNORED
}

public client_PostThink(id)
{
	if(!is_user_alive(id) || get_player_weapon(id) != CSW_WONDERCANNON || !Get_BitVar(g_Had_Base, id))
		update_specialammo(id, g_Bomb_Num[id], 0)
	else
		update_specialammo(id, g_Bomb_Num[id], 1)
}

public WE_Desperado(id,iEnt,iClip, bpammo,iButton)
{
	new Float:flNextPrimaryAttack, Float:fCurTime, iState, Float:fSound, iState2, Float:flNextPrimaryAttack2
	global_get(glb_time, fCurTime)
	pev(iEnt, pev_fuser1, fSound)
	pev(iEnt, pev_fuser2, flNextPrimaryAttack)
	pev(iEnt, pev_fuser3, flNextPrimaryAttack2)
	iState = pev(iEnt, pev_iuser1)
	iState2 = pev(iEnt, pev_iuser2)
	
	if(!(iButton & IN_ATTACK2) && iState && g_Bomb_Num[id])
	{
		if(iState == 3 || (iState == 2 && g_fast[id] < get_gametime()))
		{
			Set_WeaponAnim(id, 9)
			client_cmd(id, "spk %s", SOUND_FIRE2)
			set_pdata_float(iEnt, 46, 1.03, 4)
				
			static Ent; Ent = Stock_CreateEntityBase(id, "info_target", MOVETYPE_TOSS, S_WONDERCANNON, WCB_PRIMCLASS, SOLID_BBOX, 0.01)
			if(!pev_valid(Ent)) return
			
			static Float:Origin[3], Float:Angles[3]
			get_weapon_attachment(id, Origin, 20.0)
			pev(id, pev_angles, Angles)
			
			set_pev(Ent, pev_gravity, 2.5)
			set_pev(Ent, pev_origin, Origin)
			set_pev(Ent, pev_angles, Angles)
			set_pev(Ent, pev_owner, id)
			set_pev(Ent, pev_iuser1, 0)
			set_pev(Ent, pev_iuser2, 0)
			set_pev(Ent, pev_iuser3, 0)
			
			// Create Velocity
			static Float:Velocity[3], Float:TargetOrigin[3]
			fm_get_aim_origin(id, TargetOrigin)
			get_speed_vector(Origin, TargetOrigin, 1800.0, Velocity)
			
			set_pev(Ent, pev_velocity, Velocity)
			
			new iSeq = pev(Ent, pev_iuser4)
			iSeq++
			set_pev(Ent, pev_iuser4, iSeq)
			
			update_specialammo(id, g_Bomb_Num[id], 0)
			g_Bomb_Num[id]--
			//Set_ExtraAmmo(id, g_Bomb_Num[id])
			update_specialammo(id, g_Bomb_Num[id], 1)
	
			g_iEntSeq[id] = iSeq
			g_iEnt[id][iSeq] = Ent
			g_fast[id] = 0.0
		}
		
		if(IsBombActive(id) && iState == 1)
		{
			Set_WeaponAnim(id, 6)
			
			set_pdata_float(iEnt, 46, 1.53, 4)
			set_pdata_float(iEnt, 48, 1.53, 4)
			
			set_pev(iEnt, pev_fuser3, fCurTime + 0.85)
			set_pev(iEnt, pev_iuser2, 1)
		}
		
		set_pev(iEnt, pev_fuser2, 0.0)
		set_pev(iEnt, pev_iuser1, 0)
	}
	
	if(iButton & IN_ATTACK2)
	{
		if(flNextPrimaryAttack > fCurTime)
			return
		
		if(!g_Bomb_Num[id] && IsBombActive(id) && !iState2)
		{
			set_pdata_float(iEnt, 46, 1.53, 4)
			set_pdata_float(iEnt, 48, 1.53, 4)
			
			Set_WeaponAnim(id, 6)
			set_pev(iEnt, pev_fuser2, fCurTime + 0.85)
			set_pev(iEnt, pev_iuser2, 2)
			
			emit_sound(id, CHAN_WEAPON, SOUND_RDY, VOL_NORM, ATTN_NORM, 0, PITCH_NORM)
			return
		} 
		
		if(g_Bomb_Num[id])
		{
			switch(iState)
			{
				case 0:
				{
					set_pdata_float(iEnt, 46, 0.3, 4)
					
					set_pev(iEnt, pev_fuser2, fCurTime + 0.3)
					set_pev(iEnt, pev_iuser1, 1)
					
					emit_sound(id, CHAN_WEAPON, SOUND_RDY, VOL_NORM, ATTN_NORM, 0, PITCH_NORM)
				}
				case 1:
				{
					set_pdata_float(iEnt, 46, 2.03, 4)
					set_pdata_float(iEnt, 48, 2.03, 4)
					
					Set_WeaponAnim(id, 7)
					set_pev(iEnt, pev_fuser2, fCurTime + 2.0)
					set_pev(iEnt, pev_iuser1, 2)
					
					g_fast[id] = get_gametime() + 0.08
				}
				case 2,3:
				{
					Set_WeaponAnim(id, 8)
					set_pdata_float(iEnt, 48, 3.07, 4)
					
					set_pev(iEnt, pev_fuser2, fCurTime + 3.07)
					set_pev(iEnt, pev_iuser1, 3)
				}
			}
		}
	}
	
	if((iState2 == 2 && flNextPrimaryAttack < fCurTime) || (iState2 == 1 && flNextPrimaryAttack2 < fCurTime))
	{
		set_pev(iEnt, pev_iuser2, 0)
		
		new Float:vOrigin[3], pEntity = -1
		while((pEntity = engfunc(EngFunc_FindEntityByString, pEntity, "classname", WCB_PRIMCLASS)) != 0)
		{
			if(!pev_valid(pEntity) || pev(pEntity, pev_owner) != id)
				continue;
			
			pev(pEntity, pev_origin, vOrigin)
			bomb_explo(pEntity, id, vOrigin, BOMB_RAD, BOMB_MAXDAMAGE)
		}
	}
}

public fw_Weapon_Reload(ent)
{
	static id; id = pev(ent, pev_owner)
	if(!is_user_alive(id))
		return HAM_IGNORED
	if(!Get_BitVar(g_Had_Base, id))
		return HAM_IGNORED	

	g_Clip[id] = -1
		
	static BPAmmo; BPAmmo = cs_get_user_bpammo(id, CSW_WONDERCANNON)
	static iClip; iClip = get_pdata_int(ent, 51, 4)
		
	if(BPAmmo <= 0 || iClip >= CLIP)
		return HAM_SUPERCEDE
			
	g_Clip[id] = iClip
	return HAM_IGNORED
}

public fw_Weapon_Reload_Post(ent)
{
	static id; id = pev(ent, pev_owner)
	if(!is_user_alive(id))
		return HAM_IGNORED
	if(!Get_BitVar(g_Had_Base, id))
		return HAM_IGNORED	
	if(g_Clip[id] == -1)
		return HAM_IGNORED
		
	set_pdata_int(ent, 51, g_Clip[id], 4)
	set_pdata_int(ent, 54, 1, 4)
	
	Set_WeaponAnim(id, WONDERCANNON_RELOAD)
	Set_PlayerNextAttack(id, RELOAD_TIME)
	return HAM_IGNORED
}

public fw_Weapon_WeaponIdle_Post( iEnt )
{
	if(pev_valid(iEnt) != 2)
		return
	static Id; Id = get_pdata_cbase(iEnt, 41, 4)
	if(get_pdata_cbase(Id, 373) != iEnt)
		return
	if(!Get_BitVar(g_Had_Base, Id))
		return
	
}

public fw_TraceAttack_World(Victim, Attacker, Float:Damage, Float:Direction[3], Ptr, DamageBits)
{
	if(!is_connected(Attacker))
		return HAM_IGNORED	
	if(get_player_weapon(Attacker) != CSW_WONDERCANNON || !Get_BitVar(g_Had_Base, Attacker))
		return HAM_IGNORED
		
	static Float:flEnd[3], Float:vecPlane[3]
		
	get_tr2(Ptr, TR_vecEndPos, flEnd)
	get_tr2(Ptr, TR_vecPlaneNormal, vecPlane)		
			
	Make_BulletHole(Attacker, flEnd, Damage)
	Make_BulletSmoke(Attacker, Ptr)

	SetHamParamFloat(3, float(DAMAGE))
	return HAM_HANDLED
}

public fw_TraceAttack_Player(Victim, Attacker, Float:Damage, Float:Direction[3], Ptr, DamageBits)
{
	if(!is_connected(Attacker))
		return HAM_IGNORED	
	if(get_player_weapon(Attacker) != CSW_WONDERCANNON || !Get_BitVar(g_Had_Base, Attacker))
		return HAM_IGNORED

	SetHamParamFloat(3, float(DAMAGE))
	return HAM_HANDLED
}

public fw_TakeDamage(iVictim, iInflictor, iAttacker, Float:fDamage, iDamageType)
{	
	if(iVictim != iAttacker && is_user_connected(iAttacker))
	{
		if(Get_BitVar(g_Had_Base, iAttacker) && get_user_weapon(iAttacker) == CSW_WONDERCANNON && iDamageType & DMG_BULLET)
			if(cs_zb_is_zombie(iVictim)) MakeExpAttachVic(iAttacker, iVictim)
	}
}

public fw_Weapon_PrimaryAttack(Ent)
{
	static id; id = pev(Ent, pev_owner)
	if(!is_alive(id))
		return HAM_IGNORED
	if(!Get_BitVar(g_Had_Base, id))
		return HAM_IGNORED

	pev(id, pev_punchangle, g_Recoil[id])
	return HAM_IGNORED
}

public fw_Weapon_PrimaryAttack_Post(Ent)
{
	static id; id = pev(Ent, pev_owner)
	if(!is_alive(id))
		return
	if(!Get_BitVar(g_Had_Base, id))
		return

	static Float:Push[3]
	pev(id, pev_punchangle, Push)
	xs_vec_sub(Push, g_Recoil[id], Push)
	
	xs_vec_mul_scalar(Push, RECOIL, Push)
	xs_vec_add(Push, g_Recoil[id], Push)
	
	set_pev(id, pev_punchangle, Push)
	
	set_pdata_float(Ent, 46, 0.9, 4);
	
	// Acc
	static Accena; Accena = ACCURACY
	if(Accena != -1)
	{
		static Float:Accuracy
		Accuracy = (float(100 - ACCURACY) * 1.5) / 100.0

		set_pdata_float(Ent, 62, Accuracy, 4);
	}
	set_pdata_int(Ent, 64, 0, 4)
}

public MakeExpAttachVic(id, vic)
{
	new Float:vEntOrigin[3]
	pev(vic, pev_origin, vEntOrigin)
	
	new iEnt = engfunc(EngFunc_CreateNamedEntity, engfunc(EngFunc_AllocString, "info_target"))
	set_pev(iEnt, pev_classname, "exp_null")
	set_pev(iEnt, pev_origin, vEntOrigin)
	engfunc(EngFunc_SetModel, iEnt, "models/w_usp.mdl")
	set_pev(iEnt, pev_nextthink, get_gametime() + 0.31)
	set_pev(iEnt, pev_iuser1, id)
	set_pev(iEnt, pev_iuser2, 0)
	set_pev(iEnt, pev_iuser3, vic)
	fm_set_rendering(iEnt, kRenderFxGlowShell, 0, 0, 0, kRenderTransAlpha, 0)
	
	engfunc(EngFunc_MessageBegin, MSG_PVS, SVC_TEMPENTITY, vEntOrigin, 0);
	write_byte(TE_EXPLOSION)
	engfunc(EngFunc_WriteCoord, vEntOrigin[0])
	engfunc(EngFunc_WriteCoord, vEntOrigin[1])
	engfunc(EngFunc_WriteCoord, vEntOrigin[2])
	write_short( g_cache_exp[3])
	write_byte(5)
	write_byte(25)
	write_byte(TE_EXPLFLAG_NOSOUND | TE_EXPLFLAG_NODLIGHTS | TE_EXPLFLAG_NOPARTICLES)
	message_end()
}

public fw_Think(ent)
{
	if(!pev_valid(ent))
		return
	
	static Classname[32]
	pev(ent, pev_classname, Classname, sizeof(Classname))
	
	if(equal(Classname, "exp_null"))
	{
		new id, seq, ivic
		id = pev(ent, pev_iuser1)
		seq = pev(ent, pev_iuser2)
		ivic = pev(ent, pev_iuser3)
		
		if(seq < 11)
		{
			new Float:vEntOrigin[3]
			pev(ivic, pev_origin, vEntOrigin)
			
			set_pev(ent, pev_origin, vEntOrigin)
			
			new Float:fDmg, Float:fFDmg = 25.0
			fDmg = (fFDmg *= float(seq))
			
			if(is_user_alive(ivic)) 
			{
				if(SubVicAliveCount(1) >= 2) seq += SubVicAliveCount(1)
				else seq++
				set_pev(ent, pev_iuser2, seq)
				
				if(SubVicAliveCount(0) < 2)
				{
					explo(seq, vEntOrigin)
					SpawnBlood(vEntOrigin, get_pdata_int(ivic, 89), floatround(fDmg))
				}
				
				HoldUp(ivic)
				ExecuteHamB(Ham_TakeDamage, ivic, id, id, fDmg, DMG_CLUB)
				
				if(seq < 11) engfunc(EngFunc_EmitAmbientSound, 0, vEntOrigin, SOUND_EXP, 1.0, 0.4, 0, 100)
				if(seq >= 11) engfunc(EngFunc_EmitAmbientSound, 0, vEntOrigin, SOUND_EXP2, 1.0, 0.4, 0, 100)
			}
		
			new pEntity = -1
			while((pEntity = engfunc(EngFunc_FindEntityInSphere, pEntity, vEntOrigin, 200.0)) != 0)
			{
				if(pev(pEntity, pev_takedamage) == DAMAGE_NO) continue
				if(is_user_connected(pEntity) && pEntity != id)
					if(!can_damage(pEntity, id) || !cs_zb_is_zombie(pEntity)) continue
				if(!pev_valid(pEntity) || pEntity == id) continue
				
				
				new Float:VicOrig[3]
				pev(pEntity, pev_origin, VicOrig)
				
				if(!isClearLine(vEntOrigin, VicOrig))
					continue;
					
				// subvic more than 1
				if(SubVicAliveCount(0) > 1)
				{
					explo(seq, VicOrig)
					SpawnBlood(VicOrig, get_pdata_int(ivic, 89), floatround(fDmg))
				}
					
				// make sure sub-vic is not main vic
				if(pEntity != ivic && SubVicAliveCount(0) >= 2) 
				{
					// main and sub vic alive
					if(is_user_alive(ivic) && is_user_alive(pEntity))
						beam(vEntOrigin, VicOrig)
					
					// main vic dead and sub vic alive
					if(!is_user_alive(ivic) && is_user_alive(pEntity))
					{
						// find another sub-vic in range
						if(pEntity == g_Vic[id])
							continue
						
						new Float:subVicOrig[3]
						pev(g_Vic[id], pev_origin, subVicOrig)
						
						beam(VicOrig, subVicOrig)
					}
				}
				
				// main vic dead but subvic alive
				if(!is_user_alive(ivic) && SubVicAliveCount(0))
				{
					// set new main vic from random subvic
					if(is_user_alive(pEntity)) set_pev(ent, pev_iuser3, pEntity)
				}
				
				// save new subvic
				if(is_user_alive(pEntity)) 
				{
					HoldUp(pEntity)
					Set_BitVar(g_FukSubVic, pEntity)
					g_Vic[id] = pEntity
				}
				
				ExecuteHamB(Ham_TakeDamage, pEntity, id, id, fDmg, DMG_CLUB)
			}
	
			set_pev(ent, pev_nextthink, get_gametime() + 0.31)
		} 
		
		if(seq >= 11 || !is_user_alive(id) || (!is_user_alive(ivic) && !SubVicAliveCount(0)) || get_user_weapon(id) != CSW_WONDERCANNON || !Get_BitVar(g_Had_Base, id))
		{
			remove_entity(ent)
			
			for(new i = 0; i < get_maxplayers(); i++)
				if(Get_BitVar(g_FukSubVic, i)) UnSet_BitVar(g_FukSubVic, i)
		}
	}
	
	if(equal(Classname, WCB_PRIMCLASS) && pev(ent, pev_iuser1))
	{
		new id, iStat, iAnim, iSeq
		id = pev(ent, pev_owner)
		iAnim = pev(ent, pev_iuser2)
		iStat = pev(ent, pev_iuser3)
		iSeq = pev(ent, pev_iuser4)
		
		if(pev(ent, pev_flags) & FL_ONGROUND)
		{
			if(!iAnim && g_fAnimTimer[id][iSeq][0] < get_gametime())
			{
				engfunc(EngFunc_EmitSound, ent, CHAN_WEAPON, SOUND_BOMBDROP, 1.0, 0.8, 0, 100);
				set_pev(ent, pev_iuser2, 1)
				
				if(pev(ent, pev_sequence) != 0)
				{
					set_pev(ent, pev_animtime, get_gametime())
					set_pev(ent, pev_framerate, 1.0)
					set_pev(ent, pev_sequence, 0)
				}
				
				g_fAnimTimer[id][iSeq][1] = get_gametime() + 0.1
			}
			
			// Animation
			if((iAnim == 1 || iAnim == 2) && g_fAnimTimer[id][iSeq][1] < get_gametime())
			{
				set_pev(ent, pev_iuser2, 2)
				set_pev(ent, pev_iuser3, 1)
				
				if(pev(ent, pev_sequence) != 1)
				{
					set_pev(ent, pev_animtime, get_gametime())
					set_pev(ent, pev_framerate, 1.0)
					set_pev(ent, pev_sequence, 1)
				}
			}
			g_BombAct[id][iSeq] = 1
		}
	
		if(iStat == 1 || iStat == 2)
		{
			new Float:vEntOrigin[3]
			pev(ent, pev_origin, vEntOrigin)
			
			if(iStat == 1)
			{
				new iEfx = Stock_CreateEntityBase(id, "info_target", MOVETYPE_NONE, S2_WONDERCANNON, WCB_SECCLASS, SOLID_NOT, 0.0)
				set_pev(iEfx, pev_iuser1, 1)
				set_pev(iEfx, pev_iuser2, ent)
				set_pev(iEfx, pev_owner, id)
				set_pev(iEfx, pev_origin, vEntOrigin)
				set_pev(iEfx, pev_rendermode, kRenderTransAdd)
				set_pev(iEfx, pev_renderamt, 255.0)
				set_pev(iEfx, pev_light_level, 180)
				set_pev(iEfx, pev_animtime, get_gametime())
				set_pev(iEfx, pev_sequence, 0)
				set_pev(iEfx, pev_framerate, 1.0)
				set_pev(iEfx, pev_nextthink, get_gametime())
				engfunc(EngFunc_SetSize, iEfx, Float:{-0.1, -0.1, -0.1}, Float:{0.1, 0.1, 0.1})
				
				static Float:Origin[3], Float:Angles[3]
				engfunc(EngFunc_GetAttachment, ent, 0, Origin, Angles)
				
				new iEfx2 = Stock_CreateEntityBase(id, "env_sprite", MOVETYPE_NONE, "sprites/ef_wondercannon_bomb_set.spr", "bomb_light", SOLID_NOT, 0.01)
				set_pev(iEfx2, pev_origin, Origin)
				set_pev(iEfx2, pev_iuser1, 1)
				set_pev(iEfx2, pev_iuser2, ent)
				set_pev(iEfx2, pev_rendermode, kRenderTransAdd)
				set_pev(iEfx2, pev_renderamt, 255.0)
				set_pev(iEfx2, pev_scale, 0.1)
				set_pev(iEfx2, pev_frame, 0.0)
				set_pev(iEfx2, pev_framerate, 1.0)
				set_pev(iEfx2, pev_mins, Float:{-1.0, -1.0, -1.0})
				set_pev(iEfx2, pev_maxs, Float:{1.0, 1.0, 1.0})
			}
			
			set_pev(ent, pev_iuser3, 2)
			
			if(FindBombEnemy(id, vEntOrigin, 200.0) > 0 || entity_range(id, ent) <= 70.0)
			{
				if(ent == g_iEnt[id][iSeq] && iSeq == g_iEntSeq[id]) 
					g_BombAct[id][iSeq] = 0
					
				bomb_explo(ent, id, vEntOrigin, BOMB_RAD, BOMB_MAXDAMAGE)
				return;
			}
		}
		
		set_pev(ent, pev_nextthink, get_gametime() + 0.01)
	}
	
	if(equal(Classname, WCB_SECCLASS) && pev(ent, pev_iuser1))
	{
		new iEnt
		iEnt = pev(ent, pev_iuser2)
		
		if(!pev_valid(iEnt))
		{
			set_pev(ent, pev_iuser1, 0)
			set_pev(ent, pev_flags, pev(ent, pev_flags) | FL_KILLME);
			return
		}
		
		if(pev_valid(ent)) set_pev(ent, pev_nextthink, get_gametime() + 0.01)
	}
}

public fw_GrenadeTouch(Ent, Id)
{
	if(!pev_valid(Ent))
		return
	
	static Classname[32], id
	pev(Ent, pev_classname, Classname, sizeof(Classname))
	id = pev(Ent, pev_owner)
	
	if(!is_user_connected(id)) 
		return
	
	if(equal(Classname, WCB_PRIMCLASS))
	{
		set_pev(Ent, pev_solid, SOLID_NOT)
		
		set_pev(Ent, pev_iuser1, 1)
		set_pev(Ent, pev_iuser2, 0)
		set_pev(Ent, pev_iuser3, 0)
		
		new iSeq = pev(Ent, pev_iuser4)
		g_fAnimTimer[id][iSeq][0] = get_gametime() + 0.1
						
		set_pev(Ent, pev_nextthink, get_gametime() + 0.01)
	}
}

public SubVicAliveCount(type)
{
	new i, count
	for(i = 0; i < get_maxplayers(); i++)
	{
		if(is_user_alive(i) && Get_BitVar(g_FukSubVic, i))
			count++
	}
	
	if(type) return (count <= 6) ? count : 6
	return count
}

public bomb_explo(iEnt, pevAttacker, Float:vecOrigin[3], Float:flRadius, Float:flDamage)
{
	new Float:vDir[3], Float:vecEnd[3], Float:vEntPos[3], Float:vOrigin[3], Float:flDist, pEntity = -1;
	vEntPos = vecOrigin
	
	message_begin(MSG_BROADCAST, SVC_TEMPENTITY)
	write_byte(TE_EXPLOSION)
	engfunc(EngFunc_WriteCoord, vecOrigin[0])
	engfunc(EngFunc_WriteCoord, vecOrigin[1])
	engfunc(EngFunc_WriteCoord, vecOrigin[2]+10.0)
	write_short(engfunc(EngFunc_ModelIndex, "sprites/ef_wondercannon_hit3.spr"))
	write_byte(10)
	write_byte(15)
	write_byte(TE_EXPLFLAG_NOSOUND | TE_EXPLFLAG_NODLIGHTS | TE_EXPLFLAG_NOPARTICLES)
	message_end()
	
	SendSound(SOUND_EXP2)
	
	while((pEntity = engfunc(EngFunc_FindEntityInSphere, pEntity, vecOrigin, flRadius)) != 0)
	{
		if (!pev_valid(pEntity))
			continue;
			
		pev(pEntity, pev_origin, vOrigin);
		flDist = vector_distance(vecOrigin, vOrigin);
		
		if(pEntity == pevAttacker && is_user_alive(pevAttacker))
		{
			if(flDist <= 120.0) PushAttacker(pevAttacker)
			continue;
		}
		
		if(is_user_alive(pEntity) && !cs_zb_is_zombie(pEntity))
			continue;
			
		if(is_alive(pEntity) && pev(pEntity, pev_takedamage) >0.0)
		{
			vEntPos[2] = vOrigin[2]
			
			xs_vec_sub(vOrigin, vEntPos, vDir)
			xs_vec_normalize(vDir, vDir);
			xs_vec_mul_scalar(vDir, 50.0, vDir)
			xs_vec_add(vEntPos, vDir, vecEnd)
			
			if(is_user_alive(pEntity)) MakeStunKnockBack(pEntity, vecOrigin, vOrigin, 250.0)
			
			if(pev(pEntity, pev_takedamage) > 0.0)
				ExecuteHamB(Ham_TakeDamage, pEntity, iEnt, pevAttacker, flDamage, isBreakable(pEntity) ? DMG_BLAST : DMG_CLUB)
		}
			
	}
	engfunc(EngFunc_RemoveEntity, iEnt);
}
public explo(seq, Float:vEntOrigin[3])
{
	engfunc(EngFunc_MessageBegin, MSG_PVS, SVC_TEMPENTITY, vEntOrigin, 0);
	write_byte(TE_EXPLOSION)
	engfunc(EngFunc_WriteCoord, vEntOrigin[0])
	engfunc(EngFunc_WriteCoord, vEntOrigin[1])
	
	if(6 <= seq < 11) engfunc(EngFunc_WriteCoord, vEntOrigin[2] - 27.0)
	else engfunc(EngFunc_WriteCoord, vEntOrigin[2])
	
	if(seq < 6)
	{
		if(!(seq%2)) write_short(g_cache_exp[0])
		else if((seq%2) != 0) write_short(g_cache_exp[3])
	} else if(6 <= seq < 11) write_short(g_cache_exp[1])
	else write_short(g_cache_exp[2])
	
	if(6 <= seq < 11) write_byte(7)
	else write_byte(4)
	
	if(seq < 6) write_byte(18)
	else if(6 <= seq < 11) write_byte(12)
	else write_byte(15)
	
	write_byte(TE_EXPLFLAG_NOSOUND | TE_EXPLFLAG_NODLIGHTS | TE_EXPLFLAG_NOPARTICLES)
	message_end()
}

public beam(Float:VicOrig[3], Float:SubVicOrig[3])
{
	engfunc(EngFunc_MessageBegin, MSG_PVS, SVC_TEMPENTITY, VicOrig, 0)
	write_byte(TE_BEAMPOINTS)
	engfunc(EngFunc_WriteCoord, VicOrig[0])
	engfunc(EngFunc_WriteCoord, VicOrig[1])
	engfunc(EngFunc_WriteCoord, VicOrig[2])
	engfunc(EngFunc_WriteCoord, SubVicOrig[0])
	engfunc(EngFunc_WriteCoord, SubVicOrig[1])
	engfunc(EngFunc_WriteCoord, SubVicOrig[2])
	write_short(g_cache_beam)
	write_byte(0)		// byte (starting frame) 
	write_byte(20)		// byte (frame rate in 0.1's) 
	write_byte(5)		// byte (life in 0.1's) 
	write_byte(255)		// byte (line width in 0.1's) 
	write_byte(0)		// byte (noise amplitude in 0.01's) 
	write_byte(255)		// byte,byte,byte (color) (R)
	write_byte(255)		// (G)
	write_byte(255)		// (B)
	write_byte(255)		// byte (brightness)
	write_byte(0)		// byte (scroll speed in 0.1's)
	message_end()
}

/* ===============================
------------- MUZZLEFLASH --------
=================================*/
public fw_MF_Think(ent)
{
	if(!pev_valid(ent))
		return
	
	static Classname[32]
	pev(ent, pev_classname, Classname, sizeof(Classname))
	
	if(equal(Classname, "wcn_mf") || equal(Classname, "wcn_mf2"))
	{
		static Float:fFrame, Float:fFrameMax, iWpn, iType, iHand
		pev(ent, pev_frame, fFrame)
		iWpn = pev(ent, pev_iuser4)
		iType = pev(ent, pev_iuser1)
		iHand = get_pcvar_num(cvar_hand)
		
		if(!pev_valid(iWpn))
			return
	
		fFrameMax = (iType ? g_cache_frame_mf2[iHand] : g_cache_frame_mf)
		
		fFrame += 1.0
		set_pev(ent, pev_frame, fFrame)
		
		if(fFrame >= fFrameMax) 
		{
			set_pev(ent, pev_flags, pev(ent, pev_flags) | FL_KILLME)
			return
		}
		set_pev(ent, pev_nextthink, get_gametime() + 0.05)
		return
	}
	
	if(equal(Classname, "bomb_light") && pev(ent, pev_iuser1))
	{
		new iEnt
		iEnt = pev(ent, pev_iuser2)
		
		if(!pev_valid(iEnt))
		{
			set_pev(ent, pev_iuser1, 0)
			set_pev(ent, pev_flags, pev(ent, pev_flags) | FL_KILLME);
			return
		}
		
		if(pev_valid(ent)) 
		{
			new Float:fFrame
			pev(ent, pev_frame, fFrame)
	
			if(fFrame < 10.0) fFrame += 1.0
			else fFrame = 5.0
			set_pev(ent, pev_frame, fFrame)
	
			set_pev(ent, pev_nextthink, get_gametime() + 0.045)
		}
	}
}

public MakeMuzzleFlash(id, iEnt, iBody, spr[], iType)
{
	static iMuz
	iMuz = Stock_CreateEntityBase(id, "env_sprite", MOVETYPE_FOLLOW, spr, iType ? "wcn_mf2" : "wcn_mf", SOLID_NOT,0.05)
	set_pev(iMuz, pev_body, iBody)
	set_pev(iMuz, pev_rendermode, kRenderTransAdd)
	set_pev(iMuz, pev_renderamt, 255.0)
	set_pev(iMuz, pev_aiment, id)
	set_pev(iMuz, pev_scale, 0.1)
	set_pev(iMuz, pev_frame, 0.0)
	set_pev(iMuz, pev_animtime, get_gametime())
	set_pev(iMuz, pev_iuser1, iType)
	set_pev(iMuz, pev_iuser4, iEnt)
	dllfunc(DLLFunc_Spawn, iMuz)
}

stock Stock_CreateEntityBase(id, classtype[], mvtyp, mdl[], class[], solid, Float:fNext)
{
	new pEntity = engfunc(EngFunc_CreateNamedEntity, engfunc(EngFunc_AllocString, classtype))
	set_pev(pEntity, pev_movetype, mvtyp);
	set_pev(pEntity, pev_owner, id);
	engfunc(EngFunc_SetModel, pEntity, mdl);
	set_pev(pEntity, pev_classname, class);
	set_pev(pEntity, pev_solid, solid);
	set_pev(pEntity, pev_nextthink, get_gametime() + fNext)
	return pEntity
}

////////////////////////////
stock SpawnBlood(const Float:vecOrigin[3], iColor, iAmount)
{
	if(!iAmount)
		return
	
	iAmount *= 2
	if(iAmount > 255) iAmount = 255
	
	engfunc(EngFunc_MessageBegin, MSG_PVS, SVC_TEMPENTITY, vecOrigin)
	write_byte(TE_BLOODSPRITE)
	engfunc(EngFunc_WriteCoord, vecOrigin[0])
	engfunc(EngFunc_WriteCoord, vecOrigin[1])
	engfunc(EngFunc_WriteCoord, vecOrigin[2])
	write_short(g_SpraySpr)
	write_short(g_DropSpr)
	write_byte(iColor)
	write_byte(min(max(3, iAmount / 10), 16))
	message_end()
}

stock can_damage(id1, id2)
{
	if(id1 <= 0 || id1 >= 33 || id2 <= 0 || id2 >= 33)
		return 1
		
	// Check team
	return(get_pdata_int(id1, 114) != get_pdata_int(id2, 114))
}
/*
public Set_WpnList(id)
{
	message_begin(MSG_ONE_UNRELIABLE, get_user_msgid("WeaponList"), _, id)
	write_string(Get_BitVar(g_Had_Base, id) ? "weapon_wondercannon" : weapon_wondercannon)
	write_byte(7)
	write_byte(100)
	write_byte(16)
	write_byte(BOMB_MAX)
	write_byte(0)
	write_byte(8)
	write_byte(CSW_WONDERCANNON)
	write_byte(0)
	message_end()
}

public Set_ExtraAmmo(id, num) set_pdata_int(id, 376 + 16, num, 5)
public Get_ExtraAmmo(id) return get_pdata_int(id, 376 + 16, 5)*/
stock isBreakable(iEnt)
{
	if (!pev_valid(iEnt)) return 0;
	
	static szClassname[32]
	pev(iEnt, pev_classname, szClassname, charsmax(szClassname))
	if (equal(szClassname, "func_breakable") || equal(szClassname, "func_pushable")) return 1;
	return 0;
}
public update_specialammo(id, Ammo, On)
{
	static AmmoSprites[33]
	format(AmmoSprites, sizeof(AmmoSprites), "number_%d", Ammo)
  	
	message_begin(MSG_ONE_UNRELIABLE, get_user_msgid("StatusIcon"), {0,0,0}, id)
	write_byte(On)
	write_string(AmmoSprites)
	write_byte(0) // red
	write_byte(85) // green
	write_byte(255) // blue
	message_end()	
}

/* ===============================
------------- SAFETY -------------
=================================*/
public Register_SafetyFunc()
{
	register_event("CurWeapon", "Safety_CurWeapon", "be", "1=1")
	
	RegisterHam(Ham_Spawn, "player", "fw_Safety_Spawn_Post", 1)
	RegisterHam(Ham_Killed, "player", "fw_Safety_Killed_Post", 1)
}

public Register_SafetyFuncBot(id)
{
	RegisterHamFromEntity(Ham_Spawn, id, "fw_Safety_Spawn_Post", 1)
	RegisterHamFromEntity(Ham_Killed, id, "fw_Safety_Killed_Post", 1)
}

public Safety_Connected(id)
{
	Set_BitVar(g_IsConnected, id)
	UnSet_BitVar(g_IsAlive, id)
	
	g_PlayerWeapon[id] = 0
}

public Safety_Disconnected(id)
{
	UnSet_BitVar(g_IsConnected, id)
	UnSet_BitVar(g_IsAlive, id)
	
	g_PlayerWeapon[id] = 0
	RemoveUserBomb(id)
}

public Safety_CurWeapon(id)
{
	if(!is_alive(id))
		return
		
	static CSW; CSW = read_data(2)
	if(g_PlayerWeapon[id] != CSW) g_PlayerWeapon[id] = CSW
}

public fw_Safety_Spawn_Post(id)
{
	if(!is_user_alive(id))
		return
		
	Set_BitVar(g_IsAlive, id)
}

public fw_Safety_Killed_Post(id)
{
	UnSet_BitVar(g_IsAlive, id)
}

public is_connected(id)
{
	if(!(1 <= id <= 32))
		return 0
	if(!Get_BitVar(g_IsConnected, id))
		return 0

	return 1
}

public is_alive(id)
{
	if(!is_connected(id))
		return 0
	if(!Get_BitVar(g_IsAlive, id))
		return 0
		
	return 1
}

public get_player_weapon(id)
{
	if(!is_alive(id))
		return 0
	
	return g_PlayerWeapon[id]
}

/* ===============================
--------- END OF SAFETY  ---------
=================================*/
stock IsBombActive(id)
{
	new pEntity = -1
	
	while((pEntity = engfunc(EngFunc_FindEntityByString, pEntity, "classname", WCB_PRIMCLASS)) != 0)
	{
		if(!pev_valid(pEntity) || pev(pEntity, pev_owner) != id)
			continue;
		
		new iSeq = pev(pEntity, pev_iuser4)
		
		for(new i = 0; i < iSeq; i++)
		{
			if(g_BombAct[id][i] || g_BombAct[id][i+1])
				return 1
		}
	}
	return 0
}

stock RemoveUserBomb(id)
{
	new pEntity = -1
	while((pEntity = engfunc(EngFunc_FindEntityByString, pEntity, "classname", WCB_PRIMCLASS)) != 0)
	{
		if(!pev_valid(pEntity) || pev(pEntity, pev_owner) != id)
			continue;
		
		engfunc(EngFunc_RemoveEntity, pEntity)
	}
}
stock isClearLine(Float:vOrigin1[3], Float:vOrigin2[3])
{
	new Float:flFraction;
	engfunc(EngFunc_TraceLine, vOrigin1, vOrigin2,  IGNORE_MONSTERS, -1, 0);
	get_tr2(0, TR_flFraction, flFraction)
	
	if (flFraction < 1.0) return 0;

	return 1;
}
stock PushAttacker(id)
{
	new Float:pevVelocity[3];
	pev(id, pev_velocity, pevVelocity)
	pevVelocity[0] *= 2.5
	pevVelocity[1] *= 2.5
	pevVelocity[2] += 350.0;
	set_pev(id, pev_velocity, pevVelocity);
}
stock HoldUp(iEnt, Float:flMultiple = 0.1)
{
	static Float:vecVelocity[3];
	pev(iEnt, pev_velocity, vecVelocity);
	vecVelocity[0] *= flMultiple
	vecVelocity[1] *= flMultiple
	set_pev(iEnt, pev_velocity, vecVelocity);
}
stock MakeStunKnockBack(iEnt, Float:vCenter[3], Float:vEntOrigin[3], Float:flAmount)
{
	static Float:vecVelocity[3], Float:vDir[3];
	pev(iEnt, pev_velocity, vecVelocity);
	xs_vec_sub(vEntOrigin, vCenter, vDir);
	xs_vec_normalize(vDir, vDir);
	xs_vec_mul_scalar(vDir, flAmount, vDir);
	xs_vec_add(vecVelocity, vDir, vecVelocity);
	set_pev(iEnt, pev_velocity, vecVelocity);
}
stock FindBombEnemy(pevAttacker, Float:vecOrigin[3], Float:flSearchRadius)
{
	new Float:vOrigin[3], pEntity = -1
	while((pEntity = engfunc(EngFunc_FindEntityInSphere, pEntity, vecOrigin, flSearchRadius)) != 0)
	{
		if(!pev_valid(pEntity) || pEntity == pevAttacker) continue;
		
		pev(pEntity, pev_origin, vOrigin);
		if(!isClearLine(vecOrigin, vOrigin))
			continue;
		
		if(is_user_alive(pEntity) && cs_zb_is_zombie(pEntity))
			return 1;
	}
	return 0;
}

stock Set_WeaponAnim(id, anim, iCheck=0)
{
	if(iCheck && pev(id, pev_weaponanim) == anim)
		return;

	set_pev(id, pev_weaponanim, anim)
	
	message_begin(MSG_ONE_UNRELIABLE, SVC_WEAPONANIM, {0, 0, 0}, id)
	write_byte(anim)
	write_byte(pev(id, pev_body))
	message_end()
}

stock Make_BulletHole(id, Float:Origin[3], Float:Damage)
{
	// Find target
	static Decal; Decal = random_num(41, 45)
	static LoopTime; 
	
	if(Damage > 100.0) LoopTime = 2
	else LoopTime = 1
	
	for(new i = 0; i < LoopTime; i++)
	{
		// Put decal on "world" (a wall)
		message_begin(MSG_BROADCAST, SVC_TEMPENTITY)
		write_byte(TE_WORLDDECAL)
		engfunc(EngFunc_WriteCoord, Origin[0])
		engfunc(EngFunc_WriteCoord, Origin[1])
		engfunc(EngFunc_WriteCoord, Origin[2])
		write_byte(Decal)
		message_end()
		
		// Show sparcles
		message_begin(MSG_BROADCAST, SVC_TEMPENTITY)
		write_byte(TE_GUNSHOTDECAL)
		engfunc(EngFunc_WriteCoord, Origin[0])
		engfunc(EngFunc_WriteCoord, Origin[1])
		engfunc(EngFunc_WriteCoord, Origin[2])
		write_short(id)
		write_byte(Decal)
		message_end()
	}
}

stock Make_BulletSmoke(id, TrResult)
{
	static Float:vecSrc[3], Float:vecEnd[3], TE_FLAG
	
	get_weapon_attachment(id, vecSrc)
	global_get(glb_v_forward, vecEnd)
    
	xs_vec_mul_scalar(vecEnd, 8192.0, vecEnd)
	xs_vec_add(vecSrc, vecEnd, vecEnd)

	get_tr2(TrResult, TR_vecEndPos, vecSrc)
	get_tr2(TrResult, TR_vecPlaneNormal, vecEnd)
    
	xs_vec_mul_scalar(vecEnd, 2.5, vecEnd)
	xs_vec_add(vecSrc, vecEnd, vecEnd)
    
	TE_FLAG |= TE_EXPLFLAG_NODLIGHTS
	TE_FLAG |= TE_EXPLFLAG_NOSOUND
	TE_FLAG |= TE_EXPLFLAG_NOPARTICLES
	
	engfunc(EngFunc_MessageBegin, MSG_PAS, SVC_TEMPENTITY, vecEnd, 0)
	write_byte(TE_EXPLOSION)
	engfunc(EngFunc_WriteCoord, vecEnd[0])
	engfunc(EngFunc_WriteCoord, vecEnd[1])
	engfunc(EngFunc_WriteCoord, vecEnd[2] - 10.0)
	write_short(g_SmokePuff_SprId)
	write_byte(2)
	write_byte(50)
	write_byte(TE_FLAG)
	message_end()
}

stock get_weapon_attachment(id, Float:output[3], Float:fDis = 40.0)
{ 
	static Float:vfEnd[3], viEnd[3] 
	get_user_origin(id, viEnd, 3)  
	IVecFVec(viEnd, vfEnd) 
	
	static Float:fOrigin[3], Float:fAngle[3]
	pev(id, pev_origin, fOrigin) 
	pev(id, pev_view_ofs, fAngle)
	
	xs_vec_add(fOrigin, fAngle, fOrigin) 
	
	static Float:fAttack[3]
	xs_vec_sub(vfEnd, fOrigin, fAttack)
	xs_vec_sub(vfEnd, fOrigin, fAttack) 
	
	static Float:fRate
	fRate = fDis / vector_length(fAttack)
	xs_vec_mul_scalar(fAttack, fRate, fAttack)
	
	xs_vec_add(fOrigin, fAttack, output)
}

stock get_speed_vector(const Float:origin1[3],const Float:origin2[3],Float:speed, Float:new_velocity[3])
{
	new_velocity[0] = origin2[0] - origin1[0]
	new_velocity[1] = origin2[1] - origin1[1]
	new_velocity[2] = origin2[2] - origin1[2]
	new Float:num = floatsqroot(speed*speed / (new_velocity[0]*new_velocity[0] + new_velocity[1]*new_velocity[1] + new_velocity[2]*new_velocity[2]))
	new_velocity[0] *= num
	new_velocity[1] *= num
	new_velocity[2] *= num
	
	return 1;
}
stock SendSound(const szSound[])
{
	for(new id = 0; id<get_maxplayers(); id++)
	{
		if(!pev_valid(id) || !is_user_connected(id)) continue;
		client_cmd(id, "spk %s", szSound)
	}
}
stock Set_PlayerNextAttack(id, Float:nexttime)
{
	set_pdata_float(id, 83, nexttime, 5)
}

stock Stock_Drop_Slot(id, iSlot) 
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
			engclient_cmd(id, "drop", wname)
		}
	}
}

stock Stock_Get_Wpn_Slot(iWpn)
{
	const PRIMARY_WEAPONS_BIT_SUM = (1<<CSW_SCOUT)|(1<<CSW_XM1014)|(1<<CSW_MAC10)|(1<<CSW_AUG)|(1<<CSW_UMP45)|(1<<CSW_SG550)|(1<<CSW_GALIL)|(1<<CSW_FAMAS)|(1<<CSW_AWP)|(1<<CSW_MP5NAVY)|(1<<CSW_M249)|(1<<CSW_M3)|(1<<CSW_M4A1)|(1<<CSW_TMP)|(1<<CSW_G3SG1)|(1<<CSW_SG552)|(1<<CSW_AK47)|(1<<CSW_P90)
	const SECONDARY_WEAPONS_BIT_SUM = (1<<CSW_P228)|(1<<CSW_ELITE)|(1<<CSW_FIVESEVEN)|(1<<CSW_USP)|(1<<CSW_GLOCK18)|(1<<CSW_DEAGLE)

	if(PRIMARY_WEAPONS_BIT_SUM & (1<<iWpn)) return 1
	else if(SECONDARY_WEAPONS_BIT_SUM & (1<<iWpn)) return 2
	else if(iWpn == CSW_KNIFE) return 3
	else if(iWpn == CSW_HEGRENADE) return 4
	else if(iWpn == CSW_C4) return 5
	return 6 //FLASHBANG SMOKEBANG
}
/* AMXX-Studio Notes - DO NOT MODIFY BELOW HERE
*{\\ rtf1\\ ansi\\ deff0{\\ fonttbl{\\ f0\\ fnil Tahoma;}}\n\\ viewkind4\\ uc1\\ pard\\ lang1066\\ f0\\ fs16 \n\\ par }
*/
