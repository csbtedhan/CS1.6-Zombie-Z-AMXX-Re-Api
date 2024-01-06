#include <amxmodx>
#include <xs>
#include <zombiemodlimited>
#include <fakemeta>
#include <hamsandwich>
#include <cstrike>
#include <csm>

new Float:g_flSkillTime[33], Float:g_flAPTime[33], g_Classid, Float:flCoffinRemove[8192];
new Float:flBotTime[33], Float:flSlowTime[33], g_iSlowing[33], g_Hud
new const zombie_pain_sound[][] = { "zombi/zombi_hurt_stamper_1.wav ", "zombi/zombi_hurt_stamper_2.wav" }
new const zombie_die_sound[][] = { "zombi/zombi_death_stamper_1.wav ", "zombi/zombi_death_stamper_2.wav" }

public plugin_precache()
{
	for(new i = 0; i<2; i++) 
	{
		engfunc(EngFunc_PrecacheSound, zombie_pain_sound[i])
		engfunc(EngFunc_PrecacheSound, zombie_die_sound[i])
	}
	
	engfunc(EngFunc_PrecacheModel, "models/player/zbz_stamper/zbz_stamper.mdl")
	
	engfunc(EngFunc_PrecacheModel, "models/zbz/v_knife_undertaker.mdl")
	engfunc(EngFunc_PrecacheModel, "models/zbz/v_zombibomb_undertaker.mdl")
	
	engfunc(EngFunc_PrecacheModel, "models/zbz/zombiepile.mdl");
	engfunc(EngFunc_PrecacheModel, "models/zbz/woodgibs.mdl");
	engfunc(EngFunc_PrecacheModel, "models/zbz/ef_scorpion_hole.mdl");
	
	engfunc(EngFunc_PrecacheSound, "zombi/zombi_stamper_iron_maiden_stamping.wav");
	engfunc(EngFunc_PrecacheSound, "zombi/zombi_stamper_iron_maiden_explosion.wav");
	engfunc(EngFunc_PrecacheSound, "zombi/zombi_wood_broken.wav");
}
public plugin_init() 
{
	register_plugin("[Zombie Z] Class Stamper", "1.0", "csbtedhan");
	RegisterHam(Ham_Think, "info_target", "CoffinThink");
	
	register_forward(FM_EmitSound, "fw_EmitSound")
	register_forward(FM_CmdStart, "fw_CmdStart")
	
	g_Hud = CreateHudSyncObj()
	
	g_Classid = cs_zb_register_class("Stamper Zombie", "stamper", "zbz_stamper", "undertaker", 0.8, 290.0, 1.1, 1, 7, 1);
}

public client_command(id)
{
	if(!is_user_alive(id) || !cs_zb_is_zombie(id) || cs_zb_get_zombie_class(id) != g_Classid)
		return PLUGIN_CONTINUE
	
	new arg[13]
	if (read_argv(0, arg, 12) > 11) return PLUGIN_CONTINUE 
	if(g_flSkillTime[id] <= get_gametime())
	{
		if(equali(arg, "drop") && pev(id, pev_flags) & FL_ONGROUND && !IsDucking(id))
		{
			if(MakeCoffin(id))
			{
				g_flSkillTime[id] = get_gametime() + 10.0;
				Set_WeaponAnim(id, 2)
				set_pdata_float(id, 83, 1.0);
			} else client_print(id, print_center, "No free space!")
			return PLUGIN_HANDLED
		}
	}
	return PLUGIN_CONTINUE
}

