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
 * @return Map index
 */
native mapm_is_map_in_list(map[]);

/**
 * TODO: write this.
 * 
 * @noreturn
 */
native mapm_get_prefix(prefix[], len);

/**
 * TODO: write this.
 * 
 * @noreturn
 */
native mapm_start_vote(type);

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
native mapm_push_map_to_votelist(map[], ignore_check = false);

/**
 * TODO: write this.
 * Use in mapm_analysis_of_results()
 * 
 * @noreturn
 */
native mapm_get_count_maps_in_vote();

/**
 * TODO: write this.
 * Use in mapm_analysis_of_results()
 * 
 * @noreturn
 */
native mapm_get_voteitem_info(item, map[], len, &votes);

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
forward mapm_can_be_extended(type);

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
forward mapm_analysis_of_results();

/**
 * TODO: write this.
 * 
 * @noreturn
 */
forward mapm_vote_finished(map[]);
