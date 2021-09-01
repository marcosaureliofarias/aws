/*!
 * jQuery Easy Charts
 * http://easyredmine.com/
 *
 * Copyright 2015 Easy Software Ltd.
 */
//= require_self


(function( $, undefined ) {

  $.widget("easy.easy_chart", {
    settingsChart: {
      minPieChartWidth: 450
    },
    defaultColors: ['#1f77b4', '#aec7e8', '#ff7f0e', '#ffbb78', '#2ca02c', '#98df8a', '#d62728', '#ff9896', '#9467bd',
      '#c5b0d5', '#8c564b', '#c49c94', '#e377c2', '#f7b6d2', '#7f7f7f', '#c7c7c7', '#bcbd22', '#dbdb8d', '#17becf', '#9edae5'],
    defaultSpace: 20,
    colors: function (){
      if (ERUI.sassData && ERUI.sassData["chart-palette"]) {
        return ERUI.sassData["chart-palette"].split(",");
      } else {
        return this.defaultColors;
      }

    },
    space: function (){
      if (ERUI.sassData && ERUI.sassData['base-spaceing']){
        return ERUI.sassData['base-spacing'].split("px")[0];
      }else{
        return this.defaultSpace;
      }

    },
    i18n: {
      noData: 'No data',
      currentData: 'Current',
      createBaseline: 'Create baseline',
      destroyBaseline: 'Delete baseline',
      loadBaseline: 'Load',
      toggleBaseline: 'Baseline'
    },
    localeDefinition: {
      "decimal": ".",
      "thousands": ",",
      "grouping": [3],
      "currency": ["$", ""],
      "dateTime": "%a %b %e %X %Y",
      "date": "%m/%d/%Y",
      "time": "%H:%M:%S",
      "periods": ["AM", "PM"],
      "days": ["Sunday", "Monday", "Tuesday", "Wednesday", "Thursday", "Friday", "Saturday"],
      "shortDays": ["Sun", "Mon", "Tue", "Wed", "Thu", "Fri", "Sat"],
      "months": ["January", "February", "March", "April", "May", "June", "July", "August", "September", "October", "November", "December"],
      "shortMonths": ["Jan", "Feb", "Mar", "Apr", "May", "Jun", "Jul", "Aug", "Sep", "Oct", "Nov", "Dec"]
    },
    options: {
      blockName: null, // block_name of chart area
      dataUrl: null, // url to make a request for data to
      dataMethod: null, // http method
      dataParams: {}, // params to pass to ajax
      reloadRate: 0,
      defaultChartOptions: {},
      formats: {
        labels: ",",
        y_axis: easySettings['chart_numbers_format'] === true ? '.2s' : ','
      },
      currency: null,
      data: null
    },

    _create: function() {
      this.uuid = this.element.data('uuid');
      this.options.dataParams = $.extend({uuid: this.uuid}, this.options.dataParams);
      this.options.dataUrl = this.options.dataUrl || this.element.data('url');
      this.options.dataMethod = this.options.dataMethod || this.element.data('method');
      var chartWidth = this.element.width();
      var chartSettings = this.options.dataParams.chart_settings;
      if(chartSettings) {
        var chartType = chartSettings.primary_renderer;
        if (chartWidth > 0 && chartWidth < this.settingsChart.minPieChartWidth && chartType === 'pie' ) {
            this.options.dataParams.chart_settings.legend_enabled = 0;
        }
      }
      this.chart_data = null;
      this.currency = this.options.currency || [this.element.data('currency-prefix') || '', this.element.data('currency-suffix') || ''];

      if(this.options.data && this.options.data.data) {
        this._renderChart(this.options.data);
      }
      else if (this.element.data('renderchart')) {
        this._loadAndCreate(false);
      }

      if( this.uuid !== undefined && this.uuid ) {
        this._createBaselines();
      }
    },

    _renderChart: function(data){
      var title = $(".chart-title-" + this.uuid);
      if (title) {
        title.text(data.title);
      }

      if ((data.data.columns && (data.data.columns.length === 0 || data.data.columns[0].length === 0)) ||
          (data.data.json && data.data.json.length === 0)) {
        this.element.html(this.i18n.noData);
      } else {
        this._configureAndCreateChart(data);
      }
    },

    _loadAndCreate: function(replot) {
      var that = this;
      $.ajax({
        url: this.options.dataUrl,
        data: this.options.dataParams,
        noLoader: true,
        dataType: "json", type: this.options.dataMethod || "POST"
      }).done(this._renderChart.bind(this));
    },

    _createBaselines: function() {
      var that = this,
          create_button, toggle_button, load_button, destroy_button,
          heading_links = this.element.closest('.easy-page-module').find('.module-heading-links');

      this.baseline_container = $('<div class="baseline_container" style="display:none;"></div>');
      this.baseline_select = $('<select/>').appendTo( this.baseline_container );
      load_button = $('<a href="javascript:void(0)" class="button">' + this.i18n.loadBaseline + '</a>').appendTo( this.baseline_container );
      create_button = $('<a href="javascript:void(0)" class="button-positive">' + this.i18n.createBaseline + '</a>').appendTo( this.baseline_container );
      destroy_button = $('<a href="javascript:void(0)" class="button-negative">' + this.i18n.destroyBaseline + '</a>').appendTo( this.baseline_container );
      toggle_button = heading_links.find('.baseline-toggle'); // for second load - change of period
      if( toggle_button.length === 0 ) {
        toggle_button = $('<a href="javascript:void(0)" class="icon icon-lightning baseline-toggle" title="'+ this.i18n.toggleBaseline + '"></a>');
        heading_links.prepend( toggle_button );
      } else {
        toggle_button.off('click');
      }

      toggle_button.on('click', function(evt) {
        that._loadBaselines();
        that.baseline_container.toggle();
      });

      create_button.on('click', function(evt) {
        evt.preventDefault();
        that._saveBaseline();
      });
      
      destroy_button.on('click', function(evt) {
        evt.preventDefault();
        if( that.baseline_select.val() ) {
          that._destroyBaseline( that.baseline_select.val() );
        }
      });

      load_button.on('click', function(evt) {
        evt.preventDefault();
        if( that.baseline_select.val() ) {
          that._loadBaseline( that.baseline_select.val() );
        } else {
          that.reload();
        }
      });

      this.element.before( this.baseline_container );
    },

    _configureAndCreateChart: function(chartData) {
      if (chartData === null) {
        return null;
      }

      var that = this,
          default_number_format,
          currency,
          formatDefaults,
          tooltipFormats,
          label_format,
          tooltip_format,
          total_text,
          locale,
          localeDefinition,
          countProps,
          chartAdditionalOptions = {};

      // var chart_size = [300, 300];
      currency = chartData.currency || this.currency;
      if (currency && currency[1] && currency[1] !== '' ) currency[1] = ' ' + currency[1].trim();
      localeDefinition = $.extend( {}, this.localeDefinition, {'currency': currency});
      if( chartData.formats && chartData.formats.delimiter ) {
        localeDefinition.thousands = chartData.formats.delimiter;
      }
      if( chartData.formats && chartData.formats.separator ) {
        localeDefinition.decimal = chartData.formats.separator;
      }
      var locale_time_format = d3.timeFormatDefaultLocale(localeDefinition);
      var locale_number_format = d3.formatDefaultLocale(localeDefinition);
      default_number_format = d3.format(',');
      formatDefaults = {
        currency: d3.format(easySettings['chart_numbers_format'] === true ? '$.3s' : '$,'),
        time: function(d) { return default_number_format(d) + 'h'; }
      };

      tooltipFormats = {
        currency: d3.format('$,'),
        time: formatDefaults.time
      };

      this.chart_data = chartData;
      this.chart_type = chartData.data.type;
      this.has_more_series = (chartData.data.columns !== undefined && chartData.data.columns.length > 1);
      this.has_more_series = this.has_more_series || (chartData.data.keys !== undefined && chartData.data.keys.value.length > 1);

      this.formats = $.extend( {}, this.options.formats, chartData.formats );

      label_format = formatDefaults[this.formats.labels] || d3.format(easySettings['chart_numbers_format'] === true ? '.3s' : ',');
      tooltip_format = tooltipFormats[this.formats.labels] || d3.format(',');

      $.extend(true, chartAdditionalOptions, {
        data: {
          labels: {
            format: function(value) {
              if (value < 1) {
                return tooltip_format(value);
              } else {
                return label_format(value);
              }
           }
          },
          onclick: function(data, element){
            EASY.easyChart && EASY.easyChart.onClick && EASY.easyChart.onClick(this, that, data, element);
          }
        }
      });

      if( this.chart_type !== 'pie' && !this.has_more_series ) {
        $.extend(true, chartAdditionalOptions, {
          legend: {
            show: true
          }
        });
      }
      if( this.chart_type === 'bar' && !this.has_more_series ) {
        $.extend(true, chartAdditionalOptions, {
          data: {
            color: function (color, d) {
              if(d) {
                  return that.colors()[d.index % that.colors().length];
              }
            }
          },
          size: {
             height: function () {
                 if (that.chart_options.axis.rotated){
                     return that.chart_data.data.json.length*this.space;
                 }
             }
          }
        });
      } else {
        $.extend(true, chartAdditionalOptions, {
          color: {
            pattern: that.colors()
          }
        });
      }

      // tooltip formats
      if( this.chart_type === 'line' || this.chart_type === 'bar' ) {
        $.extend(true, chartAdditionalOptions, {
          tooltip: {
            format: {
              value: function (value) {
                return tooltip_format(value);
              }
            }
          }
        });
      } else if( this.chart_type === 'pie' ) {
        $.extend(true, chartAdditionalOptions, {
          tooltip: {
            format: {
              value: function(value, ratio, id) {
                return d3.format(".0%")(ratio) + ' (' + tooltip_format(value) + ')';
              }
            }
          }
        });
      }

      if( chartData.total !== undefined ) {
        if ( $.isPlainObject(chartData.total) ) {
          total_text = '';
          var n = '';
          let total_value;
          countProps = 0;
          for ( var k in chartData.total ) {
            if (countProps > 0) {
              total_text += ' | ';
              n = (countProps + 1).toString();
            }
            if (chartData.total[k] < 1) {
              total_value = tooltip_format(chartData.total[k]);
            } else {
              total_value = label_format(chartData.total[k]);
            }

            total_text += ( chartData.data.names[k] || "Total" + n ) + ": " + total_value;
            countProps++;
          }
        } else {
          total_text = "Total: " + label_format(chartData.total);
        }
      }
      var format_y_axis_labels = formatDefaults[this.formats.y_axis] || d3.format(this.formats.y_axis);

      let title_text = total_text;
      if (chartData.title && chartData.title.text && !title_text) {
        title_text = chartData.title.text;
      }

      const chartDataSize = chartData.size || {};

      this.chart_ticks = chartData.ticks;
      this.chart_options = $.extend(true, {
        bindto: this.element.get(0),
        oninit: EASY.utils.EasyChartsOnInit,
        data: chartData.data,
        title: {
          text: title_text
        },
        padding: {
          top: that.space(),
          bottom: 1.5*that.space()
        },
        size: chartDataSize,
        axis: {
          x: {
            type: 'category',
            /*tick: {
              rotate: 30
            },*/
            categories: this.chart_ticks,
            height: 70
          },
          y: {
            tick: {
              format: function(value) {
                if (value < 1) {
                  return tooltip_format(value);
                } else {
                  return format_y_axis_labels(value);
                }
              }
            },
            padding: {
              top: 0.1,
              bottom: 0.1,
              unit: 'ratio'
            }
          }
        },
        grid: {
          y: {
            show: true
          }
        },
        line: {
          connectNull: true
        }
      }, this.options.defaultChartOptions, chartAdditionalOptions, chartData.chart_options);

      if( this.chart_type === 'bar' && this.chart_options.axis.rotated ) {
        if (this.chart_options.size) {
          if (this.chart_data.data.json.length === 1){
            this.chart_options.size.height = (this.chart_data.data.json.length + 1.5) * this.chart_options.axis.x.height;
          }
          else{
            this.chart_options.size.height = (this.chart_data.data.json.length + 1) * this.chart_options.axis.x.height;
          }
        }
        this.element.addClass('is-rotated');
      }

      if(chartData.data.names && chartData.data.entity_names) {
        for ( k in chartData.data.names ) {
          if (chartData.data.entity_names[k]) {
            chartData.data.names[k] = chartData.data.entity_names[k] + ' - ' + chartData.data.names[k];
          }
        }
      }

      if( this.chart_type === 'pie' ) {
        // Sorted on backend, because item 'other' must stay on end.
        this.chart_options.data['order'] = null
      }
      this.chart = c3.generate(this.chart_options);

      var onclick = this.chart.element.dataset.onclick;
      if (onclick) {
        this.chart._onclick = JSON.parse(onclick);
      }
      
      // START extension 4 legend
      
      toggle = function toggle(id) {
        this.chart.toggle(id);
      }
      
      const chart = this.chart
      const chart_options = this.chart_options;
      
      if(chart_options.legend && !chart_options.legend.hide && chart_options.data.columns && this.chart_type === 'pie'){
        
        const legendNames = chart_options.data.columns.map(x => x[0]);
        
        document.querySelector('#'+ chart.element.id + ' .c3-legend-item').parentElement.style.display =  'none';
        d3.select('#'+ chart.element.id).insert('div', '.chart').attr('class', `c3-legend c3-legend--${chart_options.legend.position}-${chart_options.legend.inset.anchor} cols--${parseInt(1 + legendNames.length / 12)}`).selectAll('div')
          .data(legendNames)
          .enter().append('span')
          .attr('data-id', function(id) {
            return id;
          })
          .attr('class', 'c3-legend-item')
          .html(function(id) {
            return id;
          })
          .each(function(id) {
            //d3.select(this).append('span').style
            d3.select(this).insert('span').attr('class', 'c3-legend-item-color').style('background-color', chart.color(id));
          })
          .on('mouseover', function(id) {
            chart.focus(id);
          })
          .on('mouseout', function(id) {
            chart.revert();
          })
          .on('click', function(id) {
            $(this).toggleClass('c3-legend-item-hidden');
            chart.toggle(id);
          });
        // END extension 4 legend
      }
      return chart;
    },

    _loadBaselines: function() {
      var that = this;
      this.baseline_select.children().remove();
      $.ajax(window.urlPrefix + '/easy_page_zone_modules/'+this.uuid+'/easy_chart_baselines.json').done(function(data) {
        that.baseline_select.append('<option value="">' + that.i18n.currentData + '</option>');
        for (var i = 0; i < data.length; ++i) {
          that.baseline_select.append('<option value="'+data[i].id.toString() + '">' + (data[i].name || 'No name') + ' (' + data[i].date + ')</option>');
        }
      });
    },

    _saveBaseline: function() {
      if(this.chart_data) {
        var that = this;
        $.ajax(window.urlPrefix + '/easy_page_zone_modules/'+this.uuid+'/easy_chart_baselines.json', {
          method: 'POST',
          data: {
            easy_chart_baseline: {
              data: this.chart_data.data,
              ticks: this.chart_ticks,
              options: this.chart_data.chart_options
            }
          }
        }).done(function(data) {
            that.baseline_select.append('<option value="'+data.id.toString() + '">' + (data.name || 'No name') + ' (' + data.date + ')</option>');
            that.baseline_select.val(data.id.toString());
        }).fail(function(data) {
            var json = data.responseJSON;
            if (json.errors) {
              alert(json.errors.join("\n"));
            }
        });
      };
    },
    
    _destroyBaseline: function( baseline_id ) {
      var that = this;
      $.ajax(window.urlPrefix + '/easy_chart_baselines/'+baseline_id.toString()+'.json', {
          method: 'DELETE'
      }).done(function(data) {
          that.baseline_select.find("option[value='" + that.baseline_select.val() + "']").remove();
          that.baseline_select.val('');
          that.reload();
      });
    },

    _loadBaseline: function( baseline_id ) {
      var that = this;
      $.ajax(window.urlPrefix + '/easy_chart_baselines/'+baseline_id.toString()+'.json').done(function(data) {
        // var columns;
        // for( var key in data.data.columns) {
        //   columns = data.data.columns[key];
        //   break;
        // }
        // columns.shift();
        // columns = columns.map(parseFloat);
        // columns.unshift( 'Baseline ' + data.date );
        that._configureAndCreateChart(data);
      });
    },

    reload: function() {
      if(this.chart) {
        this.chart = this.chart.destroy();
      }
      this._loadAndCreate(true);
    },

    setDataParam: function(param, value) {
      this.options.dataParams[param] = value;
    },

    getDataParam: function(param) {
      return this.options.dataParams[param];
    }

  });

  /** TEMPORAL FIX - c3 cannot render itself if browser tab is not displayed.
   * Can be removed when c3 bug is fixed */
  c3.chart.internal.fn.afterInit = function (/*config*/) {
    if (!document.hidden) return;
    var chart = this.api;
    var handler = function (/*event*/) {
      chart.show();
      document.removeEventListener("visibilitychange", handler);
    };
    document.addEventListener("visibilitychange", handler);
  }

})( jQuery );
