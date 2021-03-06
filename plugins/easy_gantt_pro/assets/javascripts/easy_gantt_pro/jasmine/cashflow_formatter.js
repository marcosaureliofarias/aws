xdescribe("Cashflow formatter", function () {
  var data36=[
    {i:0.2564,e:"0.3"},
    {i:25.2564,e:"25.3"},
    {i:156,e:"156"},
    {i:900,e:"900"},
    {i:1000,e:"1k"},
    {i:1400,e:"1.4k"},
    {i:1500,e:"1.5k"},
    {i:1550,e:"1.6k"},
    {i:15000,e:"15k"},
    {i:15400,e:"15k"},
    {i:15450,e:"15k"},
    {i:15500,e:"16k"},
    {i:19550,e:"20k"},
    {i:188450,e:"188k"},
    {i:188500,e:"189k"},
    {i:1000500,e:"1M"},
    {i:1400500,e:"1.4M"},
    {i:1500500,e:"1.5M"},
    {i:1550600,e:"1.6M"},
    {i:10040400,e:"10M"},
    {i:10400400,e:"10M"},
    {i:10450400,e:"10M"},
    {i:10500400,e:"11M"},
    {i:10550400,e:"11M"},
    {i:100400500,e:"100M"},
    {i:100450500,e:"100M"},
    {i:100500520,e:"101M"},
    {i:-156,e:"-156"},
    {i:-900,e:"-900"},
    {i:-1000,e:"-1k"},
    {i:-1400,e:"-1.4k"},
    {i:-1500,e:"-1.5k"},
    {i:-1550,e:"-1.6k"},
    {i:-15000,e:"-15k"},
    {i:-15400,e:"-15k"},
    {i:-15450,e:"-15k"},
    {i:-15500,e:"-16k"},
    {i:-19550,e:"-20k"},
    {i:-188450,e:"-188k"},
    {i:-188500,e:"-189k"},
    {i:-1000500,e:"-1M"},
    {i:-1400500,e:"-1.4M"},
    {i:-1500500,e:"-1.5M"},
    {i:-1550600,e:"-1.6M"},
    {i:-10040400,e:"-10M"},
    {i:-10400400,e:"-10M"},
    {i:-10450400,e:"-10M"},
    {i:-10500400,e:"-11M"},
    {i:-10550400,e:"-11M"},
    {i:-100400500,e:"-100M"},
    {i:-100450500,e:"-100M"},
    {i:-100500520,e:"-101M"}
  ];
  var data50=[
    {i:0.2564,e:"0.3"},
    {i:25.2564,e:"25.3"},
    {i:156,e:"156"},
    {i:900,e:"900"},
    {i:1000,e:"1k"},
    {i:1400,e:"1.4k"},
    {i:1500,e:"1.5k"},
    {i:1550,e:"1.6k"},
    {i:15000,e:"15k"},
    {i:15400,e:"15.4k"},
    {i:15500,e:"15.5k"},
    {i:19550,e:"19.6k"},
    {i:188450,e:"188k"},
    {i:188500,e:"189k"},
    {i:1000500,e:"1M"},
    {i:1400500,e:"1.4M"},
    {i:1500500,e:"1.5M"},
    {i:1550600,e:"1.6M"},
    {i:10040400,e:"10M"},
    {i:10400400,e:"10.4M"},
    {i:10500400,e:"10.5M"},
    {i:10550400,e:"10.6M"},
    {i:100400500,e:"100M"},
    {i:100450500,e:"100M"},
    {i:100500520,e:"101M"},
    {i:-156,e:"-156"},
    {i:-900,e:"-900"},
    {i:-1000,e:"-1k"},
    {i:-1400,e:"-1.4k"},
    {i:-1500,e:"-1.5k"},
    {i:-1550,e:"-1.6k"},
    {i:-15000,e:"-15k"},
    {i:-15400,e:"-15.4k"},
    {i:-15500,e:"-15.5k"},
    {i:-19550,e:"-19.6k"},
    {i:-188450,e:"-188k"},
    {i:-188500,e:"-189k"},
    {i:-1000500,e:"-1M"},
    {i:-1400500,e:"-1.4M"},
    {i:-1500500,e:"-1.5M"},
    {i:-1550600,e:"-1.6M"},
    {i:-10040400,e:"-10M"},
    {i:-10400400,e:"-10.4M"},
    {i:-10500400,e:"-10.5M"},
    {i:-10550400,e:"-10.6M"},
    {i:-100400500,e:"-100M"},
    {i:-100450500,e:"-100M"},
    {i:-100500520,e:"-101M"}
  ];
  it("width 36",function () {
    for(var i=0;i<data36.length;i++){
      var line=data36[i];
      expect(ysy.pro.cashflow.formatter(line.i,36,true)).toBe(line.e,line.i+" should be "+line.e);
    }
  });
  it("width 50",function () {
    for(var i=0;i<data50.length;i++){
      var line=data50[i];
      expect(ysy.pro.cashflow.formatter(line.i,50,true)).toBe(line.e,line.i+" should be "+line.e);
    }
  });

});
