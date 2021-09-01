<template>
  <div class="repeating-invitations">
    <ul class="vue-modal__attributes vue-modal__attributes--invitations">
      <Attribute
        :bem="bem"
        :data="invitations"
        :multiple="true"
        class="l__w--full"
        @child-value-change="setUsers"
      />
    </ul>
    <div class="vue-modal__button-panel">
      <button type="button" class="button-positive" @click="saveUsers">
        {{ translations.button_save }}
      </button>
      <button type="button" class="button" @click="$emit('onBlur')">
        {{ translations.button_cancel }}
      </button>
    </div>
  </div>
</template>

<script>
import Attribute from "../generalComponents/Attribute";
export default {
  name: "InvitationsPopup",
  components: {
    Attribute
  },
  props: {
    bem: Object,
    translations: Object,
    entity: {
      type: Object,
      default: () => {}
    }
  },
  data() {
    return {
      users: this.prepareValue()
    };
  },
  computed: {
    invitations() {
      return {
        labelName: this.translations.label_invitations,
        value: this.users,
        classes: { edit: ["u-editing"], show: ["u-showing"] },
        inputType: "autocomplete",
        searchQuery: this.fetchUsers,
        optionsArray: false,
        filterable: false,
        withSpan: false,
        editable: true,
        withLoading: false
      };
    }
  },
  methods: {
    prepareValue() {
      const invitations = this.entity.easyInvitations;
      const formattedValue = invitations.map(invitation => {
        return { name: invitation.user.name, value: invitation.user.id };
      });
      return formattedValue;
    },
    async fetchUsers(id, term) {
      term = term || "";
      const invitations = this.entity.easyInvitations;
      const url = `/easy_autocompletes/users_in_meeting_calendar?include_groups=true&include_me=true&term=${term}`;
      const response = await fetch(url);
      const data = await response.json();
      const formattedData = [];
      data.users.forEach(user => {
        const value = user.id === "me" ? EASY.currentUser.id : user.id;
        const invited = invitations.find(el => el.user.id == value);
        if (!invited) {
          formattedData.push({
            value: value,
            name: user.value
          });
        }
      });
      return formattedData;
    },
    setUsers(payload) {
      this.users = payload.inputValue;
    },
    saveUsers() {
      // we need to send users active users as Array of ids
      const userIds = this.users.map(payloadVal => {
        const id = payloadVal.value || payloadVal.id;
        return id.toString();
      });
      this.$emit("data-change", {
        payload: { user_ids: userIds }
      });
      this.$emit("onBlur");
    }
  }
};
</script>

<style scoped></style>
