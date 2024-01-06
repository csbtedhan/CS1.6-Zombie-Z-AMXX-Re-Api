#include <amxmodx>
#include <xs>
#include <zombiemodlimited>
#include <fakemeta>
#include <hamsandwich>
#include <csm>

#define MINSTAT	350
#define MAXSTAT	1000
new Float:g_flSkillTime[33], g_iSkillStat[2][33], g_iJump[33], g_Classid, g_Hud
new const zombie_pain_sound[][] = { "zombi/boosterzombie_hurt1.wav ", "zombi/boosterzombie_hurt2.wav" }
new const zombie_die_sound[][] = { "zombi/boosterzombie_death1.wav ", "zombi/boosterzombie_death2.wav" }

public plugin_precache()
{
	for(new i = 0; i<2; i++) 
	{
		engfunc(EngFunc_PrecacheSound, zombie_pain_sound[i])
		engfunc(EngFunc_PrecacheSound, zombie_die_sound[i])
	}
	
	engfunc(EngFunc_PrecacheModel, "models/player/zbz_booster/zbz_booster.mdl")
	
	engfunc(EngFunc_PrecacheModel, "models/zbz/v_knife_booster.mdl")
	engfunc(EngFunc_PrecacheModel, "models/zbz/v_zombibomb_booster.mdl")
	
	engfunc(EngFunc_PrecacheSound, "zombi/boosterzombie_booster.wav");
}

public plugin_init() 
{
	register_plugin("[Zombie Z] Class Chaser", "1.0", "csbtedhan");
	register_forward(FM_CmdStart, "fw_CmdStart")
	register_forward(FM_EmitSound, "fw_EmitSound")
	
	g_Hud = CreateHudSyncObj()
	
	g_Classid = cs_zb_register_class("Chaser Zombie", "booster", "zbz_booster", "booster", 0.8, 310.0, 0.75, 1, 27, 1);
}


public client_command(id)
{
	if(!is_user_alive(id) || !cs_zb_is_zombie(id) || cs_zb_get_zombie_class(id) != g_Classid)
		return PLUGIN_CONTINUE
	
	new arg[13]
	if (read_argv(0, arg, 12) > 11) return PLUGIN_CONTINUE 
	if(g_iSkillStat[0][id] >= MINSTAT && get_user_weapon(id) == CSW_KNIFE)
	{
		if(equali(arg, "drop"))
		{
			set_pdata_float(id, 83, 1.3);
			Boost(id)
			g_iSkillStat[0][id] = 0
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
		if(g_flSkillTime[id] <= get_gametime() && g_iSkillStat[1][id] == 0 && get_user_weapon(id) == CSW_KNIFE)
		{
			g_iSkillStat[1][id] = 1
			set_pdata_float(id, 83, 1.0);
			set_pev(id, pev_gravity, 0.45);
			play_sound(id, "zombi/speedup.wav")
			fm_set_rendering(id, kRenderFxGlowShell, 100, 100, 100)
			g_flSkillTime[id] = get_gametime() + 7.0;
			
		}
	}
}
public fw_CSZB_Infected(id, attacker)
{
	g_iJump[id] = 0
	g_iSkillStat[0][id] = 0
	g_iSkillStat[1][id] = 0;
}
public fw_CSZB_OnStartRound(id)
{
	g_iJump[id] = 0
	g_iSkillStat[0][id] = 0
	g_iSkillStat[1][id] = 0;
}
public fw_CSHUD(id)
{
	if(!cs_zb_is_zombie(id) || cs_zb_get_zombie_class(id) != g_Classid || !is_user_alive(id))
		return
		
	new width
	width = (((g_iSkillStat[0][id] - 1 ) * 100) / MAXSTAT)
	width = max(0, min(100, width))
	
	set_hudmessage(255, 255, 255, -1.0, 0.25, 0, 0.0, 1.0, 0.0, 0.0, 12);
	ShowSyncHudMsg(id, g_Hud, "[G]Booster %i%: %s [R]Gravity: %s", width, (g_flSkillTime[id] <= get_gametime() && g_iSkillStat[0][id] > MINSTAT) ? "Ready" : "Cooldown",  (g_flSkillTime[id] <= get_gametime() && g_iSkillStat[1][id] ==0) ? "Ready" : "Cooldown");
	
}
public Boost(id)
{
	if(!cs_zb_is_zombie(id) || cs_zb_get_zombie_class(id) != g_Classid || !is_user_alive(id))
		return
		
	
	SetPlayerAnimation(id, "skill");
	
	new Float:vVelocity[3], Float:pVelocity[3];
	pev(id, pev_velocity, pVelocity);
	velocity_by_aim(id, g_iSkillStat[0][id], vVelocity);
	xs_vec_add(pVelocity, vVelocity, pVelocity);
	set_pev(id, pev_velocity, pVelocity);
	
	if(!cs_zb_is_using_nvgs(id))
	{
		message_begin(MSG_ONE_UNRELIABLE, get_user_msgid("ScreenFade"), _, id);
		write_short(1<<9);
		write_short(0);
		write_short(0x0000);
		write_byte(200);//r
		write_byte(0);  //g
		write_byte(0);  //b
		write_byte(100);
		message_end();
	}
			
	engfunc(EngFunc_EmitSound, id, CHAN_BODY, "zombi/boosterzombie_booster.wav", 1.0, 0.8, 0, 100);
}
public fw_CSZB_OnPreThink(id)
{
	if(!cs_zb_is_zombie(id) || cs_zb_get_zombie_class(id) != g_Classid || !is_user_alive(id))
		return
	
	if(g_flSkillTime[id] <= get_gametime() && g_iSkillStat[1][id])
	{
		set_pdata_float(id, 83, 1.0);
		g_iSkillStat[1][id] = 0
		set_pev(id, pev_gravity, 0.7)
		set_pev(id, pev_maxspeed, 280.0)
		fm_set_rendering(id);
		g_flSkillTime[id] = get_gametime() + 8.0;
	}
	
	if((pev(id, pev_button) & IN_JUMP) && (pev(id, pev_flags) & FL_ONGROUND))
	{
		g_iJump[id] = 1;
	}
}
public fw_CSZB_OnPostThink(id)
{
	if(!cs_zb_is_zombie(id) || cs_zb_get_zombie_class(id) != g_Classid || !is_user_alive(id))
		return
		
	static Float:pVelocity[3]
	if(g_iJump[id] && (pev(id, pev_flags) & FL_ONGROUND) && !(pev(id, pev_oldbuttons) & IN_JUMP))
	{
		pev(id, pev_velocity, pVelocity);
		g_iJump[id] = 0
		g_iSkillStat[0][id] = min(MAXSTAT, g_iSkillStat[0][id] + floatround(vector_length(pVelocity)*0.085));
	}
		
}

stock play_sound(id, const sound[])
{
	if (equal(sound[strlen(sound)-4], ".mp3"))
		client_cmd(id, "mp3 play ^"sound/%s^"", sound)
	else
		client_cmd(id, "spk ^"%s^"", sound)
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
