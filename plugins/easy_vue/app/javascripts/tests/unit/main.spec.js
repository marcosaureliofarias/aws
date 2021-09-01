import { shallowMount, mount, createLocalVue } from "@vue/test-utils";
import Vuex from "vuex";
import Locales from "../mocks/locales";
import Mixins from "../mocks/mixins";
import utils from "../../src/mixins/utils";
// Apollo polyfill
import "unfetch/polyfill";

// Components
import IssueModal from "../../src/components/IssueModal";
import LogTime from "../../src/components/issue/LogTime";
import SpentTimeList from "../../src/components/issue/SpentTimeList";
import Wrapper from "../../src/components/generalComponents/Wrapper";
import PopUp from "../../src/components/generalComponents/PopUp";
import SideBar from "../../src/components/generalComponents/Sidebar";
import InlineInput from "../../src/components/generalComponents/InlineInput";
import Comments from "../../src/components/issue/Comments";
import CommentItem from "../../src/components/issue/CommentItem";
import Overview from "../../src/components/issue/Overview";
import TaskListPopUp from "../../src/components/issue/TaskListPopUp";
import Tags from "../../src/components/issue/Tags";
import Coworkers from "../../src/components/issue/Coworkers";
import EmptyModal from "../../src/components/EmptyModal";
import vSelect from "@easy/vue-select";
import datetime from "vue2-datepicker";
import mixins from "../mocks/mixins";
import moment from "moment";

const actions = {
  saveIssueStateValue: jest.fn(),
  saveProjectStateValue: jest.fn(),
  fetchStateValue: jest.fn(),
  fetchIssueValue: jest.fn(),
  fetchJournals: jest.fn(),
  fetchTimeEntries: jest.fn(),
  getFilteredArray: jest.fn(),
  mutateValue: jest.fn(),
  actionsJudge: jest.fn()
};

const mutations = {
  setStoreValue: jest.fn(),
  saveIssueStateValue: jest.fn()
};

const issue = {
  id: 1,
  watchers: [
    {
      value: "Dante",
      id: 1
    },
    {
      value: "Callie",
      id: 2
    }
  ],
  coworkers: [
    {
      avatarUrl:
        "//www.gravatar.com/avatar/2bdce8ef7998d3b2ed3a873d4a8d3432?rating=PG&size=50&default=identicon",
      value: "Dante",
      id: 1
    },
    {
      avatarUrl:
        "//www.gravatar.com/avatar/2bdce8ef7998d3b2ed3a873d4a8d3432?rating=PG&size=50&default=identicon",
      value: "Callie",
      id: 2
    }
  ],
  project: {
    id: 2,
    activitiesPerRole: [
      {
        id: "16",
        internalName: null,
        isDefault: false,
        name: "Work",
        type: "TimeEntryActivity"
      }
    ]
  },
  priority: {
    easyColorScheme: "scheme-1"
  },
  tracker: {
    name: "Bug",
    enabledFields: ["done_ratio"]
  },
  timeEntriesCustomValues: [],
  timeEntries: [
    {
      comments: "Starý koment",
      deletable: true,
      easyIsBillable: false,
      editable: true,
      hours: 1,
      id: 1,
      spentOn: "2019-01-01",
      user: {}
    }
  ],
  tags: [
    { name: "Alert", isActive: true },
    { name: "Warning", isActive: false }
  ],
  deletableWatchers: true,
  addableWatchers: true
};

const state = {
  allLocales: Locales,
  allSettings: {
    timelog_comment_editor_enabled: true,
    text_formatting: "text"
  },
  issue: issue,
  showModal: true,
  newAvailableWatchers: ["Callie", "Dante"],
  assignableUsers: [
    {
      value: "Dante",
      id: 1
    },
    {
      value: "Callie",
      id: 2
    }
  ],
  allUsers: [{ name: "Easy Admin", id: "1" }]
};

const bem = {
  block: "vue-modal",
  ify: function (b, e, m) {
    let output = b;
    output += e ? "__" + e : "";
    output = m ? output + " " + output + "--" + m : output;
    return output.toLowerCase();
  }
};

window.EASY = {
  currentUser: {
    id: 1
  }
};

const localVue = createLocalVue();
localVue.use(Vuex);
localVue.mixin(Mixins);

