
#include < amxmodx >
#include < fakemeta_util >
#include < hamsandwich >
#include < cstrike >
#include < csm >
#include < engine >
#include < zombiemodlimited >

#define V_MODEL "models/zbz/wpn/v_oldbalrog11.mdl"
#define P_MODEL "models/zbz/wpn/p_oldbalrog11.mdl"
#define W_MODEL "models/zbz/wpn/w_primgroup1.mdl"
#define SHELL_MODEL "models/zbz/wpn/shell_bcs.mdl"

#define CSW_BALROG11 	CSW_XM1014
#define weapon_balrog11 	"weapon_xm1014"
#define FireClassname		"balrog11_fire"

new const WeaponSounds[][] = 
{
	"weapons/balrog11g-1.wav",
	"weapons/balrog11-2.wav",
	"weapons/balrog11_charge.wav"
}

new const szFlameModel[] = "sprites/flame_puff01.spr"

new const TRACER_ENTITY[][]={ "info_target", "func_breakable", "func_pushable", "func_wall", "func_wall_toggle", "func_door", "func_door_rotating",
		"func_button", "func_conveyor", "hostage_entity", "func_tank", "func_tankmortar", "func_tanklaser", "func_tankrocket", "button_target" }
		
new cvar_effect

#define Get_BitVar(%1,%2) (%1 & (1 << (%2 & 31)))
#define Set_BitVar(%1,%2) %1 |= (1 << (%2 & 31))
#define UnSet_BitVar(%1,%2) %1 &= ~(1 << (%2 & 31))
new g_HadWpn, g_Event, g_Attack, Float:g_flFiretime[8192]

public plugin_precache()
{
	engfunc(EngFunc_PrecacheModel, V_MODEL)
	engfunc(EngFunc_PrecacheModel, P_MODEL)
	engfunc(EngFunc_PrecacheModel, W_MODEL)
	engfunc(EngFunc_PrecacheModel, SHELL_MODEL)
	engfunc(EngFunc_PrecacheModel, szFlameModel)
	
	register_forward(FM_PrecacheEvent, "fw_PrecacheEvent_Post", 1)
	for(new i = 0; i < sizeof(WeaponSounds); i++)
		engfunc(EngFunc_PrecacheSound, WeaponSounds[i])
}

public plugin_init()
{
	register_plugin("[Zombie Z] Extra Oldtime Balrog-XI", "1.0", "csbtedhan")
	
	register_forward(FM_SetModel, "fw_SetModel")
	register_forward(FM_UpdateClientData,"fw_UpdateClientData_Post", 1)	
	register_forward(FM_PlaybackEvent, "fw_PlaybackEvent")
	register_forward(FM_CmdStart, "fw_CmdStart");
	
	RegisterHam(Ham_Think, "info_target", "fw_Think");
	RegisterHam(Ham_Touch, "info_target", "fw_Touch");
	RegisterHam(Ham_TraceAttack, "worldspawn", "fw_TraceAttack")
	for(new i=0; i<sizeof(TRACER_ENTITY); i++)
		RegisterHam(Ham_TraceAttack, TRACER_ENTITY[i], "fw_TraceAttack")
		
	RegisterHam(Ham_Weapon_PrimaryAttack, weapon_balrog11, "fw_PrimaryAttack");
	RegisterHam(Ham_Item_Deploy, weapon_balrog11, "fw_Item_Deploy_Post", 1);
	RegisterHam(Ham_Item_Holster, weapon_balrog11, "fw_Item_Holster");
	RegisterHam(Ham_Item_AddToPlayer, weapon_balrog11, "fw_Item_AddToPlayer_Post", 1);
	RegisterHam(Ham_Weapon_WeaponIdle, weapon_balrog11, "fw_Weapon_WeaponIdle")	
	RegisterHam(Ham_Weapon_WeaponIdle, weapon_balrog11, "fw_Weapon_WeaponIdle_Post", 1)
	
	register_message(get_user_msgid("DeathMsg"), "message_DeathMsg")
	
	cvar_effect = register_cvar("sv_balrog11_full_effect", "0")
	
	cs_register_custom_item("Balrog-XI", 4750, 2, "GiveBalrog11", "balrog11")
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
	if(Get_BitVar(g_HadWpn, id))
	{
		for(new x = 0; x<8;x++)
			update_specialammo(id, x, 0)
	}
	UnSet_BitVar(g_HadWpn,id)
	UnSet_BitVar(g_Attack,id)
	
	
}
public GiveBalrog11(id)
{
	if(!is_user_alive(id)) return;
	
	drop_weapons(id, 1)
	
	Set_BitVar(g_HadWpn,id)
	UnSet_BitVar(g_Attack,id)
	fm_give_item(id, "weapon_xm1014")
}
public message_DeathMsg()
{
	// get value data
	new killer, weapon[32]
	killer = get_msg_arg_int(1)
	get_msg_arg_string(4, weapon, charsmax(weapon))
	
	if((Get_BitVar(g_HadWpn, killer) && equal(weapon, "xm1014")))
		set_msg_arg_string(4, "balrog11")
		
	return PLUGIN_CONTINUE
}

