#include <amxmodx>
#include <fakemeta>
#include <engine>
#include <cstrike>
#include <csm>
#include <fakemeta_util>
#include <hamsandwich>
#include <zombiemodlimited>

#define CSW_USAS CSW_XM1014
#define weapon_usas "weapon_xm1014"

#define Get_BitVar(%1,%2) (%1 & (1 << (%2 & 31)))
#define Set_BitVar(%1,%2) %1 |= (1 << (%2 & 31))
#define UnSet_BitVar(%1,%2) %1 &= ~(1 << (%2 & 31))
new g_HadWpn, g_Attack, g_Event, g_HamBot, g_Hit

new const szUSASModels[3][] = { "models/zbz/wpn/p_gatlingex.mdl" , "models/zbz/wpn/v_gatlingex.mdl" , "models/zbz/wpn/w_primgroup2.mdl" }
new const CAN_DAMAGE_ENTITY[][]={ "info_target" , "func_breakable" , "func_pushable" , "hostage_entity" }
new const TRACER_ENTITY[][]={ "info_target", "func_breakable", "func_pushable", "func_wall", "func_wall_toggle", "func_door", "func_door_rotating", "weaponbox",
		"func_button", "func_conveyor", "hostage_entity", "func_tank", "func_tankmortar", "func_tanklaser", "func_tankrocket", "button_target"  , "func_train" , "func_tracktrain", "func_vehicle"}
		
new const WeaponSounds[][] =
{
	"weapons/gatlingex-1.wav",
	"weapons/gatlingex-2.wav",
	"weapons/gatlingex-2_amb.wav",
	"weapons/gatlingex-2_exp.wav"
}
public plugin_precache()
{
	for( new i = 0 ; i < 3 ; i ++ )
	{
		engfunc(EngFunc_PrecacheModel, szUSASModels[i])
	}
	
	engfunc(EngFunc_PrecacheModel, "sprites/ef_gatlingex_explosion.spr")
	engfunc(EngFunc_PrecacheModel, "sprites/ef_gatlingex_fireball.spr")
	engfunc(EngFunc_PrecacheModel, "sprites/ef_gatlingex_star.spr")
	
	register_forward(FM_PrecacheEvent, "fw_PrecacheEvent_Post", 1)
	for(new i = 0; i < sizeof(WeaponSounds); i++)
		precache_sound(WeaponSounds[i])
}
public plugin_init()
{
	register_plugin("[Zombie Z] Extra Infernal Cannon", "1.0", "csbtedhan")
	
	register_forward(FM_SetModel, "fw_SetModel")
	register_forward(FM_UpdateClientData,"fw_UpdateClientData_Post", 1)	
	register_forward(FM_PlaybackEvent, "fw_PlaybackEvent")
	register_forward(FM_CmdStart, "fw_CmdStart");
	
	RegisterHam(Ham_Think, "info_target", "FireBallThink")
	RegisterHam(Ham_Touch, "info_target", "FireBallImpact")
	
	RegisterHam(Ham_TraceAttack, "worldspawn", "fw_TraceAttack")
	for(new i=0; i<sizeof(TRACER_ENTITY); i++)
		RegisterHam(Ham_TraceAttack, TRACER_ENTITY[i], "fw_TraceAttack")
	RegisterHam(Ham_TraceAttack, "player", "HamF_TakeDamage")
	for(new i=0; i<sizeof(CAN_DAMAGE_ENTITY); i++)
		RegisterHam(Ham_TraceAttack, CAN_DAMAGE_ENTITY[i], "HamF_TakeDamage")
		
	RegisterHam(Ham_Item_Holster, weapon_usas, "fw_Item_Holster");
	RegisterHam(Ham_Weapon_PrimaryAttack, weapon_usas, "fw_PrimaryAttack");
	RegisterHam(Ham_Weapon_PrimaryAttack, weapon_usas, "fw_PrimaryAttack_Post", 1);
	RegisterHam(Ham_Item_Deploy, weapon_usas, "fw_Item_Deploy_Post", 1);
	RegisterHam(Ham_Item_AddToPlayer, weapon_usas, "fw_Item_AddToPlayer_Post", 1);
	RegisterHam(Ham_Item_PostFrame, weapon_usas, "fw_Item_PostFrame");
	RegisterHam(Ham_Weapon_Reload, weapon_usas, "fw_Weapon_Reload_Post", 1);	
	
	register_message(get_user_msgid("DeathMsg"), "message_DeathMsg")
	
	cs_register_custom_item("Infernal Cannon", 3100, 2, "GiveUsas", "gatlingex")
}