describe("Wrapper.vue", () => {
  let store, wrapper;
  beforeEach(() => {
    // Set a vue instance before each test bc of $destroy
    // It will fail othervise dunno why
    window.EasyVue = {
      modalInstance: {
        $destroy: jest.fn()
      }
    };
    store = new Vuex.Store({ actions, state });
    store.state.showModal = true;
    wrapper = shallowMount(Wrapper, {
      store,
      localVue,
      propsData: {
        task: issue,
        actionButtons: [],
        block: "vue-modal",
        onCloseFnc: jest.fn()
      }
    });
    expect(wrapper.vm).toBeTruthy();
  });

  test("Close modal on outside click", () => {
    expect(true).toBe(true);
    const modalMask = wrapper.find(".vue-modal__mask");
    // click outside of modal
    modalMask.trigger("mousedown");
    setTimeout(() => {
      expect(wrapper.vm.onCloseFnc).toHaveBeenCalled();
      expect(store.state.showModal).toBeFalsy();
    }, 0);
  });
  test("Dont close modal on click inside", () => {
    const modal = wrapper.find(".vue-modal__container");
    // click on modal
    modal.trigger("mousedown");
    expect(wrapper.vm.onCloseFnc).not.toHaveBeenCalled();
    expect(store.state.showModal).toBeTruthy();
  });
  test("Close modal on close button click", () => {
    // click on close button
    const modalCloseBtn = wrapper.find(".vue-modal__button--close");
    modalCloseBtn.trigger("click");
    expect(wrapper.vm.onCloseFnc).toHaveBeenCalled();
    expect(store.state.showModal).toBeFalsy();
  });
});

describe("LogTime.vue", () => {
  let store, wrapper;

  beforeEach(() => {
    store = new Vuex.Store({ mutations, actions, state });
    wrapper = shallowMount(LogTime, {
      store,
      mixins: [mixins],
      localVue,
      components: {
        datetime
      },
      propsData: {
        task: issue,
        editTimeEntry: false,
        editTimeEntryPayload: {},
        bem: bem
      }
    });
  });

  test("Edit time entry", () => {
    // vue time entry should be edited to this time entry
    const timeEntryToPatch = {
      comments: "Nový koment",
      deletable: true,
      easyIsBillable: true,
      editable: true,
      hours: "5",
      id: 1,
      spentOn: new Date("2020-02-02T00:00:00.000Z"),
      user: {}
    };
    wrapper.vm.setValues(timeEntryToPatch);
    expect(wrapper.vm.patchTimeEntries(1)[0]).toEqual(timeEntryToPatch);
  });

  test("Save time entry", async () => {
    wrapper.vm.saveTimeEntries();
    expect(wrapper.vm.comment).toEqual("");
  });

  test("Enable and disable save", async () => {
    const saveButton = wrapper.find("button");
    wrapper.vm.hours = "10,5";
    expect(wrapper.vm.canSave).toBe(true);
    await wrapper.vm.$nextTick();
    expect(saveButton.attributes("disabled")).toBeFalsy();
    wrapper.vm.hours = "";
    expect(wrapper.vm.canSave).toBe(false);
    await wrapper.vm.$nextTick();
    expect(saveButton.attributes("disabled")).toEqual("disabled");
    wrapper.vm.hours = "0";
    expect(wrapper.vm.canSave).toBe(false);
    await wrapper.vm.$nextTick();
    expect(saveButton.attributes("disabled")).toEqual("disabled");
  });
});

describe("SpentTimeList.vue", () => {
  let store, wrapper;

  beforeEach(() => {
    store = new Vuex.Store({ mutations, actions, state });
    wrapper = shallowMount(SpentTimeList, {
      store,
      localVue,
      propsData: {
        task: issue,
        bem: bem,
        spentHours: 10
      }
    });
    expect(wrapper.vm).toBeTruthy();
  });

  test("Cancel deleting time entry", () => {
    wrapper.vm.cancelDeleting = jest.fn();
    wrapper.vm.deleteTimeEntry(false);
    expect(wrapper.vm.cancelDeleting).toHaveBeenCalled();
  });
});

