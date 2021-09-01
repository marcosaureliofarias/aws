EASY.schedule.main(function () {
  EASY.backgroundServices.url = "/easy_services/load_backgrounds.json";
  var services = {};

  function EasyBackgroundService(name, execution, beforeExecution) {
    this.name = name;
    this.execution = execution || function(){};
    this.beforeExecution = beforeExecution || function(){};
  }

  // Load specific services. Should not be called directly.
  // User load() or loadAll() instead.
  function loadServices(services) {
    if (!EASY.backgroundServices.active || EASY.backgroundServices.active.length === 0) {
      return
    }

    var activeServices = [];
    var params = {};

    $.each(services, function (name, service) {
      if (EASY.backgroundServices.active.indexOf(name) !== -1) {
        activeServices.push(service);
        service.beforeExecution(params)
      }
    });

    params["services"] = $.map(activeServices, function(s){ return s.name });

    $.ajax({
      method: "POST",
      url: (window.urlPrefix + EASY.backgroundServices.url),
      data: params,
      noLoader: true,
      dataType: "json"
    }).done(function (data) {
      $.each(activeServices, function (index, service) {
        service.execution(data[service.name])
      })
    })
  }

  EASY.backgroundServices.add = function (name, execution, beforeExecution) {
    services[name] = new EasyBackgroundService(name, execution, beforeExecution);
  };

  // Load selected services
  //
  //   load("easy_activity", "attendance_statuses")
  //   load(["easy_activity", "attendance_statuses"])
  //
  EASY.backgroundServices.load = function () {
    var serviceNames = [].concat.apply([], arguments);// flatten
    var servicesInner = {};
    var service;

    $.each(serviceNames, function (index, name) {
      if (service = services[name]) {
        servicesInner[name] = service
      }
    });

    loadServices(servicesInner)
  };

  // Load all active services
  EASY.backgroundServices.loadAll = function () {
    loadServices(services)
  };

// ----------------------------------------------------------------------------
// Attendace statuse to users

  EASY.backgroundServices.add("attendance_statuses",
      // Handle result
      function (data) {
        if (!data) return;

        $("span.attendance-user-status").not(".attendance-loaded").each(function () {
          var id = this.getAttribute("data-id");
          var status = data[id];

          if (status) {
            $(this).addClass("attendance-loaded").append(status)
          }
        })
      },

      // Add params
      function (params) {
        var userIds = $("span.attendance-user-status").map(function () {
          return this.getAttribute("data-id")
        }).get();

        // Does not work on phantomjs
        // userIds = new Set(userIds.toArray())
        // params["user_ids_on_page"] = Array.from(userIds)

        userIds = userIds.filter(function (value, index, self) {
          return self.indexOf(value) === index
        });
        params["user_ids_on_page"] = userIds
      }
  );

// ----------------------------------------------------------------------------
// Activity count to sidebar

  EASY.backgroundServices.add("easy_activity",
      function (data) {
        if (!data) return;

        var trigger = $("a#easy_activity_feed_trigger");
        var activitiesCount = parseInt(data["current_activities_count"]);

        if (activitiesCount > 0) {
          trigger.css("visibility", "inherit").addClass("has-sign fast");
          var mark = $("<span/>").attr("class", "sign count").text(activitiesCount);
          trigger.append(mark);
        }
      }
  );

// ----------------------------------------------------------------------------
// Issue timer for sidebar

  EASY.backgroundServices.add("easy_issue_timer",
      function (data) {
        if (!data) return;

        var trigger = $("#easy_issue_timers_list_trigger");
        var runningCount = parseInt(data["running_count"]);

        if (runningCount > 0) {
          trigger.css("visibility", "inherit").addClass("icon-spin has-sign fast");

          if (data["is_active"]) {
            trigger.addClass("timer-active")
          } else {
            trigger.addClass("timer-inactive")
          }

          setTimeout(function () {
            trigger.removeClass("icon-spin");
            var mark = $("<span/>").attr("class", "sign count").text(runningCount);
            trigger.append(mark)
          }, 1000)
        } else {
          trigger.parent().remove()
        }
      }
  );

// ----------------------------------------------------------------------------
// Broadcasts

  EASY.backgroundServices.add("easy_broadcast",
      function (data) {
        if (!data) return;

        $.each(data, function (index, easy_broadcast) {
          EASY.utils.broadcast.showBroadcastFlashMessage('notice', easy_broadcast.message, easy_broadcast.id)
        })
      }
  );


// ----------------------------------------------------------------------------
// easy_page_user_tabs
  EASY.backgroundServices.add("easy_page_user_tabs",
      function (data) {
        if (!data) return;
        var menu = $("#top-menu-container");
        var menuMyPageLink = menu.find('a.my-page');
        var menuMyPage = menuMyPageLink.parent();
        menuMyPage.addClass('with-easy-submenu');

        var links = $.map(data, function (link) {
          return "<li>" + link + "</li>";
        }).join('');

        var html = "<span class='easy-top-menu-more-toggler user-tabs'><i class='icon-arrow down'></i></span>" +
            "<ul class='menu-children easy-menu-children' style='display: none;' id='easy_menu_children_my_page'>" + links + "</ul>";
        menuMyPage.append(html);
        $('.easy-top-menu-more-toggler.user-tabs').toggleable({observer: EASY.defaultClickObserver, content: $('#easy_menu_children_my_page')})
      }
  );
});
window.LazyLoader = {};
LazyLoader.refresh = function () {
  // For backward compatibility
  EASY.schedule.main(function () {
    EASY.backgroundServices.load("attendance_statuses");
  });
};
