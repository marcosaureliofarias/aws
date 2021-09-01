$.widget("EASY.customTooltip" , $.EASY.Widget, {
  // Name is there for developers comfort especially in error reporting
  name:"Custom tooltip",

  content: null,

  observer: null,

  state: null,

  _customInit: function(){
    var self = this;
    self.element.each( function() {
      var $this = $(this);
      if (!$this.attr('data-title')){
        $this.attr('data-title', $this.attr('title'));
        $this.removeAttr('title');
      }
      $this.addClass('tooltip');
      $this.find('.tooltip').remove();
      var contentElement = $('<small class="tooltip-content"></small>');
      contentElement.text($this.attr("data-title"));
      $this.append(contentElement);
    });
  }
});

EASY.schedule.late(function () {
  $('.easy-activity-feed__activity-event-header').customTooltip();
});