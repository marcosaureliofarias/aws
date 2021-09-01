/**
 * DO NOT INCLUDE THIS FILE INTO WEB PAGE
 * THIS CODE IS ONLY MODEL FOR CODE DEFINED ELSEWHERE (i.e. in redmine_extension_gem)
 */
if(1===1){
  throw "DO NOT INCLUDE THIS FILE INTO WEB PAGE";
}
window.EASY = {};
/**
 * @typedef {Function} SchedulePrerequisite
 * @return {boolean}
 */
/**
 * @type {{out: boolean, late: EASY.schedule.late, require: EASY.schedule.require, main: EASY.schedule.main}}
 */
EASY.schedule = {
  /**
   * Functions, which should be executed right after "DOMContentLoaded" event.
   * @param {Function} func
   * @param {number} [priority=0] - Greater the priority, sooner [func] are called. Each 5 priority delays execution
   *                              by 30ms. Also negative values are accepted.
   */
  main: function (func, priority) {
  },
  /**
   * Functions, which should wait for [prerequisite] fulfillment
   * After that [func] is executed with return value of [prerequisite] as parameter
   * @example
   * // execute function after jQuery and window.logger are present
   * EasyGem.schedule.require(function($,logger){
     *   logger.log($.fn.jquery);
     * },'jQuery',function(){
     *   return window.logger;
     * });
   * @param {Function} func - function which will be called when all prerequisites are met. Results of prerequisites
   *                          are send into [func] as parameters
   * @param {...(SchedulePrerequisite|string)} prerequisite - more than one prerequisite can be specified here
   *                                           as rest parameters. Function or String are accepted. If String is used,
   *                                           predefined getter from [moduleGetters] or getter defined by [define]
   *                                           are called.
   */
  require: function (func, prerequisite) {
  },
  /**
   * Functions, which should be executed after several loops after "DOMContentLoaded" event.
   * Each 5 levels of priority increase delay by one stack.
   * @param {Function} func
   * @param {number} [priority=0]
   */
  late: function (func, priority) {
  },
  /**
   * Define module, which will be loaded by [require] function with [name] prerequisite
   * Only one instance will be created and cached also for future use.
   * If no one request the module, getter is never called.
   * @example
   * EasyGem.schedule.define('Counter', function () {
     *   var count = 0;
     *   return function () {
     *     console.log("Count: " + count++);
     *   }
     * });
   * @param {string} name
   * @param {Function} getter - getter or constructor
   */
  define: function (name, getter) {
  }
};
/**
 * Wrapper for safe execution of [body] function only in read phase to prevent force-redraws.
 * @example
 * // fill storage with values from DOM
 * var storage = {};
 * EasyGem.read(function(){
   *   this.offset = $element.offset();
   *   this.scrollTop = $(window).scrollTop();
   * }, storage);
 * @param {RenderFunction} body
 * @param {Object} [context]
 */
EasyGem.read = function (body, context) {
};
/**
 * Wrapper for safe execution of [body] function only in render phase to prevent force-redraws.
 * @example
 * var left = $element.css("left");
 * EasyGem.render(function(){
   *   $element.css({left: (left + 5) + "px"});
   * });
 * @param {RenderFunction} body - obtain execution time as first parameter
 * @param {Object} [context]
 */
EasyGem.render = function (body, context) {
};
/**
 * Complex and most-safe wrapper for DOM-manipulation code
 * Execute [read] and [render] function only in proper phases.
 * @example
 * // prevents layout thrashing
 * $table.find("td.first_column").each(function() {
   *   EasyGem.readAndRender(function() {
   *     return this.width();
   *   }, function(width, time) {
   *     this.next().width(width);
   *   }, $(this));
   * });
 * @param {RenderFunction} read
 * @param {RenderFunction} render - function(readResult, time) callback
 * @param {Object} [context]
 */
EasyGem.readAndRender = function (read, render, context) {
};