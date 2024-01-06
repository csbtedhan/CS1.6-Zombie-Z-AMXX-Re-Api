
native cs_dynamic_explosion(Float:Origin[3], ent, id, type)
native cs_incendiary_explosion(Float:Origin[3], ent, Float:duration)
native cs_radius_damage(pevAttacker, iInflictor, Float:vecOrigin[3], Float:flMaxDamage, Float:flRadius, Float:flKnockback, bitsDamageType, iCheckTeam)
native cs_take_damage(pevAttacker, iInflictor, iVictim, Float:flDamage, bitsDamageType, iCheckteam)
native cs_trigger_radius_damage(pevAttacker, Float:vecOrigin[3], iDamage, iRadius, Float:flDuration, bitsDamageType)
native cs_event_smoke(Float:Origin[3], Float:scale, Float:duration, Float:Color[3], Float:Velocity[3], type, spr, Float:maxscale)
native cs_set_user_footstep(index, silent)
native cs_get_user_footstep(index)
native cs_draw_vgui_combat(id, victim, headshot, weapon[])
native misc_make_bullet_hole(Float:vecOrigin[3], iEnt, iSound, pTextureName[64])

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
	CLASSVOICE_EVOLUTION
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

/* AMXX-Studio Notes - DO NOT MODIFY BELOW HERE
*{\\ rtf1\\ ansi\\ deff0{\\ fonttbl{\\ f0\\ fnil Tahoma;}}\n\\ viewkind4\\ uc1\\ pard\\ lang1033\\ f0\\ fs16 \n\\ par }
*/
