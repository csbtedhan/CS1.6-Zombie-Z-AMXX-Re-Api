#include <amxmodx>
#include <xs>
#include <zombiemod>
#include <fakemeta>
#include <hamsandwich>
#include <csm>

#define BROKENWING_MINDAMAGETOTAL	1200.0

new Float:g_flSkillTime[2][33], g_iSkillStat[2][33], Float:g_flDamaged[33], g_Classid, Debug, Float:flBotTime[33], g_Hud
new const zombie_pain_sound[][] = { "zombi/flyzombie_hurt1.wav ", "zombi/flyzombie_hurt2.wav" }
new const zombie_die_sound[][] = { "zombi/flyzombie_death1.wav ", "zombi/flyzombie_death2.wav" }

public plugin_precache()
{
	for(new i = 0; i<2; i++) 
	{
		engfunc(EngFunc_PrecacheSound, zombie_pain_sound[i])
		engfunc(EngFunc_PrecacheSound, zombie_die_sound[i])
	}
	
	engfunc(EngFunc_PrecacheModel, "models/player/zbz_flying/zbz_flying.mdl")
	
	engfunc(EngFunc_PrecacheModel, "models/zbz/v_knife_flying.mdl")
	engfunc(EngFunc_PrecacheModel, "models/zbz/v_zombibomb_flying.mdl")
	
	engfunc(EngFunc_PrecacheSound, "zombi/flyzombie_pressure.wav");
	engfunc(EngFunc_PrecacheSound, "zombi/flyzombie_fly_idle.wav");
	engfunc(EngFunc_PrecacheSound, "zombi/flyzombie_fly_start.wav");
	engfunc(EngFunc_PrecacheSound, "zombi/flyzombie_downhill_start.wav");
}
public plugin_init() 
{
	register_plugin("[Zombie Z] Class Rusty Wing", "1.0", "csbtedhan");
	register_forward(FM_CmdStart, "fw_CmdStart")
	register_forward(FM_EmitSound, "fw_EmitSound")
	register_forward(FM_Touch, "fw_EndDownHill")
	
	g_Hud = CreateHudSyncObj()
	
	RegisterHam(Ham_TakeDamage, "player", "HamF_TakeDamage", 1)
	
	g_Classid = cs_zb_register_class("Rusty Wing", "flying", "zbz_flying", "flying", 0.8, 330.0, 0.75, 1, 29, 1, 1);
}

public fw_CSHUD(id)
{
	if(!cs_zb_is_zombie(id) || cs_zb_get_zombie_class(id) != g_Classid || !is_user_alive(id))
		return
		
	set_hudmessage(255, 255, 255, -1.0, 0.25, 0, 0.0, 0.2, 0.0, 0.0);
	ShowSyncHudMsg(id, g_Hud, "[G]Flying: %s [R]Fastrun: %s", (g_flSkillTime[0][id] <= get_gametime()) ? "Ready" : "Cooldown",  (g_flSkillTime[1][id] <= get_gametime() && g_iSkillStat[1][id]==0) ? "Ready" : "Cooldown");
}
public client_command(id)
{
	if(!is_user_alive(id) || !cs_zb_is_zombie(id) || cs_zb_get_zombie_class(id) != g_Classid)
		return PLUGIN_CONTINUE
	
	new arg[13]
	if (read_argv(0, arg, 12) > 11) return PLUGIN_CONTINUE 
	if(g_flSkillTime[0][id] <= get_gametime() && g_iSkillStat[1][id] == 0)
	{
		if(equali(arg, "drop"))
		{
			if(g_iSkillStat[0][id] == 0)
			{
				set_pdata_float(id, 83, 1.3);
				SetPlayerAnimation(id, "fly_start");
				g_flSkillTime[0][id] = get_gametime() + 0.1;
				g_iSkillStat[0][id] = 1;
			} else if(g_iSkillStat[0][id] == 3) {
				g_flSkillTime[0][id] = get_gametime() + 0.1;
				SetPlayerAnimation(id, "downhill_start");
				Set_WeaponAnim(id, 8);
				set_pdata_float(id, 83, 1.0);
				engfunc(EngFunc_EmitSound, id, CHAN_BODY, "zombi/flyzombie_downhill_start.wav", 1.0, 0.8, 0, 100);
				g_iSkillStat[0][id] = 4;
				
			}
			return PLUGIN_HANDLED
		}
	}
	return PLUGIN_CONTINUE
}
public client_putinserver(id)
{
	if(!Debug && is_user_bot(id) && get_cvar_num("bot_quota"))
	{
		set_task(0.1, "RegHamBots", id)
	}
	
}
public RegHamBots(id)
{
	if(Debug)return;
	RegisterHamFromEntity(Ham_TakeDamage, id, "HamF_TakeDamage", 1)
	
	Debug = 1
}
public HamF_TakeDamage(id, inflictor, attacker, Float:flDamage, dmgbits)
{
	if(!is_user_alive(id) || !cs_zb_is_zombie(id) || cs_zb_get_zombie_class(id) != g_Classid)
		return
		
	g_flDamaged[id] += flDamage
	if(g_flDamaged[id] >= BROKENWING_MINDAMAGETOTAL*0.5 && g_iSkillStat[0][id])
		set_pev(id, pev_skin, 1);
	if(g_flDamaged[id] >= BROKENWING_MINDAMAGETOTAL && g_iSkillStat[0][id])
	{
		set_pev(id, pev_skin, 2);
		g_flSkillTime[0][id] = get_gametime() + 10.0;
		g_iSkillStat[0][id] = 0;
		g_flDamaged[id] = 0.0;
	}
}
public fw_EndDownHill(id, iPtd)
{
	if(!is_user_alive(id) || !cs_zb_is_zombie(id) || cs_zb_get_zombie_class(id) != g_Classid)
		return
		
	if(g_iSkillStat[0][id] == 5)
	{
		Set_WeaponAnim(id, 10);
		set_pdata_float(id, 83, 0.6);
		g_flSkillTime[0][id] = get_gametime() + 10.0;
		SetPlayerAnimation(id, "downhill_end");
		g_iSkillStat[0][id] = 0;
	}
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
	if(CurButton & IN_RELOAD && g_iSkillStat[1][id] == 0 && g_iSkillStat[0][id] == 0)
	{
		CurButton &= ~IN_RELOAD
		set_uc(uc_handle, UC_Buttons, CurButton)
		if(g_flSkillTime[1][id] <= get_gametime())
		{
			g_iSkillStat[1][id] = 1;
			set_pdata_int(id, 363, 110);
			set_pev(id, pev_maxspeed, 450.0);
			fm_set_rendering(id, kRenderFxGlowShell, 255, 0, 0);
			engfunc(EngFunc_EmitSound, id, CHAN_VOICE, "zombi/flyzombie_pressure.wav", 1.0, 0.8, 0, 100);
			g_flSkillTime[1][id] = get_gametime() + 8.0;
		}
	}
}

