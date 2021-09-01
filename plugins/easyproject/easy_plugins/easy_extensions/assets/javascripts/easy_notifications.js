window.EasyNotifications = function (opts) {
    var defaultOptions = {};
    var _options = $.extend({}, defaultOptions, opts);
    var _notify;

    this.init = function () {
        this.checkPermissions();
    };

    this.checkPermissions = function () {
        if (!("Notification" in window)) {
            _notify = false;
        } else if (Notification.permission === "granted") {
            _notify = true;
        } else if (Notification.permission !== 'denied') {
            Notification.requestPermission().then(function (permission) {
                if (permission === "granted") {
                    _notify = true;
                }
            });
        }
    };

    this.showNotification = function (title, options) {
        var opts = $.extend({}, _options, options);

        if (_notify) {
            var n = new Notification(title, opts);

            if (opts.url) {
                n.onclick = function() {
                    window.focus();
                    window.location = opts.url;
                }
            }

            // n.onclick = function () {
            //     window.focus();
            // };

            // setTimeout(n.close.bind(n), 4000);
        }
    };

    this.show = function (data) {
        this.showNotification(data.title, data.options)
    };

    this.init();
};