window.ysy=window.ysy||{},ysy.pro=ysy.pro||{},ysy.pro.resource=ysy.pro.resource||{},EasyGem.extend(ysy.pro.resource,{MARGIN:.05,renderStyles:{},compiledStyles:{},renderer_patch:function(){$.extend(gantt.templates,{grid_bullet_assignee:function(e){return e&&e.widget&&e.widget.model&&e.widget.model.avatar?'<div class="gantt_tree_icon gantt-assignee-avatar-bullet">'+e.widget.model.avatar+"</div>":"<div class='gantt_tree_icon gantt-assignee-bullet'></div>"},superitem_after_assignee:function(e){var r=e.widget&&e.widget.model;if(r._unassigned)return"";for(var t=[],s=0;s<7;s++)if(r.week_hours[s]!==r.__proto__.week_hours[s]){t.push(ysy.settings.labels.maxHours+": "+JSON.stringify(r.week_hours));break}return 1!==r.estimated_ratio&&t.push(ysy.settings.labels.estimatedRatio+": "+r.estimated_ratio),0===t.length?"":'<span class="gantt-superitem-after">('+t.join(", ")+")</span>"}}),this.compileStyles()},compileStyles:function(){this.renderStyles=ysy.settings.styles.resource,this.compiledStyles.wrong={fontStyle:this.renderStyles.fontBold,textColor:this.renderStyles.wrong},this.compiledStyles.fixed={fontStyle:this.renderStyles.fontBold,textColor:this.renderStyles.fixed},this.compiledStyles.normal={fontStyle:this.renderStyles.fontNormal,textColor:this.renderStyles.normal}},bindRenderers:function(){ysy.view.bars.registerRenderer("assignee",this.assignee_canvas_renderer),ysy.view.bars.registerRenderer("project",this.projectRenderer),ysy.view.bars.registerRenderer("task",this.taskRenderer),ysy.view.bars.registerRenderer("reservation",this.taskRenderer)},removeRenderers:function(){ysy.view.bars.removeRenderer("assignee",this.assignee_canvas_renderer),ysy.view.bars.removeRenderer("project",this.projectRenderer),ysy.view.bars.removeRenderer("task",this.taskRenderer),ysy.view.bars.removeRenderer("reservation",this.taskRenderer)},taskRenderer:function(e,r){var t=r().call(this,e,r);$(t).removeClass("gantt_parent_task-subtype");var s=ysy.pro.resource,n=$.proxy(s.issue_canvas_renderer,gantt)(e);if(n&&ysy.view.bars.insertCanvas(n,t),e.pos_y&&(t.style.transform="translate(0,"+(e.pos_y*gantt.config.row_height||0)+"px)"),ysy.settings.resource.withMilestones){var o=$.proxy(s.milestones.milestone_renderer,gantt)(e);o&&t.appendChild(o)}return t},projectRenderer:function(e,r){var t=r().call(this,e,r),s=$.proxy(ysy.pro.resource.project_canvas_renderer,gantt)(e);return s&&ysy.view.bars.insertCanvas(s,t),t},issue_canvas_renderer:function(e){var r=ysy.pro.resource;if(e.widget){var t=e.widget.model.getAllocations();if(null!==t){var s=ysy.view.bars.canvasListBuilder();s.build(e,this),"day"!==ysy.settings.zoom.zoom?$.proxy(r.issue_week_renderer,this)(e,t,s):$.proxy(r.issue_day_renderer,this)(e,t,s);var n=s.getElement(),o=null;return n.onclick=function(e){e.stopPropagation();var r=new MouseEvent(e.type,e);o||(o=setTimeout(function(){o=null,n.parentNode.dispatchEvent(r)},300))},e.widget.model.isEditable()&&(n.ondblclick=function(e){o&&(clearTimeout(o),o=null),$.proxy(r.allocationChange,n)(e,t.allocations)}),(n=s.getElement()).className+=" gantt-task-tooltip-area",n}}},project_canvas_renderer:function(e){var r=ysy.pro.resource,t=r.countSubAllocations(this,e.widget.model),s=ysy.view.bars.canvasListBuilder();s.build(e,this),"day"!==ysy.settings.zoom.zoom?$.proxy(r.issue_week_renderer,this)(e,t,s):$.proxy(r.issue_day_renderer,this)(e,t,s);var n=s.getElement();return n.className+=" project",n},issue_day_renderer:function(e,r,t){var s=ysy.pro.resource,n=r.allocations,o=s.compiledStyles;for(var i in n)if(n.hasOwnProperty(i)){var a=moment(i);if(!(a.isBefore(e.start_date)||e.end_date.diff(a,"days")<-1)){var d=n[i];if(d!==undefined){if(!t.inRange(i))return;if(r.types[i])if("fixed"===r.types[i])var l=o.fixed;else l=o.wrong;else{if(!d)continue;l=o.normal}var y=s.roundTo1(d);t.fillTextAt(i,y,l)}}}},issue_week_renderer:function(e,r,t){var s=ysy.pro.resource,n=ysy.settings.zoom.zoom,o=s._weekAllocationSummer(r,n,e.start_date,e.end_date),i=o.allocations,a=s.compiledStyles;for(var d in i)if(i.hasOwnProperty(d)&&t.inRange(d)){var l=i[d];if(0!==l){if(o.types[d])if("fixed"===o.types[d])var y=a.fixed;else y=a.wrong;else y=a.normal;var u=s.roundTo1(l);t.fillTextAt(d,u,y)}}},assignee_canvas_renderer:function(e){var r=ysy.pro.resource;if(e.widget&&!e.widget.model._unassigned){var t=e.widget.model,s=t.resources_sums,n=r.countSubAllocations(this,e.widget.model),o=n.allocations;for(var i in s)s.hasOwnProperty(i)&&(o[i]=(o[i]||0)+s[i]);ysy.settings.resource.buttons.hidePlanned&&r.planned.subtractPlanned(o,t);var a=ysy.view.bars.canvasListBuilder();a.build(e,this,this._min_date,this._max_date),ysy.settings.resource.freeCapacity?"day"!==ysy.settings.zoom.zoom?$.proxy(r.freeCapacity.assignee_week_renderer,this)(e,t,n,a):$.proxy(r.freeCapacity.assignee_day_renderer,this)(e,t,n,a):"day"!==ysy.settings.zoom.zoom?$.proxy(r.assignee_week_renderer,this)(e,t,n,a):$.proxy(r.assignee_day_renderer,this)(e,t,n,a);var d=a.getElement();return d.className+=" assignee",d.onmousedown=$.proxy(r.events.onMouseDown,d),d.onclick=function(e){$.proxy(r.events.onClick,d)(e,t)},d}},assignee_day_renderer:function(e,r,t,s){var n=ysy.pro.resource,o=this._min_date.valueOf(),i=moment(this._max_date).add(1,"days").valueOf(),a=t.allocations;for(var d in a)if(a.hasOwnProperty(d)){var l=moment(d);+l<o||+l>i||n.assignee_one_day_renderer.call(this,d,l,r,a[d],r.getEvents(d),t.types[d],s)}},assignee_one_day_renderer:function(e,r,t,s,n,o,i){var a=ysy.pro.resource;if(!(s<a.MARGIN&&s>-a.MARGIN)||n&&n.length){var d=null;if(n&&n.length>0){d={};for(var l=0;l<n.length;l++){var y=n[l];d[y.type]===undefined&&(d[y.type]=0),d[y.type]+=y.hours}}if(i.inRange(e)){if(ysy.settings.resource.freeCapacity)var u=s<0;else{var c=t.getMaxHours(e,r);u=c<s}var f=a.compiledStyles;if(u||o&&"fixed"!==o)var v=f.wrong;else v="fixed"===o?f.fixed:f.normal;a.renderTextIn(e,s,d,i,c,v)}}},assignee_week_renderer:function(e,r,t,s){var n=ysy.pro.resource,o=n._weekAllocationSummer(t,ysy.settings.zoom.zoom,this._min_date,this._max_date,r),i=o.allocations,a=o.types,d=o.events;for(var l in i)i.hasOwnProperty(l)&&n.assignee_one_week_renderer.call(this,l,null,r,i[l],d[l],a[l],s)},assignee_one_week_renderer:function(e,r,t,s,n,o,i){var a=ysy.pro.resource;if((!(s<a.MARGIN&&s>-a.MARGIN)||n)&&i.inRange(e)){var d=a.renderStyles;if(ysy.settings.resource.freeCapacity)var l=t,y=1-s/(t||.001);else y=s/((l=t.getMaxHoursInterval(e,r,ysy.settings.zoom.zoom))||.001);var u={};0!==y&&(u.backgroundColor=a.occupationToColor(y),u.shrink=!0),o?(u.fontStyle=d.fontBold,u.textColor="fixed"===o?d.fixed:d.wrong):(u.fontStyle=d.fontNormal,u.textColor=d.normal),a.renderTextIn(e,s,n,i,l,u)}},roundTo1:function(e){if(!e)return"";var r=(e=parseFloat(e))%1;return r<0&&(r+=1),r<this.MARGIN||r>1-this.MARGIN?e.toFixed():e.toFixed(1)},occupationToColor:function(e){if(0!==e){var r=ysy.pro.resource.renderStyles;return e>1?r.overAllocations:e>.7?r.fullAllocations:r.someAllocations}},renderTextIn:function(e,r,t,s,n,o){var i=s.columnWidth;if(t){const e=ysy.settings.labels.eventTypes.symbols;var a={easy_holiday_event:e.easy_holiday_event_short,meeting:e.meeting_short,nonworking_attendance:e.nonworking_attendance_short,unapproved_nonworking_attendance:e.unapproved_nonworking_attendance_short},d=[],l="meeting";t[l]&&d.push(a[l]+this.roundTo1(t[l])),t[l="nonworking_attendance"]&&d.push(a[l]+this.roundTo1(t[l])),t[l="unapproved_nonworking_attendance"]&&d.push(a[l]+this.roundTo1(t[l])),t[l="easy_holiday_event"]!=undefined&&d.push(a[l]+(t.isWeek?this.roundTo1(t[l]):""))}var y=d&&d.length;if(r>this.MARGIN||r<-this.MARGIN)if(n===undefined||i<40)var u=this.roundTo1(r);else{var c=" / ";i<55&&(c="/"),u=this.roundTo1(r)+c+this.roundTo1(n)}if(y)var f=d.join(",");s.fillTwoTextAt(e,f,u,o)},countSubAllocations:function(e,r){var t={},s={};r.isAssignee&&r.is_group&&r.user_ids&&this._groupAllocationSummer(r.user_ids,t);for(var n=ysy.data.issues.getArray(),o=0;o<n.length;o++){var i=n[o];if(r.isProject){if(i.project_id!==r.real_id||i.assigned_to_id!==r.assigned_to_id)continue}else if(i.assigned_to_id!==r.id)continue;var a=i.getAllocations();if(null!==a){var d=a.allocations,l=a.types;for(var y in d)d.hasOwnProperty(y)&&(l[y]&&(s[y]!==undefined&&"fixed"!==s[y]||(s[y]=l[y])),d[y]<=0||(t[y]===undefined?t[y]=d[y]:t[y]+=d[y]))}}return{allocations:t,types:s}},_groupAllocationSummer:function(e,r){for(var t=0;t<e.length;t++){var s=ysy.data.assignees.getByID(e[t]);if(s){var n=this.countSubAllocations(this,s).allocations;for(var o in n)n.hasOwnProperty(o)&&(r[o]===undefined?r[o]=n[o]:r[o]+=n[o])}}},_weekAllocationSummer:function(e,r,t,s,n){var o=ysy.view.bars,i=t.valueOf(),a=moment(s).add(1,"days").valueOf(),d=(ysy.pro.resource.MARGIN,{}),l={},y=e.allocations,u=e.types,c={};for(var f in y)if(y.hasOwnProperty(f)){var v=o.getFromDateCache(f);if(!(+v<i||+v>a)){var _=y[f],g=moment(v).startOf("week"===r?"isoWeek":r).toISOString();if(n){n.getMaxHours(f,v)<_&&(l[g]="wrong");var p=n.getEvents(f);if(p&&p.length>0){var h=c[g];h||(h={isWeek:!0},c[g]=h);for(var m=0;m<p.length;m++){var w=p[m];h[w.type]===undefined&&(h[w.type]=0),h[w.type]+=w.hours}}}d[g]===undefined?d[g]=_:d[g]+=_,u[f]&&(l[g]!==undefined&&"fixed"!==l[g]||(l[g]=u[f]))}}return{allocations:d,types:l,events:c}}});