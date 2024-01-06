#include <amxmodx>
#include <fakemeta>
#include <engine>
#include <cstrike>
#include <csm>
#include <fakemeta_util>
#include <hamsandwich>
#include <zombiemodlimited>
#include <reapi>

#define CSW_USAS CSW_XM1014
#define weapon_usas "weapon_xm1014"

#define Get_BitVar(%1,%2) (%1 & (1 << (%2 & 31)))
#define Set_BitVar(%1,%2) %1 |= (1 << (%2 & 31))
#define UnSet_BitVar(%1,%2) %1 &= ~(1 << (%2 & 31))
new g_HadWpn, g_Attack, g_Event, g_Hit, g_HamBot

new const szUSASModels[3][] = { "models/zbz/wpn/p_kronos12ex.mdl" , "models/zbz/wpn/v_kronos12ex.mdl" , "models/zbz/wpn/w_primgroup1.mdl" }
new const TRACER_ENTITY[][]={ "info_target", "func_breakable", "func_pushable", "func_wall", "func_wall_toggle", "func_door", "func_door_rotating", "weaponbox",
		"func_button", "func_conveyor", "hostage_entity", "func_tank", "func_tankmortar", "func_tanklaser", "func_tankrocket", "button_target"  , "func_train" , "func_tracktrain", "func_vehicle"}
		
new const WeaponSounds[][] =
{
	"weapons/balrog11g-1.wav",
	"weapons/kronos3_beep.wav"
}
public plugin_precache()
{
	for( new i = 0 ; i < 3 ; i ++ )
	{
		engfunc(EngFunc_PrecacheModel, szUSASModels[i])
	}
	
	register_forward(FM_PrecacheEvent, "fw_PrecacheEvent_Post", 1)
	for(new i = 0; i < sizeof(WeaponSounds); i++)
		precache_sound(WeaponSounds[i])
}
public plugin_init()
{
	register_plugin("[Zombie Z] Extra Scorching Auto Shotgun", "1.0", "csbtedhan")
	
	register_forward(FM_SetModel, "fw_SetModel")
	register_forward(FM_UpdateClientData,"fw_UpdateClientData_Post", 1)	
	register_forward(FM_PlaybackEvent, "fw_PlaybackEvent")
	register_forward(FM_CmdStart, "fw_CmdStart");
	
	RegisterHam(Ham_Think, "beam", "BeamTraceThink");
	
	RegisterHam(Ham_TraceAttack, "player", "HamF_TakeDamage", 1)
		
	RegisterHam(Ham_TraceAttack, "worldspawn", "fw_TraceAttack")
	for(new i=0; i<sizeof(TRACER_ENTITY); i++)
		RegisterHam(Ham_TraceAttack, TRACER_ENTITY[i], "fw_TraceAttack")
		
	RegisterHam(Ham_Weapon_PrimaryAttack, weapon_usas, "fw_PrimaryAttack");
	RegisterHam(Ham_Weapon_PrimaryAttack, weapon_usas, "fw_PrimaryAttack_Post", 1);
	RegisterHam(Ham_Item_Deploy, weapon_usas, "fw_Item_Deploy_Post", 1);
	RegisterHam(Ham_Item_Holster, weapon_usas, "fw_Item_Holster");
	RegisterHam(Ham_Item_AddToPlayer, weapon_usas, "fw_Item_AddToPlayer_Post", 1);
	RegisterHam(Ham_Item_PostFrame, weapon_usas, "fw_Item_PostFrame");
	RegisterHam(Ham_Weapon_Reload, weapon_usas, "fw_Weapon_Reload_Post", 1);	
	RegisterHam(Ham_Weapon_WeaponIdle, weapon_usas, "fw_Weapon_WeaponIdle")
	
	register_message(get_user_msgid("DeathMsg"), "message_DeathMsg")
	
	cs_register_custom_item("Scorching Auto Shotgun", 3500, 2, "GiveUsas", "kronos12ex")
}

public fw_PrecacheEvent_Post(type, const name[])
	if(equal("events/xm1014.sc", name)) g_Event = get_orig_retval()
	
