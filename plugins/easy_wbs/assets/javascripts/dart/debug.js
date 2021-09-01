(function (pluginName) {
  var el;
  if (!window.Hammer) {
    el = document.createElement("script");
    el.defer = true;
    el.async = false;
    el.src = "/plugin_assets/" + pluginName + "/javascripts/dart/hammer.js";
    document.head.appendChild(el);
  }
  el = document.createElement("script");
  el.defer = true;
  el.async = false;
  el.src = "/plugin_assets/" + pluginName + "/javascripts/dart/build/web/" + pluginName + "/dart_stack_trace_mapper.js";
  document.head.appendChild(el);
  el = document.createElement("script");
  el.defer = true;
  el.async = false;
  el.src = "/plugin_assets/" + pluginName + "/javascripts/dart/build/web/" + pluginName + "/require.js";
  el.setAttribute("data-main", "/plugin_assets/" + pluginName + "/javascripts/dart/build/web/" + pluginName + "/main.dart.bootstrap");
  document.head.appendChild(el);
})("easy_wbs");
