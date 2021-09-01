const issueHelper = {
  getPriority(eventValue, state, id) {
    const pairedPriority = state.allEnumerations.filter(
      priorityEnum => +priorityEnum.id === id
    );
    if (!pairedPriority.length) return;
    return pairedPriority[0];
  },
  getLocales(allLocales) {
    const transformedLocales = {};
    allLocales.forEach(locale => {
      const transformedKey = locale.key.replace(/\./gm, "_");
      transformedLocales[transformedKey] = locale.translation;
    });
    return transformedLocales;
  },
  deleteByID(obj, id) {
    return obj.filter(child => child.id !== id);
  },
  transformArrayToObject(array) {
    const transformedObj = {};
    array.forEach(element => {
      transformedObj[element.key] = element.value;
    });
    return transformedObj;
  },
  getValidationErrorMessages(errors) {
    const messages = errors.map(error => {
      return error.fullMessages;
    });
    return messages;
  }
};

export default issueHelper;
