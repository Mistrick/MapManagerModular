#include <amxmodx>
#include <map_manager>

#if AMXX_VERSION_NUM < 183
#include <colorchat>
#endif

#define PLUGIN "Map Manager: Nomination"
#define VERSION "0.0.1"
#define AUTHOR "Mistrick"

#pragma semicolon 1

public plugin_init()
{
	register_plugin(PLUGIN, VERSION, AUTHOR);
}

public mapm_prepare_votelist()
{
	new test_list[][] = {
		"de_dust2",
		"deathrun_arctic",
		"deathrun_c00l_f",
		"deathrun_all_green2"
	};

	for(new i; i < sizeof(test_list); i++) {
		server_print("%d - %s", i + 1, test_list[i]);
		mapm_push_map_to_votelist(test_list[i]);
	}
}