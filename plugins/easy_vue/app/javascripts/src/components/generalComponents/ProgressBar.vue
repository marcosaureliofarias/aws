<template>
  <span class="progress-parent">
    <table
      class="progress  progress-60"
      style="width: 100%;"
      :title="`${getRatio}%`"
    >
      <tbody>
        <tr>
          <td
            :style="{ width: `${getRatio}%` }"
            class="closed"
            :title="`${getRatio}%`"
          />
          <td :style="{ width: `${100 - getRatio}%` }" class="todo" />
        </tr>
      </tbody>
    </table>
    <p class="percent" @click="$emit('progress-click')">{{ getRatio }}%</p>
    <slot />
  </span>
</template>

<script>
export default {
  name: "ProgressBar",
  props: {
    type: String,
    ratio: Number
  },
  computed: {
    getRatio() {
      const ratio = this.$props.ratio;
      const type = this.$props.type;
      if (type === "timeRatio" && ratio === null) {
        this.$emit("hide-time-ratio");
      }
      return ratio;
    }
  }
};
</script>

<style lang="scss" scoped></style>
