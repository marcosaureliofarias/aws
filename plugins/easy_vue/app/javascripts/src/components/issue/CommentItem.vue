<template>
  <div>
    <div>
      <p :class="bem.ify(block, 'comment-signature')">
        <a
          title="By clicking show profile."
          data-remote="true"
          :href="getUserHrefUrl(comment.user)"
          :class="bem.ify(block, 'comment-avatar') + ' avatar__wrapper'"
        >
          <img
            alt="#"
            title=""
            class="gravatar"
            :srcset="getUserAvatarSrc(comment.user)"
            :src="getUserAvatarSrc(comment.user)"
          />
        </a>
        {{ comment.user.name }}
        <span v-if="comment.privateNotes" class="private">
          {{ `(${translations.field_is_private})` }}
        </span>
        {{ strictDateFormat(comment.createdOn) }}
      </p>
      <div :class="bem.ify(block, 'comment-body')" v-html="comment.notes" />
      <div
        v-if="emojiPlugin"
        class="emoji"
        @mouseenter="showEmojiBoxFunc(true)"
        @mouseleave="showEmojiBoxFunc(false)"
      >
        <div v-if="showEmojiBox" class="emoji__box">
          <div v-if="emojiDetail.length" class="emoji__detail">
            <span v-for="(detail, i) in emojiDetail" :key="i">
              <img
                alt="#"
                title=""
                class="gravatar gravatar--emoji"
                :srcset="getUserAvatarSrc(detail.author.avatarUrl)"
                :src="getUserAvatarSrc(detail.author.avatarUrl)"
              />
              <a :href="getUserHrefUrl(detail.author)" data-remote="true">
                {{ detail.author.name }}
              </a>
            </span>
          </div>
          <span
            v-for="(emoji, i) in emojiList"
            :key="i"
            class="icon emoji__emoji-icon"
            style="cursor: pointer;"
            @mouseenter="showEmojiDetail(i)"
            @mouseleave="stopEmojiDetail"
            @click="toggleEmoji({ emojilist: commentsEmojiList[i], emoji: i })"
          >
            {{ emoji }}
            <span class="emoji__number">
              {{ commentsEmojiList[i].length }}
            </span>
          </span>
        </div>
        <span
          v-else
          class="excluded icon icon-christmas-linux emoji__button"
          @click="showEmojiBox = !showEmojiBox"
        />
      </div>
      <a
        v-if="permissionToAction(comment)"
        href="#"
        :title="translations.label_user_form_other_settings"
        class="excluded"
        :class="actionsBtnClass"
        @click="showActions = !showActions"
      />
      <div
        v-if="showActions"
        v-blur-closing="{
          handler: 'onBlur'
        }"
        class="excluded"
        :class="bem.ify(block, 'comment-actions')"
      >
        <a
          v-if="permissions.addableNotes"
          class="excluded icon icon-undo"
          href="#"
          @click="$emit('comment-reply')"
        >
          {{ translations.button_reply }}
        </a>
        <a
          v-if="comment.editable"
          class="excluded icon icon-edit"
          href="#"
          @click="$emit('comment-edit')"
        >
          {{ translations.button_edit }}
        </a>
        <a
          v-if="comment.deletable"
          class="excluded icon icon-del"
          :class="bem.ify(block, 'comment-button-delete')"
          href="#"
          @click.stop="showConfirm($event, isMobile)"
        >
          {{ translations.button_delete }}
        </a>
      </div>
    </div>
    <PopUp
      v-if="currentComponent"
      :bem="bem"
      :align="alignment"
      :custom-styles="custom"
      :component="currentComponent"
      :translations="translations"
      :excluded-items="excludedItems"
      @onBlur="currentComponent = null"
      @confirmed="confirmAction($event)"
    />
  </div>
</template>

<script>
import PopUp from "../generalComponents/PopUp";

export default {
  name: "CommentItem",
  components: {
    PopUp
  },
  props: {
    comment: Object,
    bem: Object,
    translations: Object,
    permissions: Object,
    emojiList: Object,
    isMobile: {
      type: Boolean,
      default: false
    }
  },
  data() {
    return {
      currentComponent: null,
      alignment: "",
      excludedItems: [],
      custom: {},
      block: this.$props.bem.block,
      element: this.$props.bem.block + "-" + this.$options.name.toLowerCase(),
      showActions: false,
      showEmojiBox: false,
      emojiPlugin: false, // turn off emojis
      commentsEmoji: this.$props.comment.easyEmojis,
      emojiDetail: [],
      emojiDetailFunc: null,
      permissionToAction: (comment) => {
        return (
          comment.editable || comment.deletable || this.permissions.addableNotes
        );
      }
    };
  },
  computed: {
    actionsBtnClass() {
      return {
        [this.bem.ify(this.block, "comment-menu-btn")]: true,
        "icon-reorder": !this.showActions,
        "icon-close": this.showActions
      };
    },
    commentsEmojiList() {
      const list = [];
      for (let emoji in this.$props.emojiList) {
        if (!this.$props.emojiList.hasOwnProperty(emoji)) continue;
        list[emoji] = [];
      }
      for (let comentEmoji in this.$props.comment.easyEmojis) {
        if (
          !this.$props.comment.easyEmojis.hasOwnProperty(comentEmoji) &&
          !list.hasOwnProperty(comentEmoji)
        )
          continue;
        list[this.$props.comment.easyEmojis[comentEmoji].emojiId].push(
          this.$props.comment.easyEmojis[comentEmoji]
        );
      }
      return list;
    }
  },
  methods: {
    showConfirm(e, isMobile) {
      this.custom = {
        width: "auto",
        height: "95px !important",
        display: "flex",
        "align-items": "center"
      };
      this.alignment = this.getAlignment(e, {}, isMobile);
      this.currentComponent = "Confirm";
    },
    confirmAction(value) {
      if (value) {
        this.$emit("comment-delete");
      }
      this.currentComponent = null;
    },
    showEmojiBoxFunc(open) {
      this.showEmojiBox = open;
      this.emojiDetail = [];
    },
    showEmojiDetail(i) {
      this.emojiDetailFunc = setTimeout(() => {
        this.emojiDetail = this.commentsEmojiList[i];
      }, 500);
    },
    stopEmojiDetail() {
      clearInterval(this.emojiDetailFunc);
    },
    toggleEmoji(options) {
      this.emojiDetail = [];
      this.$emit("toggle-emoji", options);
    },
    onBlur() {
      this.showActions = false;
    }
  }
};
</script>