public fw_PrecacheEvent_Post(type, const name[])
	if(equal("events/xm1014.sc", name)) g_Event = get_orig_retval()
	
public GiveUsas(id)
{
	if(!is_user_alive(id)) return;
	
	drop_weapons(id, 1)
	
	Set_BitVar(g_HadWpn,id)
	UnSet_BitVar(g_Attack,id)
	fm_give_item(id, "weapon_xm1014")
	
	cs_set_user_bpammo(id, CSW_USAS, 180)
	
	new iWpn = get_pdata_cbase(id, 373);
	if(pev_valid(iWpn) && get_pdata_int(iWpn, 43) == CSW_USAS)
		set_pdata_int(iWpn, 51, 45);
}
public message_DeathMsg()
{
	// get value data
	static id, weapon[32]
	id = get_msg_arg_int(1)
	get_msg_arg_string(4, weapon, charsmax(weapon))
	
	if(equal(weapon, "xm1014"))
	{
		if(Get_BitVar(g_HadWpn,id)) set_msg_arg_string(4, "gatlingex")
	}
		
	return PLUGIN_CONTINUE
}
public fw_Remove_Item(id, itemid, slot)
{
	if(slot == 0)
	{
		if(Get_BitVar(g_HadWpn, id))
		{
			for(new x = 0; x<4;x++)
				update_specialammo(id, x, 0)
		}
		UnSet_BitVar(g_HadWpn,id)
		UnSet_BitVar(g_Hit,id)
	}
}

public client_putinserver(id)
{
	if(is_user_bot(id) && !g_HamBot && get_cvar_num("bot_quota"))
	{
		set_task(0.5, "RegHamBots", id)
	}
}
public RegHamBots(id)
{
	g_HamBot = 1
	RegisterHamFromEntity(Ham_TraceAttack, id, "HamF_TakeDamage")
}
public HamF_TakeDamage(iVictim, iAttacker, Float:Damage, Float:Direction[3], Ptr, DamageBits)
{	
	if(!is_user_connected(iAttacker) || get_user_weapon(iAttacker) != CSW_USAS) 
		return HAM_IGNORED;
	
	if(Get_BitVar(g_Attack, iAttacker) && Get_BitVar(g_HadWpn, iAttacker))
	{
		SetHamParamFloat(3, 92.5)
		if(is_user_alive(iVictim) && !cs_zb_is_zombie(iAttacker) && cs_zb_is_zombie(iVictim))
		{
			static Float:flEnd[3], Float:vecPlane[3], Float:vDir[3]
			xs_vec_mul_scalar(vecPlane, 3.0, vDir)
			get_tr2(Ptr, TR_vecEndPos, flEnd)
			xs_vec_add(flEnd, vDir, flEnd)
			MakeEffect(flEnd, vecPlane)
		
			Set_BitVar(g_Hit,iAttacker)
		}
		return HAM_HANDLED
	}
	return HAM_IGNORED;
}

