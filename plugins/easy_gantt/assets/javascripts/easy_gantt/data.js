/* data.js */
/* global ysy */
window.ysy = window.ysy || {};
ysy.data = ysy.data || {};
ysy.data.Data = function () {
  this._onChange = [];
  this._deleted = false;
  this._created = false;
  this._changed = false;
  this._cache = null;
};
ysy.data.Data.prototype = {
  permissions: null,
  problems: {},
  init: function (obj, parent) {
    this._old = obj;
    EasyGem.extend(this, obj);
    this._parent = parent;
    this._postInit();
    return this;
  },
  _postInit: function () {
  },
  set: function (key, val) {
    // in the case of object as a first parameter:
    // - parameter key is object and parameter val is not used.
    let history = true;
    if (typeof key === "object") {
      if(key.hasOwnProperty("history")){
        history = key.history;
        delete key.history;
      }
      var nObj = key;
    } else {
      nObj = {};
      nObj[key] = val;
    }
    var rev = {};
    for (var k in nObj) {
      if (!nObj.hasOwnProperty(k)) continue;
      var nObjk = nObj[k];
      var thisk = this[k];
      if (nObjk !== thisk) {
        if (ysy.main.isSameMoment(thisk, nObjk)) {
          ysy.log.debug("date filtered as same", "set");
          continue;
        }
        rev[k] = thisk;
        if (rev[k] === undefined) {
          rev[k] = null;
        }
      } else {
        ysy.log.debug(k + "=" + nObjk + " filtered as same", "set");
      }
    }
    if ($.isEmptyObject(rev)) {
      return false;
    }
    rev._changed = this._changed;
    $.extend(this, nObj);
    this._fireChanges(this, "set");
    if(!history) return true;
    ysy.history.add(rev, this);
    this._changed = true;
    return true;
  },
  register: function (func, ctx) {
    for (var i = 0; i < this._onChange.length; i++) {
      var reg = this._onChange[i];
      if (reg.ctx === ctx) {
        this._onChange[i] = {func: func, ctx: ctx};
        return;
      }
    }
    this._onChange.push({func: func, ctx: ctx});
  },
  unregister: function (ctx) {
    var nonch = [];
    for (var i = 0; i < this._onChange.length; i++) {
      var reg = this._onChange[i];
      if (reg.ctx !== ctx) {
        nonch.push(reg);
      }
    }
    this._onChange = nonch;
  },
  setSilent: function (key, val) {
    if (typeof key === "object") {
      var different;
      var keyk, thisk;
      for (var k in key) {
        if (!key.hasOwnProperty(k)) continue;
        keyk = key[k];
        thisk = this[k];
        if (keyk === thisk)continue;
        if (ysy.main.isSameMoment(thisk, keyk)) continue;
        this[k] = keyk;
        different = true;
      }
      return different || false;
      //$.extend(this, key);
    } else {
      if (this[key] === val) return false;
      this[key] = val;
      return true;
    }
  },
  _fireChanges: function (who, reason, onlyChildChanged) {
    if (who) {
      var reasonPart = "";
      if (reason) {
        reasonPart = " because of " + reason;
      }
      if (who === this) {
        var targetPart = "itself";
      } else {
        targetPart = this._name;
      }
      var name = who._name;
      if (!name) {
        name = who.name;
      }
      if (!name) {
        ysy.log.warning(who);
      }
      ysy.log.log("* " + name + " ordered repaint on " + targetPart + reasonPart);

    }
    if (onlyChildChanged) {
      var onChangeArray = this._onChildChange;
    } else {
      onChangeArray = this._onChange;
      this._cache = null;
    }
    if (onChangeArray.length > 0) {
      ysy.log.log("- " + this._name + (onlyChildChanged ? " on ChildChange" : " onChange") + " fired for " + onChangeArray.length + " widgets");
    } else {
      ysy.log.log("- no " + (onlyChildChanged ? "childChange" : "change") + " for " + this._name);
    }
    for (var i = 0; i < onChangeArray.length; i++) {
      var ctx = onChangeArray[i].ctx;
      if (!ctx || ctx.deleted) {
        onChangeArray.splice(i, 1);
        continue;
      }
      //this.onChangeNew[i].func();
      ysy.log.log("-- changes to " + (ctx.name ? ctx.name : ctx._name) + " widget");
      //console.log(ctx);
      onChangeArray[i].func.call(ctx, reason);
    }
  },
  remove: function () {
    if (this._deleted) return;
    var prevChanged = this._changed;
    this._changed = true;
    this._deleted = true;
    if (this._parent && this._parent.isArray) {
      this._parent.pop(this);
    }
    ysy.history.add(function () {
      this._changed = prevChanged;
      this._deleted = false;
      if (this._parent && this._parent.isArray) {
        this._parent._fireChanges(this, "revert parent");
      }
    }, this);
    this._fireChanges(this, "remove");
  },
  removeSilent: function () {
    if (this._deleted) return;
    this._deleted = true;
  },
  clearCache: function () {
    this._cache = null;
  },
  getDiff: function (newObj) {
    var diff = {};
    var any = false;
    for (var key in newObj) {
      if (!newObj.hasOwnProperty(key)) continue;
      var newItem = newObj[key];
      if (newItem != this._old[key]) {
        if (moment.isMoment(newItem)) {
          if (newItem.format("YYYY-MM-DD") === this._old[key]) continue;
        }
        diff[key] = newObj[key];
        any = true;
      }
    }
    if (!any) return null;
    return diff;
  },
  isEditable: function () {
    if (!this.permissions) return false;
    return !!this.permissions.editable;
  },
  getProblems: function () {
    if (this._cache && this._cache.problems !== undefined) {
      return this._cache.problems;
    }
    var ret = [];
    for (var problemType in this.problems) {
      if (!this.problems.hasOwnProperty(problemType)) continue;
      var res = this.problems[problemType].call(this);
      if (res) ret.push(res);
    }
    if (ret.length === 0) {
      ret = false;
    }
    if (!this._cache) {
      this._cache = {};
    }
    this._cache.problems = ret;
    return ret;
  }
};
//###########################################################################################x
ysy.data.Array = function () {
  ysy.data.Data.call(this);
  this.array = [];
  this.dict = {};
  this._onChildChange = [];
};
ysy.main.extender(ysy.data.Data, ysy.data.Array, {
  isArray: true,
  get: function (i) {
    if (i < 0 || i >= this.array.length) return null;
    return this.array[i];
  },
  getArray: function () {
    if (!this._cache) {
      var cache = [];
      for (var i = 0; i < this.array.length; i++) {
        if (this.array[i]._deleted) continue;
        cache.push(this.array[i]);
      }
      this._cache = cache;
    }
    return this._cache;
  },
  getByID: function (id) {
    if (id === undefined || id === null) return null;
    var el = this.dict[id];
    if (el) return el;
    for (var i = 0; i < this.array.length; i++) {
      if (id === this.array[i].id) {
        this.dict[id] = this.array[i];
        return this.array[i];
      }
    }
  },
  pushSilent: function (elem) {
    if (elem.id) {
      var same = this.getByID(elem.id);
      if (same) {
        var needFire = false;
        if (same._deleted !== elem._deleted) {
          needFire = true;
        }
        elem._onChange = same._onChange;
        same.setSilent(elem);
        same._fireChanges(this, "pushSame");
        if (needFire) {
          this._fireChanges(this, "pushSame");
        }
        return same;
      }
    }
    if (!elem._parent) {
      elem._parent = this;
    }
    elem.register(function () {
      // registered for observing changes in own children
      // do not propagate to full this._fireChanges()
      this.orderFireChildChange(elem);
    }, this);
    this.array.push(elem);
    if (elem.id) {
      this.dict[elem.id] = elem;
    }
    return elem;

  },
  childRegister: function (func, ctx) {
    for (var i = 0; i < this._onChildChange.length; i++) {
      var reg = this._onChildChange[i];
      if (reg.ctx === ctx) {
        this._onChildChange[i] = {func: func, ctx: ctx};
        return;
      }
    }
    this._onChildChange.push({func: func, ctx: ctx});
  },
  push: function (elem) {
    //var rev=this.array.slice();
    elem._changed = true;
    elem._created = true;
    elem = this.pushSilent(elem);
    this._fireChanges(this, "push");
    ysy.history.add(function () {
      //this.pop(elem);
      this._deleted = true;
      this._parent._fireChanges(this, "push revert");
      //this._fireChanges(this,"push revert");
    }, elem);

  },
  pop: function (model) {
    //ysy.data.history.saveDelete(this);
    if (model === undefined) {
      return false;
    }
    if (!model._deleted) {
      model.remove();
      return true;
    } else {

    }
    this._fireChanges(this, "pop");
    /*if(model._created){
     var rev=this.array.slice();
     this.cache=null;
     var arr=this.array;
     for(var i=0;i<arr;i++){
     if(arr[i]===model){
     this.array.splice(i, 1);
     console.log("removed item No. " + i);
     this._fireChanges(this,"pop");
     ysy.history.add(rev,this);
     return true;
     }
     }
     return false;
     }*/
    //this.array[i].deleted=true;
  },
  clear: function () {
    this.array = [];
    this.dict = {};
    this._fireChanges(this, "clear all");
  },
  clearSilent: function () {
    this.array = [];
    this.dict = {};
    this._cache = null;
  },
  orderFireChildChange: function (elem) {
    if (this.childChangeTimeout) {
      return;
    }
    var self = this;
    this.childChangeTimeout = setTimeout(function () {
      self._fireChanges(elem, "child updated", true);
      self.childChangeTimeout = null;
    }, 0);
  }
  /*size: function () {
   return this.getArray().length;
   }*/

});
//##############################################################################
ysy.data.IssuesArray = {
  _name: "IssuesArray"
};
//##############################################################################
ysy.data.Issue = function () {
  ysy.data.Data.call(this);
};
ysy.main.extender(ysy.data.Data, ysy.data.Issue, {
  _name: "Issue",
  ganttType: "task",
  isIssue: true,
  closed: false,
  css: '',
  _postInit: function () {
    if (this.start_date) {
      if (typeof this.start_date === "string") {
        this.start_date = moment(this.start_date, "YYYY-MM-DD");
      } else if (!this.start_date._isAMomentObject) {
        console.error("start_date is not string");
        this.start_date = moment(this.start_date).startOf("day");
      }
    }
    if (this.due_date) {
      this.end_date = moment(this.due_date, "YYYY-MM-DD");
      delete this.due_date;
    }
    if (this.start_date) {
      this._start_date = this.start_date;
    } else {
      if (this.end_date && this.end_date.isBefore(moment())) {
        this._start_date = moment(this.end_date);
      } else {
        this._start_date = moment().startOf("day");
      }
    }
    if (this.end_date) {
      this._end_date = this.end_date;
    } else {
      if (this.start_date && this.start_date.isAfter(moment())) {
        this._end_date = moment(this.start_date);
      } else {
        this._end_date = moment().startOf("day");
      }
    }
    //this.end_date._isEndDate = true;
    this._end_date._isEndDate = true;
    if (this.soonest_start) {
      this.soonest_start = moment(this.soonest_start, "YYYY-MM-DD");
    }
    if (this.latest_due) {
      this.latest_due = moment(this.latest_due, "YYYY-MM-DD");
      this.latest_due._isEndDate = true;
    }
    this._transformColumns();
  },
  _transformColumns: function () {
    var cols = this.columns;
    if (!cols) return;
    var ncols = {};
    for (var i = 0; i < cols.length; i++) {
      var col = cols[i];
      var cname = col.name.replace(/\./g, '_');
      ncols[cname] = col.value;
      if (col.value_id !== undefined) {
        ncols[cname + "_id"] = col.value_id;
      }
    }
    this.columns = ncols;
  },
  set: function (key, val) {
    // in the case of object as a first parameter:
    // - parameter key is object and parameter val is not used.
    if (typeof key === "object") {
      var nObj = key;
    } else {
      nObj = {};
      nObj[key] = val;
    }
    nObj = this._dateSetHelper(nObj);
    return ysy.data.Data.prototype.set.call(this, nObj);
  },
  setSilent: function (key, val) {
    // in the case of object as a first parameter:
    // - parameter key is object and parameter val is not used.
    if (typeof key === "object") {
      var nObj = key;
    } else {
      nObj = {};
      nObj[key] = val;
    }
    nObj = this._dateSetHelper(nObj);
    return ysy.data.Data.prototype.setSilent.call(this, nObj);
  },
  _dateSetHelper: function (nObj) {
    if (nObj.start_date) {
      if (nObj.start_date.isSame(this._start_date)) {
        delete nObj.start_date;
      } else {
        nObj._start_date = nObj.start_date
      }
    }
    if (nObj.end_date) {
      if (nObj.end_date.isSame(this._end_date)) {
        delete nObj.end_date;
      } else {
        nObj._end_date = nObj.end_date
      }
    }
    return nObj;
  },
  getID: function () {
    return this.id;
  },
  getParent: function () {
    var parent = ysy.data.issues.getByID(this.parent_issue_id);
    if (parent) {
      if (this.project_id === parent.project_id) {
        return this.parent_issue_id;
      }
    }
    if (this.fixed_version_id) {
      parent = ysy.data.milestones.getByID(this.fixed_version_id + "p" + this.project_id);
      if (parent) return "m" + this.fixed_version_id + "p" + this.project_id;
      parent = ysy.data.milestones.getByID(this.fixed_version_id);
      if (parent) {
        if (this.project_id === parent.project_id) {
          return "m" + this.fixed_version_id;
        }
      }
    }
    if (ysy.data.projects.getByID(this.project_id)) {
      return "p" + this.project_id;
    }
    return false;
  },
  problems: {
    checkOverMile: function () {
      if(!ysy.settings.milestonePush) return;
      if (!this.fixed_version_id) return;
      var milestone = ysy.data.milestones.getByID(this.fixed_version_id);
      if (!milestone || milestone._noDate) return;
        /*ysy.error("Error: Issue "+this.id+" not found its milestone");*/
      if (milestone.start_date.diff(this._end_date, "days") < 0)
        return ysy.settings.labels.problems.overMilestone
            .replace("%{effective_date}", milestone.start_date.format(gantt.config.date_format));
    },
    overDue: function () {
      if (
          !this.closed
          && this.end_date
          && this.end_date.isBefore(moment().subtract(1, "day")))
        return ysy.settings.labels.problems.overdue;
    }
  },
  getDuration: function (unit) {
    unit = unit || "days";
    if (this._cache && this._cache.duration) {
      return this._cache.duration[unit];
    }
    var durationPack = gantt._working_time_helper.get_work_units_between(this._start_date, this._end_date, "all");
    if (!this._cache) {
      this._cache = {};
    }
    this._cache.duration = durationPack;
    return durationPack[unit];
  },
  isOpened: function () {
    var opened = ysy.data.limits.openings[this.getID()];
    if (opened === undefined) {
      return true;
    }
    return opened;
  }
});
//############################################################################
ysy.data.Relation = function () {
  ysy.data.Data.call(this);
};
ysy.main.extender(ysy.data.Data, ysy.data.Relation, {
  _name: "Relation",
  _unlocked: false,
  _postInit: function () {
    //if(this.delay&&this.delay>0){this.delay--;}
  },
  getID: function () {
    return "r" + this.id;
  },
  getActDelay: function () {
    var sourceDate = this.getSourceDate();
    var targetDate = this.getTargetDate();
    if (!sourceDate || !targetDate) return this.delay;
    var correction = 0;
    if (sourceDate._isEndDate) correction -= 1;
    if (targetDate._isEndDate) correction += 1;
    return targetDate.diff(sourceDate, "days") + correction;
  },
  getSourceDate: function (source) {
    if (!source) source = this.getSource();
    if (!source) return null;
    if (this.type === "precedes") return source._end_date;
    if (this.type === "finish_to_finish") return source._end_date;
    if (this.type === "start_to_start") return source._start_date;
    if (this.type === "start_to_finish") return source._start_date;
    return null;
  },
  getTargetDate: function (target) {
    if (!target) target = this.getTarget();
    if (!target) return null;
    if (this.type === "precedes") return target._start_date;
    if (this.type === "finish_to_finish") return target._end_date;
    if (this.type === "start_to_start") return target._start_date;
    if (this.type === "start_to_finish") return target._end_date;
    return null;
  },
  getSourceCorrection: function () {
    if (this.type === "precedes") return 1;
    if (this.type === "finish_to_finish") return 1;
    return 0;
  },
  getTargetCorrection: function () {
    if (this.type === "start_to_finish") return -1;
    if (this.type === "finish_to_finish") return -1;
    return 0;
  },
  //getOtherDate: function (date, forSource) {
  //  var otherDate = gantt._working_time_helper.add_worktime(date, forSource ? -this.delay : this.delay, "day");
  //},
  getProblems: function () {
    var del = this.getActDelay();
    if(del < 0){
      if(this.checkNegativeDelay()) return [];
    }
    var diff = (this.delay || 0) - del;
    if (diff > 0)
      return [
        ysy.settings.labels.problems.shortDelay
            .replace("%{diff}", diff.toFixed(0))
      ];
    return [];
  },
  checkDelay: function () {
    var del = this.getActDelay();
    if(del < 0){
      if(this.checkNegativeDelay()) return true;
    }
    return del >= (this.delay || 0);
  },
  checkNegativeDelay:function () {
    var sourceDate = this.getSourceDate();
    var targetDate = this.getTargetDate();
    if (!sourceDate || !targetDate) return true;
    var delay = gantt._working_time_helper.get_work_units_between(sourceDate,targetDate,"days");
    return this.delay <= delay;
  },
  getSource: function () {
    return ysy.data.issues.getByID(this.source_id);
  },
  getTarget: function () {
    return ysy.data.issues.getByID(this.target_id);
  },
  isEditable: function () {
    var source = this.getSource();
    if (!source) return false;
    if (source.isEditable()) return true;
    var target = this.getTarget();
    if (!target) return false;
    if (target.isEditable()) return true;
  },
  isHalfLink: function () {
    return !(ysy.data.issues.getByID(this.source_id) && ysy.data.issues.getByID(this.target_id));
  }
});
//############################################################################
ysy.data.SimpleRelation = function () {
  ysy.data.Data.call(this);
};
ysy.main.extender(ysy.data.Relation, ysy.data.SimpleRelation, {
  _name: "SimpleRelation",
  isSimple: true,
  sendMoveRequest: function (allRequests) {
    return false
  },
  isEditable: function () {
    return false;
  }
});
//##############################################################################
ysy.data.Milestone = function () {
  ysy.data.Data.call(this);
};
ysy.main.extender(ysy.data.Data, ysy.data.Milestone, {
  _name: "Milestone",
  ganttType: "milestone",
  milestone: true,
  _postInit: function () {
    if (this.start_date) {
      if (typeof this.start_date === "string") {
        this.start_date = moment(this.start_date, "YYYY-MM-DD");
      } else {
        this.start_date = moment(this.start_date).startOf("day");
      }
    }
    if (!this.start_date) {
      this._noDate = true;
      this.start_date = moment().startOf("day");
    }
  },
  getID: function () {
    return "m" + this.id;
  },
  getIssues: function () {
    var retissues = [];
    var issues = ysy.data.issues.getArray();
    for (var i = 0; i < issues.length; i++) {
      if (issues[i].fixed_version_id === this.id) {
        retissues.push(issues[i]);
      }
    }
    return retissues;
  },
  _fireChanges: function (who, reason) {
    var prototype = ysy.data.Data.prototype;
    prototype._fireChanges.call(this, who, reason);
    var childs = this.getIssues();
    for (var i = 0; i < childs.length; i++) {
      childs[i]._fireChanges(this, "milestone change");
    }
  },
  getProblems: function () {
    return false;
  },
  getParent: function () {
    if (ysy.data.projects.getByID(this.project_id)) {
      return "p" + this.project_id;
    }
    return false;
  },
  isOpened: function () {
    var opened = ysy.data.limits.openings[this.getID()];
    if (opened === undefined) {
      return true;
    }
    return opened;
  }
});
//##############################################################################
ysy.data.SharedMilestone = function () {
  ysy.data.Milestone.call(this);
};
ysy.main.extender(ysy.data.Milestone, ysy.data.SharedMilestone, {
  _name: "SharedMilestone",
  isShared: true,
  ganttSubtype: "shared_milestone",
  _postInit: function () {
    this.real_id = this.id;
    this.id = this.id + "p" + this.project_id;
    this.css = "gantt_milestone_shared";
    this.__proto__.__proto__._postInit.call(this);
    this.real_milestone.register(function (reason) {
      if (reason === "revert") return;
      if (this.start_date.isSame(this.real_milestone.start_date)) return;
      this.set({start_date: moment(this.real_milestone.start_date)});
    }, this);
  },
  isEditable: function () {
    return false;
  }
});
//##############################################################################
ysy.data.Project = function () {
  ysy.data.Data.call(this);
};
ysy.main.extender(ysy.data.Data, ysy.data.Project, {
  _name: "Project",
  ganttType: "project",
  isProject: true,
  needLoad: true,
  issues_count: 0,
  has_subprojects: false,
  _shift: 0,
  _postInit: function () {
    this.start_date = this.start_date ? moment(this.start_date, "YYYY-MM-DD") : null;
    //this.end_date=moment(this.due_date).add(1, "d");
    if (this.due_date) {
      this.end_date = moment(this.due_date, "YYYY-MM-DD");
      this.end_date._isEndDate = true;
    }
    delete this.due_date;
    if (this.is_baseline) {
      this._ignore = true;
    }
    this.project_id = this.id;
    this.hadIssue = !!this.issues_count;
    if (ysy.settings.projectID === this.id) {
      ysy.data.limits.openings[this.getID()] = true;
      this.needLoad = false;
    }
    if (ysy.settings.global) {
      this.needLoad = this.needLoad && this.has_subprojects;
    }
    this._transformColumns();
  },
  _transformColumns: function () {
    var cols = this.columns;
    if (!cols) return;
    var ncols = {};
    for (var i = 0; i < cols.length; i++) {
      var col = cols[i];
      var cname = col.name.replace(/\./g, '_');
      ncols[cname] = col.value;
      if (col.value_id !== undefined) {
        ncols[cname + "_id"] = col.value_id;
      }
    }
    this.columns = ncols;
  },
  getID: function () {
    return "p" + this.id;
  },
  problems: {},
  getProgress: function () {
    return this.done_ratio / 100.0 || 0;
  },
  getParent: function () {
    if (ysy.data.projects.getByID(this.parent_id)) {
      return "p" + this.parent_id;
    }
    return false;
  },
  isOpened: function () {
    return ysy.data.limits.openings[this.getID()] || false;
  }
});
//##############################################################################