public fw_Item_AddToPlayer_Post(Ent, id)
{
	if(!pev_valid(Ent))
		return HAM_IGNORED
		
	if(pev(Ent, pev_impulse) == 2521)
	{
		Set_BitVar(g_HadWpn, id)
		set_pev(Ent, pev_impulse, 0)
	}
		
	return HAM_HANDLED
}

public fw_TraceAttack(Victim, Attacker, Float:Damage, Float:Direction[3], Ptr, DamageBits)
{
	if(!is_user_connected(Attacker))
		return HAM_IGNORED	
	if(get_user_weapon(Attacker) != CSW_BALROG11 || !Get_BitVar(g_HadWpn, Attacker))
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
		
	if(get_user_weapon(id) != CSW_BALROG11 || !Get_BitVar(g_HadWpn, id))
		return
		
	new NewButton; NewButton = get_uc(uc_handle, UC_Buttons)
	new OldButton; OldButton = pev(id, pev_oldbuttons)
	
	if(NewButton & IN_ATTACK)
	{
		if(!Get_BitVar(g_Attack,id)) Set_BitVar(g_Attack,id)
	} else if(NewButton & IN_ATTACK2) {
		SpecialShoot_Handle(id)
	} else {
		if(OldButton & IN_ATTACK)
		{
			if(Get_BitVar(g_Attack,id)) 
			{
				UnSet_BitVar(g_Attack,id)
				new ent = get_pdata_cbase(id, 373)
				if(pev_valid(ent)) set_pev(ent, pev_iuser2, 0);
			}
		}
	}
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
	
	set_pev(ent, pev_effects, pev(ent, pev_effects) | EF_NODRAW);
	set_pev(ent, pev_solid, 0)
	set_pev(ent, pev_movetype, 0);
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
		new weapon; weapon = find_ent_by_owner(-1, weapon_balrog11, entity)
		if(Get_BitVar(g_HadWpn, iOwner) && pev_valid(weapon))
		{
			set_pev(weapon, pev_impulse, 2521)
			engfunc(EngFunc_SetModel, entity, W_MODEL)
			set_pev(entity, pev_body, 0);
			UnSet_BitVar(g_HadWpn,iOwner)
			UnSet_BitVar(g_Attack,iOwner)
			update_specialammo(iOwner, pev(weapon, pev_iuser1), 0)
			
			return FMRES_SUPERCEDE
		}
	}

	return FMRES_IGNORED;
}

public fw_UpdateClientData_Post(id, sendweapons, cd_handle)
{
	if(!is_user_alive(id))
		return FMRES_IGNORED	
	if(get_user_weapon(id) == CSW_BALROG11 && Get_BitVar(g_HadWpn, id))
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
	if(get_user_weapon(invoker) != CSW_BALROG11 || !Get_BitVar(g_HadWpn, invoker))
		return FMRES_IGNORED
	if(eventid != g_Event)
		return FMRES_IGNORED
	
	engfunc(EngFunc_PlaybackEvent, flags | FEV_HOSTONLY, invoker, eventid, delay, origin, angles, fparam1, fparam2, iParam1, iParam2, bParam1, bParam2)
	
	Set_WeaponAnim(invoker, 1)
	emit_sound(invoker, CHAN_WEAPON, WeaponSounds[0], 1.0, 0.5, 0, PITCH_NORM)
	Eject_Shell(invoker, 0)
	
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
	
	new iId ; iId = get_pdata_int(iEnt, 43, 4)
	new iMaxClip ; iMaxClip = 7

	new iClip ; iClip = get_pdata_int(iEnt, 51, 4)
	new fInSpecialReload ; fInSpecialReload = get_pdata_int(iEnt, 55, 4)

	if( !iClip && !fInSpecialReload )
		return HAM_IGNORED

	if( fInSpecialReload )
	{
		new iBpAmmo ; iBpAmmo = get_pdata_int(id, 381, 5)

		if( iClip < iMaxClip && iBpAmmo )
		{
			Shotgun_Reload(iEnt, iId, iMaxClip, iClip, iBpAmmo, id)
			return HAM_SUPERCEDE
		}
		else if( iClip >= iMaxClip )
		{
			Set_WeaponAnim(id, 4)
				
			set_pdata_int(iEnt, 55, 0, 4)
			set_pdata_float(iEnt, 48, 1.5, 4)
		}
	}
	
	return HAM_IGNORED
}