public fw_TraceAttack(Victim, Attacker, Float:Damage, Float:Direction[3], Ptr, DamageBits)
{
	if(!is_user_connected(Attacker))
		return HAM_IGNORED	
	if(get_user_weapon(Attacker) != CSW_USAS || !Get_BitVar(g_HadWpn, Attacker))
		return HAM_IGNORED
		
	static Float:flEnd[3], Float:vecPlane[3], Float:vDir[3], pHit
		
	get_tr2(Ptr, TR_vecEndPos, flEnd)
	get_tr2(Ptr, TR_vecPlaneNormal, vecPlane)
	get_tr2(Ptr, TR_pHit, pHit)
			
	Make_BulletHole(flEnd, pHit)
	
	xs_vec_mul_scalar(vecPlane, 3.0, vDir)
	xs_vec_add(flEnd, vDir, flEnd)
	MakeEffect(flEnd, vecPlane)
	
	return HAM_IGNORED
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
	
	if(equal(model, "models/w_xm1014.mdl"))
	{
		static weapon; weapon = find_ent_by_owner(-1, weapon_usas, entity)
		if(pev_valid(weapon))
		{
			if(Get_BitVar(g_HadWpn, iOwner))
			{
				set_pev(weapon, pev_impulse, 2292) 
				engfunc(EngFunc_SetModel, entity, szUSASModels[2])
				set_pev(entity, pev_body, 4)
				
				UnSet_BitVar(g_Hit, iOwner)
				UnSet_BitVar(g_HadWpn,iOwner)
				UnSet_BitVar(g_Attack,iOwner)
				return FMRES_SUPERCEDE
			}
			
		}
	}

	return FMRES_IGNORED;
}

public fw_PrimaryAttack(Ent)
{
	if(pev_valid(Ent) != 2)
		return
	static Id; Id = get_pdata_cbase(Ent, 41, 4)
	if(get_pdata_cbase(Id, 373) != Ent)
		return
	if(!Get_BitVar(g_HadWpn, Id))
		return
		
	Set_BitVar(g_Attack,Id)
}

public fw_Item_AddToPlayer_Post(Ent, id)
{
	if(!pev_valid(Ent))
		return HAM_IGNORED
		
	if(pev(Ent, pev_impulse) == 2292)
	{
		Set_BitVar(g_HadWpn, id)
		set_pev(Ent, pev_impulse, 0)	
		
	}
	return HAM_HANDLED
}


