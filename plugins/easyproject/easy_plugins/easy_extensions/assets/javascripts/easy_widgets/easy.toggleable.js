$.widget("EASY.toggleable" , $.EASY.Widget, {
  // Name is there for developers comfort especially in error reporting
  name:"Click on click out",

  content: null,

  observer: null,

  state: null,



  _customInit: function(){
    var self = this;
    self.state = false;
    self.content = self.options.content || $(this.element.attr("data-widget-content"));
    self.trigger = self.options.trigger;
    self.avoid = self.options.avoid;
    self.ignore = self.options.ignore;
    self.observer = self.options.observer || EASY.defaultClickObserver;
    self.openCallback = self.options.openCallback;
    self.closeCallback = self.options.closeCallback;

    if(self.observer) self.observer.addClickTarget(self);
    if(self.trigger) self.$triggerElement = $(self.trigger);
    if(self.content) self.$contentElement = $(self.content);

    self.element.addClass('w-toggleable');

    var element = self.trigger ? self.$triggerElement : $(self.element) ;

    element.click( function( event ){
      var event = event || window.event; // use the value of event if available or if not assume it's IE and use window.event
      self.observer.reportEvent(event);
      // debugger;
      if(!self.state){
        if(!$(event.target).is(self.avoid) && !$.contains( self.$contentElement[0], event.target)) {
          self.element.addClass('w-toggleable--active');
          if(self.trigger) self.$triggerElement.addClass('w-toggleable__trigger--active u-active');
          if(self.content) self.$contentElement.addClass('w-toggleable__content--active u-active');
          self._toggleState();
          if (self.openCallback) self.openCallback();
          return false;
        }
      }else{
        self._close();
      }
    });
  },

  clickOutCallback: function ( event ){
    var self = this;
    if( self.state ){
      var element = self.content ? $(self.content) : self.element;
      element.each(function(item){
        requestAnimationFrame(function(){
          if(
              self.state &&
              !$(self.content).find(event.target).length &&
              !$(event.target).data("not-toggleable-close") &&
              !$(event.target).is(self.ignore) &&
              !$(event.target).parents().is(self.ignore) &&
              !$(event.target).parents().is(self.content)
          ){
            // debugger;
            self._close();
          };
        });
      })
    }
  },

  _close: function(){
    var self = this;
    self._cleanup();
    self._toggleState();
    if (self.closeCallback) self.closeCallback();
  },

  _cleanup: function(){
    var self = this;
    self.element.removeClass('w-toggleable--active');
    if(self.trigger) self.$triggerElement.removeClass('w-toggleable__trigger--active u-active');
    if(self.content) self.$contentElement.removeClass('w-toggleable__content--active u-active');
  },

  _customDestroy: function(){
    var self = this;
    self._cleanup();
  }
});

EASY.schedule.late(function () {
  $('[data-widget~=toggleable]').each(function(){
    var $this = $(this);
    $this.toggleable({observer: EASY.defaultClickObserver, content: $($this.attr('data-widget-content'))});
  })
});
