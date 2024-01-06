#include <amxmodx>
#include <xs>
#include <zombiemodlimited>
#include <fakemeta>
#include <hamsandwich>
#include <cstrike>
#include <csm>

new Float:g_flSkillTime[33], Float:g_flAPTime[33], g_Classid, Float:flTrapRemove[8192];
new Float:flBotTime[33], g_Hud
new const zombie_pain_sound[][] = { "zombi/zombi_hurt_heavy_01.wav ", "zombi/zombi_hurt_heavy_02.wav" }
new const zombie_die_sound[][] = { "zombi/zombi_death_heavy_01.wav ", "zombi/zombi_death_heavy_02.wav" }

#define TRAP_MODEL	"models/zbz/zombitrap.mdl"

public plugin_precache()
{
	for(new i = 0; i<2; i++) 
	{
		engfunc(EngFunc_PrecacheSound, zombie_pain_sound[i])
		engfunc(EngFunc_PrecacheSound, zombie_die_sound[i])
	}
	
	engfunc(EngFunc_PrecacheModel, "models/player/zbz_heavy/zbz_heavy.mdl")
	
	engfunc(EngFunc_PrecacheModel, "models/zbz/v_knife_heavy.mdl")
	engfunc(EngFunc_PrecacheModel, "models/zbz/v_zombibomb_heavy.mdl")
	
	engfunc(EngFunc_PrecacheModel, TRAP_MODEL);
	
	engfunc(EngFunc_PrecacheSound, "zombi/zombi_trapsetup.wav");
	engfunc(EngFunc_PrecacheSound, "zombi/zombi_trapped.wav");
	engfunc(EngFunc_PrecacheSound, "zombi/zombi_trapped_female.wav");
}
public plugin_init() 
{
	register_plugin("[Zombie Z] Class Heavy", "1.0", "csbtedhan");
	RegisterHam(Ham_Think, "info_target", "TrapThink");
	RegisterHam(Ham_Touch, "info_target", "TrapTouch");
	
	register_forward(FM_EmitSound, "fw_EmitSound")
	register_forward(FM_CmdStart, "fw_CmdStart")
	
	g_Hud = CreateHudSyncObj()
	
	g_Classid = cs_zb_register_class("Heavy Zombie", "heavy", "zbz_heavy", "heavy", 0.8, 250.0, 1.3, 1, 13, 1);
}

public fw_CSHUD(id)
{
	if(!cs_zb_is_zombie(id) || cs_zb_get_zombie_class(id) != g_Classid || !is_user_alive(id))
		return
		
	set_hudmessage(255, 255, 255, -1.0, 0.25, 0, 0.0, 0.2, 0.0, 0.0, 12);
	ShowSyncHudMsg(id, g_Hud, "[G]Scapegoats (Trap): %s [R]Hardening: %s", (g_flSkillTime[id] <= get_gametime()) ? "Ready" : "Cooldown",  (g_flAPTime[id] <= get_gametime()) ? "Ready" : "Cooldown");
}
public client_command(id)
{
	if(!is_user_alive(id) || !cs_zb_is_zombie(id) || cs_zb_get_zombie_class(id) != g_Classid)
		return PLUGIN_CONTINUE
	
	new arg[13]
	if (read_argv(0, arg, 12) > 11) return PLUGIN_CONTINUE 
	if(g_flSkillTime[id] <= get_gametime())
	{
		if(equali(arg, "drop"))
		{
			MakeTrap(id)
			g_flSkillTime[id] = get_gametime() + 8.0;
			return PLUGIN_HANDLED
		}
	}
	return PLUGIN_CONTINUE
}

