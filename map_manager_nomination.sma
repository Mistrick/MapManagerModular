#include <amxmodx>

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