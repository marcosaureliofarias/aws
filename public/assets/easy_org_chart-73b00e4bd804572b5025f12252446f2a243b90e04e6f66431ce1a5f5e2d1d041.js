!function(a){function e(a,e){var t=parseFloat(a.data("zoom"))||1;switch(e){case"in":t+=.1;break;case"out":t-=.1;break;default:t=1}a.data("zoom",t),a.children().css({transform:"scale("+t+")","transform-origin":"top left"})}function t(){s.each(function(){var t=a(this),r=t.parent(),o=t.data("path"),n=t.data("org-chart-editable"),d=t.data("org-chart-vertical-depth");o&&a.ajax({url:o,dataType:"json",cache:!1}).done(function(e){a.isEmptyObject(e)||t.orgchart(a.extend(v,{data:e,draggable:n,verticalDepth:d}))}),r.on("click","[data-org-chart-zoom]",function(a){a.preventDefault(),e(t,a.target.dataset.orgChartZoom)})})}function r(e){var t=a("<li class='link-list-item org-chart-user-list-item org-chart-user-removable' id='easy-org-chart-user-"+e.id+"' draggable='true'><span class='avatar-container'><img class='gravatar small' width='32' height='32' src='"+e.avatar+"'></span><div class='link-list-item-content link-list-item-ellipsis'>"+p(e.name)+"</div></li>");return t.data("org-chart-user",e),o.append(t),t}var o=a("#easy-org-chart-users"),n=a("#easy-org-chart-form"),d=a("#easy-org-chart-users-search"),s=a('[data-role="easy-org-chart"]'),i=a("#easy-org-chart-users-drop-zone"),c=a('[data-org-chart-action="save"]'),l=a("#easy-org-chart-with-user-id"),h=[],g=a("#easy-org-chart-without-user-id"),u=[],f={},v={draggable:!0,removable:!0,pan:!1,createNode:function(a,e,t){var r=a.find(".edge");a.html(m(e,t).html()),a.addClass("orgchart-user"),a.append(r)}},p=function(a){var e=document.createElement("div");return e.appendChild(document.createTextNode(a)),e.innerHTML},m=function(e,t){var r=a("<div draggable='true' id='"+e.id+"' class='node orgchart-user'></div>"),o=a("<ul class='orgchart-user-custom-fields'></ul>");t=a.extend({draggable:!0},t);if(e.avatar&&r.append("<div class='orgchart-user-avatar'><img width='32' height='32' class='gravatar' src='"+e.avatar+"'></div>"),t.draggable?r.append("<div class='orgchart-user-title'>"+p(e.name)+"</div>"):r.append("<div class='orgchart-user-title'><a href='/users/"+e.user_id+"/profile' data-remote='true'>"+p(e.name)+"</a></div>"),e.custom_fields.length>0){for(var n=0;n<e.custom_fields.length;n++)o.append("<li>"+e.custom_fields[n]+"</li>");r.append(o)}return f[e.id]=e,r},y=function(a){!0===a&&d.val(""),n.submit()},b=function(a){var e=atob(a).match(/User\/(\d+)$/);return e?parseInt(e[1]):0},w=function(a,e){return a.filter(function(a){return a!==e})},C=function(e){var t=a("#easy-org-chart-user-"+e),r=b(e);t.addClass("org-chart-user-hidden").hide(),h=w(h,r),u.push(r),l.val(h),g.val(u)},x=function(e){var t=a("#easy-org-chart-user-"+e),o=b(e);0===t.length&&f[e]&&(t=r(f[e])).removeClass("org-chart-user-removable"),t.removeClass("org-chart-user-hidden").show(),h.push(o),u=w(u,o),l.val(h),g.val(u)},D=function(){s.find(".node-parent").removeClass("node-parent"),s.find("table:has(.nodes) > tbody > tr:first-child .node").addClass("node-parent")};d.on("keyup",a.debounce(y,200)),s.on("drop",function(e){e.preventDefault();var t,r=e.originalEvent;t=a("#"+r.dataTransfer.getData("text")).data("org-chart-user"),t=a.extend(v,{data:t}),s.orgchart(t),C(t.id)}).on("dragover",function(a){""===this.innerHTML&&a.preventDefault()}).on("nodedropped.orgchart",function(a){C(a.draggedNode.attr("id")),D(),c.attr("disabled",!1)}).on("nodedragstart.orgchart",function(a){a.childrenState.exist||i.show()}).on("nodedragend.orgchart",function(){i.hide()}),o.on("dragstart",".org-chart-user-list-item",function(e){var t,r=a(this),o=e.originalEvent;r.is(".org-chart-user-list-item")||(r=r.closest(".org-chart-user-list-item")),t=m(r.data("org-chart-user")),a('<td colspan="2"><table><tr><td></td></tr></table></td>').find("td").append(t),s.find(".orgchart").data("dragged",t),o.dataTransfer.setDragImage(r[0],16,26),o.dataTransfer.setData("text",r.attr("id")),s.find(".node").addClass("allowedDrop")}).on("dragend",function(a){a.preventDefault(),s.find(".allowedDrop").removeClass("allowedDrop")}),i.on("scroll touchmove mousewheel",function(a){return a.preventDefault(),a.stopPropagation(),!1}).on("dragover",function(a){a.preventDefault()}).on("drop",function(a){a.preventDefault();var e,t=a.originalEvent.dataTransfer.getData("text");e=s.find("#"+t),s.orgchart("removeNodes",e),x(t),D(),c.attr("disabled",!1),i.hide()}),c.on("click",function(){var e=a(this),t={};s.children(".orgchart").length&&(t=s.orgchart("getHierarchy")),a.ajax(e.data("path"),{type:"post",data:{easy_org_chart:t}}).done(function(){showFlashMessage("notice","Organization structure has been successfully saved.").delay(1e3).fadeOut()}).fail(function(){showFlashMessage("error","Server Error.")}),c.attr("disabled",!0)}),a('[data-org-chart-action="export"]').on("click",function(){var e,t,r=a(this).closest(".orgchart-wrapper").find('[data-role="easy-org-chart"]').find(".orgchart"),o=a("body"),n=a("#ajax-indicator");if(0===r.length)return!1;(e=r.clone()).css("transform",""),e.find(".gravatar").removeClass("gravatar"),o.append(e),t=e.get(0),n.show(),html2canvas(t,{width:t.clientWidth,height:t.clientHeight,onrendered:function(t){var r="WebkitAppearance"in document.documentElement.style,d=!!window.sidebar,s="Microsoft Internet Explorer"===navigator.appName||"Netscape"===navigator.appName&&navigator.appVersion.indexOf("Edge")>-1;if(!r&&!d||s)window.navigator.msSaveBlob(t.msToBlob(),"easy-org-chart.png");else{var i=o.children(".org-chart-download");0===i.length&&(i=a('<a class="org-chart-download" download="easy-org-chart.png"></a>'),o.append(i)),i.attr("href",t.toDataURL()).get(0).click()}e.remove(),n.hide()}})}),a('[data-org-chart-action="toggle"]').on("click",function(){var e=a(this),t=e.closest(".orgchart-wrapper").find('[data-role="easy-org-chart"]'),r=t.find(".orgchart");if(0===r.length)return!1;if("expanded"===e.data("status")){var o=r.find(".node-root");t.orgchart("hideChildren",o),e.removeClass("icon-remove").addClass("icon-add").html(e.data("org-chart-expand")),e.data("status","collapsed")}else e.removeClass("icon-add").addClass("icon-remove").html(e.data("org-chart-collapse")),r.find("tr.hidden").removeClass("hidden"),r.find(".slide-up").removeClass("slide-up"),e.data("status","expanded")}),a("#easy-org-chart-form").on("ajax:success",function(e,t){a("#easy-org-chart-users").find(".org-chart-user-removable").remove();for(var o=0;o<t.entities.length;o++)r(t.entities[o])}),document.onkeydown=function(a){if(a.shiftKey||a.ctrlKey){var t=a.which||a.keyCode||a.charCode;38===t&&e(s,"in"),40===t&&e(s,"out")}},EASY.schedule.late(function(){t(),y(!0)})}(jQuery);