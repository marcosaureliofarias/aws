!function(e){var t=0,n=function(){return(new Date).getTime()+t++},a=function(e){return"["+e+"]$1"},o=function(e){return"_"+e+"_$1"},i=function(t,n,a){return t?"function"==typeof t?(n&&console.warn("association-insertion-traversal is ignored, because association-insertion-node is given as a function."),t(a)):"string"==typeof t?n?a[n](t):"this"==t?a:e(t):void 0:a.parent()};e(document).on("click",".add_fields",function(t){t.preventDefault(),t.stopPropagation();var r=e(this),s=r.data("association"),c=r.data("associations"),d=r.data("association-insertion-template"),u=r.data("association-insertion-method")||r.data("association-insertion-position")||"before",l=r.data("association-insertion-node"),f=r.data("association-insertion-traversal"),p=parseInt(r.data("count"),10),g=new RegExp("\\[new_"+s+"\\](.*?\\s)","g"),v=new RegExp("_new_"+s+"_(\\w*)","g"),m=n(),h=d.replace(g,a(m)),_=[],w=t;for(h==d&&(g=new RegExp("\\[new_"+c+"\\](.*?\\s)","g"),v=new RegExp("_new_"+c+"_(\\w*)","g"),h=d.replace(g,a(m))),_=[h=h.replace(v,o(m))],p=isNaN(p)?1:Math.max(p,1),p-=1;p;)m=n(),h=(h=d.replace(g,a(m))).replace(v,o(m)),_.push(h),p-=1;var y=i(l,f,r);y&&0!=y.length||console.warn("Couldn't find the element to insert the template. Make sure your `data-association-insertion-*` on `link_to_add_association` is correct."),e.each(_,function(t,n){var a=e(n),o=jQuery.Event("cocoon:before-insert");if(y.trigger(o,[a,w]),!o.isDefaultPrevented()){y[u](a);y.trigger("cocoon:after-insert",[a,w])}})}),e(document).on("click",".remove_fields.dynamic, .remove_fields.existing",function(t){var n=e(this),a=n.data("wrapper-class")||"nested-fields",o=n.closest("."+a),i=o.parent(),r=t;t.preventDefault(),t.stopPropagation();var s=jQuery.Event("cocoon:before-remove");if(i.trigger(s,[o,r]),!s.isDefaultPrevented()){var c=i.data("remove-timeout")||0;setTimeout(function(){n.hasClass("dynamic")?o.detach():(n.prev("input[type=hidden]").val("1"),o.hide()),i.trigger("cocoon:after-remove",[o,r])},c)}}),e(document).on("ready page:load turbolinks:load",function(){e(".remove_fields.existing.destroyed").each(function(){var t=e(this),n=t.data("wrapper-class")||"nested-fields";t.closest("."+n).hide()})})}(jQuery);