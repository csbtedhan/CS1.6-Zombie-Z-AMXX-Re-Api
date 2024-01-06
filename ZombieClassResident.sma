#include <amxmodx>
#include <csm>
#include <zombiemodlimited>
#include <fakemeta>
#include <hamsandwich>
#include <xs>
#include <reapi>

new Float:g_flSkillTime[2][33], g_iSkillStat[2][33], g_iUseCount[33], g_Classid, g_Hud
new const zombie_pain_sound[] = "zombi/resident_hurt1.wav"
new const zombie_die_sound[] = "zombi/resident_death.wav"


public plugin_precache() 
{
	engfunc(EngFunc_PrecacheModel, "models/player/zbz_resident/zbz_resident.mdl")
	
	engfunc(EngFunc_PrecacheModel, "models/zbz/v_knife_resident.mdl")
	engfunc(EngFunc_PrecacheModel, "models/zbz/v_zombibomb_resident.mdl")
	
	engfunc(EngFunc_PrecacheSound, "zombi/resident_skill1.wav")
	engfunc(EngFunc_PrecacheSound, "zombi/resident_skill2.wav")
	
	engfunc(EngFunc_PrecacheSound, zombie_pain_sound)
	engfunc(EngFunc_PrecacheSound, zombie_die_sound)
	
}
public plugin_init() 
{
	register_plugin("[Zombie Z] Class Resident", "1.0", "csbtedhan");
	
	g_Hud = CreateHudSyncObj()
	
	register_forward(FM_CmdStart, "fw_CmdStart")
	register_forward(FM_EmitSound, "fw_EmitSound")
	
	g_Classid = cs_zb_register_class("Resident Zombie", "resident", "zbz_resident", "resident", 0.8, 320.0, 0.7, 1, 19, 1);
}