public fw_CSHUD(id)
{
	if(!cs_zb_is_zombie(id) || cs_zb_get_zombie_class(id) != g_Classid || !is_user_alive(id))
		return
		
	set_hudmessage(255, 255, 255, -1.0, 0.25, 0, 0.0, 0.2, 0.0, 0.0);
	ShowSyncHudMsg(id, g_Hud, "[G]Stamp: %s [R]Hardening: %s", (g_flSkillTime[id] <= get_gametime()) ? "Ready" : "Cooldown",  (g_flAPTime[id] <= get_gametime()) ? "Ready" : "Cooldown");
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
			cs_set_user_armor(id, pev(id, pev_armorvalue) + 1000, CS_ARMOR_KEVLAR);
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
	
	if(is_user_bot(id) && flBotTime[id] <= get_gametime() && pev(id, pev_flags) & FL_ONGROUND)
	{
		if(random(10) > 7 && !IsDucking(id)) MakeCoffin(id)
		flBotTime[id] = get_gametime() + 10.0;
	}	
}
public fw_CSNew_Round() RemoveSpecificEntity("zombiepile")
public fw_CSZB_Infected(id, attacker) g_iSlowing[id] = 0;
public fw_CSZB_Killed(id, attacker) 
{
	g_iSlowing[id] = 0;
	RemoveUserCoffin(id);
}
public fw_CSZB_OnSpawn(id) 
{
	g_iSlowing[id] = 0;
	RemoveUserCoffin(id);
}
public fw_CSZB_OnPreThink(id)
{
	if(!is_user_alive(id)) return;
	
	if(g_iSlowing[id] == 1 && !cs_zb_is_zombie(id))
	{
		static Float:vVelocity[3]; pev(id, pev_velocity, vVelocity);
		vVelocity[0] *= 0.3
		vVelocity[1] *= 0.3
		set_pev(id, pev_velocity, vVelocity);
		if(flSlowTime[id] <= get_gametime()) g_iSlowing[id] = 0;
	}
	
	if(cs_zb_is_zombie(id) && g_iSlowing[id]) g_iSlowing[id] = 0;
}
public MakeCoffin(id)
{
	static pEnt, Float:vOrigin[3], Float:vForward[3], Float:vAngle[3];
	pev(id, pev_origin, vOrigin);
	pev(id, pev_v_angle, vAngle);
	vAngle[0] = 0.0;
	engfunc(EngFunc_MakeVectors, vAngle);
	global_get(glb_v_forward, vForward);
	xs_vec_mul_scalar(vForward, 40.0, vForward);
	xs_vec_add(vForward, vOrigin, vOrigin);
	
	if(engfunc(EngFunc_PointContents, vOrigin) == CONTENTS_SOLID)
		return 0;
	
	pEnt = engfunc(EngFunc_CreateNamedEntity, engfunc(EngFunc_AllocString, "info_target"))
	set_pev(pEnt, pev_origin, vOrigin);
	set_pev(pEnt, pev_movetype, MOVETYPE_TOSS);
	set_pev(pEnt, pev_euser1, id);
	set_pev(pEnt, pev_classname, "zombiepile");
	
	set_pev(pEnt, pev_takedamage, 2.0);
	set_pev(pEnt, pev_health, 100000.0 + 550.0);
	set_pev(pEnt, pev_angles, vAngle);
	
	engfunc(EngFunc_SetModel, pEnt, "models/zbz/zombiepile.mdl");
	
	set_pev(pEnt, pev_solid, SOLID_BBOX);
	engfunc(EngFunc_SetSize, pEnt, Float:{-10.0, -6.0, -36.0}, Float:{10.0, 6.0, 36.0})
	
	engfunc(EngFunc_DropToFloor, pEnt);
	
	flCoffinRemove[pEnt] = get_gametime() + 10.0;
	set_pev(pEnt, pev_nextthink, get_gametime());
	set_pev(pEnt, pev_dmgtime, get_gametime() + 3.0);
	
	ShockwaveEffect(vOrigin);
	engfunc(EngFunc_EmitAmbientSound, 0, vOrigin, "zombi/zombi_stamper_iron_maiden_stamping.wav", 1.0, 0.8, 0, 100);
	
	SlowDownTarget(vOrigin, id, 0);
	return 1;
}
public CoffinThink(Ent)
{
	if(!isCoffin(Ent)) return;
	
	if(pev(Ent, pev_iuser2) == 1)
	{
		engfunc(EngFunc_RemoveEntity, Ent);
		return;
	}
	
	static Float:vOrigin[3];
	pev(Ent, pev_origin, vOrigin);
	
	if(FindEnemy(Ent))
	{
		set_pev(Ent, pev_iuser1, 1);
	}
	
	if(pev(Ent, pev_iuser1) == 1 && pev(Ent, pev_dmgtime) <= get_gametime())
	{
		CoffinDestroyed(Ent);
		engfunc(EngFunc_RemoveEntity, Ent);
		return;
	}
	
	if(flCoffinRemove[Ent] <= get_gametime() || pev(Ent, pev_health) - 100000.0 <= 0.0)
	{
		CoffinDestroyed(Ent);
		engfunc(EngFunc_RemoveEntity, Ent);
		return;
	}
	set_pev(Ent, pev_nextthink, get_gametime());
}
public CoffinDestroyed(Ent)
{
	static Float:vOrigin[3];
	pev(Ent, pev_origin, vOrigin);
	
	message_begin(MSG_BROADCAST, SVC_TEMPENTITY)
	write_byte(3)
	engfunc(EngFunc_WriteCoord, vOrigin[0])
	engfunc(EngFunc_WriteCoord, vOrigin[1])
	engfunc(EngFunc_WriteCoord, vOrigin[2])
	write_short(engfunc(EngFunc_ModelIndex, "sprites/zombiebomb_exp.spr"))
	write_byte(30);
	write_byte(30);
	write_byte(14);
	message_end()
	
	message_begin(MSG_BROADCAST, SVC_TEMPENTITY)
	write_byte(TE_BREAKMODEL)
	engfunc(EngFunc_WriteCoord, vOrigin[0])
	engfunc(EngFunc_WriteCoord, vOrigin[1])
	engfunc(EngFunc_WriteCoord, vOrigin[2]+24)
	engfunc(EngFunc_WriteCoord, 16)
	engfunc(EngFunc_WriteCoord, 16)
	engfunc(EngFunc_WriteCoord, 16)
	engfunc(EngFunc_WriteCoord, random_num(-50, 50))
	engfunc(EngFunc_WriteCoord, random_num(-50, 50))
	engfunc(EngFunc_WriteCoord, 25)
	write_byte(10)
	write_short(engfunc(EngFunc_ModelIndex, "models/zbz/woodgibs.mdl"))
	write_byte(10)
	write_byte(25)
	write_byte(0x08)
	message_end()
	
	engfunc(EngFunc_EmitAmbientSound, 0, vOrigin, "zombi/zombi_stamper_iron_maiden_explosion.wav", 1.0, 0.5, 0, 100);
	engfunc(EngFunc_EmitAmbientSound, 0, vOrigin, "zombi/zombi_wood_broken.wav", 1.0, 0.8, 0, 100);
	
	SlowDownTarget(vOrigin, pev(Ent, pev_euser1), 1)
}
public ShockwaveEffect(Float:vOrigin[3])
{
	vOrigin[2] -= 36.0
	static pEnt; pEnt = engfunc(EngFunc_CreateNamedEntity, engfunc(EngFunc_AllocString, "info_target"))
	set_pev(pEnt, pev_origin, vOrigin);
	set_pev(pEnt, pev_classname, "zombiepile");
	engfunc(EngFunc_SetModel, pEnt, "models/zbz/ef_scorpion_hole.mdl");
	
	set_pev(pEnt, pev_iuser2, 1);
	set_pev(pEnt, pev_framerate, 1.0)
	set_pev(pEnt, pev_animtime, get_gametime());
	set_pev(pEnt, pev_nextthink, get_gametime() + 0.5);
	set_pev(pEnt, pev_sequence, 1)
}
public SlowDownTarget(Float:vOrigin[3], id, iMode)
{
	static pEnt, Float:pOrigin[3], Float:flDist, Float:flDamage
	pEnt = -1
	while((pEnt = engfunc(EngFunc_FindEntityInSphere, pEnt, vOrigin, 250.0)) != 0)
	{
		if(!pev_valid(pEnt)) continue;
		pev(pEnt, pev_origin, pOrigin);
		if(!isClearLine(pOrigin, vOrigin)) continue;
		
		flDist = vector_distance(pOrigin, vOrigin);
		flDamage = 50.0 - floatmul(50.0, floatdiv(flDist, 250.0))
		
		if(isBreakable(pEnt) && flDamage <= 0.0) flDamage = floatdiv(50.0, 2.0);
		if(flDamage > 0.0) ExecuteHamB(Ham_TakeDamage, pEnt, id, id, flDamage, isBreakable(pEnt) ? DMG_BLAST : DMG_CLUB);
		
		if(is_user_alive(pEnt))
		{
			if(!cs_zb_is_zombie(pEnt))
			{
				g_iSlowing[pEnt] = 1;
				flSlowTime[pEnt] = get_gametime() + 3.0;
			} else if (pEnt == id && iMode) Stock_MakeKnockback(pEnt, pOrigin, vOrigin, flDist, 450.0);
			
			message_begin(MSG_ONE_UNRELIABLE, get_user_msgid("ScreenShake"), _, pEnt)
			write_short((1<<12)*4)
			write_short((1<<12)*2)
			write_short((1<<12)*10)
			message_end()
		}
	}
}
stock IsDucking(id)
{
	return (pev(id, pev_flags) & (FL_DUCKING | FL_ONGROUND) == (FL_DUCKING | FL_ONGROUND))
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
		if(vector_distance(xOrigin, vOrigin) <= 250.0 && isClearLine(xOrigin, vOrigin))
			return 1;
	}
	return 0;
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

