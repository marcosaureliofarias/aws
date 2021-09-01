EasyGem.module.part("easyAgile", ['ActiveClass'], function () {
  "use strict";
  window.easyClasses = window.easyClasses || {};
  window.easyClasses.agile = window.easyClasses.agile || {};

  /**
   *
   * @constructor
   * @param {KanbanRoot} kanbanRoot
   * @param {Object} groupList
   * @property {Array.<{id:int,label:String}>}
   */
  function StickyLane(kanbanRoot, groupList) {
    this.cols = [];
    this.kanbanRoot = kanbanRoot;
    this.order = 500000;
    this.possibleValues = [];
    this._onChange = [];
    var keys = Object.keys(groupList);
    for (var i = 0; i < keys.length; i++) {
      var item = groupList[keys[i]];
      this.possibleValues.push({id: keys[i], label: item.name, order: item.order});
    }
    this.possibleValues.sort(function (a, b) {
      return a.order - b.order;
    });
    if (this.possibleValues.length) {
      this.changeValue(this.possibleValues[0]);
    }
  }

  easyClasses.ActiveClass.extendByMe(StickyLane);
  /**
   *
   * @type {KanbanRoot}
   */
  StickyLane.prototype.kanbanRoot = null;
  StickyLane.prototype.item = {id: 0, label: "---"};

  StickyLane.prototype.changeValue = function (item) {
    this.item = item;
    var value = item.id;
    this.cols = [];
    var ordering = this.kanbanRoot.middleColumnsOrdering;
    for (var i = 0; i < ordering.length; i++) {
      var column = this.kanbanRoot.middleColumns[ordering[i]];
      for (var j = 0; j < column.issuesList.length; j++) {
        var issues = column.issuesList[j];
        // noinspection EqualityComparisonWithCoercionJS
        if (issues.filterValue == value) break;
      }
      this.cols.push(new window.easyClasses.agile.IssuesCol(issues, this, column, this.kanbanRoot));
    }
    this._fireChanges(item);
  };

  /**
   *
   * @type {Array.<IssuesCol>}
   */
  StickyLane.prototype.cols = null;

  /**
   * @return {Array}
   */
  StickyLane.prototype.getData = function () {
    var out = [];
    for (var i = 0; i < this.cols.length; i++) {
      out.push(this.cols[i].getData());
    }
    return out;
  };

  /**
   *
   * @type {string}
   */
  StickyLane.prototype.name = "";

  window.easyClasses.agile.StickyLane = StickyLane;
});
