$.widget("EASY.styleChat" , $.EASY.Widget, {
  // Name is there for developers comfort especially in error reporting
  name: "Change chat appearance according to EP style",

  _customInit: function () {
    var servicebarItems = $('#easy_servicebar').find('li > a');
    servicebarItems.attr('onclick', 'window.EasyInstantMessenger.closeChat()');
    var self = this;
    self.element.addClass('er_easyim');
    // test of "ugly" ordinary scrollbar
    // $('#easy_instant_messages_body').perfectScrollbar({
    //   suppressScrollX: true,
    //   includePadding: true,
    //   wheelPropagation: false,
    //   swipePropagation: false
    // }).css({overflowY: 'hidden'});

    $(document).on('easy_IM_loaded', function() {
      window.EasyInstantMessenger.chatLi = $('#easy_servicebar').find('#easy_instant_messages_toggle').parent();

      window.EasyInstantMessenger.openChat = function () {
        this.chatWindow = true;
        this.chatLi.append('<span id="easy_servicebar_component_beak" style="z-index: 901; right: 0;"><a id="easy_servicebar_close_toggler" class="icon-close" onclick="window.EasyInstantMessenger.closeChat()"></a></span>');
        $('#easy_instant_messages_wrapper').removeClass("easyim__wrapper--hidden");
        $('#easy_instant_messages_toggle').addClass("active");
        $('#easy_servicebar_component').css('display', 'none');

        //turn off overflow in mobile view for better scrolling in chat container
        if (window.ERUI.isMobile) $('body').css('overflow-y', 'hidden');

      };

      window.EasyInstantMessenger.closeChat = function () {
        this.chatWindow = false;
        this.chatLi.find("#easy_servicebar_component_beak").remove();

        window.clearInterval(this.interval);
        this.interval = window.setInterval(this.checkMessages, 70 * 1000, this);

        $('#easy_instant_messages_wrapper').addClass("easyim__wrapper--hidden");
        $('#easy_instant_messages_toggle').removeClass("active");
        this.displayReceivedMessagesCount();
        if (window.ERUI.isMobile) {
          $('body').css('overflow-y', 'auto');
        }
      }
    });
  }
});