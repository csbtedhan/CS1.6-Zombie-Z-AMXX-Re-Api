#include <amxmodx>
#include <xs>
#include <zombiemodlimited>
#include <fakemeta>
#include <hamsandwich>
#include <cstrike>
#include <csm>

new Float:g_flSkillTime[33], Float:g_flAPTime[33], g_iSkillStat[33], g_Classid, Debug, Float:flGibRemove[8192], Float:flBotTime[33], g_Hud
new const zombie_pain_sound[][] = { "zombi/boomer_hurt1.wav ", "zombi/boomer_hurt2.wav" }
new const zombie_die_sound[] = "zombi/boomer_death.wav "


public plugin_precache()
{
	for(new i = 0; i<2; i++) 
		engfunc(EngFunc_PrecacheSound, zombie_pain_sound[i])
		
	engfunc(EngFunc_PrecacheSound, zombie_die_sound)
	engfunc(EngFunc_PrecacheModel, "models/player/zbz_boomer/zbz_boomer.mdl")
	
	engfunc(EngFunc_PrecacheModel, "models/zbz/v_knife_boomer.mdl")
	engfunc(EngFunc_PrecacheModel, "models/zbz/v_zombibomb_boomer.mdl")
	
	engfunc(EngFunc_PrecacheModel, "models/zbz/ef_boomer.mdl")
	engfunc(EngFunc_PrecacheModel, "models/zbz/ef_poison03.mdl")
	engfunc(EngFunc_PrecacheModel, "sprites/spr_boomer.spr");
	engfunc(EngFunc_PrecacheModel, "sprites/ef_boomer_ex.spr");
}
public plugin_init() 
{
	register_plugin("[Zombie Z] Class Venom", "1.0", "csbtedhan");
	RegisterHam(Ham_Think, "info_target", "BoomerGibThink");
	RegisterHam(Ham_Killed, "player", "fw_PlayerKilled")
	
	register_message(get_user_msgid("ClCorpse"), "msg_clcorpse")	
	
	g_Hud = CreateHudSyncObj()
	
	register_forward(FM_EmitSound, "fw_EmitSound")
	register_forward(FM_CmdStart, "fw_CmdStart")
	
	g_Classid = cs_zb_register_class("Venom Zombie", "boomer", "zbz_boomer", "boomer", 0.8, 260.0, 1.2, 1, 15, 1);
}
public client_putinserver(id)
{
	if(!Debug && is_user_bot(id) && get_cvar_num("bot_quota"))
	{
		set_task(0.1, "RegHamBots", id)
	}
	
}

public fw_CSHUD(id)
{
	if(!cs_zb_is_zombie(id) || cs_zb_get_zombie_class(id) != g_Classid || !is_user_alive(id))
		return
		
	set_hudmessage(255, 255, 255, -1.0, 0.25, 0, 0.0, 0.2, 0.0, 0.0, 12);
	ShowSyncHudMsg(id, g_Hud, "[G]Self-Destruct: %s [R]Hardening: %s", (g_flSkillTime[id] <= get_gametime() && g_iSkillStat[id]==0) ? "Ready" : "Cooldown",  (g_flSkillTime[id] <= get_gametime()) ? "Ready" : "Cooldown");
}
public msg_clcorpse()
{
	static id
	id = get_msg_arg_int(12)
	
	if(cs_zb_get_zombie_class(id) != g_Classid || !cs_zb_is_zombie(id))
		return PLUGIN_CONTINUE
	
	return PLUGIN_HANDLED
}  

