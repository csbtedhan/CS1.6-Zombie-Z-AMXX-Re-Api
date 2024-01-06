#include <amxmodx>
#include <xs>
#include <csm>
#include <zombiemodlimited>
#include <fakemeta>
#include <hamsandwich>

new Float:g_flSkillTime[2][33], g_iSkillStat[2][33], g_Classid, Float:flBatRemove[8192], Float:g_flOldMaxSpeed[33], g_Hud;
new const zombie_pain_sound[] = "zombi/zombi_banshee_hurt.wav "
new const zombie_die_sound[] = "zombi/zombi_banshee_death.wav "

public plugin_precache()
{
	engfunc(EngFunc_PrecacheSound, zombie_pain_sound)
	engfunc(EngFunc_PrecacheSound, zombie_die_sound)
	
	engfunc(EngFunc_PrecacheModel, "models/player/zbz_witch/zbz_witch.mdl")
	
	engfunc(EngFunc_PrecacheModel, "models/zbz/v_knife_witch.mdl")
	engfunc(EngFunc_PrecacheModel, "models/zbz/v_zombibomb_witch.mdl")
	
	engfunc(EngFunc_PrecacheModel, "models/zbz/bat_witch.mdl");
	engfunc(EngFunc_PrecacheModel, "sprites/ef_bat.spr");
	
	engfunc(EngFunc_PrecacheSound, "zombi/zombi_banshee_laugh.wav");
	engfunc(EngFunc_PrecacheSound, "zombi/zombi_banshee_pulling_fail.wav");
	engfunc(EngFunc_PrecacheSound, "zombi/zombi_banshee_pulling_fire.wav");
	
}
public plugin_init() 
{
	register_plugin("[Zombie Z] Class Banshee", "1.0", "csbtedhan");
	RegisterHam(Ham_Think, "info_target", "BatThink");
	RegisterHam(Ham_Touch, "info_target", "BatImpact");
	
	g_Hud = CreateHudSyncObj()
	
	register_forward(FM_EmitSound, "fw_EmitSound")
	register_forward(FM_CmdStart, "fw_CmdStart")
	
	g_Classid = cs_zb_register_class("Banshee Zombie", "banshee", "zbz_witch", "witch", 0.7, 280.0, 1.3, 1, 23, 1);
}

