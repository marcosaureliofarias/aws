<template>
  <section id="invitations" :class="bem.ify(bem.block, 'section')">
    <h2 :class="bem.ify(bem.block, 'heading') + ' icon--group'">
      {{ translations.label_invitations }}
      <span
        v-if="editable"
        :title="translations.button_manage_invitations"
        :class="`excluded icon-edit ${bem.ify(bem.block, 'heading-action')}`"
        @click="handlePopup('InvitationsPopup', $event)"
      />
    </h2>
    <div class="entity-array labeled">
      <span
        v-for="(invitation, i) in invitations"
        :key="i"
        :class="getInvitationClass(invitation)"
      >
        {{ invitation.user.name }}
      </span>
    </div>
  </section>
</template>

<script>
export default {
  name: "Invitations",
  props: {
    invitations: {
      type: Array,
      default: () => []
    },
    bem: {
      type: Object,
      default: () => {}
    },
    translations: {
      type: Object,
      default: () => {}
    },
    editable: {
      type: Boolean,
      default: true
    }
  },
  methods: {
    getInvitationClass(invitation) {
      if (invitation.accepted === null) return "";
      return invitation.accepted ? "positive" : "negative";
    },
    handlePopup(component, e) {
      this.$emit("handle-popup", { component, e });
    }
  }
};
</script>

<style scoped></style>
