#if defined _map_manager_core_included
  #endinput
#endif
#define _map_manager_core_included

#if AMXX_VERSION_NUM >= 175
	#pragma reqlib map_manager_core
	#if !defined AMXMODX_NOAUTOLOAD
		#pragma loadlib map_manager_core
	#endif
#else
	#pragma library map_manager_core
#endif

#include <map_manager_consts>
#include <map_manager_stocks>

/**
 * TODO: write this.
 * 
 * @noreturn
 */
native mapm_start_vote();

/**
 * TODO: write this.
 * 
 * @noreturn
 */
native mapm_stop_vote();

/**
 * TODO: write this.
 * 
 * @noreturn
 */
native mapm_push_map_to_votelist(map[]);

/**
 * TODO: write this.
 * 
 * @noreturn
 */
forward mapm_maplist_loaded(Array:maplist);

/**
 * TODO: write this.
 * 
 * @noreturn
 */
forward mapm_prepare_votelist();

/**
 * TODO: write this.
 * 
 * @noreturn
 */
forward mapm_can_be_in_votelist(map[]);

/**
 * TODO: write this.
 * 
 * @noreturn
 */
forward mapm_vote_started();

/**
 * TODO: write this.
 * 
 * @noreturn
 */
forward mapm_vote_finished();