describe("mixins", () => {
  let store, wrapper;
  beforeEach(() => {
    store = new Vuex.Store({ mutations, actions, state });
    wrapper = shallowMount(Wrapper, {
      store,
      localVue,
      mixins: [utils],
      propsData: {
        id: 1
      },
      data() {
        return {
          wip: false
        };
      }
    });
    expect(wrapper.vm).toBeTruthy();
  });

  test("deep object set", () => {
    const main = {
      first: {
        second: {
          third: 0
        }
      }
    };
    const path = ["first", "second", "third"];
    const value = 1;
    wrapper.vm.deepObjectSet(main, value, path);
    expect(main.first.second.third).toEqual(1);
  });

  test("deep object get", () => {
    const main = {
      first: {
        second: {
          third: 0
        }
      }
    };
    const path = ["first", "second", "third"];
    wrapper.vm.deepObjectGet(main, path);
    expect(main.first.second.third).toEqual(0);
  });

  test("get alignment", () => {
    const e = {
      target: {
        offsetTop: 30
      }
    };
    const options = {
      topOffs: 10,
      rightOffs: 10,
      bottomOffs: 10,
      leftOffs: 0
    };
    const alignment = {
      top: "40px",
      right: "10px",
      bottom: "10px",
      left: ""
    };
    let isMobile = false;
    expect(wrapper.vm.getAlignment(e, options, isMobile)).toEqual(alignment);
    alignment.top = "";
    isMobile = true;
    expect(wrapper.vm.getAlignment(e, options, isMobile)).toEqual(alignment);
  });

  test("Work in Progress", () => {
    wrapper.vm.wipActivated(!wrapper.vm.wip);
    expect(wrapper.vm.wip).toBe(true);
    wrapper.vm.wipActivated(!wrapper.vm.wip);
    expect(wrapper.vm.wip).toBe(false);
    wrapper.vm.wip = undefined;
    wrapper.vm.wipActivated(wrapper.vm.wip);
    expect(wrapper.vm.wip).toBeFalsy();
  });

  test("Saving value", async () => {
    const eventValue = {
      inputValue: {
        id: 1,
        value: "Easy Admin"
      },
      showFlashMessage: jest.fn()
    };
    const names = "assigned_to_id";
    const name = "assignedTo";
    const valueFunc = jest.fn();
    let { payload } = await wrapper.vm.saveValue(eventValue, names, name);
    delete payload.processFunc;
    const correctPayload = {
      name: "assignedTo",
      prop: {
        name: "assigned_to_id",
        value: 1
      },
      reqBody: {
        issue: {
          assignedTo: {
            id: 1,
            value: "Easy Admin"
          },
          assigned_to_id: 1
        }
      },
      reqType: "patch",
      value: {
        assignedTo: {
          id: 1,
          value: "Easy Admin"
        },
        assigned_to_id: 1
      }
    };
    expect(payload).toEqual(correctPayload);
    payload = await wrapper.vm.saveValue(eventValue, names, name, valueFunc);
    expect(valueFunc).toHaveBeenCalled();
  });
  test("Get ratio", () => {
    const spent = 30;
    const estimated = 60;
    const ratio = wrapper.vm.getTotalRatio(spent, estimated);
    expect(ratio).toBe(50);
  });
});

describe("SideBar", () => {
  let store, wrapper;
  const active = [
    {
      name: "Coworkers",
      anchor: "",
      active: true,
      isModuleActive: true,
      ref: "coworkers",
      showAddAction: true,
      onClick: jest.fn()
    }
  ];
  beforeEach(() => {
    store = new Vuex.Store({ mutations, actions, state });
    wrapper = shallowMount(SideBar, {
      store,
      localVue,
      mixins: [utils],
      components: {
        PopUp
      },
      propsData: {
        bem: bem,
        active: active
      },
      data() {
        return {
          sidebarOpen: false
        };
      }
    });
    expect(wrapper.vm).toBeTruthy();
  });
  test("Add action", () => {
    wrapper.find(".icon-add-action").trigger("click");
    expect(wrapper.vm.activeItems[0].onClick).toBeCalled();
  });
  test("Open sidebar", async () => {
    const openedClass = "vue-modal__sidebar--opened";
    wrapper.find(".icon-back").trigger("click");
    await wrapper.vm.$nextTick();
    expect(wrapper.vm.sidebarOpen).toBe(true);
    expect(wrapper.find(".icon-arrow")).toBeTruthy();
    let wrapperClassName = wrapper.find(".vue-modal__sidebar").element
      .className;
    expect(wrapperClassName).toContain(openedClass);
    wrapper.find(".icon-arrow").trigger("click");
    await wrapper.vm.$nextTick();
    wrapperClassName = wrapper.find(".vue-modal__sidebar").element.className;
    expect(wrapper.find(".icon-back")).toBeTruthy();
    expect(wrapperClassName).not.toContain(openedClass);
  });
});

