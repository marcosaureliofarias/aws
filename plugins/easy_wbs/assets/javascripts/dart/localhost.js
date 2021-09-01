(function (pluginName) {
  var el;
  if (!window.Hammer) {
    el = document.createElement("script");
    el.defer = true;
    el.async = false;
    el.src = "/plugin_assets/" + pluginName + "/javascripts/dart/hammer.js";
    document.head.appendChild(el);
  }
  if (window.navigator.userAgent.indexOf('(Dart)') > -1) {
    el = document.createElement("script");
    el.defer = true;
    el.async = false;
    el.type = 'application/dart';
    el.src = "http://localhost:8080/" + pluginName + "/main.dart";
    document.head.appendChild(el);
  } else {
    el = document.createElement("script");
    el.defer = true;
    el.async = false;
    el.src = "http://localhost:8080/" + pluginName + "/dart_stack_trace_mapper.js";
    document.head.appendChild(el);
    el = document.createElement("script");
    el.defer = true;
    el.async = false;
    el.src = "http://localhost:8080/" + pluginName + "/require.js";
    el.setAttribute("data-main", "http://localhost:8080/" + pluginName + "/main.dart.bootstrap.js");
    document.head.appendChild(el);
  }
})("easy_wbs");