public fw_CmdStart(id, uc_handle, seed)
{
	if(!is_user_alive(id))
		return
	if(get_user_weapon(id) != CSW_USAS || !Get_BitVar(g_HadWpn, id))
		return 

	static CurButton; CurButton = get_uc(uc_handle, UC_Buttons)
	if(CurButton & IN_RELOAD)
	{
		CurButton &= ~IN_RELOAD
		set_uc(uc_handle, UC_Buttons, CurButton)
		
		static maxclip, ent; ent = fm_get_user_weapon_entity(id, CSW_USAS)
		if(!pev_valid(ent)) return
		
		static fInReload; fInReload = get_pdata_int(ent, 54, 4)
		static Float:flNextAttack; flNextAttack = get_pdata_float(id, 83, 5)
		
		if (flNextAttack > 0.0)
			return
			
		if (fInReload)
			return
			
		maxclip = 45
		if(cs_get_weapon_ammo(ent) >= maxclip)
		{
			Set_WeaponAnim(id, 0)
			return
		}
			
		fw_Weapon_Reload_Post(ent)
	}
	
}
public fw_Item_PostFrame(ent)
{
	if(!pev_valid(ent)) return
	
	static id; id = pev(ent, pev_owner)
	if(!Get_BitVar(g_HadWpn, id)) return
	
	if(get_user_button(id) & IN_ATTACK2 && get_pdata_float(ent, 47, 4) <= 0.0 && pev(ent, pev_iuser2) > 0)
	{
		update_specialammo(id, pev(ent, pev_iuser2), 0)
		set_pev(ent, pev_iuser2, pev(ent, pev_iuser2) - 1)
		update_specialammo(id, pev(ent, pev_iuser2), 1)
		
		set_pdata_float(ent, 46, 1.0, 4)
		set_pdata_float(ent, 47, 1.0, 4)
		set_pdata_float(ent, 48, 1.5, 4)
		
		ShootFireBall(id)
		Set_WeaponAnim(id, 5)
		emit_sound(id, CHAN_WEAPON, WeaponSounds[1], 1.0, 0.6, 0, PITCH_NORM)
		
	}
	static iBpAmmo ; iBpAmmo = get_pdata_int(id, 381, 5)
	static iClip ; iClip = get_pdata_int(ent, 51, 4)
	static iMaxClip ; iMaxClip = 45

	if(get_pdata_int(ent, 54, 4) && get_pdata_float(id, 83, 5) <= 0.0)
	{
		static j; j = min(iMaxClip - iClip, iBpAmmo)
		set_pdata_int(ent, 51, iClip + j, 4)
		set_pdata_int(id, 381, iBpAmmo-j, 5)
		
		set_pdata_int(ent, 54, 0, 4)
		cs_set_weapon_ammo(ent, iClip + j)
	
		update_ammo(id, CSW_USAS, cs_get_weapon_ammo(ent), cs_get_user_bpammo(id, CSW_USAS))
	
		return
	}
}
public fw_Weapon_Reload_Post(ent)
{
	if(!pev_valid(ent)) return HAM_IGNORED
	static id; id = pev(ent, pev_owner)

	if(Get_BitVar(g_HadWpn, id))
	{
		static Float:flTime, CurBpAmmo; CurBpAmmo = cs_get_user_bpammo(id, CSW_USAS)
		
		if(CurBpAmmo  <= 0)
			return HAM_IGNORED

		flTime = 2.0
		set_pdata_int(ent, 55, 0, 4)
		set_pdata_float(id, 83, flTime, 5)
		set_pdata_float(ent, 48, flTime + 2.5, 4)
		set_pdata_float(ent, 46, flTime + 0.85, 4)
		set_pdata_float(ent, 47, flTime + 0.85, 4)
		set_pdata_int(ent, 54, 1, 4)
		
		Set_WeaponAnim(id, 3)			
		
		return HAM_HANDLED
	}
	
	return HAM_IGNORED	
}
public fw_PrimaryAttack_Post(Ent)
{
	if(pev_valid(Ent) != 2)
		return
	static Id; Id = get_pdata_cbase(Ent, 41, 4)
	if(get_pdata_cbase(Id, 373) != Ent)
		return
	if(!Get_BitVar(g_HadWpn, Id))
		return
		
	static Float:punch[3]; pev(Id, pev_punchangle, punch)
	xs_vec_mul_scalar(punch, 0.45, punch)
	set_pev(Id, pev_punchangle, punch)
	
	if(get_pdata_int(Ent, 51, 4) > 0)
	{
		if(pev(Ent, pev_iuser2) < 3)
		{
			set_pev(Ent, pev_iuser1, pev(Ent, pev_iuser1) + 1)
			if(pev(Ent, pev_iuser1) >= 15)
			{
				set_pev(Ent, pev_iuser1, 0)
				update_specialammo(Id, pev(Ent, pev_iuser2), 0)
				set_pev(Ent, pev_iuser2, pev(Ent, pev_iuser2) + 1)
				update_specialammo(Id, pev(Ent, pev_iuser2), 1)
			}
		}
	}
	
	UnSet_BitVar(g_Attack,Id)
}
public fw_Item_Holster(Ent)
{
	if(pev_valid(Ent) != 2)
		return
	new Id; Id = get_pdata_cbase(Ent, 41, 4)
	if(get_pdata_cbase(Id, 373) != Ent)
		return
		
	update_specialammo(Id, pev(Ent, pev_iuser1), 0)
}
public fw_Item_Deploy_Post(Ent)
{
	if(pev_valid(Ent) != 2)
		return
	static Id; Id = get_pdata_cbase(Ent, 41, 4)
	if(get_pdata_cbase(Id, 373) != Ent)
		return
	if(!Get_BitVar(g_HadWpn, Id))
		return
	set_pev(Id, pev_viewmodel2, szUSASModels[1])
	set_pev(Id, pev_weaponmodel2, szUSASModels[0])
	
	if(pev(Ent, pev_iuser2) > 0)
		update_specialammo(Id, pev(Ent, pev_iuser2), 1)
	
	Set_WeaponAnim(Id, 4)
}

