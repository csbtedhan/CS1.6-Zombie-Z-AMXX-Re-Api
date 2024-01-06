
#include < amxmodx >
#include < fakemeta_util >
#include < hamsandwich >
#include < cstrike >
#include < csm >
#include < engine >
#include < zombiemodlimited >

#define V_MODEL "models/zbz/wpn/v_sgmissilepaintgs18.mdl"
#define P_MODEL "models/zbz/wpn/p_sgmissilepaintgs18_a.mdl"
#define P_MODEL2 "models/zbz/wpn/p_sgmissilepaintgs18_b.mdl"
#define W_MODEL "models/zbz/wpn/w_primgroup2.mdl"
#define SHELL_MODEL "models/zbz/wpn/shell_sgdrill.mdl"

#define CSW_SGMISSILE 	CSW_XM1014
#define weapon_sgmissile 	"weapon_xm1014"
#define FireClassname		"sgmissile_missile"

new const WeaponSounds[][] = 
{
	"weapons/sgmissile-1.wav",
	"weapons/sgmissile-2.wav",
	"weapons/sgmissile_exp.wav",
	"weapons/sgmissile_reload.wav"
}

new const szFlameModel[] = "sprites/ef_sgmissile_line.spr"

new const TRACER_ENTITY[][]={ "info_target", "func_breakable", "func_pushable", "func_wall", "func_wall_toggle", "func_door", "func_door_rotating",
		"func_button", "func_conveyor", "hostage_entity", "func_tank", "func_tankmortar", "func_tanklaser", "func_tankrocket", "button_target" }
		
new cvar_effect

#define Get_BitVar(%1,%2) (%1 & (1 << (%2 & 31)))
#define Set_BitVar(%1,%2) %1 |= (1 << (%2 & 31))
#define UnSet_BitVar(%1,%2) %1 &= ~(1 << (%2 & 31))
new g_HadWpn, g_Event, Float:g_flFiretime[8192]

public plugin_precache()
{
	engfunc(EngFunc_PrecacheModel, V_MODEL)
	engfunc(EngFunc_PrecacheModel, P_MODEL)
	engfunc(EngFunc_PrecacheModel, P_MODEL2)
	engfunc(EngFunc_PrecacheModel, W_MODEL)
	engfunc(EngFunc_PrecacheModel, SHELL_MODEL)
	engfunc(EngFunc_PrecacheModel, szFlameModel)
	
	engfunc(EngFunc_PrecacheModel, "sprites/ef_sgmissile.spr")
	
	register_forward(FM_PrecacheEvent, "fw_PrecacheEvent_Post", 1)
	for(new i = 0; i < sizeof(WeaponSounds); i++)
		engfunc(EngFunc_PrecacheSound, WeaponSounds[i])
}

public plugin_init()
{
	register_plugin("[Zombie Z] Magnum Launcher", "1.0", "csbtedhan")
	
	register_forward(FM_SetModel, "fw_SetModel")
	register_forward(FM_UpdateClientData,"fw_UpdateClientData_Post", 1)	
	register_forward(FM_PlaybackEvent, "fw_PlaybackEvent")
	register_forward(FM_CmdStart, "fw_CmdStart");
	register_forward(FM_StartFrame, "fw_ServerFrame");
	
	RegisterHam(Ham_Think, "info_target", "fw_Think");
	RegisterHam(Ham_Touch, "info_target", "fw_Touch");
	RegisterHam(Ham_TraceAttack, "player", "fw_TakeDamage")
	RegisterHam(Ham_TraceAttack, "worldspawn", "fw_TraceAttack")
	for(new i=0; i<sizeof(TRACER_ENTITY); i++)
		RegisterHam(Ham_TraceAttack, TRACER_ENTITY[i], "fw_TraceAttack")
		
	RegisterHam(Ham_Item_Deploy, weapon_sgmissile, "fw_Item_Deploy_Post", 1);
	RegisterHam(Ham_Item_AddToPlayer, weapon_sgmissile, "fw_Item_AddToPlayer_Post", 1);
	RegisterHam(Ham_Weapon_WeaponIdle, weapon_sgmissile, "fw_Weapon_WeaponIdle")	
	RegisterHam(Ham_Weapon_Reload, weapon_sgmissile, "fw_Weapon_Reload_Post", 1);	
	RegisterHam(Ham_Item_PostFrame, weapon_sgmissile, "fw_Item_PostFrame");
	
	register_message(get_user_msgid("DeathMsg"), "message_DeathMsg")
	
	cvar_effect = register_cvar("sv_sgmissile_full_effect", "0")
	
	cs_register_custom_item("Magnum Launcher", 6500, 2, "GiveBalrog11", "sgmissile")
}

