describe("Users", function () {
  beforeAll(function () {
    this.main = easyScheduler;
    this.scheduler = this.main.scheduler;
    this.helper = this.main.tests;
    this.selectedUsers = this.main.assigneeData.selectedAssignees;
    this.main.assigneeData.selectedAssignees = this.main.assigneeData.selectedAssignees.slice();

  });
  beforeEach(jasmineHelper.initPageMatchers);
  beforeEach(function () {
    this.oldPath = this.main.settings.paths.user_allocation_data_path;
  });
  describe("groups", function () {
    it("add 3 users", function (done) {
      this.main.settings.paths.user_allocation_data_path = "/plugin_assets/easy_scheduler/data/jasmine/group_users.json";
      expect(".easy-calendar__user-select-input").toExistsOnPage();
      var groupUi = {item: {id: 88, value: "Grouper"}};
      $(".easy-calendar__user-select-input").trigger("autocompleteselect", [groupUi]);
      var group = this.main.assigneeData.getAssigneeById(groupUi.item.id);
      expect(group).toBeDefined();
      expect(group.name).toEqual(groupUi.item.value);
      expect(group.isActive()).toBeTruthy();
      EasyGem.schedule.require(function () {
        for (var id = 89; id <= 91; id++) {
          expect("[data-user_id=\"" + id + "\"]").toExistsOnPage();
        }
        done();
      }, function () {
        return $(".easy-calendar__assignees").text().indexOf("Grouper 2") > -1;
      });
    });
  });

  it("add single user", function (done) {
    this.main.settings.paths.user_allocation_data_path = "/plugin_assets/easy_scheduler/data/jasmine/single_user.json";
    var userUi = {item: {id: 191, value: "Loner"}};
    $(".easy-calendar__user-select-input").trigger("autocompleteselect", [userUi]);
    var user = this.main.assigneeData.getAssigneeById(userUi.item.id);
    expect(user).toBeDefined();
    expect(user.name).toEqual(userUi.item.value);
    expect(user.isActive()).toBeTruthy();
    var self = this;
    EasyGem.schedule.require(function () {
      var user = self.main.assigneeData.getAssigneeById(userUi.item.id);
      expect(user.testAttribute).toEqual("testToken123");
      expect("[data-user_id=\"" + user.id + "\"]").toExistsOnPage();
      done();
    }, function () {
      return $(".easy-calendar__assignees").text().indexOf("Loner 123") > -1;
    });
  });
  afterEach(function () {
    this.main.settings.paths.user_allocation_data_path = this.oldPath;
  });
  afterAll(function () {
    this.main.assigneeData.selectedAssignees = this.selectedUsers;
    this.main.assigneesView.refreshAll();
  });
});