public fw_UpdateClientData_Post(id, sendweapons, cd_handle)
{
	if(!is_user_alive(id))
		return FMRES_IGNORED	
	if(get_user_weapon(id) == CSW_USAS && Get_BitVar(g_HadWpn, id))
		set_cd(cd_handle, CD_flNextAttack, get_gametime() + 0.001) 
	
	return FMRES_HANDLED
}

public fw_PlaybackEvent(flags, invoker, eventid, Float:delay, Float:origin[3], Float:angles[3], Float:fparam1, Float:fparam2, iParam1, iParam2, bParam1, bParam2)
{
	if (!is_user_connected(invoker))
		return FMRES_IGNORED	
	if(get_user_weapon(invoker) != CSW_USAS || !Get_BitVar(g_HadWpn, invoker))
		return FMRES_IGNORED
	if(eventid != g_Event)
		return FMRES_IGNORED
	
	engfunc(EngFunc_PlaybackEvent, flags | FEV_HOSTONLY, invoker, eventid, delay, origin, angles, fparam1, fparam2, iParam1, iParam2, bParam1, bParam2)
	
	new Float:origin[3]; pev(invoker, pev_origin, origin)
	Set_WeaponAnim(invoker, random_num(1,2))
	emit_sound(invoker, CHAN_WEAPON, WeaponSounds[0], 1.0, 0.6, 0, PITCH_NORM)
	
	Eject_Shell(invoker)
	
	return FMRES_SUPERCEDE
}

