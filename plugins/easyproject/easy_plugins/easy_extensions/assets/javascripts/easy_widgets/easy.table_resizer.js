/*
USAGE:

To make table resizable, create instance of TableResizer with table selector, for example: new TableResizer(#myTable),
add data-attribute "data-resizable-colum-id='columnName'" to all table heads, you want to be able to resize, so final
element should look like this: <th class="testClass" data-resizable-column-id="subject">column</th>

TableResizer by default saves every table columns widths to localStorage. In case you dont want to save widths,
you need to disable it trough options i.e. new TableResizer("#myTable", { dontSaveStorage: true })

If you want to use sticky columns moving right and left, use sticky: true in options and add dataAttr to every sticky
element you want to make sticky i.e. <th class="testClass" data-resizable-column-id="firstHead" data-resizable-sticky>column</th>

Use option observeTableChange if you have table with dynamic adding elements to table and you still want to have it sticky etc...
*/

class TableResizer {
  constructor(tableId, options = {}) {
    this.tableSelector = tableId;
    this.tableEl = document.querySelector(tableId);
    this.sticky = options.sticky;
    this.observeTableChange = options.observeTableChange;
    this.dontSaveStorage = options.dontSaveStorage;
    this.drag = {};
    this.DEFAULTWIDTH = 150;
    this.init();
  }

  init() {
    if (!this.tableEl) return;
    const prepared = this.prepareTable();
    if (!prepared) return;
    this.loadSavedColumns();
    this.calculateStickyColumns();
  }

  prepareTable() {
    this.tableEl.classList.add("table-resizer");
    const heads = this.tableEl.querySelectorAll("th[data-resizable-column-id]");
    if (heads.length === 0) return false;
    heads.forEach(thead => {
      const handle = this.createHandle();
      thead.style.boxSizing = "border-box";
      let minWidth = window.getComputedStyle(thead).getPropertyValue("min-width");
      minWidth = parseFloat(minWidth);
      thead.style.width = `${minWidth || this.DEFAULTWIDTH}px`;
      /*
      affix is cloned header for "sticky" purposes, if there is no sticky cloned column, then add handle to normal
      head otherwise we need to put it in "sticky" cloned affix element
       */
      const theadAffix = thead.querySelector(".affix-cell-wrap");
      if (theadAffix) {
        theadAffix.appendChild(handle);
      } else {
        thead.appendChild(handle);
      }

      // set listener for every handle
      handle.addEventListener("mousedown", this.dragStart.bind(this));
    });
    this.setTableListeners();
    return true;
  }

  loadSavedColumns() {
    if (this.dontSaveStorage) return;
    const storage = JSON.parse(window.localStorage.getItem("table_resizer"));
    if (!storage) return;
    for (let tableKeyId in storage) {
      if (!storage.hasOwnProperty(tableKeyId)) continue;
      if (tableKeyId !== this.tableSelector) continue;
      const table = storage[tableKeyId];

      for (let columnId in table) {
        if (!table.hasOwnProperty(columnId)) continue;
        const columnWidth = table[columnId];
        const selector = document.querySelector(
          `${this.tableSelector} th[data-resizable-column-id="${columnId}"]`
        );
        if (selector) {
          selector.style.width = columnWidth + "px";
        }
      }
    }
  }

  saveColumns() {
    if (this.dontSaveStorage) return;
    let nxtColWidth, nxtColDataId;
    const curColDataId = this.drag.curCol.dataset.resizableColumnId;
    const curColWidth = this.drag.curCol.offsetWidth;

    if (this.drag.nxtCol) {
      nxtColDataId = this.drag.nxtCol.dataset.resizableColumnId;
      nxtColWidth = this.drag.nxtCol.offsetWidth;
    }
    let storage = JSON.parse(window.localStorage.getItem("table_resizer"));

    let tablesJson = {};
    let newCols = {};

    if (nxtColDataId) {
      newCols[curColDataId] = curColWidth;
      newCols[nxtColDataId] = nxtColWidth;
    } else {
      newCols[curColDataId] = curColWidth;
    }

    tablesJson[this.tableSelector] = newCols;

    if (!storage) {
      window.localStorage.setItem("table_resizer", JSON.stringify(tablesJson));
      return;
    }

    const isTableInStorage = window.EASY.utils.isStorageItem(
      "table_resizer",
      this.tableSelector
    );
    if (!isTableInStorage) {
      storage[this.tableSelector] = {};
    }

    storage[this.tableSelector][curColDataId] = curColWidth;
    if (nxtColDataId) {
      storage[this.tableSelector][nxtColDataId] = nxtColWidth;
    }
    window.localStorage.setItem("table_resizer", JSON.stringify(storage));
  }