public fw_PrecacheEvent_Post(type, const name[])
	if(equal("events/xm1014.sc", name)) g_Event = get_orig_retval()
	
public fw_Remove_Item(id, itemid, slot)
{
	if(slot == 0) RemoveBalrog11(id)
}
public client_disconnected(id) RemoveBalrog11(id)
public RemoveBalrog11(id)
{
	UnSet_BitVar(g_HadWpn,id)
}
public GiveBalrog11(id)
{
	if(!is_user_alive(id)) return;
	
	drop_weapons(id, 1)
	
	Set_BitVar(g_HadWpn,id)
	fm_give_item(id, "weapon_xm1014")
	new iWpn = get_pdata_cbase(id, 373);
	if(pev_valid(iWpn) && get_pdata_int(iWpn, 43) == CSW_SGMISSILE)
	{
		set_pdata_int(iWpn, 51, 30);
		set_pev(iWpn, pev_iuser1, 0);
		set_pev(iWpn, pev_fuser1, get_gametime() + 4.0);
	}
}
public fw_CSHUD(id)
{
	if(get_user_weapon(id) != CSW_SGMISSILE || !Get_BitVar(g_HadWpn, id) || cs_zb_is_zombie(id) || !is_user_alive(id))
		return
	
	new pEnt = get_pdata_cbase(id, 373)
	if(!pev_valid(pEnt))
		return
	
	if(pev(pEnt, pev_iuser1))
	{
		set_dhudmessage(100, 100, 255, 0.85, 0.95, 0, 0.0, 0.2, 0.0, 0.0);
		show_dhudmessage(id, "%i", pev(pEnt, pev_iuser1))
	}
}
public message_DeathMsg()
{
	// get value data
	new killer, weapon[32]
	killer = get_msg_arg_int(1)
	get_msg_arg_string(4, weapon, charsmax(weapon))
	
	if((Get_BitVar(g_HadWpn, killer) && equal(weapon, "xm1014")))
		set_msg_arg_string(4, "sgmissile")
		
	return PLUGIN_CONTINUE
}

public fw_Item_AddToPlayer_Post(Ent, id)
{
	if(!pev_valid(Ent))
		return HAM_IGNORED
		
	if(pev(Ent, pev_impulse) == 2532)
	{
		Set_BitVar(g_HadWpn, id)
		set_pev(Ent, pev_impulse, 0)
	}
		
	return HAM_HANDLED
}

public fw_TakeDamage(Victim, Attacker, Float:Damage, Float:Direction[3], Ptr, DamageBits)
{
	if(!is_user_connected(Attacker))
		return HAM_IGNORED	
	if(get_user_weapon(Attacker) != CSW_SGMISSILE)
		return HAM_IGNORED
		
	SetHamParamFloat(3, 60.0);
	return HAM_HANDLED;
}
public fw_TraceAttack(Victim, Attacker, Float:Damage, Float:Direction[3], Ptr, DamageBits)
{
	if(!is_user_connected(Attacker))
		return HAM_IGNORED	
	if(get_user_weapon(Attacker) != CSW_SGMISSILE || !Get_BitVar(g_HadWpn, Attacker))
		return HAM_IGNORED
		
	new Float:flEnd[3], Float:vecPlane[3], pHit
		
	get_tr2(Ptr, TR_vecEndPos, flEnd)
	get_tr2(Ptr, TR_vecPlaneNormal, vecPlane)
	get_tr2(Ptr, TR_pHit, pHit)
			
	Make_BulletHole(flEnd, pHit)
	
	return HAM_IGNORED
}