describe("Issue Modal", () => {
  let store, wrapper;
  beforeEach(() => {
    store = new Vuex.Store({ mutations, actions, state });
    wrapper = shallowMount(IssueModal, {
      store,
      localVue,
      mixins: [utils],
      propsData: {
        bem: bem,
        id: 1
      },
      computed: {
        headlineClasses: () => "scheme-1"
      }
    });
    expect(wrapper.vm).toBeTruthy();
  });
  test("Get current pop up inner", async () => {
    const spy = jest.spyOn(wrapper.vm, "getCoworkersData");
    const e = {
      target: {
        offsetTop: 30
      },
      preventDefault: jest.fn()
    };
    wrapper.vm.getCurrentPopUpInner("confirm", e, false);
    expect(wrapper.vm.currentComponent).toBe("Confirm");
    await wrapper.vm.getCurrentPopUpInner("coworkers", e, false);
    expect(wrapper.vm.getCoworkersData).toBeCalled();
    expect(wrapper.vm.popUpOptions).toEqual(store.state.newAvailableWatchers);
  });
});

describe("Inline input", () => {
  let store, wrapper;
  const data = {
    labelName: "label",
    value: {
      name: "Dante",
      id: 1
    },
    classes: { edit: ["u-editing"], show: ["u-showing"] },
    id: "#author-input-select",
    inputType: "autocomplete",
    optionsArray: false,
    filterable: false,
    unit: "h",
    withSpan: true,
    editable: true
  };
  beforeEach(() => {
    store = new Vuex.Store({ mutations, actions, state });
    wrapper = shallowMount(InlineInput, {
      store,
      localVue,
      components: {
        vSelect
      },
      propsData: {
        data: data,
        id: 1,
        value: {
          name: "Dante",
          id: 1
        }
      },
      data() {
        return {
          spanToInput: true
        };
      }
    });
    expect(wrapper.vm).toBeTruthy();
  });
  test("Textilize Span Data", async () => {
    // expect(true).toBe(true);
    //Without input value
    wrapper.vm.inputValue = "";
    expect(wrapper.vm.textilizeSpanData()).toBe("Dante");
    //With input value and unit
    wrapper.setProps({ value: "30" });
    expect(wrapper.vm.textilizeSpanData()).toBe("30 h");
    // //With input value
    await wrapper.vm.$nextTick();
    wrapper.setProps({ value: "Subject" });
    wrapper.vm.data.unit = null;
    expect(wrapper.vm.textilizeSpanData()).toBe("Subject ");
  });

  test("Change Span To Input", async () => {
    wrapper.vm.data.inputType = null;
    const spy = jest.spyOn(wrapper.vm, "focusInput");
    wrapper.find(".editable-input__backdrop");
    wrapper.find(".vue-modal__headline--static").trigger("click");
    await wrapper.vm.$nextTick();
    expect(wrapper.vm.focusInput).toBeCalled();
  });
  test("Save and create activity", async () => {
    wrapper.vm.oldValue = "";
    const spy = jest.spyOn(wrapper.vm, "setShow");
    const stub = jest.fn();
    wrapper.vm.$on("child-value-change", stub);
    wrapper.vm.saveAndCreateActivity();
    expect(wrapper.vm.setShow).toBeCalled();
    expect(stub).toBeCalled();
  });
  test("Change Selected Value", async () => {
    wrapper.vm.inputValue = {
      value: "<< me >>",
      id: 1
    };
    await wrapper.vm.changeSelectedValue();
    expect(wrapper.vm.inputValue).toEqual({ name: "Easy Admin", id: "1" });
    await wrapper.vm.changeSelectedValue();
    expect(wrapper.vm.inputValue).toEqual({ name: "Easy Admin", id: "1" });

    // test array
    wrapper.vm.inputValue = [{ name: "<< me >>", value: 1 }];
    await wrapper.vm.changeSelectedValue();
    expect(wrapper.vm.inputValue).toEqual([{ name: "Easy Admin", id: "1" }]);
  });
  test("Show input with link", () => {
    const data = {
      labelName: "label",
      value: "Link value",
      classes: { edit: ["u-editing"], show: ["u-showing"] },
      id: "#author-input-select",
      inputType: "autocomplete",
      optionsArray: false,
      filterable: false,
      unit: "h",
      withSpan: true,
      editable: false,
      withLink: true,
      link: "www.test-link.cz"
    };
    wrapper = shallowMount(InlineInput, {
      store,
      localVue,
      components: {
        vSelect
      },
      propsData: {
        data: data,
        id: 1,
        value: "input value"
      }
    });
    const link = wrapper.find("a");
    expect(link.attributes("href")).toBe(data.link);
    expect(link.attributes("title")).toBe(wrapper.vm.value);
  });
});