stock isClearLine(Float:vOrigin1[3], Float:vOrigin2[3])
{
	new Float:flFraction;
	engfunc(EngFunc_TraceLine, vOrigin1, vOrigin2,  IGNORE_MONSTERS|IGNORE_GLASS, -1, 0);
	get_tr2(0, TR_flFraction, flFraction)
	
	return (flFraction == 1.0);
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

stock isTarget(Ent)
{
	if (pev_valid(Ent) && !cs_zb_is_zombie(Ent) && is_user_alive(Ent))
		return 1;
	return 0;
}

stock Set_WeaponAnim(id, anim)
{
	set_pev(id, pev_weaponanim, anim)
	
	message_begin(MSG_ONE_UNRELIABLE, SVC_WEAPONANIM, {0, 0, 0}, id)
	write_byte(anim)
	write_byte(0)
	message_end()
}
stock RemoveUserCoffin(id)
{
	new pEnt = -1
	while((pEnt = engfunc(EngFunc_FindEntityByString, pEnt, "classname", "zombiepile")) != 0)
	{
		if(isCoffin(pEnt) && pev(pEnt, pev_euser1) == id)
			engfunc(EngFunc_RemoveEntity, pEnt)
	}
}
stock RemoveSpecificEntity(const szClassName[])
{
	new pEnt = -1
	while((pEnt = engfunc(EngFunc_FindEntityByString, pEnt, "classname", szClassName)) != 0)
	{
		if(!pev_valid(pEnt)) continue;
		
		engfunc(EngFunc_RemoveEntity, pEnt)
	}
}
stock isCoffin(Ent)
{
	if(!pev_valid(Ent)) return 0;
	
	static szClassName[32]; pev(Ent, pev_classname,szClassName, 31);
	return (equal(szClassName, "zombiepile"))
}
stock play_sound(id, const sound[])
{
	if (equal(sound[strlen(sound)-4], ".mp3"))
		client_cmd(id, "mp3 play ^"sound/%s^"", sound)
	else
		client_cmd(id, "spk ^"%s^"", sound)
}
/* AMXX-Studio Notes - DO NOT MODIFY BELOW HERE
*{\\ rtf1\\ ansi\\ deff0{\\ fonttbl{\\ f0\\ fnil Tahoma;}}\n\\ viewkind4\\ uc1\\ pard\\ lang1057\\ f0\\ fs16 \n\\ par }
*/
