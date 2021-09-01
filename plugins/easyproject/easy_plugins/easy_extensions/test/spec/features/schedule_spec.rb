require 'easy_extensions/spec_helper'

feature 'schedule', logged: :admin, js: true do

  let(:project) { FactoryGirl.create(:project) }

  it 'require' do
    visit project_path(project)
    prepare_test_suite

    # language=JavaScript
    execute_script '
      EASY.schedule.require(function() {
        EASY.scheduleTest("require one getter");
      },function () {return true;});'
    test_passes 'require one getter'

    # language=JavaScript
    execute_script '
      EASY.schedule.require(function(text) {
        EASY.scheduleTest("require one getter with "+text+" value",text === "XXX");
      },function () {return "XXX";});'
    test_passes 'require one getter with XXX value'

    # language=JavaScript
    execute_script '
      EASY.schedule.require(function(text1,text2) {
        EASY.scheduleTest("require two getters with values "+text1+" and "+text2);
      },function () {return "AAA";},function () {return "XXX";});'
    test_passes 'require two getters with values AAA and XXX'

    # language=JavaScript
    execute_script '
      EASY.schedule.require(function() {
        EASY.scheduleTest("require delayed getter");
      },function () {return "AAA";},function () {return window.XXXGGGAAA;});'
    test_failed 'require delayed getter'
    # language=JavaScript
    execute_script 'window.XXXGGGAAA=true'
    test_passes 'require delayed getter'

  end

  it 'require with strings' do
    visit project_path(project)
    prepare_test_suite

    # language=JavaScript
    execute_script '
      EASY.schedule.require(function($) {
        var failed = ($ && $.fn && $.fn.jquery)?"":" failed";
        EASY.scheduleTest("require jQuery"+failed);
      },"jQuery");'
    test_passes 'require jQuery'

    # language=JavaScript
    execute_script '
      EASY.schedule.require(function(module) {
        EASY["testModule" + module.name]=module;
        EASY.scheduleTest("require test module "+(module && module.name));
      },"test module XXX");'
    test_failed 'require test module XXX'

    # language=JavaScript
    execute_script '
      EASY.schedule.define("test module XXX",function() {return {name:"XXX"};});'
    test_passes 'require test module XXX'

    # language=JavaScript
    execute_script '
    EASY.schedule.require(function(module) {
      var failed = (module === EASY["testModule" + module.name])?"":" failed";
      EASY.scheduleTest("require creates only one instance"+failed);
      },"test module XXX");'
    test_passes 'require test module XXX'
  end

  it 'require complex module-> getter' do
    visit project_path(project)
    prepare_test_suite

    # language=JavaScript
    execute_script '
      window.testModuleBBB = {name:"BBB"};
      EASY.schedule.require(function($,namedModule,module1,module2) {
        var jQuery = ($ && $.fn && $.fn.jquery)?"jQuery":"";
        EASY.scheduleTest("require "+jQuery+","+namedModule.name+","+module1.name+","+module2.name);
      },
      "jQuery",
      "test module XYZ",
      function() { return window.testModuleBBB;},
      function() { return window.testModuleHHH;}
    );'
    test_failed 'require jQuery,XYZ,BBB,HHH'

    # language=JavaScript
    execute_script '
      EASY.schedule.define("test module XYZ",function() {return {name:"XYZ"};});'
    test_failed 'require jQuery,XYZ,BBB,HHH'

    # language=JavaScript
    execute_script 'window.testModuleHHH = {name:"HHH"};'
    test_passes 'require jQuery,XYZ,BBB,HHH'
  end

  it 'require complex getter-> module' do
    visit project_path(project)
    prepare_test_suite

    # language=JavaScript
    execute_script '
      window.testModuleBBB = {name:"BBB"};
      EASY.schedule.require(function($,namedModule,module1,module2) {
        var jQuery = ($ && $.fn && $.fn.jquery)?"jQuery":"";
        EASY.scheduleTest("require "+jQuery+","+namedModule.name+","+module1.name+","+module2.name);
      },
      "jQuery",
      "test module XYZ",
      function() { return window.testModuleBBB;},
      function() { return window.testModuleHHH;}
    );'
    test_failed 'require jQuery,XYZ,BBB,HHH'

    # language=JavaScript
    execute_script 'window.testModuleHHH = {name:"HHH"};'
    test_failed 'require jQuery,XYZ,BBB,HHH'

    # language=JavaScript
    execute_script '
      EASY.schedule.define("test module XYZ",function() {return {name:"XYZ"};});'
    test_passes 'require jQuery,XYZ,BBB,HHH'
  end


  ######################################################################################################################

  def prepare_test_suite
    execute_script(
        # language=JavaScript
        '(function(){
      var resultsElement = document.createElement("DIV");
      resultsElement.innerText+="TEST SUITE: ";
      document.body.appendChild(resultsElement);
      EASY.scheduleTest=function(name) {
        resultsElement.innerText+=" <<< Test "+name+" >>>";
      };
    })();')
  end

  def test_passes(name)
    expect(page).to have_text "<<< Test #{name} >>>"
  end

  def test_failed(name)
    expect(page).not_to have_text "<<< Test #{name} >>>"
  end

end
