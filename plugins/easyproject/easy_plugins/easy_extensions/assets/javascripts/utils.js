/**
 *
 * @param {String} type
 * @param {String} message
 * @param {String} description
 * @example showAntMessage('error', 'Title', 'longer description')
 * @see https://www.antdv.com/components/notification/#API
 */
window.showAntMessage = function(type, message, description) {
  let event = new CustomEvent("notify", { detail: { type: type, message: message, description: description } });
  window.dispatchEvent(event);
}