public fw_CmdStart(id, uc_handle, seed)
{
	if(!is_user_alive(id))
		return
		
	if(!Get_BitVar(g_HadWpn, id))
		return
		
	static CurButton; CurButton = get_uc(uc_handle, UC_Buttons)
	static maxclip, ent; ent = fm_get_user_weapon_entity(id, CSW_SGMISSILE)
	if(!pev_valid(ent)) return
		
	if(get_user_weapon(id) == CSW_SGMISSILE)
	{
		if(CurButton & IN_ATTACK2 && get_pdata_float(ent, 47, 4) <= 0.0 && pev(ent, pev_iuser1) > 0) 
		{
			SpecialShoot_Handle(id)
		} 
		if(CurButton & IN_RELOAD)
		{
			CurButton &= ~IN_RELOAD
			set_uc(uc_handle, UC_Buttons, CurButton)
			
			static fInReload; fInReload = get_pdata_int(ent, 54, 4)
			static Float:flNextAttack; flNextAttack = get_pdata_float(id, 83, 5)
			
			if (flNextAttack > 0.0)
				return
				
			if (fInReload)
				return
				
			maxclip = 30
			if(cs_get_weapon_ammo(ent) >= maxclip)
			{
				Set_WeaponAnim(id, 0)
				return
			}
				
			fw_Weapon_Reload_Post(ent)
		}
	} else {
		if(pev(ent, pev_iuser1) < 10 && pev(ent, pev_fuser1) <= get_gametime())
		{
			set_pev(ent, pev_iuser1, pev(ent, pev_iuser1) + 1);
			set_pev(ent, pev_fuser1, get_gametime() + 2.0);
		}
	}
}
public fw_ServerFrame()
{
	new Ent, pEnt = -1
	while((pEnt = engfunc(EngFunc_FindEntityByString, pEnt, "classname", "weaponbox")) != 0)
	{
		if(!isMagnumBox(pEnt)) continue;
		
		Ent = find_ent_by_owner(-1, weapon_sgmissile, pEnt)
		if(pev(Ent, pev_fuser1) <= get_gametime() && pev(Ent, pev_iuser1) < 10)
		{
			set_pev(Ent, pev_fuser1, get_gametime() + 2.0);
			set_pev(Ent, pev_iuser1, pev(Ent, pev_iuser1) + 1)
		}
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
	
		update_ammo(id, CSW_SGMISSILE, cs_get_weapon_ammo(ent), cs_get_user_bpammo(id, CSW_SGMISSILE))
	
		return
	}
	
	if(pev(ent, pev_iuser1) < 10 && pev(ent, pev_fuser1) <= get_gametime())
	{
		if(pev(ent, pev_iuser1) < 1)
		{
			set_pev(id, pev_weaponmodel2, P_MODEL2)
			Set_WeaponAnim(id, 11);
			set_pdata_float(ent, 46, 0.75, 4);
			set_pdata_float(ent, 47, 0.75, 4);
			set_pdata_float(ent, 48, 1.0, 4);
		}
		client_cmd(id, "spk weapons/sgmissile_reload.wav")
		set_pev(ent, pev_iuser1, pev(ent, pev_iuser1) + 1);
		set_pev(ent, pev_fuser1, get_gametime() + 2.0);
	}
}
public fw_Weapon_Reload_Post(ent)
{
	static id; id = pev(ent, pev_owner)

	if(Get_BitVar(g_HadWpn, id))
	{
		static Float:flTime, CurBpAmmo; CurBpAmmo = cs_get_user_bpammo(id, CSW_SGMISSILE)
		
		if(CurBpAmmo  <= 0)
			return HAM_IGNORED

		flTime = 1.1
		set_pdata_int(ent, 55, 0, 4)
		set_pdata_float(id, 83, flTime, 5)
		set_pdata_float(ent, 48, flTime + 2.5, 4)
		set_pdata_float(ent, 46, flTime + 0.85, 4)
		set_pdata_float(ent, 47, flTime + 0.85, 4)
		set_pev(ent, pev_fuser1, get_gametime() + 3.0);
		set_pdata_int(ent, 54, 1, 4)
		
		Set_WeaponAnim(id, pev(ent, pev_iuser1) ?5 : 1)			
		
		return HAM_HANDLED
	}
	
	return HAM_IGNORED	
}
public fw_Think(Ent)
{
	if(!isBalrogFire(Ent))
		return
		
	new Type; Type = pev(Ent, pev_iuser1)
	if(Type) FireThink(Ent)
	else FireSystemThink(Ent)
}