describe("Comments", () => {
  let store, wrapper;
  const permissions = {
    addableNotes: true
  };
  const journals = [
    {
      createdOn: "10-11-2019",
      deletable: true,
      editable: true,
      id: 25,
      user: {
        name: "Dante",
        id: 1
      },
      details: {
        asString: "",
        id: 40
      },
      notes: "<p>Hello, this is comment </p>"
    },
    {
      createdOn: "10-11-2019",
      deletable: true,
      editable: true,
      id: 25,
      user: {
        name: "Dante",
        id: 1
      },
      details: {
        asString: "",
        id: 39
      }
    }
  ];
  beforeEach(() => {
    store = new Vuex.Store({ mutations, actions, state });
    wrapper = shallowMount(Comments, {
      store,
      localVue,
      mixins: [utils],
      components: {
        CommentItem
      },
      propsData: {
        bem: bem,
        journals,
        permissions
      },
      data() {
        return {
          action: "edit",
          commentEditConfig: {
            edit: true,
            editId: 1
          },
          editCommentInput: ""
        };
      }
    });
    expect(wrapper.vm).toBeTruthy();
  });
  test("Edit comment", () => {
    const spy = jest.spyOn(wrapper.vm, "updateComment");
    const stub = jest.fn();
    wrapper.vm.$on("update-comment", stub);
    wrapper.vm.saveComment("<p>Comment</p>", journals[0]);
    expect(wrapper.vm.updateComment).toBeCalled();
    expect(stub).toBeCalled();
    expect(wrapper.vm.action).toBe("");
  });

  test("Reply to comment", () => {
    const spy = jest.spyOn(wrapper.vm, "addComment");
    const stub = jest.fn();
    wrapper.vm.$on("add-comment", stub);
    wrapper.vm.action = "reply";
    wrapper.vm.saveComment("<p>Comment</p>", journals[0]);
    expect(wrapper.vm.addComment).toBeCalled();
    expect(wrapper.vm.commentEditConfig.edit).toBe(false);
    expect(wrapper.vm.commentEditConfig.editId).toBe("");
    expect(stub).toBeCalled();
    expect(wrapper.vm.action).toBe("");
  });

  test("Setting of comment edit or reply value", () => {
    wrapper.vm.commentEditOrReplyValue(journals[0]);
    expect(wrapper.vm.editCommentInput).toEqual(journals[0].notes);
    //Change to reply
    wrapper.vm.action = "reply";
    const quoteStructure = `${journals[0].user.name} wrote:\n> <blockquote>${journals[0].notes}</blockquote>\n\n"`;
    wrapper.vm.commentEditOrReplyValue(journals[0]);
    expect(wrapper.vm.editCommentInput).toEqual(quoteStructure);
  });

  test("Comment delete", () => {
    const stub = jest.fn();
    wrapper.vm.$on("delete-comment", stub);
    expect(wrapper.vm.comments.length).toBe(1);
    wrapper.vm.commentDelete(journals[0], 0);
    expect(stub).toBeCalled();
    expect(wrapper.vm.comments.length).toBe(0);
  });
});

describe("Overview", () => {
  let store, wrapper;

  beforeEach(() => {
    state.issue.tracker = {};
    state.issue.project = {};
    state.issue.tracker.enabledFields = ["done_ratio"];
    state.issue.safeAttributeNames = ["done_ratio"];
    state.issue.project.enabledModuleNames = [];
    store = new Vuex.Store({ mutations, actions, state });
    wrapper = shallowMount(Overview, {
      store,
      localVue,
      mixins: [utils],
      propsData: {
        task: issue,
        bem: bem
      },
      computed: {
        getTimeRatio: () => 50
      }
    });
    expect(wrapper.vm).toBeTruthy();
  });

  test("Time ratio overview", () => {
    const result = [
      { name: "0%", value: 0 },
      { name: "10%", value: 10 },
      { name: "20%", value: 20 },
      { name: "30%", value: 30 },
      { name: "40%", value: 40 },
      { name: "50%", value: 50 },
      { name: "60%", value: 60 },
      { name: "70%", value: 70 },
      { name: "80%", value: 80 },
      { name: "90%", value: 90 },
      { name: "100%", value: 100 }
    ];
    const optionsArray = wrapper.vm.createDoneRatioOptions();
    expect(optionsArray).toEqual(result);
  });
});

