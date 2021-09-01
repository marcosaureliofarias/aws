// jQuery modals fix
EASY.schedule.main(function () {
  $.widget("ui.dialog",$.ui.dialog,{_allowInteraction:function(t){return this._super(t)?!0:t.target.ownerDocument!==this.document[0]?!0:$(t.target).closest(".cke_dialog").length?!0:$(t.target).closest(".cke").length?!0:void 0},_moveToTop:function(t,o){t&&this.options.modal||this._super(t,o)}});
});
