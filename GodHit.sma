
#include <amxmodx>
#include <fakemeta>
#include <hamsandwich>


new gBot
new const szSound[][] = { "player/god_hit1.wav", "player/god_hit2.wav", "player/god_hit3.wav" }

public plugin_precache()
{
	for(new x = 0; x < sizeof(szSound); x ++ )
		engfunc(EngFunc_PrecacheSound, szSound[x])
}
public plugin_init() 
{
	register_plugin("[CSGO:DM] God Hit", "1.0", "csbtedhan")
	
	RegisterHam(Ham_TraceAttack, "player", "HamF_TraceAttack")
}
public client_putinserver(id)
{
	if(is_user_bot(id) && get_cvar_num("bot_quota") && !gBot)
	{
		set_task(0.1, "RegHamBot", id);
	}
}
public RegHamBot(id)
{
	if(gBot) return;
	
	RegisterHamFromEntity(Ham_TraceAttack, id, "HamF_TraceAttack");
	gBot = 1
}

public HamF_TraceAttack(victim, attacker, Float:fDamage, Float:vDir[3], tr, DmgType)
{
	if(!pev_valid(victim) || !is_user_connected(victim))
		return;
		
	static Float:end[3];
	get_tr2(tr, TR_vecEndPos, end)
	
	if(is_user_alive(victim) && pev(victim, pev_takedamage) == 0.0)
	{
		message_begin(MSG_BROADCAST,SVC_TEMPENTITY);
		write_byte( 9 )
		engfunc( EngFunc_WriteCoord , end[0] )
		engfunc( EngFunc_WriteCoord , end[1] )
		engfunc( EngFunc_WriteCoord , end[2] )
		message_end()	
		
		engfunc(EngFunc_EmitAmbientSound, 0, end, szSound[random_num(0,2)], 1.0, 0.9, 0, 100)
	}
}