public fw_Weapon_WeaponIdle_Post( iEnt )
{
	if(pev_valid(iEnt) != 2)
		return 
	new id; id = get_pdata_cbase(iEnt, 41, 4)
	if(get_pdata_cbase(id, 373) != iEnt)
		return

	if(!Get_BitVar(g_HadWpn, id))
		return
		
	new SpecialReload; SpecialReload = get_pdata_int(iEnt, 55, 4)
	if(!SpecialReload && get_pdata_float(iEnt, 48, 4) <= 0.25)
	{
		Set_WeaponAnim(id, 0)
		set_pdata_float(iEnt, 48, 20.0, 4)
	}	
}
public Shotgun_Reload(iEnt, iId, iMaxClip, iClip, iBpAmmo, id)
{
	if(iBpAmmo <= 0 || iClip == iMaxClip)
		return

	if(get_pdata_int(iEnt, 46, 4) > 0.0)
		return

	if(!Get_BitVar(g_HadWpn, id))
		return
		
	switch( get_pdata_int(iEnt, 55, 4) )
	{
		case 0:
		{
			Set_WeaponAnim(id, 5)
			 
			set_pdata_int(iEnt, 55, 1, 4)
			set_pdata_float(id, 83, 0.15, 5)
			set_pdata_float(iEnt, 48, 0.45, 4)
			set_pdata_float(iEnt, 46, 0.45, 4)
			set_pdata_float(iEnt, 47, 0.45, 4)
			return
		}
		case 1:
		{
			if( get_pdata_float(iEnt, 48, 4) > 0.0 )
				return
			set_pdata_int(iEnt, 55, 2, 4)
			set_pdata_float(iEnt, 48, 0.45, 4)
		}
		default:
		{
			set_pev(iEnt, pev_iuser2, 0)
			Set_WeaponAnim(id, 3)
			set_pdata_int(iEnt, 51, iClip + 1, 4)
			set_pdata_int(id, 381, iBpAmmo-1, 5)
			set_pdata_int(iEnt, 55, 1, 4)
		}
	}
}
public fw_PrimaryAttack(Ent)
{
	if(pev_valid(Ent) != 2)
		return
	new Id; Id = get_pdata_cbase(Ent, 41, 4)
	if(get_pdata_cbase(Id, 373) != Ent)
		return
	if(!Get_BitVar(g_HadWpn, Id))
		return
		
	if(Get_BitVar(g_Attack,Id) && pev(Ent, pev_iuser1) < 7 && pev(Id, pev_waterlevel) != 3 && get_pdata_int(Ent, 51, 4) > 0)
	{
		set_pev(Ent, pev_iuser2, pev(Ent, pev_iuser2)+1)
		if(pev(Ent, pev_iuser2) >= 4)
		{
			update_specialammo(Id, pev(Ent, pev_iuser1), 0)
			set_pev(Ent, pev_iuser1, pev(Ent, pev_iuser1)+1)
			set_pev(Ent, pev_iuser2, 0)
			update_specialammo(Id, pev(Ent, pev_iuser1), pev(Ent, pev_iuser1) > 0 ? 1 : 0)
			emit_sound(Id, CHAN_ITEM, WeaponSounds[2], 1.0, 0.7, 0, PITCH_NORM)
		}
	}
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
	new Id; Id = get_pdata_cbase(Ent, 41, 4)
	if(get_pdata_cbase(Id, 373) != Ent)
		return
	if(!Get_BitVar(g_HadWpn, Id))
		return
		
	set_pev(Ent, pev_iuser2, 0)
	update_specialammo(Id, pev(Ent, pev_iuser1), pev(Ent, pev_iuser1) > 0 ? 1:0)
	set_pev(Id, pev_viewmodel2, V_MODEL)
	set_pev(Id, pev_weaponmodel2, P_MODEL)
}

