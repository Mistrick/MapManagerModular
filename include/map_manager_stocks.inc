#if defined _map_manager_stocks_included
  #endinput
#endif
#define _map_manager_stocks_included

stock valid_map(map[])
{
	if(is_map_valid(map)) return true;
	
	new len = strlen(map) - 4;
	
	if(len < 0) return false;
	
	if(equali(map[len], ".bsp")) {
		map[len] = '^0';
		if(is_map_valid(map)) return true;
	}
	
	return false;
}
stock get_map_prefix(map[], prefix[], size)
{
	copy(prefix, size, map);
	for(new i; prefix[i]; i++) {
		if(prefix[i] == '_') {
			prefix[i + 1] = 0;
			return 1;
		}
	}
	return 0;
}
stock bool:is_string_with_space(string[])
{
	for(new i; string[i]; i++) {
		if(string[i] == ' ') return true;
	}
	return false;
}
