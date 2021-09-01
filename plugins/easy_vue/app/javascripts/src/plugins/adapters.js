if (window.gantt) {
  gantt.modalAdapter = {
    open(...args){
      return EasyVue.showModal(...args);
    }
  };
}