public fw_Touch(ent, id)
{
	if(!isBalrogFire(ent))
		return
	if(isBalrogFire(id)) 
		return;

	new pevAttacker = pev(ent, pev_owner);
	new Float:vVel[3], Float:vDir[3], Float:vOrigin[3]; pev(ent, pev_origin, vOrigin);
	
	message_begin(MSG_BROADCAST, SVC_TEMPENTITY)
	write_byte(TE_EXPLOSION)
	engfunc(EngFunc_WriteCoord, vOrigin[0])
	engfunc(EngFunc_WriteCoord, vOrigin[1])
	engfunc(EngFunc_WriteCoord, vOrigin[2])
	write_short(engfunc(EngFunc_ModelIndex, "sprites/ef_sgmissile.spr"))
	write_byte(5)
	write_byte(20)
	write_byte(14)
	message_end()
	
	if(pev_valid(id) && is_user_alive(id) && cs_zb_is_zombie(id))
	{
		pev(ent, pev_velocity, vVel);
		pev(id, pev_velocity, vDir)
		xs_vec_add(vVel, vDir, vVel);
		set_pev(id, pev_velocity, vVel);
	}
	
	DoRadiusDamage(pevAttacker, ent, vOrigin, 400.0, 100.0);
	engfunc(EngFunc_EmitAmbientSound, ent, vOrigin, WeaponSounds[2], 0.4, 0.8, 0, 100 + random_num(-5, 10));
	engfunc(EngFunc_RemoveEntity, ent);
}

public fw_SetModel(entity, model[])
{
	if(!pev_valid(entity))
		return FMRES_IGNORED
	
	new Classname[32]
	pev(entity, pev_classname, Classname, sizeof(Classname))
	
	if(!equal(Classname, "weaponbox"))
		return FMRES_IGNORED
	
	new iOwner
	iOwner = pev(entity, pev_owner)
	
	if(equal(model, "models/w_xm1014.mdl"))
	{
		new weapon; weapon = find_ent_by_owner(-1, weapon_sgmissile, entity)
		if(Get_BitVar(g_HadWpn, iOwner) && pev_valid(weapon))
		{
			set_pev(weapon, pev_impulse, 2532)
			engfunc(EngFunc_SetModel, entity, W_MODEL)
			set_pev(entity, pev_body, 7);
			UnSet_BitVar(g_HadWpn,iOwner)
			
			return FMRES_SUPERCEDE
		}
	}

	return FMRES_IGNORED;
}

public fw_UpdateClientData_Post(id, sendweapons, cd_handle)
{
	if(!is_user_alive(id))
		return FMRES_IGNORED	
	if(get_user_weapon(id) == CSW_SGMISSILE && Get_BitVar(g_HadWpn, id))
	{
		set_cd(cd_handle, CD_flNextAttack, get_gametime() + 0.001) 
		return FMRES_HANDLED
	}
	return FMRES_IGNORED	
}

public fw_PlaybackEvent(flags, invoker, eventid, Float:delay, Float:origin[3], Float:angles[3], Float:fparam1, Float:fparam2, iParam1, iParam2, bParam1, bParam2)
{
	if (!is_user_connected(invoker))
		return FMRES_IGNORED	
	if(get_user_weapon(invoker) != CSW_SGMISSILE || !Get_BitVar(g_HadWpn, invoker))
		return FMRES_IGNORED
	if(eventid != g_Event)
		return FMRES_IGNORED
	
	engfunc(EngFunc_PlaybackEvent, flags | FEV_HOSTONLY, invoker, eventid, delay, origin, angles, fparam1, fparam2, iParam1, iParam2, bParam1, bParam2)
	
	new pEnt = get_pdata_cbase(invoker, 373)
	if(!pev_valid(pEnt))
		return FMRES_IGNORED
	
	Set_WeaponAnim(invoker, pev(pEnt, pev_iuser1) ? random_num(7,8) : 3)
	emit_sound(invoker, CHAN_WEAPON, WeaponSounds[0], 1.0, 0.5, 0, PITCH_NORM)
	Eject_Shell(invoker)
	
	return FMRES_SUPERCEDE
}
public fw_Weapon_WeaponIdle( iEnt )
{
	if(pev_valid(iEnt) != 2)
		return HAM_IGNORED
	new id; id = get_pdata_cbase(iEnt, 41, 4)
	if(get_pdata_cbase(id, 373) != iEnt)
		return HAM_IGNORED
	if( get_pdata_float(iEnt, 48, 4) > 0.0 )
		return HAM_IGNORED
		
	if(!Get_BitVar(g_HadWpn, id))
		return HAM_IGNORED
	
	Set_WeaponAnim(id, pev(iEnt, pev_iuser1) ? 4 : 0)
	set_pdata_float(iEnt, 48, 10.0, 4);
	
	return HAM_HANDLED
}

