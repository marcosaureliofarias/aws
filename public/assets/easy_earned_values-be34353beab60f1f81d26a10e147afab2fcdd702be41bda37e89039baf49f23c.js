!function(e){e.widget("easy.earnedValue",{options:{data:null,value_names:null},_create:function(){var t=d3.time.format("%Y-%m-%d");this.chart=c3.generate({bindto:this.element.get(0),data:{xFormat:"%Y-%m-%d",json:this.options.data,keys:{x:"date",value:this.options.value_names},names:this.options.names,type:"line"},axis:{x:{type:"timeseries",tick:{format:"%Y-%m-%d"}}},grid:{x:{lines:[{value:t(new Date),text:"Today"}]}},line:{connectNull:!0}}),e(".c3-circles",this.element).remove(),e(".c3-axis-x line",this.element).remove()}})}(jQuery);