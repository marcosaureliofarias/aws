window.ysy = window.ysy || {};
ysy.pro = ysy.pro || {};
ysy.pro.unfixRelations = ysy.pro.unfixRelations || {};
EasyGem.extend(ysy.pro.unfixRelations, {
  name: "UnfixRelations",
  buttonExtendee: {
    id: "unfix_relations",
    bind () {
      this.model = ysy.settings.unfixRelations;
      this._register(ysy.settings.resource);
      if (this.isOn()) {
        ysy.pro.unfixRelations.open();
      }
    },
    func () {
      if (!this.isOn()) {
        ysy.pro.unfixRelations.open();
      } else {
        ysy.pro.unfixRelations.close();
      }
      ysy.data.storage.savePersistentData('unfixRelations', ysy.settings.unfixRelations.active);
    },
    isOn () {
      return ysy.main.checkForStorageValue('unfixRelations', ysy.settings.unfixRelations.active);
    },
  },
  patch () {
    if (!$("#easy_gantt_menu").find("#button_unfix_relations").length) {
      ysy.pro.unfixRelations = null;
      return;
    }
    ysy.settings.unfixRelations = new ysy.data.Data();
    ysy.settings.unfixRelations.init({
      _name: "UnfixRelations",
      active: false,
    });
      ysy.pro.toolPanel.registerButton(this.buttonExtendee);
  },
  open () {
    const setting = ysy.settings.unfixRelations;
    if (setting.setSilent("active", true)) {
      const relations = gantt.getLinks();
      if (relations.length > 0){
        relations.forEach( relation => { this.addUnfix(relation) } );
      }
      setting._fireChanges(this, "toggle");
    }
  },
  close () {
    const setting = ysy.settings.unfixRelations;
    this.removeUnfixRelations();
    if (setting.setSilent("active", false)) {
      setting._fireChanges(this, "toggle");
    }
  },
  removeUnfixRelations (){
    const relations = gantt.getLinks();
    relations.forEach( relation => { this.removeUnfix(relation) });
  },
  removeUnfix (relation){
    const link = relation.widget.model;
    const newDelay = ysy.pro.relations.getMinimizedDelay(link);
    if(( newDelay >= link._old.delay ) && ysy.settings.unfixRelations.active ) {
      link.set({ delay: link._old.delay,_unlocked: false, history: false});
    } else {
      link.set({ delay: newDelay, _unlocked: false });
    }
  },
  addUnfix (relation){
    const link = relation.widget.model;
    if( !ysy.settings.unfixRelations.active) return;
      link.set({ delay: 0 , _unlocked: true, history: false});
  },
});