describe("Task List Pop Up", () => {
  let store, wrapper;
  const options = {
    data: {
      settings: {
        name: "relatedTasks",
        queryName: "allAvailableRelations",
        issuePropName: "relations",
        heading: "Related",
        action: "addRelation",
        multiselect: true,
        selectOptionsArray: []
      }
    },
    inherited: {
      name: "Coworkers",
      anchor: "",
      active: true,
      isModuleActive: true,
      ref: "coworkers",
      showAddAction: true,
      onClick: jest.fn()
    },
    tasks: [
      {
        subject: "-+93+8+",
        id: "1468",
        easyLevel: 2,
        status: {
          id: "2",
          isClosed: false,
          name: "New"
        },
        assignedTo: null,
        doneRatio: 0,
        priority: {
          id: "12",
          easyColorScheme: "",
          name: "Normal"
        },
        checked: false
      }
    ]
  };
  beforeEach(() => {
    store = new Vuex.Store({ mutations, actions, state });
    wrapper = shallowMount(TaskListPopUp, {
      store,
      localVue,
      propsData: {
        bem: bem,
        options: options,
        inPopUp: true,
        translations: {}
      }
    });
  });

  test("Save button is disabled at beggining", () => {
    const saveButton = wrapper.find(".button");
    expect(saveButton.attributes("disabled")).toBe("disabled");
  });

  test("Save button is active after choosing a relation type and task", async () => {
    const saveButton = wrapper.find(".button");
    wrapper.vm.itemList = wrapper.vm.options.tasks;
    wrapper.vm.relationType = "Blocks";
    await wrapper.vm.$nextTick();
    expect(saveButton.attributes("disabled")).toBeFalsy();
  });

  test("Delay appears after choosing a precedes or follows relation type", () => {
    wrapper.vm.relationType = "Precedes";
    const delay = wrapper.find(".vue-modal__tasklistpopup-delay");
    expect(delay).toBeTruthy();
    wrapper.vm.relationType = "Blocks";
    expect(delay).toEqual({ selector: ".vue-modal__tasklistpopup-delay" });
    wrapper.vm.relationType = "Follows";
    expect(delay).toBeTruthy();
  });

  test("Close pop up on choose parent", async () => {
    const task = wrapper.vm.options.tasks[0];
    await wrapper.vm.addParent(task);
    expect(wrapper.emitted().onBlur).toBeTruthy();
  });

  test("Refetch task list and close pop up on save", async () => {
    const spy = jest.spyOn(wrapper.vm, "reFetchValue");
    await wrapper.vm.save();
    expect(wrapper.vm.reFetchValue).toBeCalled();
    expect(wrapper.emitted().onBlur).toBeTruthy();
  });
});

describe("Tags", () => {
  let store, wrapper;
  const tags = ["alert", "warning"];

  beforeEach(() => {
    state.issue.tags = [
      { name: "alert", id: 2 },
      { name: "warning", id: 3 }
    ];
    store = new Vuex.Store({ mutations, actions, state });
    wrapper = shallowMount(Tags, {
      store,
      localVue,
      propsData: {
        options: tags,
        bem: bem
      }
    });
    expect(wrapper.vm).toBeTruthy();
  });

  test("Create a tag list on mounted", () => {
    expect(wrapper.vm.tagList).toEqual([
      { name: "warning", isActive: true },
      { name: "alert", isActive: true }
    ]);
  });

  test("Remove tag", () => {
    wrapper.vm.addOrRemoveTag({ name: "alert", isActive: false });
    expect(wrapper.vm.activeTags).toEqual([{ name: "warning", id: 3 }]);
  });

  test("Add tag", () => {
    wrapper.vm.addOrRemoveTag({ name: "error", isActive: true });
    expect(wrapper.vm.activeTags).toEqual([
      { name: "alert", id: 2 },
      { name: "warning", id: 3 },
      { name: "error", isActive: true }
    ]);
  });

  test("Create a new tag", () => {
    const newTagName = "new tag";
    wrapper.vm.filterValue = newTagName;
    wrapper.vm.createTag();
    expect(wrapper.vm.tagList).toEqual([
      { name: newTagName, isActive: true },
      { name: "warning", isActive: true },
      { name: "alert", isActive: true }
    ]);
    expect(wrapper.vm.activeTags).toEqual([
      { name: "alert", id: 2 },
      { name: "warning", id: 3 },
      { name: newTagName, isActive: true }
    ]);
    expect(wrapper.vm.filterValue).toBeFalsy();
  });
});