public fw_Item_Deploy_Post(Ent)
{
	if(pev_valid(Ent) != 2)
		return
	new Id; Id = get_pdata_cbase(Ent, 41, 4)
	if(get_pdata_cbase(Id, 373) != Ent)
		return
	if(!Get_BitVar(g_HadWpn, Id))
		return
		
	set_pev(Id, pev_viewmodel2, V_MODEL)
	set_pev(Id, pev_weaponmodel2, pev(Ent, pev_iuser1) ? P_MODEL2 : P_MODEL)
	
	Set_WeaponAnim(Id, pev(Ent, pev_iuser1) ? 6 : 2);
}

public SpecialShoot_Handle(id)
{
	new pEnt = get_pdata_cbase(id, 373)
	if(!pev_valid(pEnt))
		return
	if(get_pdata_float(pEnt, 47, 4) > 0.0)
		return
	if(pev(pEnt, pev_iuser1) <= 0)
		return		
	// Shoot Handle
	set_pdata_float(pEnt, 46, 0.35, 4)
	set_pdata_float(pEnt, 47, 0.5, 4)
	set_pdata_float(pEnt, 48, 1.35, 4)
	set_pev(pEnt, pev_fuser1, get_gametime() + 4.0);
	
	Stock_SetPlayerAnim(id, "shoot_m249")
	set_pev(pEnt, pev_iuser1, pev(pEnt, pev_iuser1)-1)
	
	set_pev(id, pev_weaponmodel2, pev(pEnt, pev_iuser1) ? P_MODEL2 : P_MODEL)
	Set_WeaponAnim(id, pev(pEnt, pev_iuser1) <= 0 ? 10 : 9)
	emit_sound(id, CHAN_WEAPON, WeaponSounds[1], 1.0, 0.6, 0, PITCH_NORM)
	
	Create_FireSystem(id)
}
public FireSystemThink(Ent)
{
	new Float:Origin[3], Float:Scale;
		
	new id = pev(Ent, pev_owner)
	if(cs_zb_is_zombie(id) || !is_user_alive(id) || !is_user_connected(id))
	{
		engfunc(EngFunc_RemoveEntity, Ent)
		return;
	}
	
	pev(Ent, pev_origin, Origin)
	pev(Ent, pev_scale, Scale)
		
	Scale += 0.12 
	Scale = floatmin(1.0, Scale)
	set_pev(Ent, pev_scale, Scale)
	
	if(get_pcvar_num(cvar_effect)) Create_Fire(Origin, Scale*0.4, random_float(9.0,11.0))
		
	set_pev(Ent, pev_nextthink, get_gametime()+0.05)
	
	// time remove
	if(get_gametime() >= g_flFiretime[Ent]) engfunc(EngFunc_RemoveEntity, Ent)
}
public FireThink(Ent)
{
	new Float:avel[3]
	pev(Ent, pev_avelocity, avel)
	avel[2] = random_num(0, 1) == 1 ? -1400.0 : 1400.0
	if(avel[2] == 0.0) set_pev(Ent, pev_avelocity, avel)
	
	set_pev(Ent, pev_renderamt, floatmin(85.0, floatmax(0.0, (g_flFiretime[Ent]-get_gametime())*85.0)))
	
	if(g_flFiretime[Ent] <= get_gametime()) 
	{
		engfunc(EngFunc_RemoveEntity, Ent)
		return;
	}
	set_pev(Ent, pev_nextthink, get_gametime())
}

public Create_FireSystem(id)
{
	new Float:vOrigin[3], Float:StartOrigin[3], Float:EndOrigin[10][3], Float:flLeft
	get_position(id, 0.0, 0.0, 0.0, vOrigin)
	flLeft = 5.0
	// Left
	get_position(id, 512.0, -200.0, 0.0, EndOrigin[0])
	get_position(id, 512.0, -160.0, 0.0, EndOrigin[1])
	get_position(id, 512.0, -120.0, 0.0, EndOrigin[2])
	get_position(id, 512.0, -80.0, 0.0, EndOrigin[3])
	get_position(id, 512.0, -20.0, 0.0, EndOrigin[4])
	
	// Right
	get_position(id, 512.0, 20.0, 0.0, EndOrigin[5])
	get_position(id, 512.0, 80.0, 0.0, EndOrigin[6])	
	get_position(id, 512.0, 120.0, 0.0, EndOrigin[7])	
	get_position(id, 512.0, 160.0, 0.0, EndOrigin[8])	
	get_position(id, 512.0, 200.0, 0.0, EndOrigin[9])	
	
	// Create Fire
	for(new i = 0; i < 10; i++) 
	{
		get_position(id, 30.0, flLeft, 0.0, StartOrigin)
		engfunc(EngFunc_TraceLine, vOrigin, StartOrigin, 0, id, 0)
		get_tr2(0, TR_vecEndPos, StartOrigin)
		Create_System(id, StartOrigin, EndOrigin[i], 1000.0)
		flLeft -= 1.0
	}
}