  calculateStickyColumns() {
    if (!this.sticky) return;
    // calculating sticky positions
    const tableRows = this.tableEl.querySelectorAll("tr");

    tableRows.forEach(row => {
      let sumLeft = 0;
      const stickyColumns = row.querySelectorAll(
        "th[data-resizable-sticky], td[data-resizable-sticky]"
      );
      if (!stickyColumns) return;

      stickyColumns.forEach((column, index) => {
        column.style.position = "sticky";
        if (index === 0) {
          column.style.left = "0";
          return;
        }
        const prevColWidth = stickyColumns[index - 1].offsetWidth;
        sumLeft += prevColWidth;
        column.style.left = sumLeft + "px";
      });
    });
  }

  setTableListeners() {
    this.tableEl.addEventListener("mousemove", this.dragMove.bind(this));
    document.addEventListener("mouseup", this.dragEnd.bind(this));

    // Set mutation observer for tables that dynamically add some content
    // i.e. recalculate all sticky positions after adding rows or columns to table
    if (this.observeTableChange) {
      const config = {
        attributes: false,
        childList: true,
        subtree: true
      };
      const observer = new MutationObserver(this.recalculateTable.bind(this));
      observer.observe(this.tableEl, config);
    }
  }

  dragStart(e) {
    // disable selecting text when dragging
    this.tableEl.style.userSelect = "none";
    this.drag.pageX = e.pageX;
    this.drag.curCol = e.target.closest("th");
    this.drag.nxtCol = this.drag.curCol.nextElementSibling;
    this.drag.curColResizable = this.drag.curCol.dataset.resizableColumnId;
    this.drag.curColWidth = this.drag.curCol.offsetWidth;
    this.drag.prevStateCurColWidth = this.drag.curColWidth;
    if (this.drag.nxtCol) {
      this.drag.nxtColResizable = this.drag.nxtCol.dataset.resizableColumnId;
      this.drag.nxtColWidth = this.drag.nxtCol.offsetWidth;
    }
  }

  dragMove(e) {
    if (this.drag.curCol) {
      let diffX = e.pageX - this.drag.pageX;
      if (this.drag.nxtCol) {
        this.drag.curCol.style.width = this.drag.curColWidth + diffX + "px";
        // test if column is not resizing and if so, dont allow it to change other columns
        if (this.drag.prevStateCurColWidth === this.drag.curColWidth) {
          diffX = 0;
        } else {
          this.drag.prevStateCurColWidth = this.drag.curColWidth;
        }
        if (this.drag.nxtColResizable) {
          this.drag.nxtCol.style.width = this.drag.nxtColWidth - diffX + "px";
        }
      }
      if (this.sticky) {
        this.calculateStickyColumns();
      }
    }
  }

  dragEnd() {
    // enable text selecting on dragEnd
    this.tableEl.style.userSelect = "auto";
    if (this.drag.curCol && this.drag.curColResizable) {
      this.saveColumns();
      this.clearDrag();
    }
  }

  clearDrag() {
    // set all drag attributes to null
    Object.keys(this.drag).forEach(key => (this.drag[key] = null));
  }

  recalculateTable() {
    if (this.sticky) this.calculateStickyColumns();
  }

  createHandle() {
    const handle = document.createElement("div");
    handle.classList.add("column__handle");
    handle.style.right = "-5px";
    handle.style.top = "0";
    handle.style.position = "absolute";
    handle.style.height = "100%";
    handle.style.width = "10px";
    handle.style.display = "block";
    handle.style.zIndex = "10000000";
    handle.title = "";
    return handle;
  }
}
