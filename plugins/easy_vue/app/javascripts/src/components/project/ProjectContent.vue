<template>
  <div>
    <Detail :project="project" :bem="bem" />
    <Description :entity="project" :bem="bem" :editable="true" @save="saveDescription" />
    <MemberList :users="project.users" :bem="bem" />
    <History :activities="activities" :translations="translations" :bem="bem" />
  </div>
</template>
<script>
import Description from "../generalComponents/Description";
import Detail from "./Detail";
import MemberList from "./MemberList";
import History from "../generalComponents/History";
export default {
  name: "DefaultView",
  components: {
    MemberList,
    Detail,
    Description,
    History
  },
  props: {
    project: Object,
    bem: Object,
    activeBtns: Array,
    translations: Object
  },
  data() {
    return {
      block: this.$props.bem.block,
      element: this.$props.bem.element,
      modifier: this.$options.name.toLowerCase()
    };
  },
  computed: {
    activities() {
      let activities = [];
      const journals = this.$props.project.journals;
      journals.forEach(journal => {
        if (journal.details.length > 0) {
          journal.details.forEach(detail => {
            const activity = {
              createdOn: journal.createdOn,
              id: journal.id,
              notes: journal.notes,
              user: journal.user,
              details: {
                asString: detail.asString
              }
            };
            activities.push(activity);
          });
        } else {
          activities.push(journal);
        }
      });
      return activities;
    },
  },
  methods: {
    async saveDescription(inputValue) {
      const value = {
        description: inputValue
      };
      const payload = {
        name: "description",
        value,
        reqBody: {
          project: value
        }
      };
      await this.$store.dispatch("saveProjectStateValue", payload);
    },
  }
};
</script>
<style lang="scss" scoped></style>
