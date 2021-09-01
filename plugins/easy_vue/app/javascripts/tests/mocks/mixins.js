const mixins = {
  methods: {
    showByTracker: () => true,
    isModuleEnabled: () => true,
    dateISOStringParseZone: date => date,
    dateFormatString: () => "",
    dateFormatForRequest: (date, type) => date,
    serializeForm: () => "someSerializedText",
    registerShortcut: () => {},
    allowShortcuts: () => {},
    attachShortcutEvent: () => {},
    moveAndFocus: () => {},
    isFeatureEnabled: () => {},
    wipActivated: () => {},
    getFirstDayOfWeek: () => {},
    setOldModalsStyle: () => {},
    showBackdrop: () => {},
    prepareLabelClass: () => ""
  }
};

export default mixins;
