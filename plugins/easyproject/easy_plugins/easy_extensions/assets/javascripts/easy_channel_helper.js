window.EasyChannelHelper = function (opts) {
    var defaultOptions = {};
    var _options = $.extend({}, defaultOptions, opts);
    var that = this;

    this.init = function () {
    };

    this.doSomething = function (payload) {
        Object.keys(payload).forEach(function (k) {
            switch (k) {
                case "modal":
                    that._showModal(payload.modal);
                    break;
                case "notification":
                    that._showNotification(payload.notification);
                    break;
            }
        });
    };

    this._showModal = function (payload) {
        for (var index = 0; index < payload.buttons.length; ++index) {
            switch (payload.buttons[index].click) {
                case "close":
                    payload.buttons[index].click = function () {
                        $(this).dialog('close');
                    };
                    break;
            }
        }

        showModal('ajax-modal', '40%');

        $("#ajax-modal").html(payload.message);
        $('#ajax-modal').dialog("option", {
            buttons: payload.buttons,
            title: payload.title
        });
    };

    this._showNotification = function (payload) {
        var notification = new window.EasyNotifications();
        notification.show(payload);
    };

    this.init();
};