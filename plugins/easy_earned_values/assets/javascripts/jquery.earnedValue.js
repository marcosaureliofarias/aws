;(function($, undefined) {
  $.widget('easy.earnedValue', {
    options: {
      data: null,
      value_names: null
    },
    _create: function() {

      // this.chart = c3.generate({
      //   bindto: this.element.get(0),
      //   data: {
      //     xs: this.options.xs,
      //     columns: this.options.columns,
      //     names: this.options.names,
      //     type: 'spline'
      //   },
      //   axis: {
      //     x: {
      //       type: 'timeseries'
      //     }
      //   }
      // });

      var format = d3.time.format("%Y-%m-%d");

      this.chart = c3.generate({
        bindto: this.element.get(0),
        data: {
          xFormat: '%Y-%m-%d',
          json: this.options.data,
          keys: {
            x: 'date',
            value: this.options.value_names,
          },
          names: this.options.names,
          type: 'line'
          // type: 'spline'
        },
        axis: {
          x: {
            type: 'timeseries',
            tick: {
              // format: d3.timeFormat('%Y-%m-%d')
              format: '%Y-%m-%d'
            }
          },
        },
        grid: {
          x: {
            lines: [
                {value: format( new Date() ), text: 'Today'} //position: 'start/middle'
            ]
          }
        },
        line: {
          connectNull: true
        }
      });

      $('.c3-circles', this.element).remove();
      $('.c3-axis-x line', this.element).remove();
    }
  });
})(jQuery);