public ShootFireBall(id)
{
	static Float:vOrigin[3], Float:vUp[3], Float:vVelocity[3]
	pev(id, pev_origin, vOrigin)
	pev(id, pev_view_ofs, vUp)
	xs_vec_add(vOrigin, vUp, vOrigin);
	
	new pEnt = engfunc(EngFunc_CreateNamedEntity, engfunc(EngFunc_AllocString, "info_target"))
	set_pev(pEnt, pev_origin, vOrigin)
	set_pev(pEnt, pev_classname, "gatlingex_fireball")
	engfunc(EngFunc_SetModel, pEnt, "sprites/ef_gatlingex_fireball.spr")
	set_pev(pEnt, pev_owner, id)
	set_pev(pEnt, pev_movetype, 5)
	set_pev(pEnt, pev_solid, 2)
	set_pev(pEnt, pev_mins, Float:{-1.0, -1.0, -1.0})
	set_pev(pEnt, pev_maxs, Float:{1.0, 1.0, 1.0})
	set_pev(pEnt, pev_dmgtime, get_gametime() + 6.0)
	set_pev(pEnt, pev_nextthink, get_gametime())
	set_pev(pEnt, pev_iuser1, 6)
	set_pev(pEnt, pev_renderamt, 255.0)
	set_pev(pEnt, pev_rendermode, kRenderTransAdd)
	set_pev(pEnt, pev_frame, 0.0);
	set_pev(pEnt, pev_scale, 1.0)
	
	velocity_by_aim(id, 200, vVelocity)
	set_pev(pEnt, pev_velocity, vVelocity)
	emit_sound(pEnt, CHAN_WEAPON, WeaponSounds[2], 1.0, 0.6, 0, PITCH_NORM)
	
}
public FireBallThink(Ent)
{
	if(!isFireball(Ent))
		return;
		
	static Float:vOrigin[3]
	pev(Ent, pev_origin, vOrigin)
	
	new pevOwner = pev(Ent, pev_owner)
	if(cs_zb_is_zombie(pevOwner) || !is_user_alive(pevOwner) || !is_user_connected(pevOwner))
	{
		FireBallExplode(Ent)
		return;
	}
	
	message_begin(MSG_BROADCAST, SVC_TEMPENTITY)
	write_byte(TE_DLIGHT)
	engfunc(EngFunc_WriteCoord, vOrigin[0])
	engfunc(EngFunc_WriteCoord, vOrigin[1])
	engfunc(EngFunc_WriteCoord, vOrigin[2])
	write_byte(30)
	write_byte(200)
	write_byte(140)
	write_byte(0)
	write_byte(4)
	write_byte(2)
	message_end()
	
	new Float:flFrame; pev(Ent, pev_frame, flFrame);
	if(flFrame >= 29.0) flFrame = 0.0
	set_pev(Ent, pev_frame, flFrame + 1.75);
	
	DoRadiusDamage(vOrigin, 250.0, 210.0, pevOwner, Ent)
	
	if(pev(Ent, pev_dmgtime) <= get_gametime())
	{
		DoRadiusDamage(vOrigin, 2250.0, 350.0, pevOwner, Ent)
		FireBallExplode(Ent)
		return;
	}
	set_pev(Ent, pev_nextthink, get_gametime() + 0.1)
}
public FireBallImpact(Ent, Id)
{
	if(!isFireball(Ent))
		return;
		
	set_pev(Ent, pev_movetype, 0)
	set_pev(Ent, pev_velocity, Float:{0.0, 0.0, 0.0})
	set_pev(Ent, pev_solid, 0)
}
stock FireBallExplode(Ent)
{
	static Float:vOrigin[3]
	pev(Ent, pev_origin, vOrigin)
	
	message_begin(MSG_BROADCAST, SVC_TEMPENTITY)
	write_byte(TE_EXPLOSION)
	engfunc(EngFunc_WriteCoord, vOrigin[0])
	engfunc(EngFunc_WriteCoord, vOrigin[1])
	engfunc(EngFunc_WriteCoord, vOrigin[2])
	write_short(engfunc(EngFunc_ModelIndex, "sprites/ef_gatlingex_explosion.spr"))
	write_byte(10)
	write_byte(20)
	write_byte(14)
	message_end()
	
	engfunc(EngFunc_EmitAmbientSound, Ent, vOrigin, WeaponSounds[3], 1.0, 0.5, 0, 100)
	engfunc(EngFunc_RemoveEntity, Ent)
}
stock DoRadiusDamage(Float:vOrigin[3], Float:flMaxDamage, Float:flRadius, pevAttacker, pevInflictor)
{
	static pEnt, Float:pOrigin[3], Float:flDist, Float:flDamage
	pEnt = -1
	while(( pEnt = engfunc(EngFunc_FindEntityInSphere, pEnt, vOrigin, flRadius)) != 0 )
	{
		if(!pev_valid(pEnt) || pEnt == pevAttacker)
			continue;
			
		if(pev(pEnt, pev_takedamage) <= 0.0 || pev(pEnt, pev_health) <= 0.0)
			continue;
			
		pev(pEnt, pev_origin, pOrigin)
		flDist = vector_distance(vOrigin, pOrigin)
		flDamage = flMaxDamage - floatmul(flMaxDamage, floatdiv(flDist, flRadius))
		if(!isClearLine(vOrigin, pOrigin)) flDamage *= 0.6
		
		if(isBreakable(pEnt) && !(pev(pEnt, pev_spawnflags) & SF_BREAK_TRIGGER_ONLY) && flDamage <= 0.0)
			flDamage = floatdiv(flMaxDamage, 2.0)
		
		if(flDamage > 0.0) ExecuteHamB(Ham_TakeDamage, pEnt, pevInflictor, pevAttacker, flDamage, isBreakable(pEnt) ? DMG_BLAST : DMG_CLUB)
	}
}
stock isClearLine(Float:vOrigin1[3], Float:vOrigin2[3])
{
	new Float:flFraction;
	engfunc(EngFunc_TraceLine, vOrigin1, vOrigin2, IGNORE_MONSTERS|IGNORE_GLASS, 0, 0);
	get_tr2(0, TR_flFraction, flFraction)
	
	if (flFraction < 1.0) return 0;

	return 1;
}
stock isBreakable(iEnt)
{
	if (!pev_valid(iEnt)) return 0;
	
	static szClassname[32]
	pev(iEnt, pev_classname, szClassname, charsmax(szClassname))
	if (equal(szClassname, "func_breakable") || equal(szClassname, "func_pushable")) return 1;
	return 0;
}
stock isFireball(Ent)
{
	if(!pev_valid(Ent)) return 0;
	
	static szClassName[32]; pev(Ent, pev_classname,szClassName, 31);
	return (equal(szClassName, "gatlingex_fireball"))
}
stock Make_BulletHole(Float:vecOrigin[3], iEnt)
{
	static szName[16]
	format(szName, 15, "{shot%i", random_num(1,5));
	message_begin(MSG_BROADCAST, SVC_TEMPENTITY)
	write_byte(104)
	engfunc(EngFunc_WriteCoord, vecOrigin[0])
	engfunc(EngFunc_WriteCoord, vecOrigin[1])
	engfunc(EngFunc_WriteCoord, vecOrigin[2])
	write_byte(get_decal_index(szName))
	write_short(iEnt)
	message_end()
				
	message_begin(MSG_BROADCAST, SVC_TEMPENTITY)
	write_byte(109)
	engfunc(EngFunc_WriteCoord, vecOrigin[0])
	engfunc(EngFunc_WriteCoord, vecOrigin[1])
	engfunc(EngFunc_WriteCoord, vecOrigin[2])
	write_short(iEnt)
	write_byte(get_decal_index(szName))
	message_end()
}
stock drop_weapons(id, dropwhat)
{
	// Get user weapons
	static weapons[32], num, i, weaponid
	num = 0 // reset passed weapons count (bugfix)
	get_user_weapons(id, weapons, num)
	
	const PRIMARY_WEAPONS_BIT_SUM = (1<<CSW_SCOUT)|(1<<CSW_XM1014)|(1<<CSW_MAC10)|(1<<CSW_AUG)|(1<<CSW_UMP45)|(1<<CSW_SG550)|(1<<CSW_GALIL)|(1<<CSW_FAMAS)|(1<<CSW_AWP)|(1<<CSW_MP5NAVY)|(1<<CSW_M249)|(1<<CSW_M3)|(1<<CSW_M4A1)|(1<<CSW_TMP)|(1<<CSW_G3SG1)|(1<<CSW_SG552)|(1<<CSW_AK47)|(1<<CSW_P90)
	const SECONDARY_WEAPONS_BIT_SUM = (1<<CSW_P228)|(1<<CSW_ELITE)|(1<<CSW_FIVESEVEN)|(1<<CSW_USP)|(1<<CSW_GLOCK18)|(1<<CSW_DEAGLE)

	// Loop through them and drop primaries or secondaries
	for (i = 0; i < num; i++)
	{
		// Prevent re-indexing the array
		weaponid = weapons[i]
		
		if ((dropwhat == 1 && ((1<<weaponid) & PRIMARY_WEAPONS_BIT_SUM)) || (dropwhat == 2 && ((1<<weaponid) & SECONDARY_WEAPONS_BIT_SUM)))
		{
			// Get weapon entity
			static wname[32]; get_weaponname(weaponid, wname, charsmax(wname))
			engclient_cmd(id, "drop", wname)
		}
	}
}
stock MakeEffect(Float:vOrigin[3], Float:vDir[3])
{
	static Float:vEnd[3];
	xs_vec_mul_scalar(vDir, 3.0, vDir);
	xs_vec_add(vOrigin, vDir, vEnd)
	
	message_begin(MSG_BROADCAST, SVC_TEMPENTITY)
	write_byte(15)
	engfunc(EngFunc_WriteCoord, vOrigin[0])
	engfunc(EngFunc_WriteCoord, vOrigin[1])
	engfunc(EngFunc_WriteCoord, vOrigin[2])
	engfunc(EngFunc_WriteCoord, vEnd[0])
	engfunc(EngFunc_WriteCoord, vEnd[1])
	engfunc(EngFunc_WriteCoord, vEnd[2])
	write_short(engfunc(EngFunc_ModelIndex, "sprites/ef_gatlingex_star.spr"))
	write_byte(1)
	write_byte(1)
	write_byte(1)
	write_byte(10)
	write_byte(1)
	message_end()
}
stock Set_WeaponAnim(id, anim)
{
	set_pev(id, pev_weaponanim, anim)
	
	message_begin(MSG_ONE_UNRELIABLE, SVC_WEAPONANIM, {0, 0, 0}, id)
	write_byte(anim)
	write_byte(0)
	message_end()
}
public update_specialammo(id, Ammo, On)
{
	new AmmoSprites[33]
	format(AmmoSprites, sizeof(AmmoSprites), "number_%d", Ammo)
  	
	message_begin(MSG_ONE_UNRELIABLE, get_user_msgid("StatusIcon"), {0,0,0}, id)
	write_byte(On)
	write_string(AmmoSprites)
	write_byte(42) // red
	write_byte(212) // green
	write_byte(255) // blue
	message_end()
}

