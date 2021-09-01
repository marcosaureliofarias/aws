<template>
  <section id="member_list" :class="bem.ify(block, 'section')">
    <h2 :class="bem.ify(block, 'heading') + ' icon--issue'">
      {{ " Members " }}
    </h2>
    <ul :class="bem.ify(block, 'members')">
      <li v-for="(user, i) in users" :key="i">
        <img
          alt=""
          class="gravatar"
          :title="user.name"
          :srcset="user.avatarUrl + ' 2x'"
          :src="user.avatarUrl"
        />
        <a :href="userUrl(user.id)" target="_blank">{{ user.name }}</a>
      </li>
    </ul>
  </section>
</template>

<script>
export default {
  name: "MemberList",
  props: { bem: Object, users: Array },
  data() {
    return {
      translations: this.$store.state.allLocales,
      block: this.$props.bem.block,
      element: this.$props.bem.element,
      modifier: this.$options.name.toLowerCase()
    };
  },
  methods: {
    userUrl(id) {
      return `${window.urlPrefix}/users/${id}`;
    }
  }
};
</script>

<style scoped></style>
