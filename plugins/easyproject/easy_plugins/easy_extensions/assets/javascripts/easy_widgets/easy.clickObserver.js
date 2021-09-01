$.widget("EASY.clickObserver" , $.EASY.Widget, {
  // Name is there for developers comfort especially in error reporting
  name:"Close elements on click out",

  _customInit: function(){
    var self = this;
    self.element.click( function( event ){
      // console.log(event)
      self._triggerCallbacks(event);
    })
  },

  addClickTarget: function(object){
    var self = this;
    self.children.push(object);
  },
  
  _triggerCallbacks: function(event){
    var self = this;
    for (var i = 0; i <  self.children.length; i++){
      self.children[i].clickOutCallback( event );
    }
  },
  
  reportEvent: function(event){
    var self = this;
    self._triggerCallbacks(event);
  },

  _customDestroy: function(){

  }

});

EASY.schedule.main(function(){
  EASY.defaultClickObserver = $(document).clickObserver().data("EASY-clickObserver");
});