public SpecialShoot_Handle(id)
{
	new pEnt = get_pdata_cbase(id, 373)
	if(!pev_valid(pEnt))
		return
	if(get_pdata_float(id, 83, 5) > 0.0)
		return
	if(pev(pEnt, pev_iuser1) <= 0)
		return		
	// Shoot Handle
	set_pdata_float(id, 83, 0.35)
	set_pdata_float(pEnt, 46, 0.35, 4)
	set_pdata_float(pEnt, 47, 0.35, 4)
	set_pdata_float(pEnt, 48, 1.35, 4)
	
	update_specialammo(id, pev(pEnt, pev_iuser1), 0)
	set_pev(pEnt, pev_iuser1, pev(pEnt, pev_iuser1)-1)
	update_specialammo(id, pev(pEnt, pev_iuser1), pev(pEnt, pev_iuser1) > 0 ? 1 : 0)
	
	Set_WeaponAnim(id, 2)
	Eject_Shell(id, 1)
	emit_sound(id, CHAN_WEAPON, WeaponSounds[1], 1.0, 0.6, 0, PITCH_NORM)
	
	Create_FireSystem(id)
}
public FireSystemThink(Ent)
{
	new Float:Origin[3], Float:Scale, Float:vVelocity[3], Float:pVelocity[3];
		
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
	
	if(pev(Ent, pev_movetype) != MOVETYPE_NONE && get_pcvar_num(cvar_effect)) Create_Fire(Origin, Scale*0.7, random_float(9.0,11.0))
		
	set_pev(Ent, pev_nextthink, get_gametime()+0.05)
	
	pev(Ent, pev_velocity, vVelocity)
	xs_vec_mul_scalar(vVelocity, 0.25, vVelocity);
	
	new pEnt = -1
	while((pEnt = engfunc(EngFunc_FindEntityInSphere, pEnt, Origin, 40.0)) > 0)
	{
		if(!pev_valid(pEnt) || (isBreakable(pEnt) && pev(pEnt, pev_spawnflags) & SF_BREAK_TRIGGER_ONLY) || pEnt == id) continue;
		
		if(is_user_alive(pEnt) && cs_zb_is_zombie(pEnt))
		{
			pev(pEnt, pev_velocity, pVelocity)
			xs_vec_add(vVelocity, pVelocity, pVelocity);
			set_pev(pEnt, pev_velocity, pVelocity)
		}
		if(pev(pEnt, pev_health) > 0.0) ExecuteHamB(Ham_TakeDamage, pEnt, Ent, pev(Ent, pev_owner), 52.0, DMG_CLUB)
	}
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
	new Float:vOrigin[3], Float:StartOrigin[3], Float:EndOrigin[5][3], Float:flLeft
	get_position(id, 0.0, 0.0, 0.0, vOrigin)
	flLeft = 2.0
	// Left
	get_position(id, 512.0, -140.0, 0.0, EndOrigin[0])
	get_position(id, 512.0, -70.0, 0.0, EndOrigin[1])
	
	// Center
	get_position(id, 512.0, 0.0, 0.0, EndOrigin[2])
	
	// Right
	get_position(id, 512.0, 70.0, 0.0, EndOrigin[3])
	get_position(id, 512.0, 140.0, 0.0, EndOrigin[4])	
	
	// Create Fire
	for(new i = 0; i < 5; i++) 
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
	set_pev(Ent, pev_renderamt, get_pcvar_num(cvar_effect) ? 100.0 : 255.0)
	g_flFiretime[Ent] = get_gametime() + 0.6;	// time remove
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
	set_pev(Ent, pev_renderamt, 85.0)
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

stock isBreakable(iEnt)
{
	if (!pev_valid(iEnt)) return 0;
	
	new szClassname[32]
	pev(iEnt, pev_classname, szClassname, charsmax(szClassname))
	if (equal(szClassname, "func_breakable") || equal(szClassname, "func_pushable")) return 1;
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
stock Stock_DirectedVector(Float:vStart[3],Float:vEnd[3],Float:vOut[3])
{	
	xs_vec_sub(vStart, vEnd, vOut)
	xs_vec_normalize(vOut, vOut)
}
public Eject_Shell(iEnt, Type)
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
	write_short(engfunc(EngFunc_ModelIndex, !Type ? "models/shotgunshell.mdl" : SHELL_MODEL))
	write_byte(2)
	write_byte(25)
	message_end()
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
/* AMXX-Studio Notes - DO NOT MODIFY BELOW HERE
*{\\ rtf1\\ ansi\\ deff0{\\ fonttbl{\\ f0\\ fnil Tahoma;}}\n\\ viewkind4\\ uc1\\ pard\\ lang1057\\ f0\\ fs16 \n\\ par }
*/