describe("Coworkers", () => {
  let store, wrapper;
  const coworkers = [
    {
      avatarUrl: "gravatar",
      id: "42",
      name: "Callie Client"
    }
  ];
  const awailableWatchers = [
    {
      avatarUrl: "gravatar",
      id: "42",
      name: "Dolly Developer"
    }
  ];

  beforeEach(() => {
    store = new Vuex.Store({ mutations, actions, state });
    store.state.newAvailableWatchers = awailableWatchers;
    store.state.coworkers = coworkers;
    wrapper = shallowMount(Coworkers, {
      store,
      localVue,
      propsData: {
        options: coworkers,
        bem: bem,
        task: issue,
        translations: Locales
      }
    });
    expect(wrapper.vm).toBeTruthy();
  });

  test("Create a coworker list on mounted in popup", () => {
    expect(wrapper.vm.persons).toEqual([
      {
        avatarUrl: "gravatar",
        id: "42",
        isCoworker: true,
        name: "Callie Client"
      },
      {
        avatarUrl: "gravatar",
        id: "42",
        isCoworker: false,
        name: "Dolly Developer"
      }
    ]);
  });

  test("Remove coworker", () => {
    wrapper.vm.addOrRemoveCoworker({
      avatarUrl: "gravatar",
      id: "42",
      isCoworker: true,
      name: "Callie Client"
    });
    expect(wrapper.vm.coworkers).toEqual([]);
  });

  test("Add coworker", () => {
    store.state.issue.project = {
      id: 2
    };
    expect(wrapper.vm.coworkers.length).toBe(1);
    wrapper.vm.addOrRemoveCoworker({
      avatarUrl: "gravatar",
      id: "46",
      isCoworker: false,
      name: "Connie Consultant"
    });
    expect(wrapper.vm.coworkers.length).toBe(2);
    expect(actions.saveIssueStateValue).toHaveBeenCalled();
  });

  test("Unset all coworkers", () => {
    expect(wrapper.vm.coworkers.length).toBe(1);
    wrapper.vm.unsetAllCoworkers();
    expect(wrapper.vm.coworkers.length).toBe(0);
    expect(actions.saveIssueStateValue).toHaveBeenCalled();
  });
});

describe("EmptyModal.vue", () => {
  let store, wrapper;
  beforeEach(() => {
    store = new Vuex.Store({ mutations, actions, state });
    store.state.showModal = true;
    wrapper = mount(EmptyModal, {
      store,
      localVue,
      propsData: {
        bemBlock: "easy-vue",
        actionButtons: [
          {
            name: "action-button",
            closeAfterEvent: false,
            func: () => {}
          }
        ],
        options: {
          body: "<p class='helloWorld'>Tests says hello</p>",
          header: "Hello world"
        }
      }
    });
  });

  test("Empty modal without sidebar", () => {
    const bemBlock = wrapper.props("bemBlock");
    wrapper.setProps({ actionButtons: [] });
    const noSidebarResult = {
      [`${bemBlock}--no-sidebar`]: true,
      [`${bemBlock}--empty`]: true
    };
    expect(wrapper.vm.wrapperClasses).toEqual(noSidebarResult);
  });

  test("Empty modal with sidebar", () => {
    const bemBlock = wrapper.props("bemBlock");
    const noSidebarResult = {
      [`${bemBlock}--no-sidebar`]: false,
      [`${bemBlock}--empty`]: true
    };
    expect(wrapper.vm.wrapperClasses).toEqual(noSidebarResult);
  });

  test("Render HTML header properly", async () => {
    const childComponent = wrapper.findComponent(Wrapper);
    const renderedHtml = childComponent.find(".vue-modal__headline");
    expect(renderedHtml.text()).toBe(wrapper.vm.$props.options.header);
  });
});
