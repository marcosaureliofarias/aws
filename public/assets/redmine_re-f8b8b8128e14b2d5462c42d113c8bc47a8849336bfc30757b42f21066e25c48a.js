function setLayoutHeight(){$("#content div.easy-content-page").height($(window).height()-$("#top-menu").height()-$("#header").height()-$("#footer").height()-40)}function getRightPaneImage(){return""==getURLParam("visualization_type")?"<img src='/images/comment.png'><br/><img src='/images/fav_off.png'>":""}function getURLParam(e){var t="",o=window.location.href;if(o.indexOf("?")>-1)for(var n=o.substr(o.indexOf("?")).toLowerCase().split("&"),i=0;i<n.length;i++)if(n[i].indexOf(e.toLowerCase()+"=")>-1){t=n[i].split("=")[1];break}return unescape(t)}function scrollContentPaneTo(e){var t=$("#detail_view"),o=$("#"+e).offset().top,n=t.offset().top;t.animate({scrollTop:"+="+(o-n)+"px"},100)}var reLayout=null;EASY.schedule.late(function(){$("#content div.easy-content-page").css("padding","0px"),setLayoutHeight(),reLayout=$("#content div.easy-content-page").layout({applyDefaultStyles:!0,fxSpeed:"fast",panes:{closable:!1},useStateCookie:!1,cookie__name:"redmine_re_plugin",cookie__path:"/",togglerAlign_closed:"top",togglerAlign_open:"top",west__size:200,west__spacing_closed:15,west__togglerTip_closed:"Show tree",west__togglerTip_open:"Hide tree",west__togglerLength_closed:0,west__togglerLength_open:0,west__initClosed:!1,east__size:250,east__spacing_closed:35,east__togglerContent_closed:getRightPaneImage(),east__slideTrigger_open:"mouseover",east__slideTrigger_close:"mouseout",east__initClosed:!0,east__togglerLength_closed:80,east__togglerLength_open:80}),$("#detail_view").click(function(){reLayout.close("east")})}),window.onresize=setLayoutHeight;