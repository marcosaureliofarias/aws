
// Fake responsive adaptation -----------
var responsivizer = {
  content: null,
  sidebar: null,
  tableElement: [],
  tableParent: [],
  tableParentRect: [],
  minGridWidth: 270,
  minTabularWidth: 270,
  minChartWidth: 270,
  minPieChartWidth: 450,
  init: function() {
    responsivizer.content = document.getElementById('content');
    responsivizer.contentRect = responsivizer.content.getBoundingClientRect();
    responsivizer.contentWidth = responsivizer.contentRect.width;
    responsivizer.minContentWidth = 560; //1.25*responsivizer.sidebarWidth;
    $('table.list').each( function(index) {
      responsivizer.tableElement[index] = $(this);
      responsivizer.tableParent[index] = responsivizer.tableElement[index].parent();
      responsivizer.tableParentRect[index] = responsivizer.tableParent[index][0].getBoundingClientRect();
    });
  },
  read: function() {
    $.each( responsivizer.tableElement, function( index ){
      responsivizer.tableParentRect[index] = responsivizer.tableParent[index][0].getBoundingClientRect();
    });
  },
  tableFakeResponsive: function() {
    $.each( responsivizer.tableParentRect, function( index,parent ){
      var parentWidth = parent.width;
      var cls="fake-responsive";
      if (parentWidth < responsivizer.minContentWidth){
        responsivizer.tableElement[index].addClass(cls);
      }
      if ( responsivizer.minContentWidth < parentWidth){
        responsivizer.tableElement[index].removeClass(cls);
      }
    });
  },
  contentFakeResponsive: function() {
    if ($("#content").width() < responsivizer.minContentWidth) {
      $("#content,#sidebar").addClass('fake-responsive');
    } else {
      $("#content,#sidebar").removeClass('fake-responsive');
    }
    responsivizer.timeout = true;
  },
  gridFakeResponsive: function() {
    $("#content").find(".splitcontent").not($("#easy_grid_sidebar").find(".splitcontent")).each(function() {
      var $this = $(this);
      if($this.width() < 2 * responsivizer.minGridWidth){
        $this.addClass('fake-responsive');
      }else{
        $this.removeClass('fake-responsive');
      }
    });
  },
  tabularFakeResponsive: function() {
    $(".tabular").each(function() {
      var $this = $(this);
      if($this.width() < responsivizer.minTabularWidth){
        $this.addClass('fake-responsive');
      }else{
        $this.removeClass('fake-responsive');
      }
    });
  },
  chartFakeResponsive: function(target) {
    var $parent = !(typeof target === "undefined") ? $(target) : $(document);
    $parent.find(".c3.easy_query_chart").each(function() {
      var $this = $(this);
      var chart = $this.data('easyEasy_chart').chart;
      var legendHide = false;
      var chartData = $this.data().easyEasy_chart.chart_data.chart_options;
      if (chartData.hasOwnProperty('legend')){
        legendHide = chartData.legend.hide;
      }
      chart.resize();
      var width = $this.width();
      var chartType = $this.data().easyEasy_chart.chart_type;
      if (legendHide || width > 0 && width < responsivizer.minChartWidth){
        $this.addClass('fake-responsive');
        chart.legend.hide();
      }
      else if (chartType === 'pie' && width > 0 && width < responsivizer.minPieChartWidth) {
        $this.addClass('fake-responsive');
        chart.legend.hide();
      } else {
        $this.removeClass('fake-responsive');
        chart.legend.show();
      }
    });
  },
  fakeResponsive: function(target) {
    responsivizer.read();
    responsivizer.tableFakeResponsive();
    responsivizer.contentFakeResponsive();
    responsivizer.gridFakeResponsive();
    responsivizer.tabularFakeResponsive();
    responsivizer.chartFakeResponsive(target);
  },
  contentResized: function() {
    var width = $("#content").width();
    if(responsivizer.contentWidth !== width){;
      responsivizer.contentWidth = width;
      return true;
    }else{
      return false;
    }
  }
};

EASY.responsivizer = responsivizer;