public GiveUsas(id)
{
	if(!is_user_alive(id)) return;
	
	drop_weapons(id, 1)
	
	Set_BitVar(g_HadWpn,id)
	UnSet_BitVar(g_Attack,id)
	UnSet_BitVar(g_Hit,id)
	fm_give_item(id, "weapon_xm1014")
	
	new iWpn = get_pdata_cbase(id, 373);
	if(pev_valid(iWpn) && get_pdata_int(iWpn, 43) == CSW_USAS)
		set_pdata_int(iWpn, 51, 30);
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
public message_DeathMsg()
{
	// get value data
	static id, weapon[32]
	id = get_msg_arg_int(1)
	get_msg_arg_string(4, weapon, charsmax(weapon))
	
	if(equal(weapon, "xm1014"))
	{
		if(Get_BitVar(g_HadWpn,id)) set_msg_arg_string(4, "kronos12ex")
	}
		
	return PLUGIN_CONTINUE
}
public fw_Remove_Item(id, itemid, slot)
{
	if(slot == 0)
	{
		UnSet_BitVar(g_HadWpn,id)
		UnSet_BitVar(g_Attack,id)
		UnSet_BitVar(g_Hit,id)
	}
}
public HamF_TakeDamage(iVictim, iAttacker, Float:fDamage, Float:Direction[3], Ptr,  iDamageType)
{	
	if(!is_user_connected(iAttacker) || !Get_BitVar(g_HadWpn, iAttacker) || get_user_weapon(iAttacker) != CSW_USAS) 
		return HAM_IGNORED;
	
	if(Get_BitVar(g_Attack, iAttacker) && is_user_alive(iVictim) && cs_zb_is_zombie(iVictim))
	{
		Set_BitVar(g_Hit,iAttacker)
	}
		
	return HAM_IGNORED;
}
public fw_TraceAttack(Victim, Attacker, Float:Damage, Float:Direction[3], Ptr, DamageBits)
{
	if(!is_user_connected(Attacker))
		return HAM_IGNORED	
	if(get_user_weapon(Attacker) != CSW_USAS || !Get_BitVar(g_HadWpn, Attacker))
		return HAM_IGNORED
		
	static Float:flEnd[3], Float:vecPlane[3], pHit
		
	get_tr2(Ptr, TR_vecEndPos, flEnd)
	get_tr2(Ptr, TR_vecPlaneNormal, vecPlane)
	get_tr2(Ptr, TR_pHit, pHit)
			
	Make_BulletHole(flEnd, pHit)
	
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
				set_pev(weapon, pev_impulse, 2291) 
				set_pev(weapon, pev_iuser1, 0);
				set_pev(weapon, pev_iuser2, 0);
				engfunc(EngFunc_SetModel, entity, szUSASModels[2])
				set_pev(entity, pev_body, 13)
				
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
		return HAM_IGNORED;
	static Id; Id = get_pdata_cbase(Ent, 41, 4)
	if(get_pdata_cbase(Id, 373) != Ent)
		return HAM_IGNORED;
	if(!Get_BitVar(g_HadWpn, Id))
		return HAM_IGNORED;
		
	Set_BitVar(g_Attack,Id)
	if(pev(Ent, pev_iuser2)==2)
	{
		if(get_pdata_int(Ent, 51, 4) > 0)
		{
			new Float:flRecoil[3]; pev(Id, pev_punchangle, flRecoil);
			flRecoil[0] -= 2.0
			set_pev(Id, pev_punchangle, flRecoil);
			
			MakeBurstShot(Id)
			Set_WeaponAnim(Id, 5)
			if(!(pev(Id, pev_flags) & FL_DUCKING)) SetAnimation(Id, "ref_shoot_m249", 1.0)
			else SetAnimation(Id, "crouch_shoot_m249", 1.0)
			set_pdata_float(Ent, 46, 0.3, 4)
			set_pdata_float(Ent, 48, 1.3, 4)
			
			emit_sound(Id, CHAN_WEAPON, WeaponSounds[0], 1.0, 0.6, 0, PITCH_NORM)
			emit_sound(Id, CHAN_ITEM, WeaponSounds[1], 1.0, 0.6, 0, PITCH_NORM)
			Eject_Shell(Id)
			set_pdata_int(Ent, 51, get_pdata_int(Ent, 51, 4) - 1, 4);
		}
		UnSet_BitVar(g_Attack,Id)
		return HAM_SUPERCEDE;
	}
	return HAM_IGNORED;
}

public fw_Item_AddToPlayer_Post(Ent, id)
{
	if(!pev_valid(Ent))
		return HAM_IGNORED
		
	if(pev(Ent, pev_impulse) == 2291)
	{
		Set_BitVar(g_HadWpn, id)
		set_pev(Ent, pev_impulse, 0)	
		
	}
	return HAM_HANDLED
}


public BeamTraceThink( Ent )
{
	if ( !pev_valid( Ent ) || pev( Ent , pev_iuser1 ) != 76253 )
		return HAM_IGNORED;
		
	static Float:flDmgtime; pev( Ent , pev_dmgtime , flDmgtime )
	
	if ( flDmgtime <= get_gametime() )
	{
		engfunc( EngFunc_RemoveEntity , Ent );
		return HAM_IGNORED;
	}
	
	set_pev( Ent , pev_renderamt , floatmin(150.0, floatmax(0.0, (pev(Ent, pev_dmgtime)-get_gametime())*150.0)) );
	set_pev( Ent , pev_nextthink , get_gametime() );
	
	return HAM_IGNORED;
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
			
		if(pev(ent, pev_iuser2) == 2)
			return;
			
		maxclip = 30
		if(cs_get_weapon_ammo(ent) >= maxclip)
		{
			Set_WeaponAnim(id, pev(ent, pev_iuser2))
			return
		}
			
		fw_Weapon_Reload_Post(ent)
	}
	
}
public fw_Item_PostFrame(ent)
{
	static id; id = pev(ent, pev_owner)
	if(!Get_BitVar(g_HadWpn, id)) return
	
	static iBpAmmo ; iBpAmmo = get_pdata_int(id, 381, 5)
	static iClip ; iClip = get_pdata_int(ent, 51, 4)
	static iMaxClip ; iMaxClip = 30

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
	
	if(get_user_button(id) & IN_ATTACK2 && pev(ent, pev_iuser2)==1 && get_pdata_float(ent, 47, 4) <= 0.0)
	{
		Set_WeaponAnim(id, 11)
		set_pdata_float(ent, 46, 0.95, 4)
		set_pdata_float(ent, 47, 0.95, 4)
		set_pdata_float(ent, 48, 1.95, 4)
		
		set_pev(ent, pev_iuser2, 2)
		set_pev(ent, pev_iuser3, 1)
	}
	if(pev(ent, pev_iuser3) == 1 && pev(ent, pev_iuser2) == 2 && get_pdata_float(ent, 47, 4) <= 0.0)
	{
		set_pdata_int(id, 363, 70);
		set_pev(ent, pev_iuser3, 2);
		set_pdata_float(ent, 47, 6.0, 4);
		
		message_begin(MSG_ONE, get_user_msgid("BarTime"), _, id)
		write_short(6)
		message_end()
	}
	if(pev(ent, pev_iuser2)==2 && get_pdata_float(ent, 47, 4) <= 0.0 && pev(ent, pev_iuser3) == 2)
	{
		Set_WeaponAnim(id, 12)
		set_pdata_int(id, 363, 90);
		set_pev(ent, pev_iuser1, 0)
		set_pev(ent, pev_iuser2, 0)
		set_pev(ent, pev_iuser3, 0)
		set_pdata_float(ent, 46, 0.95, 4)
		set_pdata_float(ent, 47, 0.95, 4)
		set_pdata_float(ent, 48, 1.95, 4)
	}
}
public fw_Weapon_Reload_Post(ent)
{
	static id; id = pev(ent, pev_owner)

	if(Get_BitVar(g_HadWpn, id))
	{
		static Float:flTime, CurBpAmmo; CurBpAmmo = cs_get_user_bpammo(id, CSW_USAS)
		
		if(CurBpAmmo  <= 0)
			return HAM_IGNORED

		set_pdata_int(id, 363, 90);
		
		if(pev(ent, pev_iuser2) == 2) set_pev(ent, pev_iuser2, 0)
		set_pev(ent, pev_iuser3, 0)
		flTime = 2.5
		set_pdata_int(ent, 55, 0, 4)
		set_pdata_float(id, 83, flTime, 5)
		set_pdata_float(ent, 48, flTime + 2.5, 4)
		set_pdata_float(ent, 46, flTime + 0.85, 4)
		set_pdata_float(ent, 47, flTime + 0.85, 4)
		set_pdata_int(ent, 54, 1, 4)
		
		Set_WeaponAnim(id, 6 + pev(ent, pev_iuser2))			
		
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
	
	if(Get_BitVar(g_Hit, Id))
	{
		UnSet_BitVar(g_Hit, Id)
		if(pev(Ent, pev_iuser2) == 0)
		{
			set_pev(Ent, pev_iuser1, pev(Ent, pev_iuser1) + 1)
			if(pev(Ent, pev_iuser1) >= 15)
			{
				set_pev(Ent, pev_iuser1, 0)
				set_pev(Ent, pev_iuser2, 1)
				Set_WeaponAnim(Id, 10)
				set_pdata_float(Ent, 48, 1.0, 4);
			}
		}
	}
	UnSet_BitVar(g_Attack,Id)
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
	
	if(pev(Ent, pev_iuser2) == 2)
	{
		set_pev(Ent, pev_iuser2, 0)
		set_pev(Ent, pev_iuser3, 0)
		set_pdata_int(Id, 363, 90);
	}
	
	Set_WeaponAnim(Id, 8 + pev(Ent, pev_iuser2))
}

public fw_Item_Holster(Ent)
{
	if(pev_valid(Ent) != 2)
		return HAM_IGNORED;
	static Id; Id = get_pdata_cbase(Ent, 41, 4)
	if(get_pdata_cbase(Id, 373) != Ent)
		return HAM_IGNORED;
	if(!Get_BitVar(g_HadWpn, Id))
		return HAM_IGNORED;
	
	if(pev(Ent, pev_iuser2) == 2)
	{
		set_pev(Ent, pev_iuser2, 0)
		set_pev(Ent, pev_iuser3, 0)
	}
	set_pdata_int(Id, 363, 90);
	return HAM_IGNORED;
}
public fw_Weapon_WeaponIdle( iEnt )
{
	if(pev_valid(iEnt) != 2)
		return HAM_IGNORED
	static id; id = get_pdata_cbase(iEnt, 41, 4)
	if(get_pdata_cbase(id, 373) != iEnt)
		return HAM_IGNORED
	if( get_pdata_float(iEnt, 48, 4) > 0.0 )
		return HAM_IGNORED
		
	if(!Get_BitVar(g_HadWpn, id))
		return HAM_IGNORED
		
	new iMode = pev(iEnt, pev_iuser2)
	
	if(get_pdata_float(iEnt, 48, 4) <= 0.1)
	{
		Set_WeaponAnim(id, iMode)
		set_pdata_float(iEnt, 48, 20.0, 4)
		return HAM_HANDLED
	}
	return HAM_IGNORED
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
	
	new iWpn = get_pdata_cbase(invoker, 373);
	if(!pev_valid(iWpn)) return FMRES_IGNORED
	
	new Float:origin[3]; pev(invoker, pev_origin, origin)
	Set_WeaponAnim(invoker, 3 + pev(iWpn, pev_iuser2))
	emit_sound(invoker, CHAN_WEAPON, WeaponSounds[0], 1.0, 0.6, 0, PITCH_NORM)
	
	Eject_Shell(invoker)
	
	return FMRES_SUPERCEDE
}
stock MakeBurstShot(id)
{
	new Float:vOrigin[3], Float:vUp[3], Float:pOrigin[3], Float:vDir[3], Float:vDist[3], Float:vEnd[3];
	pev(id, pev_origin, vOrigin);
	pev(id, pev_view_ofs, vUp)
	xs_vec_add(vOrigin, vUp, vOrigin);
	
	new Float:flFract, iTotal = 0
	new tr = create_tr2();
	
	for(new x = 0; x < get_maxplayers(); x ++ )
	{
		if(!is_user_connected(x) || !is_user_alive(x) || !cs_zb_is_zombie(x))
			continue;
		
		pev(x, pev_origin, pOrigin);
		if(!is_in_viewcone(id, pOrigin, 1) || !isClearLine(vOrigin, pOrigin))
			continue;
			
		xs_vec_sub(pOrigin, vOrigin, vDir);
		xs_vec_normalize(vDir, vDir);
		
		xs_vec_mul_scalar(vDir, 8192.0, vDist);
		xs_vec_add(vOrigin, vDist, vEnd);
		engfunc(EngFunc_TraceLine, vOrigin, vEnd, 0, id, tr);
		get_tr2(tr, TR_flFraction, flFract)
		if(flFract < 1.0)
		{
			rg_multidmg_clear()
			ExecuteHamB(Ham_TraceAttack, x, id, 515.0, vDir, tr, DMG_BULLET)
			rg_multidmg_apply(id, id)
		}
		Stock_DrawBeam(vOrigin, pOrigin)
		iTotal ++
	}
	free_tr2(tr);
	
	return iTotal
}
stock isClearLine(Float:vOrigin1[3], Float:vOrigin2[3])
{
	new Float:flFraction;
	engfunc(EngFunc_TraceLine, vOrigin1, vOrigin2, IGNORE_MONSTERS|IGNORE_GLASS, 0, 0);
	get_tr2(0, TR_flFraction, flFraction)
	
	if (flFraction < 1.0) return 0;

	return 1;
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
stock Set_WeaponAnim(id, anim)
{
	set_pev(id, pev_weaponanim, anim)
	
	message_begin(MSG_ONE_UNRELIABLE, SVC_WEAPONANIM, {0, 0, 0}, id)
	write_byte(anim)
	write_byte(0)
	message_end()
}

stock Stock_DrawBeam(Float:vStart[3], Float:vEnd[3])
{
	new Float: flMins[3];
	new Float: flMaxs[3];
	
	static iBeamEntity; iBeamEntity = engfunc(EngFunc_CreateNamedEntity, engfunc(EngFunc_AllocString, "beam"));
	set_pev(iBeamEntity, pev_flags, pev(iBeamEntity, pev_flags) | FL_CUSTOMENTITY);
	set_pev(iBeamEntity, pev_skin, 0);
	set_pev(iBeamEntity, pev_sequence, 0);
	
	set_pev(iBeamEntity, pev_origin, vStart);
	set_pev(iBeamEntity, pev_angles, vEnd);
	set_pev(iBeamEntity, pev_modelindex, engfunc(EngFunc_ModelIndex, "sprites/smoke.spr"))
	set_pev(iBeamEntity, pev_scale, 6.0);
	set_pev(iBeamEntity, pev_rendercolor, Float: { 224.0 , 224.0 , 255.0 } );
	set_pev(iBeamEntity, pev_renderamt, 150.0);
	set_pev(iBeamEntity, pev_iuser1, 76253);
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
	
	set_pev(iBeamEntity, pev_nextthink, get_gametime() + 0.5);
	set_pev(iBeamEntity, pev_dmgtime, get_gametime() + 1.5);
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
stock SetAnimation(id, const AnimName[], Float:rate=1.0)
{
	static AnimNum, Float:FrameRate, Float:GroundSpeed, bool:Loops
	if ((AnimNum=lookup_sequence(id,AnimName,FrameRate,Loops,GroundSpeed))==-1) AnimNum=0

	if (!Loops || (Loops && pev(id,pev_sequence)!=AnimNum))
	{
		set_pev(id, pev_gaitsequence, AnimNum)
		set_pev(id, pev_sequence, AnimNum)
		set_pev(id, pev_frame, 0.0)
		set_pev(id, pev_animtime, get_gametime())
	}
	set_pev(id, pev_framerate, rate)

	set_pdata_int(id, 40, Loops, 4)
	set_pdata_int(id, 39, 0, 4)

	set_pdata_float(id, 36, FrameRate, 4)
	set_pdata_float(id, 37, GroundSpeed, 4)
	set_pdata_float(id, 38, get_gametime(), 4)

	set_pdata_int(id, 73, 28, 5)
	set_pdata_int(id, 74, 28, 5)
	set_pdata_float(id, 220, get_gametime(), 5)
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
*{\\ rtf1\\ ansi\\ deff0{\\ fonttbl{\\ f0\\ fnil Tahoma;}}\n\\ viewkind4\\ uc1\\ pard\\ lang1066\\ f0\\ fs16 \n\\ par }
*/