(function(){

  EASY.easyChart || (EASY.easyChart = {});

  EASY.easyChart.onClick = function (chart, widget, data, element) {
    if (chart._onclick && chart._onclick.url) {
      const allData = widget.chart_data.all_data;
      let dataItem;
      dataItem = widget.chart_data.all_data[data.index];
      // Need to check by names and values. Relates to bug with deleting element from pie chart
      if (widget.chart_type === "pie") {
        dataItem = Object.values(allData).filter(el => el.values === data.value && el.name === data.name)[0];
      }

      // Pasted url could be encoded
      var url = decodeURIComponent(chart._onclick.url);

      // Reload the current page is not desirable
      if (url === '' || url === '?') {
        return
      }

      url = url.replace(/%name%/g, dataItem.name)
               .replace(/%raw_name%/g, dataItem.raw_name)
               .replace(/%value%/g, dataItem.values)
               .replace(/%second_value%/g, dataItem.values2);

      // Does not work on IE 11
      var searchParams = new URLSearchParams(location.search);

      var filtersData = $(".global-filter__field select, .global-filter__field input").serializeArray();

      url = url.replace(/%([a-z0-9\-\_]+)%/gi, function(match, url_token){
        var globalFilter = filtersData.find(function(filter){
          return filter.name === url_token;
        });

        if (globalFilter) {
          return globalFilter.value;
        }
        else if (searchParams.has(url_token)) {
          return searchParams.get(url_token);
        }
        else {
          return '';
        }
      });

      switch(chart._onclick.target) {
        case "modal":
          // To get hostname from url
          var urlParser = document.createElement("a");
          urlParser.href = url;

          var $ajaxModal = $("<div>", { style: "padding: 0 !important; overflow: hidden !important" });
          var $container = $("<div>", { style: "width: 100%; border: none; height: 100%" });
          var $loading = $("<div>", { class: "bigger text-center", style: "padding: 20px" }).append(I18n.labelLoading);
          var $iframe = $("<iframe>", { style: "border: none; width: 100%; height: 100%; visibility: hidden; position: absolute;"});

          $ajaxModal.append(
            $container.append($loading)
                      .append($iframe)
          );
          $("body").append($ajaxModal);

          EPExtensions.showEasyModal($ajaxModal, {
            width: "80%",
            title: urlParser.hostname,
            close: function(event, ui) {
              ERUI.body.removeClass('modal-opened');
              $ajaxModal.dialog("destroy");
              $ajaxModal.remove();
            }
          });

          // both `append($container)` and `showEasyModal` trigger opening url from iframe
          $iframe.attr("src", url);

          // This sould be replaced by FullScreen from ep.com
          $iframe.on("load", function(){
            $loading.hide();
            $iframe.css({"visibility": "visible"});

            var ajaxMaxHeight = $ajaxModal.dialog("option", "maxHeight");
            $ajaxModal.dialog("option", "height", ajaxMaxHeight - 20);
            var iframeWindow = $iframe[0].contentWindow;
            if (!iframeWindow.EASY && !iframeWindow.EASY.utils && !iframeWindow.EASY.utils.FullScreen) return;
            const iframeContent = iframeWindow.document.getElementById("content");
            new iframeWindow.EASY.utils.FullScreen(iframeContent).setFullScreenOnly();
          });
          break;

        case "blank":
          window.open(url, "_blank");
          break;

        default:
          window.location = url;
      }
    }
  };

})();