public Boost(id)
{
	if(!cs_zb_is_zombie(id) || cs_zb_get_zombie_class(id) != g_Classid || !is_user_alive(id))
		return
		
	
	new Float:vVelocity[3], Float:pVelocity[3];
	pev(id, pev_velocity, pVelocity);
	vVelocity[2] = 650.0;
	xs_vec_add(pVelocity, vVelocity, pVelocity);
	set_pev(id, pev_velocity, pVelocity);
	
	engfunc(EngFunc_EmitSound, id, CHAN_BODY, "zombi/flyzombie_fly_start.wav", 1.0, 0.8, 0, 100);
}
public fw_CSZB_Killed(id, attacker)
{
	g_iSkillStat[0][id] = 0
	g_iSkillStat[1][id] = 0
	g_flDamaged[id] = 0.0;
}
public fw_CSZB_OnSpawn(id)
{
	g_iSkillStat[0][id] = 0
	g_iSkillStat[1][id] = 0
	g_flDamaged[id] = 0.0;
}
public fw_CSZB_OnPreThink(id)
{
	if(!cs_zb_is_zombie(id) || cs_zb_get_zombie_class(id) != g_Classid || !is_user_alive(id))
		return
	
	if(flBotTime[id] <= get_gametime() && is_user_bot(id) && BotFindEnemy(id) && !IsDucking(id) && g_flSkillTime[0][id] <= get_gametime() && g_iSkillStat[0][id] == 0)
	{
		set_pdata_float(id, 83, 1.3);
		SetPlayerAnimation(id, "fly_start");
		g_flSkillTime[0][id] = get_gametime() + 0.1;
		g_iSkillStat[0][id] = 1;
		flBotTime[id] = get_gametime() + random_float(20.0, 25.0)
	}
	if(g_flSkillTime[1][id] <= get_gametime())
	{
		if(g_iSkillStat[1][id] == 1)
		{
			g_iSkillStat[1][id] = 0;
			set_pev(id, pev_maxspeed, 330.0);
			fm_set_rendering(id);
			set_pdata_int(id, 363, 90);
			g_flSkillTime[1][id] = get_gametime() + 6.0
		}
	}
	if(g_iSkillStat[1][id] == 1) set_pev(id, pev_maxspeed, 450.0);
	
	if(g_flSkillTime[0][id] <= get_gametime())
	{
		if(g_iSkillStat[0][id] == 1)
		{
			SetPlayerAnimation(id, "fly_start_loop");
			Boost(id)
			g_iSkillStat[0][id] = 2
			g_flSkillTime[0][id] = get_gametime() + 0.85
		}
		else if(g_iSkillStat[0][id] == 2)
		{
			SetPlayerAnimation(id, "fly_start_end");
			g_iSkillStat[0][id] = 3;
			engfunc(EngFunc_EmitSound, id, CHAN_BODY, "zombi/flyzombie_fly_idle.wav", 1.0, 0.8, 0, 100);
		}
		else if (g_iSkillStat[0][id] == 4)
		{
			g_iSkillStat[0][id] = 5;
			SetPlayerAnimation(id, "downhill_loop");
		}
		else if (g_iSkillStat[0][id] == 0)
		{
			set_pev(id, pev_skin, 0);
			g_flDamaged[id] = 0.0;
		}
	}
	
	if(g_iSkillStat[0][id] == 3)
	{
		new pEnt = get_pdata_cbase(id, 373);
		if(pev_valid(pEnt))
		{
			if(pev(id, pev_button) & IN_ATTACK && get_pdata_float(pEnt, 46, 4) <= 0.0)
			{
				SetPlayerAnimation(id, get_pdata_int(pEnt, 43, 4) != CSW_KNIFE ? "fly_bomb_shoot" : "fly_attack");
			} else SetPlayerAnimation(id, get_pdata_int(pEnt, 43, 4) != CSW_KNIFE ? "fly_bomb_idle" : "fly_idle");
		}
		
		if(is_user_bot(id) && random(5) > 3)
		{
			g_flSkillTime[0][id] = get_gametime() + 0.1;
			SetPlayerAnimation(id, "downhill_start");
			Set_WeaponAnim(id, 8);
			set_pdata_float(id, 83, 1.0);
			engfunc(EngFunc_EmitSound, id, CHAN_BODY, "zombi/flyzombie_downhill_start.wav", 1.0, 0.8, 0, 100);
			g_iSkillStat[0][id] = 4;
		}
	} else if (g_iSkillStat[0][id] == 5) {
		SetPlayerAnimation(id, "downhill_loop");
		Set_WeaponAnim(id, 9);
		set_pdata_float(id, 83, 1.0);
	}
}
public fw_CSZB_OnPostThink(id)
{
	if(!cs_zb_is_zombie(id) || cs_zb_get_zombie_class(id) != g_Classid || !is_user_alive(id))
		return
		
	static Float:pVelocity[3]
	if(g_iSkillStat[0][id] == 3)
	{
		pev(id, pev_velocity, pVelocity);
		pVelocity[2] = -50.0;
		set_pev(id, pev_velocity, pVelocity);
		if(pev(id, pev_flags) & FL_ONGROUND)
		{
			g_flSkillTime[0][id] = get_gametime() + 10.0;
			g_iSkillStat[0][id] = 0;
		}
	} else if (g_iSkillStat[0][id] == 2) {
		new Float:pVelocity[3];
		pev(id, pev_velocity, pVelocity);
		pVelocity[2] = 450.0;
		set_pev(id, pev_velocity, pVelocity);
	} else if (g_iSkillStat[0][id] == 5) {
		velocity_by_aim(id, 1250, pVelocity)
		pVelocity[2] = floatmin(-150.0, pVelocity[2])
		set_pev(id, pev_velocity, pVelocity);
		if(pev(id, pev_flags) & FL_ONGROUND)
		{
			Set_WeaponAnim(id, 10);
			set_pdata_float(id, 83, 0.6);
			g_flSkillTime[0][id] = get_gametime() + 10.0;
			SetPlayerAnimation(id, "downhill_end");
			g_iSkillStat[0][id] = 0;
		}
	}
}
stock BotFindEnemy(id)
{
	static Float:vOrigin[3], Float:xOrigin[3]
	pev(id, pev_origin, vOrigin);
	for(new x = 0; x < get_maxplayers(); x ++ )
	{
		if(!is_user_connected(x) || !is_user_alive(x) || cs_zb_is_zombie(x) || x == id)
			continue;
		
		pev(x, pev_origin, xOrigin);
		if(isClearLine(xOrigin, vOrigin))
			return 1;
	}
	return 0;
}
stock isClearLine(Float:vOrigin1[3], Float:vOrigin2[3])
{
	new Float:flFraction;
	engfunc(EngFunc_TraceLine, vOrigin1, vOrigin2, IGNORE_MONSTERS|IGNORE_GLASS, 0, 0);
	get_tr2(0, TR_flFraction, flFraction)
	
	if (flFraction < 1.0) return 0;

	return 1;
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
stock IsDucking(id)
{
	return (pev(id, pev_flags) & (FL_DUCKING | FL_ONGROUND) == (FL_DUCKING | FL_ONGROUND))
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
/* AMXX-Studio Notes - DO NOT MODIFY BELOW HERE
*{\\ rtf1\\ ansi\\ deff0{\\ fonttbl{\\ f0\\ fnil Tahoma;}}\n\\ viewkind4\\ uc1\\ pard\\ lang1057\\ f0\\ fs16 \n\\ par }
*/
