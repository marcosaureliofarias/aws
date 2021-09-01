<template>
  <div :class="bem.ify(bem.block, 'tags')">
    <div :class="bem.ify(block, `${element}-head`)">
      <h4 :class="bem.ify(bem.block, `${element}-heading`)">
        {{ translations.label_easy_tags }}
      </h4>
      <span
        :class="bem.ify(block, `${element}-input-wrapper`) + ' input-append'"
      >
        <input
          ref="filterInput"
          v-model="filterValue"
          type="text"
          :class="bem.ify(block, `${element}-input`)"
          @keydown.enter="createTag()"
        />
        <button
          href="#"
          :disabled="!filterValue"
          :class="
            bem.ify(block, `${element}-input-button`) + ' button icon-add-action'
          "
          @click="createTag()"
        />
        <button
          href="#"
          :disabled="!filterValue"
          :class="
            bem.ify(block, `${element}-input-button`) + ' button icon--del'
          "
          @click="clearInput()"
        />
      </span>
    </div>
    <div :class="bem.ify(block, `${element}-list-wrapper`)">
      <ul :class="bem.ify(block, `${element}-list`)">
        <li
          v-for="(tag, i) in filterTags()"
          :key="i"
          :class="
            tag.isActive
              ? bem.ify(block, `${element}-item--active`) +
                ' ' +
                bem.ify(block, `${element}-item`)
              : bem.ify(block, `${element}-item`)
          "
        >
          <label :class="bem.ify(block, `${element}-item-label`)">
            <input
              v-model="tag.isActive"
              type="checkbox"
              :class="bem.ify(block, `${element}-item-checkbox`)"
              @change="addOrRemoveTag(tag)"
            />
            <span :class="bem.ify(block, `${element}-item-name`)">
              {{ tag.name }}
            </span>
          </label>
        </li>
      </ul>
    </div>
  </div>
</template>

<script>
export default {
  name: "Tags",
  props: { bem: Object, options: Array },
  data() {
    return {
      translations: this.$store.state.allLocales,
      tagList: [],
      filterValue: null,
      storeTags: this.$store.state.issue.tags,
      block: this.$props.bem.block,
      element: this.$options.name.toLowerCase()
    };
  },
  computed: {
    activeTags: {
      get() {
        return this.$store.state.issue.tags;
      },
      set(value) {
        this.storeTags = value;
      }
    }
  },
  mounted() {
    this.createTagsList();
    this.$refs.filterInput.focus();
  },
  methods: {
    filterTags() {
      if (!this.filterValue) return this.tagList;
      const filtered = this.tagList.filter(element => {
          return element.name.toLowerCase().includes(this.filterValue.toLowerCase());
        }
      );
      return filtered;
    },
    clearInput() {
      this.$refs.filterInput = null;
      this.filterValue = null;
    },
    createTag() {
      if (this.filterValue.length === 0) return;
      const tag = { isActive: true, name: this.filterValue };
      let isInTagList = false;
      let isActive = false;
      let self = this;
      this.tagList.forEach(function(tag) {
        if (self.filterValue === tag.name) {
          tag.isActive = true;
          isInTagList = true;
        }
      });
      this.activeTags.forEach(function(tag) {
        if (self.filterValue === tag.name) {
          isActive = true;
        }
      });
      if (!isInTagList) {
        this.tagList.unshift(tag);
      }
      if (!isActive) {
        this.addOrRemoveTag(tag);
      }
      const tagNames = this.tagList.map(tag => tag.name);
      const payload = {
        name: "tags",
        value: tagNames,
        level: "state"
      };
      this.$store.commit("setStoreValue", payload);
      this.filterValue = "";
    },
    createTagsList() {
      const tags = this.$props.options;
      tags.forEach(tag => {
        const item = {
          name: tag,
          isActive: !!this.activeTags.find(el => el.name === tag)
        };
        item.isActive ? this.tagList.unshift(item) : this.tagList.push(item);
      });
    },
    addOrRemoveTag(tag) {
      if (tag.isActive) {
        this.activeTags.push(tag);
        const tagNames = this.activeTags.map(tag => tag.name);
        const payload = {
            name: "tags",
            value: {
              tags: this.activeTags
            },
            reqBody: {
              entity: {
                tag_list: tagNames
              },
              id: this.$store.state.issue.id,
              klass: "issue"
            },
            reqType: "post",
            url: `${window.urlPrefix}/easy_taggables.json`
        };
        this.$store.dispatch("saveIssueStateValue", payload);
      } else {
        this.activeTags.forEach((element, i) => {
          if (element.name === tag.name) {
            this.$delete(this.activeTags, i);
            const tagNames = this.activeTags.map(tag => tag.name);
            const payload = {
              name: "tags",
              value: {
                tags: this.activeTags
              },
              reqBody: {
                entity: {
                  tag_list: tagNames
                },
                id: this.$store.state.issue.id,
                klass: "issue"
              },
              reqType: "post",
              url: "/easy_taggables.json"
            };
            this.$store.dispatch("saveIssueStateValue", payload);
          }
        });
      }
    }
  }
};
</script>

<style lang="scss" scoped></style>
