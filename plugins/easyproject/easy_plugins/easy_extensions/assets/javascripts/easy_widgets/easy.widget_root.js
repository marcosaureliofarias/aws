$.widget( "EASY.Widget", {

  // Name is there for developers comfort especially in error reporting
  name:"Widget Root",

  // Parent widget is parent of this widget in widget hierarchy tree
  parentWidget: this,

  // Target is jQuery element representing HTMLElement in which widget should be painted
  $target: null,

  options: {
    // Widget lang is i18n or just map used in repaint
    widgetLang: null,
  },


  // List<Widget>
  children: null,
  // set to true every time, you need to repaint widget. If it is set to true, next repaint loop will repaint the widget.
  repaintRequested: true,
  // stop repainting during some special operation (<input> create in <td>)
  keepPaintedState: false,

  _customInit: function () {
    // placeholder - fill in the descendants
  },

  _create: function() {
    var self = this;
    self.children =  new Array;
    self._customInit();
  },

  _destroy: function () {
    this._customDestroy();
  },

  _customDestroy: function(){
    // placeholder - fill in the descendants
  },

  _toggleState: function(){
    var self = this;
    self.state = !self.state;
  }
});