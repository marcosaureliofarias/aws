$.widget("EASY.tableSaw" , $.EASY.Widget, {
  name:"Table Saw",
  content: null,
  observer: null,
  state: null,
  breakpoint: null,
  update: 0,
  parent: null,
  parentWidth: null,

  _customInit: function(){
    var self = this;

    self.element.each( function() {
      var $this = $(this);
      $this.find('table.tablesaw').each(function(){
        var $table = $(this);
        if($table.hasClass('dataTable') || $table.hasClass('tablesaw--exclude')){
          $table.removeClass('tablesaw');
          $table.removeAttr('data-tablesaw-mode');
        }else{
          $table.on('EasyGroup--loaded',function(){
            self._refreshTablesaw($table);
          });

          $table.parent().on('tablesawcreate',function(){
            $table.addClass('tablesaw--loaded');
          });
        }
      });
      self.element.trigger( "enhance.tablesaw" );
      self.update = 1;
    });

  },

  _getSassData: function(){
    this.breakpoint = {
      small:  parseInt(ERUI.sassData['breakpoint-small'].split("px")[0]),
      medium:  parseInt(ERUI.sassData['breakpoint-sidebar'].split("px")[0])
    }
  },

  _refreshTablesaw: function($table){
    var tablesaw = $table.tablesaw().data('tablesaw');
    tablesaw.destroy.call(tablesaw);
    $table.parent().trigger( "enhance.tablesaw" );
  }

});
//
// EASY.schedule.main(function () {
//   var $content = $('#content');
//   var $modal = $('.modal');
//   $content.tableSaw();
//   ERUI.document.on("erui_interface_change_modal easy-query:after-search", function () {
//     $modal = $('.modal');
//     $modal.each(function() {
//       EASY.resetTableSaw($(this));
//     });
//     EASY.resetTableSaw($content);
//   });
//   ERUI.document.on("globalFilters:after-apply", function () {
//     EASY.resetTableSaw($content);
//   });
//   ERUI.document.on("easy_assignments_new_dom easy_pagemodule_new_dom easy_pagemodule_querypreviev_new_dom easy_entitytab_new_dom", function (event) {
//     EASY.resetTableSaw($(event.target));
//   });
// });
//
// EASY.resetTableSaw = function($element){
//   if($element.data('EASYTableSaw')) {
//     $element.data('EASYTableSaw').destroy();
//   }
//   $element.tableSaw();
// };