public fw_CSHUD(id)
{
	if(!cs_zb_is_zombie(id) || cs_zb_get_zombie_class(id) != g_Classid || !is_user_alive(id))
		return
		
	set_hudmessage(255, 255, 255, -1.0, 0.25, 0, 0.0, 0.2, 0.0, 0.0);
	ShowSyncHudMsg(id, g_Hud, "[G]Pulling Bat: %s [R]Gravity: %s", (g_flSkillTime[0][id] <= get_gametime() && g_iSkillStat[0][id]==0) ? "Ready" : "Cooldown",  (g_flSkillTime[1][id] <= get_gametime()&& g_iSkillStat[1][id]==0) ? "Ready" : "Cooldown");
}
public client_command(id)
{
	if(!is_user_alive(id) || !cs_zb_is_zombie(id) || cs_zb_get_zombie_class(id) != g_Classid)
		return PLUGIN_CONTINUE
	
	new arg[32]
	read_argv(0, arg, 31)
	
	if((contain(arg, "weapon_") != -1 || equal(arg, "lastinv")) && g_iSkillStat[1][id] != 0)
		return PLUGIN_HANDLED
		
	if(g_flSkillTime[0][id] <= get_gametime())
	{
		if(equali(arg, "drop"))
		{
			if(g_iSkillStat[0][id] == 0)
			{
				g_iSkillStat[0][id] = 1
				SetPlayerAnimation(id, "skill1")
				Set_WeaponAnim(id, 2)
				MakeBat(id)
				engfunc(EngFunc_EmitSound, id, CHAN_VOICE, "zombi/zombi_banshee_laugh.wav", 1.0, 0.8, 0, 100);
				pev(id, pev_maxspeed, g_flOldMaxSpeed[id])
				set_pev(id, pev_maxspeed, 0.1);
				
				g_flSkillTime[0][id] = get_gametime() + 1.0;
			} else {
				g_iSkillStat[0][id] = 0;
				RemoveUserBat(id)
				set_pev(id, pev_maxspeed, g_flOldMaxSpeed[id])
				g_flSkillTime[0][id] = get_gametime() + 10.0;
			}
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
		emit_sound(id, channel, zombie_pain_sound, volume, attn, flags, pitch)
		return FMRES_SUPERCEDE;
	}
	
	// Zombie dies
	if (sample[7] == 'd' && ((sample[8] == 'i' && sample[9] == 'e') || (sample[8] == 'e' && sample[9] == 'a')))
	{
		emit_sound(id, channel, zombie_die_sound, volume, attn, flags, pitch)
		return FMRES_SUPERCEDE;
	}
		
	// Zombie falls off
	if (sample[10] == 'f' && sample[11] == 'a' && sample[12] == 'l' && sample[13] == 'l')
	{
		emit_sound(id, channel, zombie_pain_sound, volume, attn, flags, pitch)
		return FMRES_SUPERCEDE;
	}
	
	return FMRES_IGNORED
}
public fw_CSNew_Round()
	RemoveUserBat(0)
public fw_CmdStart(id, uc_handle, seed)
{
	if(!cs_zb_is_zombie(id) || cs_zb_get_zombie_class(id) != g_Classid || !is_user_alive(id))
		return
		
	static CurButton;CurButton = get_uc(uc_handle, UC_Buttons)
	if(CurButton & IN_RELOAD)
	{
		CurButton &= ~IN_RELOAD
		set_uc(uc_handle, UC_Buttons, CurButton)
		if(g_flSkillTime[1][id] <= get_gametime() && g_iSkillStat[1][id] == 0)
		{
			g_iSkillStat[1][id] = 1
			set_pdata_float(id, 83, 1.0);
			Set_WeaponAnim(id, 9)
			SetPlayerAnimation(id, "skill2");
			engfunc(EngFunc_EmitSound, id, CHAN_VOICE, "zombi/speed_up.wav", 1.0, 0.8, 0, 100);
			set_pev(id, pev_gravity, 0.45);
			fm_set_rendering(id, kRenderFxGlowShell, 100, 100, 100)
			g_flSkillTime[1][id] = get_gametime() + 7.0;
			
		}
	}
}
public fw_CSZB_OnPreThink(id)
{
	if(!cs_zb_is_zombie(id) || cs_zb_get_zombie_class(id) != g_Classid || !is_user_alive(id))
		return

	if(HasBat(id))
	{
		if(g_iSkillStat[0][id] == 1)
		{
			set_pdata_float(id, 83, 1.0);
		}
	} else {
		if(g_iSkillStat[0][id] == 1)
		{
			set_pev(id, pev_maxspeed, g_flOldMaxSpeed[id])
			g_iSkillStat[0][id] = 0;
			g_flSkillTime[0][id] = get_gametime() + 10.0;
		}
	}
	if(g_flSkillTime[1][id] <= get_gametime() && g_iSkillStat[1][id])
	{
		set_pdata_float(id, 83, 1.0);
		Set_WeaponAnim(id, 10)
		g_iSkillStat[1][id] = 0
		set_pev(id, pev_gravity, 0.7)
		set_pev(id, pev_maxspeed, 280.0)
		fm_set_rendering(id);
		g_flSkillTime[1][id] = get_gametime() + 8.0;
	}
}
public MakeBat(id)
{
	static pEnt, Float:vOrigin[3], Float:vAngle[3];
	pev(id, pev_origin, vOrigin);
	pev(id, pev_v_angle, vAngle)
	vAngle[0] *= -1.0
	
	pEnt = engfunc(EngFunc_CreateNamedEntity, engfunc(EngFunc_AllocString, "info_target"))
	set_pev(pEnt, pev_origin, vOrigin);
	set_pev(pEnt, pev_movetype, MOVETYPE_FLY);
	set_pev(pEnt, pev_owner, id);
	set_pev(pEnt, pev_classname, "bat_witch");
	set_pev(pEnt, pev_angles, vAngle);
	
	set_pev(pEnt, pev_sequence, 0);
	set_pev(pEnt, pev_framerate, 1.0);
	set_pev(pEnt, pev_animtime, get_gametime());
	
	set_pev(pEnt, pev_iuser1, 0);
	
	engfunc(EngFunc_SetSize, pEnt, Float:{-20.0,-15.0,-8.0},Float:{20.0,15.0,8.0})
	engfunc(EngFunc_SetModel, pEnt, "models/zbz/bat_witch.mdl")
	
	set_pev(pEnt, pev_solid, SOLID_BBOX);
	
	flBatRemove[pEnt] = get_gametime() + 20.0;
	
	engfunc(EngFunc_EmitSound, pEnt, CHAN_STATIC, "zombi/zombi_banshee_pulling_fire.wav", 1.0, 0.8, SND_SPAWNING, 100);
	
	set_pev(pEnt, pev_nextthink, get_gametime())
	set_pev(pEnt, pev_gravity, 0.65)
	static Float:vecVelo[3]
	velocity_by_aim(id, 1500, vecVelo);
	set_pev(pEnt, pev_velocity, vecVelo);	
	
}
public BatThink(Ent)
{
	if(!isBat(Ent)) return;
	
	static Float:vOrigin[3], pevOwner
	pevOwner = pev(Ent, pev_owner);
	
	if(flBatRemove[Ent] <= get_gametime() || !is_user_alive(pevOwner) || !pev_valid(pevOwner) || !cs_zb_is_zombie(pevOwner))
	{
		BatRemove(Ent)
		engfunc(EngFunc_RemoveEntity, Ent);
		return;
	}
	
	static Float:vVelocity[3], Float:vDir[3], Float:pOrigin[3]; pev(pevOwner, pev_origin, pOrigin);
	new iGrab = pev(Ent, pev_enemy);
	if(isTarget(iGrab) && pev(Ent, pev_iuser1) == 1)
	{
		pev(iGrab, pev_origin, vOrigin)
		pev(iGrab, pev_velocity, vVelocity);
		xs_vec_sub(pOrigin, vOrigin, vDir);
		xs_vec_normalize(vDir, vDir);
		xs_vec_mul_scalar(vDir, 750.0, vDir);
		xs_vec_add(vVelocity, vDir, vVelocity)
		if(vector_length(vVelocity) > 750.0) vVelocity = vDir
		set_pev(iGrab, pev_velocity, vVelocity);
		set_pev(Ent, pev_origin, vOrigin);
		
		if(vector_distance(vOrigin, pOrigin) <= 150.0)
		{
			BatRemove(Ent)
			engfunc(EngFunc_RemoveEntity, Ent);
			return;
		}
	} else {
		if(pev(Ent, pev_iuser1) == 1)
		{
			BatRemove(Ent)
			engfunc(EngFunc_RemoveEntity, Ent);
			return;
		}
	}
	set_pev(Ent, pev_nextthink, get_gametime())
}
public BatImpact(Ent, Id)
{
	if(!isBat(Ent))
		return;
	
	if(isTarget(Id))
	{
		set_pev(Ent, pev_sequence, 1);
		set_pev(Ent, pev_framerate, 1.0);
		set_pev(Ent, pev_animtime, get_gametime());
		set_pev(Ent, pev_iuser1, 1);
		set_pev(Ent, pev_enemy, Id);
	} else {
		BatRemove(Ent)
		engfunc(EngFunc_RemoveEntity, Ent);
	}
}
public BatRemove(Ent)
{
	static Float:vOrigin[3]
	pev(Ent, pev_origin, vOrigin);
	
	message_begin(MSG_BROADCAST,SVC_TEMPENTITY)
	write_byte(TE_EXPLOSION)
	engfunc(EngFunc_WriteCoord, vOrigin[0])
	engfunc(EngFunc_WriteCoord, vOrigin[1])
	engfunc(EngFunc_WriteCoord, vOrigin[2])
	write_short(engfunc(EngFunc_ModelIndex, "sprites/ef_bat.spr"))
	write_byte(40)
	write_byte(30)
	write_byte(14)
	message_end()
	
	engfunc(EngFunc_EmitSound, Ent, CHAN_STATIC, "zombi/zombi_banshee_pulling_fire.wav", 0.0, 0.8, SND_STOP, 100);
	engfunc(EngFunc_EmitAmbientSound, 0, vOrigin, "zombi/zombi_banshee_pulling_fail.wav", 1.0, 0.8, 0, 100);
}
stock HasBat(id)
{
	new pEnt = -1
	while((pEnt = engfunc(EngFunc_FindEntityByString, pEnt, "classname", "bat_witch")) != 0)
	{
		if(isBat(pEnt) && pev(pEnt, pev_owner) == id)
			return 1
	}
	return 0;
}
stock RemoveUserBat(id)
{
	new pEnt = -1
	while((pEnt = engfunc(EngFunc_FindEntityByString, pEnt, "classname", "bat_witch")) != 0)
	{
		if(isBat(pEnt) && (pev(pEnt, pev_owner) == id && id!=0))
		{
			BatRemove(pEnt)
			engfunc(EngFunc_RemoveEntity, pEnt)
		}
	}
}
stock isTarget(Ent)
{
	if (pev_valid(Ent) && !cs_zb_is_zombie(Ent) && is_user_alive(Ent))
		return 1;
	return 0;
}
stock isBat(Ent)
{
	if(!pev_valid(Ent)) return 0;
	
	static szClassName[32]; pev(Ent, pev_classname,szClassName, 31);
	return (equal(szClassName, "bat_witch"))
}
stock fm_set_rendering(entity, fx = kRenderFxNone, r = 255, g = 255, b = 255, render = kRenderNormal, amount = 16) 
{
	new Float:RenderColor[3];
	RenderColor[0] = float(r);
	RenderColor[1] = float(g);
	RenderColor[2] = float(b);

	set_pev(entity, pev_renderfx, fx);
	set_pev(entity, pev_rendercolor, RenderColor);
	set_pev(entity, pev_rendermode, render);
	set_pev(entity, pev_renderamt, float(amount));

	return 1;
}
stock Set_WeaponAnim(id, anim)
{
	set_pev(id, pev_weaponanim, anim)
	
	message_begin(MSG_ONE_UNRELIABLE, SVC_WEAPONANIM, {0, 0, 0}, id)
	write_byte(anim)
	write_byte(0)
	message_end()
}
stock SetPlayerAnimation(id, const AnimName[], Float:rate=1.0)
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
