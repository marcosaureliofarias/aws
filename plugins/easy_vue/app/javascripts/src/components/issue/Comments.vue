<template>
  <section id="comments_anchor" :class="bem.ify(block, 'section')">
    <h2 :class="bem.ify(block, 'heading') + ' icon--comments'">
      {{ translations.label_comment_plural }}
    </h2>
    <div :class="bem.ify(block, element)">
      <div :class="bem.ify(block, 'comment-add')">
        <div :class="bem.ify(block, 'comment-add-editor')">
          <input
            v-if="!editorShow"
            ref="comment"
            type="text"
            :placeholder="translations.label_comment_add"
            :class="bem.ify(block, 'fake-ck__full-width')"
            @click="editorSwitch()"
          />
          <EditorBox
            v-if="permissions.addableNotes && editorShow"
            ref="comentEditor"
            :value="editorInput"
            :config="commentAddConfig"
            :translations="translations"
            :textile="textile"
            :bem="bem"
            @save-updates="addComment($event)"
            @valueChanged="changeComment($event, false)"
            @cancel-edit="clearChanges"
          >
            <template>
              <label
                v-if="permissions.privateComments"
                :class="bem.ify(block, element)"
              >
                {{ translations.field_private_notes }}
                <input v-model="isPrivate" type="checkbox" name="privat" />
              </label>
              <label
                :class="
                  bem.ify(block, 'contextual') + ' ' + bem.ify(block, 'legend')
                "
              >
                {{
                  `${translations.button_show} ${translations.label_visibility_all_activities}`
                }}
                <input v-model="showActivity" type="checkbox" class="button" />
              </label>
            </template>
          </EditorBox>
        </div>
        <div v-if="!showActivity" :class="bem.ify(block, `comment-wrapper`)">
          <div
            v-for="(comment, i) in comments"
            :key="comment.id"
            :class="bem.ify(block, 'comment')"
          >
            <CommentItem
              v-if="commentEditConfig.editId !== comment.id"
              :comment="comment"
              :bem="bem"
              :translations="translations"
              :permissions="permissions"
              :is-mobile="isMobile"
              :emoji-list="allAvailableEmojis"
              @comment-delete="commentDelete(comment, i)"
              @comment-edit="commentEdit(comment)"
              @comment-reply="commentReply(comment)"
              @toggle-emoji="toggleEmoji($event, comment)"
            />
            <EditorBox
              v-if="
                commentEditConfig.edit &&
                  commentEditConfig.editId === comment.id
              "
              :config="commentEditConfig"
              :value="editCommentInput"
              :translations="translations"
              :textile="textile"
              :bem="bem"
              @valueChanged="changeComment($event, true)"
              @save-updates="saveComment($event, comment)"
              @cancel-edit="cancelEdit"
            >
              <template v-if="permissions.privateComments">
                <label :class="bem.ify(block, element)">
                  {{ translations.field_private_notes }}
                  <input
                    v-model="comment.privateNotes"
                    type="checkbox"
                    name="privat"
                    @input="setEditChangedState"
                  />
                </label>
              </template>
            </EditorBox>
          </div>
        </div>
        <Activity
          v-if="showActivity"
          :bem="bem"
          :show-activity="showActivity"
          :activities="formatActivities"
        />
      </div>
      <div
        v-if="!hideAllJournalsBtn && comments.length >= 10"
        :class="bem.ify(block, 'comments__button-panel')"
      >
        <button
          type="button"
          class="button"
          @click="$emit('fetch-all-journals')"
        >
          {{ translations.button_show_all_issue_statuses }}
        </button>
      </div>
    </div>
  </section>
</template>

<script>
import Activity from "../generalComponents/Activity";
import CommentItem from "./CommentItem";
import EditorBox from "../generalComponents/EditorBox";