public Create_System(id, Float:StartOrigin[3], Float:EndOrigin[3], Float:Speed)
{
	new Ent; Ent = engfunc(EngFunc_CreateNamedEntity, engfunc(EngFunc_AllocString, "info_target"))
	
	// set info for ent
	set_pev(Ent, pev_movetype, MOVETYPE_FLY)
	set_pev(Ent, pev_rendermode, kRenderTransAdd)
	set_pev(Ent, pev_renderamt, 60.0)
	g_flFiretime[Ent] = get_gametime() + 0.7;	// time remove
	set_pev(Ent, pev_scale, 0.1)
	set_pev(Ent, pev_nextthink, get_gametime() + 0.05)
	
	set_pev(Ent, pev_classname, FireClassname)
	engfunc(EngFunc_SetModel, Ent, szFlameModel)
	set_pev(Ent, pev_mins, Float:{-1.0, -1.0, -1.0})
	set_pev(Ent, pev_maxs, Float:{1.0, 1.0, 1.0})
	set_pev(Ent, pev_origin, StartOrigin)
	set_pev(Ent, pev_solid, SOLID_TRIGGER)
	set_pev(Ent, pev_owner, id)
	set_pev(Ent, pev_frame, 1.0)

	new Float:Velocity[3]
	
	get_speed_vector(StartOrigin, EndOrigin, Speed, Velocity)
	set_pev(Ent, pev_velocity, Velocity)		
}

