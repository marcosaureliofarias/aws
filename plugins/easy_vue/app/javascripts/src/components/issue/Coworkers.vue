<template>
  <div
    ref="div"
    :class="bem.ify(block, element)"
    tabindex="0"
    @blur="$emit('on-blur')"
  >
    <div :class="bem.ify(block, `${element}-head`)">
      <h4 :class="bem.ify(block, `${element}-heading`)">
        {{ translations.field_watcher }}
        <button
          v-if="$props.task.deletableWatchers"
          href="#"
          class="button"
          @click="unsetAllCoworkers()"
        >
          {{ translations.button_unset_all }}
        </button>
      </h4>
      <span
        :class="bem.ify(block, `${element}-input-wrapper`) + ' input-append'"
      >
        <input
          ref="filterInput"
          v-model="filterValue"
          type="text"
          :class="bem.ify(block, `${element}-input`)"
          @input="filterPersons($store.state.newAvailableWatchers)"
        />
        <a
          href="#"
          :disabled="!filterValue"
          :class="
            bem.ify(block, `${element}-input-clear`) + ' button icon--del'
          "
          @click="clearInput()"
        />
      </span>
    </div>
    <div :class="bem.ify(block, `${element}-list-wrapper`)">
      <ul :class="bem.ify(block, `${element}-list`)">
        <li v-for="(person, i) in persons" :key="i" :class="isCoworker(person)">
          <label :class="bem.ify(block, `${element}-item-label`)">
            <input
              v-model="person.isCoworker"
              type="checkbox"
              :class="bem.ify(block, `${element}-item-checkbox`)"
              @click="addOrRemoveCoworker(person)"
            />
            <span
              title="By clicking show profile."
              :class="
                bem.ify(block, 'coworkers-avatar') +
                  ' avatar__wrapper ' +
                  bem.ify(block, `${element}-item-avatar`)
              "
            >
              <img
                alt=""
                title=""
                class="gravatar"
                :srcset="person.avatarUrl + ' 2x'"
                :src="person.avatarUrl"
              />
            </span>
            <span :class="bem.ify(block, `${element}-item-name`)">
              <a
                :href="`${urlPrefix}/users/${person.id}/profile`"
                target="_blank"
              >
                {{ person.name }}
              </a>
            </span>
          </label>
        </li>
      </ul>
    </div>
  </div>
</template>

<script>
import watchersQuery from "../../graphql/awailableWatchers";

export default {
  name: "Coworkers",
  props: {
    bem: Object,
    options: Array,
    task: Object,
    translations: Object,
  },
  data() {
    return {
      filterValue: null,
      defaultAvatar: this.$store.state.defaultAvatarUrl,
      persons: [],
      coworkers: [...this.$store.state.coworkers],
      block: this.$props.bem.block,
      element: this.$options.name.toLowerCase(),
      urlPrefix: window.urlPrefix,
    };
  },
  mounted() {
    this.makeCoworkersArray(this.$store.state.newAvailableWatchers);
    this.$refs.filterInput.focus();
  },
  methods: {
    isCoworker(person) {
      return person.isCoworker
        ? this.bem.ify(this.block, `${this.element}-item--active`) +
            " " +
            this.bem.ify(this.block, `${this.element}-item`)
        : this.bem.ify(this.block, `${this.element}-item`);
    },
    makeCoworkersArray(array) {
      this.persons = [];
      // available coworkers are only possible coworkers
      array.forEach((posible) => {
        let person = {
          name: posible.name,
          avatarUrl: posible.avatarUrl || this.defaultAvatar,
          isCoworker: false,
          id: posible.id,
        };
        this.persons.push(person);
      });
      // term from API returns only available coworkers without actual coworkers, so we need to add them to array
      this.coworkers.forEach((coworker) => {
        const filteredName =
          this.filterValue &&
          coworker.name.toLowerCase().includes(this.filterValue.toLowerCase());
        if (!this.filterValue || filteredName) {
          const transformed = { ...coworker };
          transformed.isCoworker = true;
          this.persons.unshift(transformed);
        }
      });
    },
    addOrRemoveCoworker(person) {
      const issueQuery = this.urlPrefix + "/issues/";
      const state = this.$store.state;
      if (!person.isCoworker) {
        // if user does not have permissions to add watchers
        this.coworkers.push(person);
        if (!this.$props.task.addableWatchers) return;
        const payload = {
          name: "watchers",
          value: {
            watchers: this.coworkers,
          },
          reqBody: {
            object_type: "issue",
            object_id: state.issue.id,
            project_id: state.issue.project.id,
            watcher: {
              user_ids: [person.id],
            },
          },
          reqType: "post",
          url: `${this.urlPrefix}/watchers.json`,
        };
        person.isCoworker = true;
        this.$store.dispatch("saveIssueStateValue", payload);
        const coworkersPayload = {
          name: "coworkers",
          value: person,
          level: "state",
          toPush: true,
        };
        this.$store.commit("setStoreValue", coworkersPayload);
      } else {
        // If user does not have permission to delete watchers
        if (!this.$props.task.deletableWatchers) return;
        this.coworkers.forEach((element, i) => {
          if (element.name === person.name) {
            this.$delete(this.coworkers, i);
            const payload = {
              name: "watchers",
              value: {
                watchers: this.coworkers,
              },
              reqBody: {
                object_type: "issue",
                object_id: state.issue.id,
                user_ids: [person.id],
              },
              reqType: "delete",
              url: `${issueQuery}${state.issue.id}/watchers/${person.id}.json`,
            };
            this.$store.dispatch("saveIssueStateValue", payload);
          }
        });
        person.isCoworker = false;
        const filteredCoworkers = this.$store.state.coworkers.filter(
          (coworker) => coworker.id !== person.id
        );
        const coworkersPayload = {
          name: "coworkers",
          value: filteredCoworkers,
          level: "state",
        };
        this.$store.commit("setStoreValue", coworkersPayload);
      }
    },
    unsetAllCoworkers() {
      const issueQuery = window.urlPrefix + "/issues/";
      const state = this.$store.state;
      this.coworkers.forEach((element) => {
        element.isCoworker = false;
        const payload = {
          name: "watchers",
          value: {
            watchers: [],
          },
          reqBody: {
            object_type: "issue",
            object_id: state.issue.id,
            user_ids: [element.id],
          },
          reqType: "delete",
          url: `${issueQuery}${state.issue.id}/watchers/${element.id}.json`,
        };
        this.$store.dispatch("saveIssueStateValue", payload);
      });
      this.coworkers = [];
      this.persons.forEach((p) => (p.isCoworker = false));
      const coworkersPayload = {
        name: "coworkers",
        value: [],
        level: "state",
      };
      this.$store.commit("setStoreValue", coworkersPayload);
    },
    async filterPersons(array) {
      const id = this.$store.state.issue.id;
      const payload = {
        name: "newAvailableWatchers",
        query: watchersQuery(id, this.filterValue),
      };
      await this.$store.dispatch("getFilteredArray", payload);
      this.makeCoworkersArray(array);
    },
    clearInput() {
      this.$refs.filterInput = null;
      this.filterValue = null;
    },
  },
};
</script>