public RegHamBots(id)
{
	if(Debug)return;
	RegisterHamFromEntity(Ham_Killed, id, "fw_PlayerKilled", 1)
	
	Debug = 1
}
public client_command(id)
{
	if(!is_user_alive(id) || !cs_zb_is_zombie(id) || cs_zb_get_zombie_class(id) != g_Classid)
		return PLUGIN_CONTINUE
	
	new arg[13], Float:flArmor
	if (read_argv(0, arg, 12) > 11) return PLUGIN_CONTINUE 
	if(g_flSkillTime[id] <= get_gametime() && g_iSkillStat[id] == 0)
	{
		if(equali(arg, "drop"))
		{
			g_iSkillStat[id] = 1
			pev(id, pev_armorvalue, flArmor)
			set_pev(id, pev_armorvalue, flArmor * 0.5)
			set_pev(id, pev_maxspeed, 350.0);
			fm_set_rendering(id, kRenderFxGlowShell, 255, 0, 0);
			engfunc(EngFunc_EmitSound, id, CHAN_VOICE, "zombi/zombi_pressure.wav", 1.0, 0.8, 0, 100);
			g_flSkillTime[id] = get_gametime() + 8.0;
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
		if(g_flAPTime[id] <= get_gametime())
		{
			play_sound(id, "zombi/smallmedkit1.wav")
			cs_set_user_armor(id, pev(id, pev_armorvalue) + 1000, CS_ARMOR_KEVLAR);
			g_flAPTime[id] = get_gametime() + 7.0;
			Set_WeaponAnim(id, 2)
			
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
public fw_CSZB_OnPreThink(id)
{
	if(!cs_zb_is_zombie(id) || cs_zb_get_zombie_class(id) != g_Classid || !is_user_alive(id))
		return;
		
	new Float:flArmor
	if(is_user_bot(id) && flBotTime[id] <= get_gametime() && g_flSkillTime[id] <= get_gametime() && g_iSkillStat[id] == 0 && random(8) > 4)
	{
		g_iSkillStat[id] = 1
		pev(id, pev_armorvalue, flArmor)
		set_pev(id, pev_armorvalue, flArmor * 0.5)
		set_pev(id, pev_maxspeed, 350.0);
		fm_set_rendering(id, kRenderFxGlowShell, 255, 0, 0);
		engfunc(EngFunc_EmitSound, id, CHAN_VOICE, "zombi/zombi_pressure.wav", 1.0, 0.8, 0, 100);
		g_flSkillTime[id] = get_gametime() + 8.0;
		flBotTime[id] = get_gametime() + random_float(8.0, 10.0)
	}
	if(g_flSkillTime[id] <= get_gametime())
	{
		if(g_iSkillStat[id] == 1)
		{
			g_iSkillStat[id] = 0;
			set_pev(id, pev_maxspeed, 270.0);
			fm_set_rendering(id);
			set_pdata_int(id, 363, 90);
			g_flSkillTime[id] = get_gametime() + 6.0
		}
	}
	if(g_iSkillStat[id] == 1) 
	{
		set_pev(id, pev_maxspeed, 350.0);
		set_pdata_float(id, 83, 1.0)
		if(FindEnemy(id))
		{
			user_kill(id)
		}
	}
}
public fw_PlayerKilled(id, pevAttacker, shouldgib)
{
	if(!cs_zb_is_zombie(id) || cs_zb_get_zombie_class(id) != g_Classid || !is_user_connected(id))
		return;
		
	g_iSkillStat[id] = 0;
	
	fm_set_rendering(id, kRenderFxNone, 0, 0, 0, kRenderTransAlpha, 0);
	
	MakeDeathEffect(id, 0);
	MakeDeathEffect(id, 1);
	MakeExplosion(id);
}
public MakeExplosion(id)
{
	static Float:vOrigin[3];
	pev(id, pev_origin, vOrigin);
	
	message_begin(MSG_BROADCAST, SVC_TEMPENTITY)
	write_byte(3)
	engfunc(EngFunc_WriteCoord, vOrigin[0])
	engfunc(EngFunc_WriteCoord, vOrigin[1])
	engfunc(EngFunc_WriteCoord, vOrigin[2])
	write_short(engfunc(EngFunc_ModelIndex, "sprites/spr_boomer.spr"))
	write_byte(random(4)+10)
	write_byte(15)
	write_byte(14)
	message_end()
	
	message_begin(MSG_BROADCAST, SVC_TEMPENTITY)
	write_byte(3)
	engfunc(EngFunc_WriteCoord, vOrigin[0])
	engfunc(EngFunc_WriteCoord, vOrigin[1])
	engfunc(EngFunc_WriteCoord, vOrigin[2])
	write_short(engfunc(EngFunc_ModelIndex, "sprites/ef_boomer_ex.spr"))
	write_byte(8)
	write_byte(10)
	write_byte(14)
	message_end()
	
	engfunc(EngFunc_EmitAmbientSound, 0, vOrigin, zombie_die_sound, 1.0, 0.7, 0, 100);
	
	static pEnt, Float:pOrigin[3], Float:flDist, Float:flDamage
	pEnt = -1
	while((pEnt = engfunc(EngFunc_FindEntityInSphere, pEnt, vOrigin, 350.0)) != 0)
	{
		if(!pev_valid(pEnt)) continue;
		
		pev(pEnt, pev_origin, pOrigin);
		flDist = vector_distance(pOrigin, vOrigin);
		flDamage = 450.0 - floatmul(450.0, floatdiv(flDist, 350.0))
		if(!isClearLine(pOrigin, vOrigin)) flDamage *= 0.6;
		
		if(isBreakable(pEnt) && flDamage <= 0.0) flDamage = floatdiv(450.0, 2.0);
		if(flDamage > 0.0) ExecuteHamB(Ham_TakeDamage, pEnt, id, id, flDamage, isBreakable(pEnt) ? DMG_BLAST : DMG_CLUB);
		
		if(is_user_alive(pEnt))
		{
			Stock_MakeKnockback(pEnt, pOrigin, vOrigin, flDist, 450.0);
			ZBombSlapAngle(pEnt)
			message_begin(MSG_ONE_UNRELIABLE, get_user_msgid("ScreenShake"), _, pEnt)
			write_short((1<<12)*4)
			write_short((1<<12)*2)
			write_short((1<<12)*10)
			message_end()
		}
	}
}
public MakeDeathEffect(id, iType)
{
	static pEnt, Float:vOrigin[3]
	pev(id, pev_origin, vOrigin);
	
	if(iType) vOrigin[2] -= 36.0
	
	pEnt = engfunc(EngFunc_CreateNamedEntity, engfunc(EngFunc_AllocString, "info_target"))
	set_pev(pEnt, pev_origin, vOrigin);
	set_pev(pEnt, pev_owner, id);
	set_pev(pEnt, pev_classname, "ef_boomer");
	
	set_pev(pEnt, pev_sequence, 0);
	set_pev(pEnt, pev_framerate, 1.0);
	set_pev(pEnt, pev_animtime, get_gametime());
	
	engfunc(EngFunc_SetModel, pEnt, iType ? "models/zbz/ef_poison03.mdl" : "models/zbz/ef_boomer.mdl")
	
	set_pev(pEnt, pev_renderamt, 255.0);
	set_pev(pEnt, pev_rendermode, iType ? kRenderTransAdd : kRenderTransAlpha);
	
	flGibRemove[pEnt] = get_gametime() + 2.0;
	
	set_pev(pEnt, pev_nextthink, get_gametime())
	
}
public BoomerGibThink(Ent)
{
	if(!isBoomerGib(Ent))
		return;
		
	set_pev(Ent, pev_renderamt, floatmin(255.0, floatmax(0.0, (flGibRemove[Ent]-get_gametime())*255.0)));
	if(flGibRemove[Ent] <= get_gametime())
	{
		engfunc(EngFunc_RemoveEntity, Ent);
		return;
	}
	set_pev(Ent, pev_nextthink, get_gametime())
}
stock Stock_MakeKnockback(iEnt, Float:fEntOrigin[3], Float:fPoint[3], Float:fDistance, Float:fDamage)
{
	new Float:fTime = floatdiv(fDistance, fDamage)
	new Float:fVelocity[3], Float:fEntVelocity[3];
	pev(iEnt, pev_velocity, fEntVelocity);
	fVelocity[0] = floatdiv((fEntOrigin[0] - fPoint[0]), fTime)
	fVelocity[1] = floatdiv((fEntOrigin[1] - fPoint[1]), fTime)
	fVelocity[2] = floatdiv((fEntOrigin[2] - fPoint[2]), fTime)
	xs_vec_add(fEntVelocity, fVelocity, fVelocity);
	fVelocity[2] += 100.0
	set_pev(iEnt, pev_velocity, fVelocity)
	return 1
}
stock Set_WeaponAnim(id, anim)
{
	set_pev(id, pev_weaponanim, anim)
	
	message_begin(MSG_ONE_UNRELIABLE, SVC_WEAPONANIM, {0, 0, 0}, id)
	write_byte(anim)
	write_byte(0)
	message_end()
}
stock ZBombSlapAngle(id)
{
	new Float:vAngle[3];
	pev(id, pev_punchangle, vAngle)
	vAngle[0] += (random(5)>3) ? -20.0 : 20.0;
	vAngle[1] += (random(5)>3) ? -20.0 : 20.0;
	set_pev(id, pev_punchangle, vAngle)
}
stock FindEnemy(id)
{
	static Float:vOrigin[3], Float:xOrigin[3]
	pev(id, pev_origin, vOrigin);
	for(new x = 0; x < get_maxplayers(); x ++ )
	{
		if(!is_user_connected(x) || !is_user_alive(x) || cs_zb_is_zombie(x) || x == id)
			continue;
		
		pev(x, pev_origin, xOrigin);
		if(vector_distance(xOrigin, vOrigin) <= 70.0 && isClearLine(vOrigin, xOrigin))
			return 1;
	}
	return 0;
}
stock isBoomerGib(Ent)
{
	if(!pev_valid(Ent)) return 0;
	
	static szClassName[32]; pev(Ent, pev_classname,szClassName, 31);
	return (equal(szClassName, "ef_boomer"))
}
stock play_sound(id, const sound[])
{
	if (equal(sound[strlen(sound)-4], ".mp3"))
		client_cmd(id, "mp3 play ^"sound/%s^"", sound)
	else
		client_cmd(id, "spk ^"%s^"", sound)
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
	if(pev(iEnt, pev_spawnflags) & SF_BREAK_TRIGGER_ONLY)
		return 0;
	if (equal(szClassname, "func_breakable") || equal(szClassname, "func_pushable")) return 1;
	return 0;
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
/* AMXX-Studio Notes - DO NOT MODIFY BELOW HERE
*{\\ rtf1\\ ansi\\ deff0{\\ fonttbl{\\ f0\\ fnil Tahoma;}}\n\\ viewkind4\\ uc1\\ pard\\ lang1057\\ f0\\ fs16 \n\\ par }
*/