export default {
  name: "Comments",
  components: {
    Activity,
    CommentItem,
    EditorBox
  },
  props: {
    journals: Array,
    bem: Object,
    permissions: Object,
    isMobile: {
      type: Boolean,
      default: false
    },
    textile: {
      type: Boolean,
      default: () => false
    }
  },
  data() {
    return {
      translations: this.$store.state.allLocales,
      allAvailableEmojis: this.$store.state.allAvailableEmojis,
      commentAddConfig: {
        edit: true,
        clearOnSave: true,
        showButtons: true,
        startupFocus: true,
        id: "comment"
      },
      commentEditConfig: {
        edit: false,
        editId: "",
        clearOnSave: false,
        showButtons: true,
        id: "commentEdit",
        startupFocus: true
      },
      editCommentInput: "",
      isPrivate: this.$store.state.allSettings.issue_private_note_as_default,
      editorInput: "",
      commentEditor: null,
      options: null,
      showActivity: false,
      action: "",
      block: this.$props.bem.block,
      element: this.$options.name.toLowerCase(),
      editorShow: false,
      running: false
    };
  },
  computed: {
    activities() {
      const activities = this.$props.journals.filter(
        el => el.details.length > 0
      );
      return activities;
    },
    comments() {
      const comments = this.$props.journals.filter(el => el.notes);
      return comments;
    },
    formatActivities() {
      let activities = [];
      const journals = this.$props.journals;
      if (this.showActivity) {
        journals.forEach(journal => {
          if (journal.details.length > 0) {
            const activity = {
              createdOn: journal.createdOn,
              id: journal.id,
              notes: journal.notes,
              user: journal.user,
              details: {
                asString: ""
              }
            };
            journal.details.forEach(detail => {
              activity.details.asString += `<br>${detail.asString}`;
            });
            activities.push(activity);
          } else {
            activities.push(journal);
          }
        });
      }
      return activities;
    },
    hideAllJournalsBtn() {
      return this.$store.state.fetchAllJournals;
    }
  },
  watch: {
    editorInput(val, oldVal) {
      // do not touch me!!!
      if (val === oldVal || this.running) return;
      if (val.includes("ilovepink")) {
        this.running = true;
        const container = document.querySelector(".vue-modal__container");
        const elms = container.querySelectorAll("*");
        if (!container || !elms) return;
        elms.forEach(el => (el.style.background = "pink"));
        let degs = 30;
        setInterval(() => {
          container.style.transform = `rotate(${degs}deg)`;
          degs += 30;
        }, 500);
      }
    }
  },
  mounted() {
    if (this.$props.textile) {
      this.registerShortcut({
        ref: this.$refs.comment,
        key: "c",
        options: {
          focus: true,
          click: true
        }
      });
    } else {
      this.registerShortcut({
        ref: this.$refs.comment,
        key: "c",
        options: {
          focus: true,
          click: true,
          ckeditor: this.commentAddConfig.id
        }
      });
    }
  },
  methods: {
    editorSwitch() {
      this.editorShow = !this.editorShow;
    },
    toggleEmoji(event, comment) {
      let remove = false;
      event.emojilist.forEach(emoji => {
        if (Number(emoji.author.id) === window.EASY.currentUser.id) {
          remove = true;
        }
      });
      const payload = {
        commentID: comment.id,
        emojiID: event.emoji
      };
      if (!remove) {
        this.$emit("add-emoji", payload);
      } else {
        this.$emit("remove-emoji", payload);
      }
    },
    datePretifier(date) {
      return this.this.strictDateFormat(date);
    },
    async addComment(inputValue) {
      const payload = {
        inputValue: inputValue,
        isPrivate: this.isPrivate
      };
      this.$emit("add-comment", payload);
      this.clearChanges();
    },
    saveComment(value, comment) {
      if (this.action === "reply") {
        this.addComment(value, comment);
        this.commentEditConfig.edit = false;
        this.commentEditConfig.editId = "";
      } else {
        this.updateComment(value, comment);
      }
      this.action = "";
    },
    async commentDelete(comment, i) {
      this.$emit("delete-comment", comment);
      this.$delete(this.comments, i);
    },
    async commentEdit(comment) {
      this.commentEditConfig.edit = true;
      this.commentEditConfig.editId = comment.id;
      this.commentEditOrReplyValue(comment);
    },
    async updateComment(value, comment) {
      comment.notes = value;
      const payload = {
        value,
        comment
      };
      this.$emit("update-comment", payload);
      this.commentEditConfig.edit = false;
      this.commentEditConfig.editId = "";
    },
    commentReply(comment) {
      this.action = "reply";
      this.commentEdit(comment);
    },
    cancelEdit() {
      this.commentEditConfig.edit = false;
      this.commentEditConfig.editId = "";
      this.wipActivated(false);
      this.action = "";
    },
    commentEditOrReplyValue(comment) {
      const quoteStructure = `${comment.user.name} wrote:\n> <blockquote>${comment.notes}</blockquote>\n\n"`;
      this.editCommentInput =
        this.action === "reply" ? quoteStructure : comment.notes;
    },
    changeComment(value, isEdit) {
      if (isEdit) {
        this.editCommentInput = value;
      } else {
        this.editorInput = value;
      }
    },
    clearChanges() {
      this.wipActivated(false);
      if (this.$store.state.allSettings.text_formatting !== "HTML") {
        this.editorInput = "";
      } else {
        this.editorInput = "";
        CKEDITOR.instances[this.commentAddConfig.id].setData("");
      }
      this.editorShow = false;
    },
    setEditChangedState() {
      if (this.commentEditConfig.changed) return;
      this.$set(this.commentEditConfig, "changed", true);
    }
  }
};
</script>
