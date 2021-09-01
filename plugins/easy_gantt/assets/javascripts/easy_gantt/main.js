/* main.js */
/* global ysy */
window.ysy = window.ysy || {};
ysy.main = ysy.main || {};
ysy.initGantt = function () {
  ysy.data.loader.init();
  ysy.data.loader.load();
  ysy.data.storage.init();
  if (!ysy.settings.easyRedmine) {
    moment.locale(ysy.settings.language || "en");
  }
  ysy.main.setFirstDayOfWeek();
  ysy.view.start();
  //ysy.main.start();
};

ysy.deepCounter = 0;
ysy.moreDashes = function () {
  var dashes = "";
  for (var i = 0; i < ysy.deepCounter; i++) {
    dashes += "│";
  }
  ysy.deepCounter++;
  return dashes + "┌ ";
};
ysy.sameDashes = function () {
  var dashes = "";
  for (var i = 0; i < ysy.deepCounter; i++) {
    dashes += "│";
  }
  return dashes + "- ";
};
ysy.lessDashes = function () {
  ysy.deepCounter--;
  if (ysy.deepCounter < 0) {
    throw "tooMany lessDashes";
  }
  var dashes = "";
  for (var i = 0; i < ysy.deepCounter; i++) {
    dashes += "│";
  }
  return dashes + "└ ";
};
