EASY.schedule.late(function(){$("#sidebar_filter_input_nojs").remove(),$("#sidebar_filter .inputs").show(),$("#sidebar_filter_input").suggestible({ajax:{suggestions:{url:window.re_options.suggest_path,dataType:"json",data:function(t){return{query:t}},loading:function(t){$("#ajax-indicator").show(),t.elements.textBox.attr("disabled","disabled")},loaded:function(t){$("#ajax-indicator").hide(),t.elements.textBox.removeAttr("disabled")}}},layout:{containers:function(t,e){return new SuggestBoxContainers(t,e)},items:function(t){return new DirectArtifactsSuggestBoxItems(t)}}});var t=$("#sidebar_filter_input_container").data("elements");t.textBox.attr("name",t.inputName)});