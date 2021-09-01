
$(document).on('keydown', '.easy-tag-list-field .ui-autocomplete-input', function(event) {
  if (event.keyCode === 13) {
    var array = $(event.target.parentElement.nextElementSibling);
    if (! array.entityArray("getValue").indexOf(event.target.value) !== -1) {
      array.entityArray("add", {id: event.target.value, name: event.target.value});
      event.target.value = "";
      event.preventDefault();
      event.stopPropagation();
    }
  }
});
