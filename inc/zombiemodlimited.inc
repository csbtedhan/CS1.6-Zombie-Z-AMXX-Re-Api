
// player handler data to core plugin
enum
{
	HDATA_CANRESPAWN,
	HDATA_HERO,
	HDATA_EVOLUTION,
	HDATA_CHANGECLASS,
	HDATA_BOMBHARDENING,
	HDATA_REINFORCED,
	HDATA_INTELECTUAL,
	HDATA_ZBARMORUP,
	HDATA_HPUP,
	HDATA_LUCKY,
	HDATA_DISCOUNT,
	HDATA_EARLYACCESS
}

// round status
enum
{
	ROUND_WARMUP,
	ROUND_NEW,
	ROUND_COUNTDOWN,
	ROUND_RUNNING,
	ROUND_ENDING
}

// nade block
enum
{
	HNADE_IGNORE,
	HNADE_BLOCK
}
native cs_zb_set_handler_data(index, handlerdata, iSet)
native cs_zb_get_handler_data(index, handlerdata)
native cs_zb_is_zombie(index)
native cs_zb_get_zombie_class(index)
native cs_zb_is_using_nvgs(index)
native cs_zb_get_user_maxhealth(index)
native cs_zb_get_maxlevel()
native cs_zb_set_level(index, newlevel)
native cs_zb_get_level(index)
native cs_zb_is_choosedzb(index)
native cs_zb_set_user_choosed(index, iSet)
native cs_zb_get_user_hero(index)
native cs_zb_register_class(const name[], const sysname[], const models[], const clawmodel[], Float:gravity, Float:maxspeed,  Float:knockback, usemodelindex, level, disablesound)
native cs_zb_get_user_thirdperson(index)
native cs_zb_set_user_unstuck(index)
native cs_zb_get_round_status()
native cs_zb_is_escape_mode()

enum
{
	CLASSVOICE_ROUNDSTART,
	CLASSVOICE_ROUNDWIN,
	CLASSVOICE_ROUNDLOSE,
	CLASSVOICE_HEADSHOT,
	CLASSVOICE_MELEE,
	CLASSVOICE_REVENGE,
	CLASSVOICE_PLANTING,
	CLASSVOICE_GRENADE,
	CLASSVOICE_EVOLUTION,
	CLASSVOICE_SKILLSPRINT,
	CLASSVOICE_SKILLHS
}

native pl_get_user_sex(id)
native pl_set_user_sex(id, sex)
native pl_get_user_team(id)
native pl_reset_user_model(id)
native pl_set_user_custom_model(id, active, model[], indexed)
native pl_set_user_model(id, model[])
native pl_set_user_model_index(id, modelindex)
native pl_reset_user_model_index(id)
native pl_set_user_sound(index, disabled)
native pl_get_user_sound(index)
native pl_get_user_model(id, model[], len)
native pl_class_is_potrait(index)
native pl_play_voice(index, type)


forward fw_CSZB_Infected(victim, attacker)
forward fw_CSZB_Killed(victim, attacker)
forward fw_CSZB_OnSpawn(id)
forward fw_CSZB_OnStartRound(id)
forward fw_CSZB_OnLevelUp(id)
forward fw_CSZB_OnPreThink(id)
forward fw_CSZB_OnPostThink(id)
forward fw_CSZB_OnEquip(id)
forward fw_CSZB_BoltImpact(id)
forward fw_CSZB_StuckRedraw(id)
forward fw_CSZB_Infecting(victim, attacker)
forward fw_CSZB_HumanNade_Pre(Ent, Owner)
forward fw_CSZB_HumanNade_Post(Ent, Owner)

/* AMXX-Studio Notes - DO NOT MODIFY BELOW HERE
*{\\ rtf1\\ ansi\\ deff0{\\ fonttbl{\\ f0\\ fnil Tahoma;}}\n\\ viewkind4\\ uc1\\ pard\\ lang1057\\ f0\\ fs16 \n\\ par }
*/