public fw_CSHUD(id)
{
	if(!cs_zb_is_zombie(id) || cs_zb_get_zombie_class(id) != g_Classid || !is_user_alive(id))
		return
		
	set_hudmessage(255, 255, 255, -1.0, 0.25, 0, 0.0, 0.2, 0.0, 0.0);
	ShowSyncHudMsg(id, g_Hud, "[G]Tentacle: %s [R]Gravity: %s", (g_flSkillTime[0][id] <= get_gametime() && g_iSkillStat[0][id]==0 && g_iUseCount[id]<2) ? "Ready" : "Cooldown",  (g_flSkillTime[1][id] <= get_gametime()&& g_iSkillStat[1][id]==0) ? "Ready" : "Cooldown");
}
public client_command(id)
{
	if(!is_user_alive(id) || !cs_zb_is_zombie(id) || cs_zb_get_zombie_class(id) != g_Classid)
		return PLUGIN_CONTINUE
	
	new arg[13]
	if (read_argv(0, arg, 12) > 11) return PLUGIN_CONTINUE 
	if(g_iSkillStat[0][id] == 0 && g_flSkillTime[0][id] <= get_gametime() && g_iUseCount[id] < 2 && get_user_weapon(id) == CSW_KNIFE)
	{
		if(equali(arg, "drop"))
		{
			g_iSkillStat[0][id] = 1
			set_pdata_float(id, 83, 1.3);
			
			Set_WeaponAnim(id, 8)
			SetPlayerAnimation(id, "skill1");
			
			engfunc(EngFunc_EmitSound, id, CHAN_VOICE, "zombi/resident_skill1.wav", 1.0, 0.8, 0, 100);
			g_flSkillTime[0][id] = get_gametime() + 0.1
			return PLUGIN_HANDLED
		}
	}
	return PLUGIN_CONTINUE
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
		if(g_flSkillTime[1][id] <= get_gametime() && g_iSkillStat[1][id] == 0 && get_user_weapon(id) == CSW_KNIFE)
		{
			g_iSkillStat[1][id] = 1
			set_pdata_float(id, 83, 1.0);
			Set_WeaponAnim(id, 9)
			SetPlayerAnimation(id, "skill2");
			engfunc(EngFunc_EmitSound, id, CHAN_VOICE, "zombi/resident_skill2.wav", 1.0, 0.8, 0, 100);
			set_pev(id, pev_gravity, 0.45);
			fm_set_rendering(id, kRenderFxGlowShell, 100, 100, 100)
			g_flSkillTime[1][id] = get_gametime() + 7.0;
			
		}
	}
}
public fw_CSZB_OnStartRound(id)
{
	g_iUseCount[id] = 0
	g_iSkillStat[0][id] = 0;
	g_flSkillTime[0][id] = get_gametime()
}
public fw_CSZB_OnSpawn(id)
{
	g_iSkillStat[0][id] = 0;
	g_flSkillTime[0][id] = get_gametime()
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
public fw_CSZB_Killed(id, attacker)
{
	if(!cs_zb_is_zombie(id) || cs_zb_get_zombie_class(id) != g_Classid)
		return
	
	g_iSkillStat[0][id] = 0
	g_iSkillStat[1][id] = 0
	set_pev(id, pev_gravity, 0.7)
	set_pev(id, pev_maxspeed, 280.0)
	fm_set_rendering(id);
}
public fw_CSZB_OnPreThink(id)
{
	if(!cs_zb_is_zombie(id) || cs_zb_get_zombie_class(id) != g_Classid || !is_user_alive(id))
		return

	if(g_iSkillStat[0][id] == 1 && g_flSkillTime[0][id] <= get_gametime())
	{
		DoRangedClaw(id)
		g_iSkillStat[0][id] = 0;
		g_iUseCount[id] ++
		g_flSkillTime[0][id] = get_gametime() + 50.0;
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
	
	if(is_user_bot(id) && BotFindEnemy(id))
	{
		if(g_iSkillStat[0][id] == 0 && g_flSkillTime[0][id] <= get_gametime() && g_iUseCount[id] < 2 && get_user_weapon(id) == CSW_KNIFE)
		{
			g_iSkillStat[0][id] = 1
			set_pdata_float(id, 83, 1.3);
			
			Set_WeaponAnim(id, 8)
			SetPlayerAnimation(id, "skill1");
			
			engfunc(EngFunc_EmitSound, id, CHAN_VOICE, "zombi/resident_skill1.wav", 1.0, 0.8, 0, 100);
			g_flSkillTime[0][id] = get_gametime() + 0.1
		}
	}
}
public DoRangedClaw(id)
{
	static Float:vOrigin[3], Float:vUps[3];
	pev(id, pev_origin, vOrigin);
	pev(id, pev_view_ofs, vUps);
	xs_vec_add(vOrigin, vUps, vOrigin);
	
	static Float:vDir[3], Float:vAngle[3], Float:vEnd[3];
	pev(id, pev_v_angle, vAngle);
	engfunc(EngFunc_MakeVectors, vAngle);
	global_get(glb_v_forward, vDir);
	xs_vec_mul_scalar(vDir, 180.0, vDir);
	xs_vec_add(vOrigin, vDir, vEnd);
	
	
	engfunc(EngFunc_TraceLine, vOrigin, vEnd, 0, id, 0);
	get_tr2(0, TR_vecEndPos, vEnd);
	
	new tr = create_tr2();
	new Float:pOrigin[3], Float:vOut[3], Float:vVel[3], Float:flDist, iVisible, pEnt = -1
	while((pEnt = engfunc(EngFunc_FindEntityInSphere, pEnt, vOrigin, 180.0)) != 0)
	{
		if(!pev_valid(pEnt) || pEnt == id)
			continue;
			
		pev(pEnt, pev_origin, pOrigin);

		xs_vec_sub(pOrigin, vOrigin, vDir);
		xs_vec_normalize(vDir, vDir);
		xs_vec_mul_scalar(vDir, 10.0, vVel);
		xs_vec_add(pOrigin, vVel, vOut);
		
		engfunc(EngFunc_TraceLine, vOrigin, vOut, 0, id, tr);

		flDist = DistanceFromLine(vOrigin, vEnd, pOrigin, iVisible)
		if(iVisible && flDist < 50.0 && isClearLine(pOrigin, vOrigin))
		{
			rg_multidmg_clear();
			ExecuteHamB(Ham_TraceAttack, pEnt, id, 5000.0, vDir, tr, DMG_BULLET);
			rg_multidmg_apply(id, id);
		}
	}
	free_tr2(tr);
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
		if(vector_distance(xOrigin, vOrigin) <= 180.0)
			return 1;
	}
	return 0;
}
stock Float:DistanceFromLine(Float:start[3],Float:end[3],Float:origin[3],&is_visible)
{
	new Float:deltas[3]
	deltas[0] = (start[1] - end[1]) / (start[0] - end[0])
	deltas[1] = (start[2] - end[2]) / (start[1] - end[1])
	deltas[2] = (start[1] - end[1]) / (start[2] - end[2])

	static Float:origin2[3]
	origin2[2] = origin[2]
	origin2[1] = (deltas[2] * (origin2[2] - start[2])) + start[1]
	origin2[0] = ((deltas[0] * start[0]) + origin2[1] - start[1]) / deltas[0]

	static Float:hit[3]
	engfunc(EngFunc_TraceLine,origin,origin2,1,0,0)
	get_tr2(0,TR_vecEndPos,hit)
	if(hit[0]==origin2[0] && hit[1]==origin2[1] && hit[2]==origin2[2])
		is_visible = 1
	else
		is_visible = 0
		

	return get_distance_f(origin,origin2)
}
stock isClearLine(Float:vOrigin1[3], Float:vOrigin2[3])
{
	new Float:flFraction;
	engfunc(EngFunc_TraceLine, vOrigin1, vOrigin2, IGNORE_MONSTERS, 0, 0);
	get_tr2(0, TR_flFraction, flFraction)
	
	if (flFraction < 1.0) return 0;

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