public fw_EmitSound(id, channel, const sample[], Float:volume, Float:attn, flags, pitch)
{
	if(!cs_zb_is_zombie(id) || cs_zb_get_zombie_class(id) != g_Classid)
		return FMRES_IGNORED
		
	if (sample[7] == 'b' && sample[8] == 'h' && sample[9] == 'i' && sample[10] == 't')
	{
		emit_sound(id, channel, zombie_pain_sound[random_num(0, 1)], volume, attn, flags, pitch)
		return FMRES_SUPERCEDE;
	}
	
	// Zombie dies
	if (sample[7] == 'd' && ((sample[8] == 'i' && sample[9] == 'e') || (sample[8] == 'e' && sample[9] == 'a')))
	{
		emit_sound(id, channel, zombie_die_sound[random_num(0, 1)], volume, attn, flags, pitch)
		return FMRES_SUPERCEDE;
	}
		
	// Zombie falls off
	if (sample[10] == 'f' && sample[11] == 'a' && sample[12] == 'l' && sample[13] == 'l')
	{
		emit_sound(id, channel, zombie_pain_sound[random_num(0, 1)], volume, attn, flags, pitch)
		return FMRES_SUPERCEDE;
	}
	
	return FMRES_IGNORED
}
public fw_CmdStart(id, uc_handle, seed)
{
	if(!cs_zb_is_zombie(id) || cs_zb_get_zombie_class(id) != g_Classid || !is_user_alive(id))
		return
		
	static CurButton;CurButton = get_uc(uc_handle, UC_Buttons)
	if(CurButton & IN_RELOAD)
	{
		CurButton &= ~IN_RELOAD
		set_uc(uc_handle, UC_Buttons, CurButton)
		if(g_flAPTime[id] <= get_gametime())
		{
			play_sound(id, "zombi/smallmedkit1.wav")
			cs_set_user_armor(id, pev(id, pev_armorvalue) + 500, CS_ARMOR_KEVLAR);
			g_flAPTime[id] = get_gametime() + 7.0;
			
			if(!cs_zb_is_using_nvgs(id))
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
					
		}
	}
	
	if(is_user_bot(id) && flBotTime[id] <= get_gametime())
	{
		if(random(10) > 7) MakeTrap(id)
		flBotTime[id] = get_gametime() + 8.0;
	}	
}
public MakeTrap(id)
{
	static pEnt, Float:vOrigin[3];
	pev(id, pev_origin, vOrigin);
	
	pEnt = engfunc(EngFunc_CreateNamedEntity, engfunc(EngFunc_AllocString, "info_target"))
	set_pev(pEnt, pev_origin, vOrigin);
	set_pev(pEnt, pev_movetype, MOVETYPE_STEP);
	set_pev(pEnt, pev_owner, id);
	set_pev(pEnt, pev_classname, "heavyzombitrap");
	
	set_pev(pEnt, pev_sequence, 1);
	set_pev(pEnt, pev_iuser1, 0);
	
	engfunc(EngFunc_SetSize, pEnt, Float:{-20.0, 20.0, -0.0}, Float:{20.0, 20.0, 30.0})
	engfunc(EngFunc_SetModel, pEnt, TRAP_MODEL)
	
	set_pev(pEnt, pev_solid, SOLID_NOT);
	
	set_pev(pEnt, pev_renderamt, 50.0);
	set_pev(pEnt, pev_rendermode, kRenderTransAlpha);
	
	flTrapRemove[pEnt] = get_gametime() + 20.0;
	
	set_pev(pEnt, pev_nextthink, get_gametime())
	set_pev(pEnt, pev_gravity, 0.65)
	static Float:vecVelo[3]
	velocity_by_aim(id, 650, vecVelo);
	set_pev(pEnt, pev_velocity, vecVelo);
	
	engfunc(EngFunc_EmitSound, pEnt, CHAN_VOICE, "zombi/zombi_trapsetup.wav", 1.0, 0.8, 0, 100);
}
public TrapThink(Ent)
{
	if(!isTrap(Ent)) return;
	
	static pClosestTarget, Float:vOrigin[3], Float:pOrigin[3];
	pev(Ent, pev_origin, vOrigin);
	
	new iOwner = pev(Ent, pev_owner);
	if(!is_user_alive(iOwner) || !pev_valid(iOwner) || !cs_zb_is_zombie(iOwner))
	{
		engfunc(EngFunc_RemoveEntity, Ent);
		return;
	}
	
	set_pev(Ent, pev_nextthink, get_gametime())
	
	if(pev(Ent, pev_flags) & FL_ONGROUND && pev(Ent, pev_solid) != SOLID_TRIGGER)
		set_pev(Ent, pev_solid, SOLID_TRIGGER);
	
	pClosestTarget = FindTarget(iOwner, vOrigin)
	
	if(isTarget(pClosestTarget) && pev(Ent, pev_iuser1) == 0)
	{
		static Float:vDir[3]
		pev(pClosestTarget, pev_origin, pOrigin);
		xs_vec_sub(pOrigin, vOrigin, vDir);
		xs_vec_normalize(vDir, vDir);
		xs_vec_mul_scalar(vDir, 120.0, vDir);
		
		if(pev(Ent, pev_flags) & FL_ONGROUND) set_pev(Ent, pev_velocity, vDir);
	}
	
	static Float:vTrappedOrigin[3], pTrapped; pTrapped = pev(Ent, pev_enemy);
	if(isTarget(pTrapped))
	{
		pev(Ent, pev_vuser1, vTrappedOrigin);
		set_pev(pTrapped, pev_origin, vTrappedOrigin);
		set_pev(pTrapped, pev_velocity, Float:{0.0, 0.0, 0.0})
	} else set_pev(Ent, pev_enemy, 0);
	
	if(flTrapRemove[Ent] <= get_gametime())
		engfunc(EngFunc_RemoveEntity, Ent);
}
public TrapTouch(Ent, pEnt)
{
	if(!isTrap(Ent) || !isTarget(pEnt) || pev(Ent, pev_iuser1) != 0) return;
	
	ExecuteHamB(Ham_TakeDamage, pEnt, Ent, Ent, 1.0, DMG_SHOCK);
	
	engfunc(EngFunc_EmitSound, pEnt, CHAN_VOICE, pl_get_user_sex(pEnt) == 1 ? "zombi/zombi_trapped_female.wav" : "zombi/zombi_trapped.wav", 1.0, 0.8, 0, 100);
	
	message_begin(MSG_ONE_UNRELIABLE, get_user_msgid("ScreenShake"), _, pEnt)
	write_short((1<<12)*4)
	write_short((1<<12)*2)
	write_short((1<<12)*10)
	message_end()
	
	if(!cs_zb_is_using_nvgs(pEnt))
	{
		message_begin(MSG_ONE_UNRELIABLE, get_user_msgid("ScreenFade"), _, pEnt);
		write_short(1<<9);
		write_short(0);
		write_short(0x0000);
		write_byte(200);//r
		write_byte(0);  //g
		write_byte(0);  //b
		write_byte(100);
		message_end();
	}
			
	set_pev(Ent, pev_rendermode, kRenderNormal);
	set_pev(Ent, pev_animtime, get_gametime());
	set_pev(Ent, pev_sequence, 1);
	set_pev(Ent, pev_frame, 0.0);
	set_pev(Ent, pev_framerate, 1.0);
	set_pev(Ent, pev_iuser1, 1);
	set_pev(Ent, pev_movetype, MOVETYPE_NONE);
	
	set_pev(Ent, pev_enemy, pEnt);
	static Float:pOrigin[3];
	pev(pEnt, pev_origin, pOrigin);
	if(IsDucking(pEnt)) pOrigin[2] += 18.0;
	set_pev(Ent, pev_vuser1, pOrigin);
	
	flTrapRemove[Ent] = get_gametime() + 8.0;
}
stock isClearLine(Float:vOrigin1[3], Float:vOrigin2[3])
{
	new Float:flFraction;
	engfunc(EngFunc_TraceLine, vOrigin1, vOrigin2,  IGNORE_MONSTERS|IGNORE_GLASS, -1, 0);
	get_tr2(0, TR_flFraction, flFraction)
	
	return (flFraction == 1.0);
}
stock FindTarget(iOwner, Float:vOrigin[3])
{
	new Float:pOrigin[3], Float:flDist, Float:flDistmin, Target, pEnt = -1
	while((pEnt = engfunc(EngFunc_FindEntityInSphere, pEnt, vOrigin, 750.0)) != 0)
	{
		if(!isTarget(pEnt) || pEnt == iOwner)
			continue;
			
		pev(pEnt, pev_origin, pOrigin);
		flDist = vector_distance(pOrigin, vOrigin);
		if((!flDistmin || flDist <= flDistmin) && isClearLine(vOrigin, pOrigin))
		{
			Target = pEnt
			flDistmin = flDist
		}
	}
	return Target
}
stock isTarget(Ent)
{
	if (pev_valid(Ent) && !cs_zb_is_zombie(Ent) && is_user_alive(Ent))
		return 1;
	return 0;
}
stock isTrap(Ent)
{
	if(!pev_valid(Ent)) return 0;
	
	static szClassName[32]; pev(Ent, pev_classname,szClassName, 31);
	return (equal(szClassName, "heavyzombitrap"))
}
stock play_sound(id, const sound[])
{
	if (equal(sound[strlen(sound)-4], ".mp3"))
		client_cmd(id, "mp3 play ^"sound/%s^"", sound)
	else
		client_cmd(id, "spk ^"%s^"", sound)
}
stock IsDucking(id)
{
	return (pev(id, pev_flags) & (FL_DUCKING | FL_ONGROUND) == (FL_DUCKING | FL_ONGROUND))
}
/* AMXX-Studio Notes - DO NOT MODIFY BELOW HERE
*{\\ rtf1\\ ansi\\ deff0{\\ fonttbl{\\ f0\\ fnil Tahoma;}}\n\\ viewkind4\\ uc1\\ pard\\ lang1057\\ f0\\ fs16 \n\\ par }
*/