public Create_Fire(Float:Origin[3], Float:Scale, Float:Frame)
{
	new Ent; Ent = engfunc(EngFunc_CreateNamedEntity, engfunc(EngFunc_AllocString, "info_target"))
	
	// set info for ent
	set_pev(Ent, pev_movetype, MOVETYPE_FLY)
	set_pev(Ent, pev_rendermode, kRenderTransAdd)
	set_pev(Ent, pev_renderamt, 60.0)
	set_pev(Ent, pev_scale, Scale)
	set_pev(Ent, pev_nextthink, get_gametime())
	
	g_flFiretime[Ent] = get_gametime() + 0.5;
	
	set_pev(Ent, pev_classname, FireClassname)
	engfunc(EngFunc_SetModel, Ent, szFlameModel)
	set_pev(Ent, pev_origin, Origin)
	set_pev(Ent, pev_frame, Frame)
	set_pev(Ent, pev_iuser1, 1)
	
	new Float:avel[3]
	avel[2] = random_num(0, 1) == 1 ? -1400.0 : 1400.0
	set_pev(Ent, pev_avelocity, avel)
}
stock DoRadiusDamage(pevAttacker, pevInflictor, Float:vOrigin[3], Float:flMaxDamage, Float:flRadius)
{
	if(!pev_valid(pevAttacker)) return;
	
	static Float:vDir[3], Float:vVel[3],  Float:xOrigin[3], Float:pOrigin[3], pEnt; pEnt = -1
	pev(pevAttacker, pev_origin, xOrigin)
	while((pEnt = engfunc(EngFunc_FindEntityInSphere, pEnt, vOrigin, flRadius)) != 0)
	{
		if(!pev_valid(pEnt) || pEnt == pevAttacker) continue;
		
		pev(pEnt, pev_origin, pOrigin)
		if(!isClearLine(pOrigin, vOrigin)) flMaxDamage *= 0.6;
		
		if(pev(pEnt, pev_health) > 0.0 && pev(pEnt, pev_takedamage) > 0.0)
		{
			ExecuteHamB(Ham_TakeDamage, pEnt, pevInflictor, pevAttacker, flMaxDamage, isBreakable(pEnt) ? DMG_BLAST : DMG_CLUB);
			if(is_user_alive(pEnt) && cs_zb_is_zombie(pEnt))
			{
				xs_vec_sub(pOrigin, xOrigin, vDir);
				xs_vec_normalize(vDir, vDir);
				xs_vec_mul_scalar(vDir, flMaxDamage * 0.7, vDir);
				pev(pEnt, pev_velocity, vVel);
				xs_vec_add(vVel, vDir, vVel);
				set_pev(pEnt, pev_velocity, vVel);
			}
		}
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
	
	new szClassname[32]
	pev(iEnt, pev_classname, szClassname, charsmax(szClassname))
	if (equal(szClassname, "func_breakable") || equal(szClassname, "func_pushable")) return 1;
	return 0;
}
stock isMagnumBox(iEnt)
{
	if (!pev_valid(iEnt)) return 0;
	
	new szClassname[32], weapon = find_ent_by_owner(-1, weapon_sgmissile, iEnt)
	pev(iEnt, pev_classname, szClassname, charsmax(szClassname))
	if (equal(szClassname, "weaponbox") && pev_valid(weapon)) return 1;
	return 0;
}
stock isBalrogFire(iEnt)
{
	if (!pev_valid(iEnt)) return 0;
	
	new szClassname[32]
	pev(iEnt, pev_classname, szClassname, charsmax(szClassname))
	if (equal(szClassname, FireClassname)) return 1;
	return 0;
}

public Eject_Shell(iEnt)
{
	static Float:vVelocity[3], Float:vOrigin[3], Float:vPVelocity[3];
	get_position(iEnt, 12.0, 6.0, -2.0, vOrigin)
	get_position(iEnt, 12.0, 8.0, -2.0, vVelocity)
	
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
	write_short(engfunc(EngFunc_ModelIndex, SHELL_MODEL))
	write_byte(2)
	write_byte(25)
	message_end()
}
stock Stock_DirectedVector(Float:vStart[3],Float:vEnd[3],Float:vOut[3])
{	
	xs_vec_sub(vStart, vEnd, vOut)
	xs_vec_normalize(vOut, vOut)
}
stock Make_BulletHole(Float:vecOrigin[3], iEnt)
{
	new szName[16]
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

stock get_position(id,Float:forw, Float:right, Float:up, Float:vStart[])
{
	new Float:vOrigin[3], Float:vAngle[3], Float:vForward[3], Float:vRight[3], Float:vUp[3]
	
	pev(id, pev_origin, vOrigin)
	pev(id, pev_view_ofs, vUp) //for player
	xs_vec_add(vOrigin, vUp, vOrigin)
	pev(id, pev_v_angle, vAngle) // if normal entity ,use pev_angles
	
	angle_vector(vAngle,ANGLEVECTOR_FORWARD, vForward) //or use EngFunc_AngleVectors
	angle_vector(vAngle,ANGLEVECTOR_RIGHT, vRight)
	angle_vector(vAngle,ANGLEVECTOR_UP, vUp)
	
	vStart[0] = vOrigin[0] + vForward[0] * forw + vRight[0] * right + vUp[0] * up
	vStart[1] = vOrigin[1] + vForward[1] * forw + vRight[1] * right + vUp[1] * up
	vStart[2] = vOrigin[2] + vForward[2] * forw + vRight[2] * right + vUp[2] * up
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
stock drop_weapons(id, dropwhat)
{
	// Get user weapons
	new weapons[32], num, i, weaponid
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
			new wname[32]; get_weaponname(weaponid, wname, charsmax(wname))
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

stock Stock_SetPlayerAnim(id, const AnimName[], Float:rate=1.0)
{
	static AnimNum, Float:FrameRate, Float:GroundSpeed, bool:Loops, Anim2[64]
	if(!(pev(id, pev_flags) & FL_DUCKING)) format(Anim2, 63, "ref_%s", AnimName)
	else format(Anim2, 63, "crouch_%s", AnimName)

	if ((AnimNum=lookup_sequence(id,Anim2,FrameRate,Loops,GroundSpeed))==-1) AnimNum=0
	
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
/* AMXX-Studio Notes - DO NOT MODIFY BELOW HERE
*{\\ rtf1\\ ansi\\ deff0{\\ fonttbl{\\ f0\\ fnil Tahoma;}}\n\\ viewkind4\\ uc1\\ pard\\ lang1057\\ f0\\ fs16 \n\\ par }
*/