stock Stock_GetPosition(id, Float:vForward, Float:vSide, Float:vUp, Float:RetValue[3])
{
	new Float:vOrigin[3], Float:vAngle[3], Float:vForwards[3], Float:vRight[3], Float:vUps[3]
	pev(id, pev_origin, vOrigin)
	pev(id, pev_view_ofs, vUps);
	xs_vec_add(vOrigin,vUps,vOrigin)
	pev(id, pev_v_angle, vAngle)
	
	engfunc(EngFunc_AngleVectors, vAngle, vForwards, vRight, vUps);
	
	RetValue[0] = vOrigin[0] + vForwards[0] * vForward + vRight[0] * vSide + vUps[0] * vUp
	RetValue[1] = vOrigin[1] + vForwards[1] * vForward + vRight[1] * vSide + vUps[1] * vUp
	RetValue[2] = vOrigin[2] + vForwards[2] * vForward + vRight[2] * vSide + vUps[2] * vUp
}
public Eject_Shell(iEnt)
{
	static Float:vVelocity[3], Float:vOrigin[3], Float:vPVelocity[3];
	Stock_GetPosition(iEnt, 12.0, 6.0, -2.0, vOrigin)
	Stock_GetPosition(iEnt, 12.0, 8.0, -2.0, vVelocity)
	
	Stock_DirectedVector(vVelocity, vOrigin, vVelocity);
	xs_vec_mul_scalar(vVelocity, 150.0, vVelocity);
	
	pev(iEnt, pev_velocity, vPVelocity);
	xs_vec_add(vVelocity, vPVelocity, vVelocity);
	
	message_begin(MSG_BROADCAST, SVC_TEMPENTITY) 
	write_byte(106)
	engfunc(EngFunc_WriteCoord, vOrigin[0])
	engfunc(EngFunc_WriteCoord, vOrigin[1])
	engfunc(EngFunc_WriteCoord, vOrigin[2])
	engfunc(EngFunc_WriteCoord, vVelocity[0])
	engfunc(EngFunc_WriteCoord, vVelocity[1])
	engfunc(EngFunc_WriteCoord, vVelocity[2])
	write_angle(random(360))
	write_short(engfunc(EngFunc_ModelIndex, "models/shotgunshell.mdl"))
	write_byte(2)
	write_byte(25)
	message_end()
}
stock Stock_DirectedVector(Float:vStart[3],Float:vEnd[3],Float:vOut[3])
{	
	xs_vec_sub(vStart, vEnd, vOut)
	xs_vec_normalize(vOut, vOut)
}
stock update_ammo(id, csw_id, clip, bpammo)
{
	if(!is_user_alive(id))
		return
		
	message_begin(MSG_ONE_UNRELIABLE, get_user_msgid("CurWeapon"), _, id)
	write_byte(1)
	write_byte(csw_id)
	write_byte(clip)
	message_end()
	
	message_begin(MSG_ONE_UNRELIABLE, get_user_msgid("AmmoX"), _, id)
	write_byte(3)
	write_byte(bpammo)
	message_end()
}
/* AMXX-Studio Notes - DO NOT MODIFY BELOW HERE
*{\\ rtf1\\ ansi\\ deff0{\\ fonttbl{\\ f0\\ fnil Tahoma;}}\n\\ viewkind4\\ uc1\\ pard\\ lang1033\\ f0\\ fs16 \n\\ par }
*/
