window.EasyAutoSubmitForm = function (formID, options) {
  var defaults = {};
  this.options = $.extend({}, defaults, options);

  var form = document.getElementById(formID);
  var url = this.options['url'] || form.action;
  var method = this.options['method'] || form.method;
  var submitButton = this.options["submit"] && document.getElementById(this.options["submit"]) || document.querySelectorAll("#" + form.id + " input[type=submit]")[0];


  this.postback = function (event) {
    var data = $("input[name='" + event.target.name + "']").serializeArray();
    // data.push({name: "format", value: "json"});

    $.ajax({url: url, type: method, data: data})
  };

  $(document).on("change", "#" + form.id + " input", this.postback);

  return this;
};
