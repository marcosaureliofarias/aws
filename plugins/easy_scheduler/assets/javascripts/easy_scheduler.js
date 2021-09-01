/*
 * = require dhtmlx_manager
 * = require ext/dhtmlxscheduler_agenda_view
 * = require ext/dhtmlxscheduler_year_view
 * = require ext/dhtmlxscheduler_active_links
 * = require ext/dhtmlxscheduler_key_nav
 * = require ext/dhtmlxscheduler_url
 * = require ext/dhtmlxscheduler_minical
 * = require_directory
*/
// throw "not implemented";

/**
 Rule of thumb:
 - dhtmlxscheduler.js + ext/dhtmlxscheduler_* - library code - do not modify it - only in rare cases if not possible to patch it
 - dhtmlx_* files - calendar-specific code (should not access CalendarMain instance or other code in files not starting with dhtmlx* )
 - init_scheduler - main contant point between dhtmlx_calendar and scheduler (scheduler specific stuff)
 - other files - scheduler specific stuff, mainly self-contained. It uses dhtmlx functions, but it does not modify them.
 */
