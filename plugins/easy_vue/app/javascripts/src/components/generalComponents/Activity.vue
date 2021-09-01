<template>
  <div :class="bem.ify(block, 'comment-wrapper')">
    <div
      v-for="(activity, i) in activities"
      :key="i"
      :class="bem.ify(block, 'comment')"
    >
      <p :class="bem.ify(block, 'comment-signature')">
        <a
          title="By clicking show profile."
          data-remote="true"
          :href="getUserHrefUrl(activity.user)"
          :class="bem.ify(block, 'comment-avatar') + ' avatar__wrapper'"
        >
          <img
            alt=""
            title=""
            class="gravatar"
            :srcset="getUserAvatarSrc(activity.user)"
            :src="getUserAvatarSrc(activity.user)"
          />
        </a>
        <span :class="bem.ify(block, 'activity-author')">
          {{ activity.user.name }}
        </span>
        <span
          v-if="activity.details.asString"
          :class="bem.ify(block, 'activity-text')"
          v-html="activity.details.asString"
        />
        <span :class="bem.ify(block, 'activity-date')">
          {{ datePretifier(activity.createdOn) }}
        </span>
      </p>
      <div
        v-if="activity.notes"
        :class="bem.ify(block, 'comment-body')"
        v-html="activity.notes"
      />
    </div>
  </div>
</template>

<script>
export default {
  name: "Activity",
  props: {
    bem: Object,
    activities: Array
  },
  data() {
    return {
      translations: this.$store.state.allLocales,
      block: this.$props.bem.block,
      element: this.$props.bem.element
    };
  },
  methods: {
    datePretifier(date) {
      return this.strictDateFormat(date);
    },
    deleteComment(i) {
      this.deleteItem("comments", i);
    }
  }
};
</script>
