#include <amxmodx> 
#include <cstrike> 
#include <fakemeta> 

new szSounds[1024][1024], iSound
new szModels[1024][1024], iModels
new szGeneric[1024][1024], iGeneric
new Enabled, HostSound

public plugin_precache() 
{ 
	load_config()
	
	register_forward(FM_PrecacheModel, "PrecacheModel") 
	register_forward(FM_PrecacheGeneric, "PrecacheGeneric") 
	register_forward(FM_PrecacheSound, "PrecacheSound") 
} 
public load_config()
{
	new cfg[64], path[128]
	get_mapname(cfg, charsmax(cfg))
	format(path, charsmax(path), "script/unprecache/%s.txt", cfg)
	if (!file_exists(path))
	{
		format(path, charsmax(path), "script/unprecache.txt")
	}
	
	new file, linedata[1386], key[512], value[960],  section
	file = fopen(path, "rt")
	
	while (file && !feof(file))
	{
		fgets(file, linedata, charsmax(linedata))
		replace(linedata, charsmax(linedata), "^n", "")
		
		if (!linedata[0] || linedata[0] == ';') continue;
		if (linedata[0] == '[')
		{
			section++
			continue;
		}
		
		if(section == 1)
		{
			parse(linedata, key, 511)
			format(szModels[iModels], 1023, "%s", key)
			iModels++
		}
		else if(section == 2)
		{
			parse(linedata, key, 511)
			format(szSounds[iSound], 1023, "%s", key)
			iSound++
		}
		else if(section == 3)
		{
			parse(linedata, key, 511)
			format(szGeneric[iGeneric], 1023, "%s", key)
			iGeneric++
		}
		else if(section == 4)
		{
			strtok(linedata, key, charsmax(key), value, charsmax(value), '=')
			trim(key)
			trim(value)
			
			if(equal(key, "unprecache_enabled")) Enabled = str_to_num(value)
			else if(equal(key, "unprecache_hostage_sound")) HostSound = str_to_num(value)
		}
	}
	server_print("Unprecache Loaded %i Model %i Sound %i Generic", iModels, iSound, iGeneric)
}

public PrecacheModel(const sModel[]) 
{ 
	if(!Enabled) return FMRES_IGNORED
	
	for(new i = 0; i < iModels; i++) 
	{ 
		if(containi(sModel, szModels[i]) != -1 ) 
		{ 
			server_print("Unprecache Block %s", sModel)
			forward_return(FMV_CELL, 0) 
			return FMRES_SUPERCEDE 
		} 
	} 
	return FMRES_IGNORED 
} 

public PrecacheSound(const sSound[]) 
{ 
	if(!Enabled) return FMRES_IGNORED
	
	if (equal(sSound, "hostage", 7) && HostSound)
		return FMRES_SUPERCEDE;
		
	for(new i = 0; i < iSound; i++) 
	{ 
		if(containi(sSound, szSounds[i]) != -1 ) 
		{ 
			server_print("Unprecache Block %s", sSound)
			forward_return(FMV_CELL, 0) 
			return FMRES_SUPERCEDE 
		} 
	} 
	return FMRES_IGNORED 
}
public PrecacheGeneric(const sGeneric[]) 
{ 
	if(!Enabled) return FMRES_IGNORED
	
	for(new i = 0; i < iGeneric; i++) 
	{
		if(containi(sGeneric, szGeneric[i]) != -1 ) 
		{ 
			server_print("Unprecache Block %s", sGeneric)
			forward_return(FMV_CELL, 0) 
			return FMRES_SUPERCEDE 
		} 
	} 
	return FMRES_IGNORED 
}
/* AMXX-Studio Notes - DO NOT MODIFY BELOW HERE
*{\\ rtf1\\ ansi\\ deff0{\\ fonttbl{\\ f0\\ fnil Tahoma;}}\n\\ viewkind4\\ uc1\\ pard\\ lang1057\\ f0\\ fs16 \n\\ par }
*/
