/* left_grid.js */
/* global ysy */
window.ysy = window.ysy || {};
ysy.view = ysy.view || {};
ysy.view.leftGrid = ysy.view.leftGrid || {};
EasyGem.extend(ysy.view.leftGrid, {
  columnsWidth: {
    id: 60,
    subject: 200,
    name: 200,
    project: 140,
    other: 70,
    updated_on: 85,
    assigned_to: 100,
    grid_width: 400,
    max_grid_width: 700,
    min_grid_width: 400,
    first_load: true
  },
  patch: function () {
    ysy.data.limits.columnsWidth = $.extend({}, this.columnsWidth);
    ysy.view.columnBuilders = ysy.view.columnBuilders || {};
    var self = this;
    $.extend(ysy.view.columnBuilders, {
      id: function (obj) {
        if (obj.id > 1000000000000) return '';
        var path = ysy.settings.paths.rootPath + ((obj.type === 'project') ? "projects/" : "issues/");
        return "<a href='" + path + obj.real_id + "' title='" + ysy.main.escapeText(obj.text) + "' target='_blank'>#" + obj.real_id + "</a>";
      },
      updated_on: function (obj) {
        if (!obj.columns) return "";
        var value = obj.columns.updated_on;
        if (value) {
          return moment.utc(value, 'YYYY-MM-DD HH:mm:ss ZZ').fromNow();
        } else {
          return "";
        }
      },
      done_ratio: function (obj) {
        if (!obj.columns) return "";
        if (obj.type === "project") return "";
        //return '<span class="multieditable">'+Math.round(obj.progress*10)*10+'</span>';
        return '<span >' + Math.round(obj.progress * 10) * 10 + '</span>';
      },
      due_date: function (obj) {
        if (!obj.columns) return "";
        const date = obj.columns["due_date"];
        let dueDate = `<span >${ysy.main.escapeText(date || "")}</span>`;
        if (!date) return dueDate;
        const isProject = obj.type === "project";
        if (!isProject) return dueDate;
        const isSubproject = !!obj.parent;
        if (!isSubproject) return dueDate;
        const isPrecedes = (() => {
          const parentId = obj.parent.match(/\d+/)[0];
          const parent = ysy.data.projects.dict[parentId];
          const parentDueDate = new Date(parent.end_date).setHours(0, 0, 0, 0);
          const subprojectDueDate = new Date(obj.end_date).setHours(0, 0, 0, 0);
          return parentDueDate < subprojectDueDate;
        })();
        if (isPrecedes) {
          const precedes = ysy.view.getLabel("warnings")["subproject_precedes_parent"];
          dueDate = `<span ><i class="icon-warning red" title="${precedes}"></i>${ysy.main.escapeText(obj.columns["due_date"] || "")}</span>`;
        }
        return dueDate;
      },
      easy_indicator: function (obj) {
        if (!obj.columns) return "";
        const indicator = obj.columns["easy_indicator"];
        if (!indicator) return "";
        const indicatorState = {
          21: "warning",
          22: "alert",
          20: "ok",
          0: "ok"
        };
        const state = indicatorState[indicator];
        const title = ysy.view.getLabel("indicator")[state];
        const easyIndicator = `<div class="state-indicator-circle easy-indicator-${state}" title="${title}"></div>`;
        return easyIndicator;
      },
      estimated_hours: function (obj) {
        if (!obj.columns || !obj.estimated) return "";
        return '<span >' + obj.estimated + '</span>';
      },
      subject: function (obj) {
        var id = parseInt(obj.real_id);
        if (isNaN(id) || id > 1000000000000) return obj.text;
        var path = self.constructUrl(obj);
        var text = ysy.main.escapeText(obj.text);
        if (gantt.modalAdapter && path && obj.$rendered_type === "task") {
          const extraClasses ="gantt_task_subject";
          const defaultLink = `<a href="${path}${id}" class="gantt_task_subject" title="${text}" target="_blank"> ${text} </a>`;
          const link = gantt.addTogglersToEntity(obj, path, extraClasses) || defaultLink; // currently unused, kept for future purposes
          return link;
        } else if (path) {
          const defaultLink = `<a href="${path}${id}" title="${text}" target="_blank"> ${text}</a>`;
          const link = gantt.addTogglersToEntity(obj, path) || defaultLink;
          return link;
        } else {
          return text;
        }
      },
      _default: function (col) {
        return function (obj) {
          if (!obj.columns) return "";
          if (col.dont_escape) return obj.columns[col.name];
          return ysy.main.escapeText(obj.columns[col.name] || "");
        };
      }

    });
    gantt._render_grid_superitem = function (item) {
      var subjectColumn = ysy.view.columnBuilders.subject;

      var tree = "";
      for (var j = 0; j < item.$level; j++)
        tree += this.templates.grid_indent(item);
      var has_child = this._has_children(item.id);
      if (has_child) {
        tree += this.templates.grid_open(item);
        tree += this.templates.grid_folder(item);
      } else {
        tree += this.templates.grid_blank(item);
        tree += this.templates.grid_file(item);
      }
      var afterText = this.templates.superitem_after_text(item, has_child);

      var odd = item.$index % 2 === 0;
      var style = "";//"width:" + (col.width - (last ? 1 : 0)) + "px;";
      var cell = "<div class='gantt_grid_superitem gantt_cell gantt_tree_cell' style='" + style + "'>" + tree + "<div class='gantt_tree_content'>"+subjectColumn(item) + afterText + "</div></div>";

      var css = odd ? " odd" : "";
      if (this.templates.grid_row_class) {
        var css_template = this.templates.grid_row_class.call(this, item.start_date, item.end_date, item);
        if (css_template)
          css += " " + css_template;
      }

      if (this.getState().selected_task == item.id) {
        css += " gantt_selected";
      }
      var el = document.createElement("div");
      el.className = "gantt_row gantt_tree_row" + css;
      //el.setAttribute("data-url","/issues/"+item.id+".json");  // HOSEK
      el.style.height = this.config.row_height + "px";
      el.style.lineHeight = (gantt.config.row_height) + "px";
      el.setAttribute(this.config.task_attribute, item.id);
      el.setAttribute('data-level', item.$level);
      el.setAttribute('data-prev-count', item.$prev);
      el.innerHTML = cell;
      return el;
    };
    $.extend(gantt.templates, {
      grid_open: function (item) {
        return "<div class='gantt_tree_icon gantt_" + (item.$open ? "close" : "open") + " gantt_tree_expander easy-gantt__icon easy-gantt__icon--" + (item.$open ? "close" : "open") + "'></div>";
      },
      grid_folder: function (item) {
        /// = HAS CHILDREN
        if (this["grid_bullet_" + gantt._get_safe_type(item.type)]) {
          return this["grid_bullet_" + gantt._get_safe_type(item.type)](item, true);
        }
        // default fallback
        if (item.$open || gantt._get_safe_type(item.type) !== gantt.config.types.task) {
          return "<div class='gantt_tree_icon easy-gantt__icon easy-gantt__icon--folder_" + (item.$open ? "open" : "closed") + "'></div>";
        } else {
          return "<div class='gantt_tree_icon easy-gantt__icon easy-gantt__icon--task gantt_drag_handle'></div>";
        }
      },
      grid_file: function (item) {
        // = HAS NO CHILDREN
        if (this["grid_bullet_" + gantt._get_safe_type(item.type)]) {
          return this["grid_bullet_" + gantt._get_safe_type(item.type)](item, false);
        }
        // default fallback
        if (gantt._get_safe_type(item.type) === gantt.config.types.task)
          return "<div class='gantt_tree_icon easy-gantt__icon easy-gantt__icon--task gantt_drag_handle'></div>";
        return "<div class='gantt_tree_icon easy-gantt__icon easy-gantt__icon--open'></div>";
      },
      grid_bullet_milestone: function (item, has_children) {
        var rearrangable = false;
        return "<div class='gantt_tree_icon easy-gantt__icon easy-gantt__icon--milestone" + (rearrangable ? "gantt_drag_handle" : "") + "'></div>";
      },
      grid_bullet_project: function (item, has_children) {
        var titles = ysy.settings.labels.titles;
        var nonLoadedIssues = item.widget && item.widget.model.issues_count;
        var loadNumber;
        if (nonLoadedIssues > 9) {
          loadNumber = 'more';
        }
        else {
          loadNumber = nonLoadedIssues;
        }
        if (nonLoadedIssues) {
          return "<div class='gantt_tree_icon easy-gantt__icon easy-gantt__icon--filter_" + loadNumber + " easy-gantt__project_issues' title='" + titles.load + " " + nonLoadedIssues + " " + titles.issues + "' data-project_id='" + item.real_id + "'></div>";
        } else {
          return "<div class='gantt_tree_icon easy-gantt__icon easy-gantt__icon--filter_none ' title='" + titles.allIssueLoaded + "'></div>";
        }
      },
      grid_bullet_task: function (item, has_children) {
        if (has_children) {
          return "<div class='gantt_tree_icon gantt_drag_handle easy-gantt__icon easy-gantt__icon--folder_" + (item.$open ? "open" : "closed") + "'></div>";
        } else {
          return "<div class='gantt_tree_icon easy-gantt__icon easy-gantt__icon--task gantt_drag_handle'></div>";
        }
      },
      superitem_after_text: function (item, has_children) {
        if (this["superitem_after_" + gantt._get_safe_type(item.type)]) {
          return this["superitem_after_" + gantt._get_safe_type(item.type)](item, has_children);
        }
        return "";
      }
    });
    gantt._render_grid_header = function () {
      var columns = this.getGridColumns();
      var cells = [];
      var width = 0,
        labels = this.locale.labels;
      let scopeKey = 'global';
      let negativeColWidth;
      if (ysy.settings.project) {
        scopeKey = `project_${ysy.settings.project.id}`
      }

      var lineHeigth = this.config.scale_height - 2;
      var resizes = [];
      let column = {};

      for (var i = 0; i < columns.length; i++) {
        var last = i === columns.length - 1;
        var col = columns[i];
        if (last && this._get_grid_width() > width + col.width)
          col.width = this._get_grid_width() - width;
        width += col.width;
        var sort = (this._sort && col.name === this._sort.name) ? ("<div class='gantt_sort gantt_" + this._sort.direction + "'></div>") : "";
        if (col.tree) {
          if (!this._sort) sort = '<div class="gantt_sort gantt_none"></div>';
          if (ysy.pro.collapsor) {
            sort += ysy.pro.collapsor.templateHtml;
          }
        }
        var cssClass = ["gantt_grid_head_cell",
          ("gantt_grid_head_" + col.name),
          (last ? "gantt_last_cell" : ""),
          this.templates.grid_header_class(col.name, col)].join(" ");
        col.width = !col.width ? col.min_width : col.width;
        var style = "width:" + (col.width - (last ? 1 : 0)) + "px;";
        column[`${col.name}`] = (col.width - (last ? 1 : 0));
        negativeColWidth = last ? Object.values(column).filter(colWidth => colWidth < 0) : [];
        if (last && !negativeColWidth.length) {
          ysy.data.storage.savePersistentData(scopeKey, JSON.stringify(column));
        }
        var label = (col.label || labels["column_" + col.name]);
        label = label || "";
        var cell = "<div class='" + cssClass + "' style='" + style + "' column_id='" + col.name + "'><div class='gantt-grid-header-multi'>" + label + sort + "</div></div>";
        if (!last) {
          resizes.push("<div style='left:" + (width - 6) + "px' class='gantt_grid_column_resize_wrap' data-column_id='" + col.name + "'></div>");
        }
        cells.push(cell);
        //var resize='<div style="height:100%;background-color:red;width:10px;cursor: col-resize;position: absolute;left:'+(width-5)+'px;z-index:1"></div>';
        /*var resize = '<div class="gantt_grid_column_resize_wrap" style="height:100%;left:' + (width - 7) + 'px;z-index:1" column-index="' + i + '">\
         <div class="gantt_grid_column_resize"></div></div>';
         resizes.push(resize);*/
      }
      //var resize = '<div class="gantt_grid_column_resize_wrap" style="height:100%;left:' + (this._get_grid_width() - 10) + 'px;z-index:1" >\
      //<div class="gantt_grid_column_resize"></div></div>';
      this.$grid_resize.style.left = (this._get_grid_width() - 6) + "px";
      this.$grid_scale.style.height = (this.config.scale_height - 1) + "px";
      this.$grid_scale.style.lineHeight = lineHeigth + "px";
      this.$grid_scale.style.width = (width - 1) + "px";
      this.$grid_scale.style.position = "relative";
      this.$grid_scale.innerHTML = cells.join("") + resizes.join("");
      ysy.view.leftGrid.resizeTable();
      if (ysy.view.collapsors) {
        ysy.view.collapsors.requestRepaint();
      }
      //resizeColumns();
    };
    gantt._calc_grid_width = function () {
      var i;
      var columns = this.getGridColumns();
      var cols_width = 0;
      var width = [];
      let columnsRealWidht = 0;
      var columnsConfig = ysy.view.leftGrid.columnsWidth;
      let scopeKey = 'global';
      if (ysy.settings.project) {
        scopeKey = `project_${ysy.settings.project.id}`
      }
      for (i = 0; i < columns.length; i++) {
        var v = parseInt(columns[i].min_width, 10);
        width[i] = v;
        cols_width += v;
      }
      if (columnsConfig.first_load) {
        const storageValue = JSON.parse(ysy.data.storage.getPersistentData(scopeKey));
        if (storageValue) {
          columns.forEach(el => {
            if (!storageValue[`${el.name}`]) {
              el.width = el.min_width;
              columnsRealWidht += el.width;
            } else {
              columnsRealWidht += storageValue[`${el.name}`];
              el.width = storageValue[`${el.name}`];
            }
          });
          this.config.grid_width = columnsRealWidht;
        } else {
          this.config.grid_width = cols_width;
        }
        columnsConfig.first_load = false;
      }
    };
  },
  constructColumns: function (columns) {
    var dcolumns = [];
    var columnBuilders = ysy.view.columnBuilders;
    var getBuilder = function (col) {
      if (columnBuilders[col.name]) {
        return columnBuilders[col.name];
      } else if (columnBuilders[col.name + "Builder"]) {
        return columnBuilders[col.name + "Builder"](col);
      }
      else return columnBuilders._default(col);
    };
    for (var i = 0; i < columns.length; i++) {
      var col = columns[i];
      var isMainColumn = col.name === "subject" || col.name === "name";
      if (col.name === "id" && !ysy.settings.easyRedmine) continue;
      var css = "gantt_grid_body_" + col.name;
      if (col.name !== "") {
        var width = ysy.data.limits.columnsWidth[col.name] || ysy.data.limits.columnsWidth["other"];
        var dcolumn = {
          name: col.name,
          label: col.title,
          min_width: width,
          width: width,
          tree: isMainColumn,
          align: isMainColumn ? "left" : "center",
          template: getBuilder(col),
          css: css
        };
        if (isMainColumn) {
          dcolumns.unshift(dcolumn);
        } else {
          dcolumns.push(dcolumn);
        }
      }
    }
    return dcolumns;
  },
  resizeTable: function () {
    var $resizes = $(".gantt_grid_column_resize_wrap:not(inited)");
    var colWidths = ysy.data.limits.columnsWidth;
    var $gantt_grid = $(".gantt_grid");
    var $gantt_grid_data = $(".gantt_grid_data");
    var $gantt_grid_scale = $(".gantt_grid_scale");
    $resizes.each(function (index, el) {
      var config = {};
      var $el = $(el);
      var column = gantt.config.columns[index].name;
      var dhtmlxDrag = new dhtmlxDnD(el, config);
      var minWidth,
        realWidth,
        resizePos,
        gridWidth;
      dhtmlxDrag.attachEvent("onDragStart", function () {
        if (this.config.started) return;
        minWidth = colWidths[column] || colWidths.other;
        realWidth = $gantt_grid.find(".gantt_grid_head_" + column).width();
        gridWidth = $gantt_grid.width();
        resizePos = $el.offset();
      });
      dhtmlxDrag.attachEvent("onDragMove", function (target, event) {
        //var diff=Math.floor(event.pageX-lastPos);
        var diff = Math.floor(dhtmlxDrag.getDiff().x);
        ysy.log.debug("moveDrag diff=" + diff + "px width=" + realWidth + "px", "grid_resize");

        $gantt_grid.width(gridWidth + diff);
        $gantt_grid_data.width(gridWidth + diff);
        $gantt_grid_scale.width(gridWidth + diff);
        $el.offset({ top: resizePos.top, left: resizePos.left + diff });
        colWidths[column] = minWidth + diff;
        var columns = gantt.config.columns;
        if (index <= columns.length - 1) {
          gantt.config.columns[index].min_width = minWidth + diff;
          gantt.config.columns[index].width = realWidth + diff + 1;
          $gantt_grid.find(".gantt_grid_head_" + column + ", .gantt_grid_body_" + column).width(realWidth + diff + "px");
        }
        gantt.config.grid_width = gridWidth + diff;
        colWidths.grid_width = gridWidth + diff;
      });
      dhtmlxDrag.attachEvent("onDragEnd", function (target, event) {
        gantt.render();
        //gantt._render_grid();
        //var data = gantt._get_tasks_data();
        //gantt._gridRenderer.render_items(data);
        //ysy.view.ganttTasks.requestRepaint();
      });
    });
    $resizes.addClass("inited");
  },
  urlMap: {
    task: "issues/",
    default: "issues/",
    milestone: "versions/",
    project: "projects/",
    assignee: {
      default: "users/",
      group: "groups/"
    }
  },
  constructUrl: function (item) {
    var path = this.urlMap[item.type || "default"];
    if (!path) return null;
    if (typeof path === "string") return ysy.settings.paths.rootPath + path;
    return ysy.settings.paths.rootPath + path[item.subtype || "default"];
  }
});
