<template>
  <section id="attachments_anchor" :class="bem.ify(block, 'section')">
    <h2 :class="bem.ify(block, 'heading') + ' icon--attachment'">
      {{ translations.label_issue_attachments_heading }}
    </h2>
    <template v-show="task.editable">
      <form v-if="!inPopUp && cfArray" ref="attachments__cf-wrapper" />
      <div
        v-if="!inPopUp"
        :class="`${bem.ify(block, `${element}-dropzone`)} ${dragover}`"
        @drop.prevent="handleAttachmentLoad($event)"
        @dragover.prevent="drag = true"
        @dragleave.prevent="drag = false"
      >
        <div v-if="!loading" class="dropzone-info">
          <p>{{ translations.label_attachment_new }}</p>
          <span
            v-if="$store.state.allSettings.attachment_max_size"
            :class="bem.ify(block, `${element}-dropzone-max-size`)"
          >
            {{ translations.setting_attachment_max_size }}:
            {{ formatedFileSize(maxFilesize) }}
          </span>
        </div>
        <div v-if="loading" class="dropzone-uploading">
          <p>
            {{ uploadedAttachmentsCount }}/{{ attachmentsCount }}
            {{ translations.label_issue_attachments_heading.toLowerCase() }}
          </p>
          <ProgressBar :ratio="uploadedRatio" />
        </div>
      </div>
      <button
        v-if="!inPopUp"
        type="button"
        class="button-positive"
        @click="addAttachment"
      >
        {{ translations.button_select_file }}
      </button>
      <input
        v-show="false"
        id="file_input"
        ref="file"
        type="file"
        name="attachment_file"
        multiple
        @change="handleAttachmentLoad()"
      />
    </template>
    <div :class="bem.ify(block, element)">
      <div
        v-for="(attachment, i) in options"
        :key="attachment.id"
        :class="bem.ify(block, `${element}-item`)"
      >
        <div :class="bem.ify(block, `${element}-item-thumb`)">
          <!-- adding version to path bc of cashing, we want picture to update -->
          <img
            v-if="attachment.thumbnailPath"
            :src="attachment.thumbnailPath + `?${attachment.version || ''}`"
            alt="#"
            @click="showView(i)"
          />
          <span
            v-if="!attachment.thumbnailPath"
            :class="
              'icon icon-attachment ' + bem.ify(block, `-item-thumb--default`)
            "
          />
        </div>
        <div :class="bem.ify(block, `${element}-item-info`)">
          <a
            v-if="attachment.deletable"
            :title="translations.button_delete"
            :class="
              bem.ify(block, `${element}-item-delete`) +
                ' icon--delete' +
                ' excluded'
            "
            @click="showConfirm($event, attachment, 'deleteAttachment')"
          />
          <a
            :href="`${attachment.attachmentPath}`"
            target="_blank"
            :class="bem.ify(block, `${element}-item-name`)"
          >
            {{ attachment.filename }}
            <span
              v-if="attachment.version"
              :class="bem.ify(block, `${element}-item-version`)"
            >
              - v{{ attachment.version }}
            </span>
          </a>
          <span :class="bem.ify(block, `${element}-item-size`)">
            {{ translations.field_filesize }}:
            {{ formatedFileSize(attachment.filesize) }}
            <a
              :class="
                bem.ify(block, `${element}-item-download`) + ' icon--download'
              "
              :href="attachment.contentUrl"
              :title="translations.title_download_attachment"
            />
            <a
              :class="bem.ify(block, `${element}-item-tab`) + ' icon-link'"
              :href="`${attachment.attachmentPath}`"
              target="_blank"
              title="Open in new tab"
            />
            <a
              v-if="!inPopUp"
              :class="
                bem.ify(block, `${element}-item-url`) +
                  ' icon-crm-1' +
                  ' excluded'
              "
              href="#"
              :title="translations.heading_easy_short_urls_new"
              @click="createShortUrl($event, attachment, i, isMobile)"
            />
            <a
              v-if="attachment.editable && attachment.webdavUrl && !inPopUp"
              :class="
                bem.ify(block, `${element}-item-edit`) +
                  ' icon-cloud' +
                  ' excluded'
              "
              href="#"
              :title="translations.heading_online_editing"
              @click="onlineEdit($event, attachment, isMobile)"
            />
            <a
              v-if="!inPopUp"
              :class="
                bem.ify(block, `${element}-item-version`) +
                  ' icon-file-new' +
                  ' exluded'
              "
              href="#"
              :title="translations.title_add_new_attachment_version"
              @click="uploadNewVersion(attachment)"
            />
            <a
              v-if="
                attachment.versions &&
                  attachment.versions.length > 1 &&
                  !inPopUp
              "
              :class="
                bem.ify(block, `${element}-item-version`) +
                  ' icon-list' +
                  ' excluded'
              "
              href="#"
              :title="translations.button_attachment_context_menu"
              @click="showVersionHistory($event, attachment, isMobile)"
            />
            <!-- first attachment obj means version and attachment.attachment its original attachment -->
            <a
              v-if="
                inPopUp &&
                  +attachment.version !== +attachment.attachment.version &&
                  attachment.attachment.editable &&
                  attachment.editable
              "
              :class="
                bem.ify(block, `${element}-item-revert`) +
                  ' icon-move' +
                  ' excluded'
              "
              href="#"
              :title="translations.label_revert_to_version"
              @click="
                showConfirm($event, attachment, 'revertVersion', isMobile)
              "
            />
            <PopUp
              v-if="currentComponent && currentAttachment.id === attachment.id"
              :bem="bem"
              :align="alignment"
              :component="currentComponent"
              :options="popUpOptions"
              :custom-values="cfArray"
              :custom-styles="custom"
              :excluded-items="excludedItems"
              :translations="translations"
              @onBlur="closePopUp"
              @confirmed="
                confirmAction($event, i, currentAttachment, action, inPopUp)
              "
            />
          </span>
          <p :class="bem.ify(block, `${element}-item-created`)">
            {{ translations.field_created_on }}
            {{ datePretifier(attachment.createdOn) }} by
            {{ attachment.author.name }}
          </p>
        </div>
      </div>
    </div>
    <VueGallery
      :images="images"
      :index="index"
      @close="closeGallery"
      @onclosed="onClosedGallery"
    />
  </section>
</template>
<script>
import VueGallery from "vue-gallery";
import PopUp from "../generalComponents/PopUp";
import ProgressBar from "../generalComponents/ProgressBar";
import attachmentsQuery from "../../graphql/attachmnents";

export default {
  name: "Attachments",
  components: {
    VueGallery,
    PopUp,
    ProgressBar,
  },
  props: {
    bem: Object,
    options: Array,
    task: Object,
    inPopUp: Boolean,
    customValues: Array,
    isMobile: {
      type: Boolean,
      default: false
    }
  },
  data() {
    return {
      file: {},
      drag: false,
      maxFilesize: this.$store.state.allSettings.attachment_max_size * 1024,
      action: "",
      showFull: false,
      index: null,
      images: [],
      newVersion: false,
      pdfPath: "",
      currentComponent: "",
      currentAttachment: null,
      versionsShow: false,
      top: 0,
      custom: {},
      popUpOptions: {},
      excludedItems: [],
      alignment: {},
      urlPrefix: window.urlPrefix,
      fileInput: { inputType: "file" },
      attachmentsCount: 0,
      uploadedAttachmentsCount: 0,
      loading: false,
      translations: this.$store.state.allLocales,
      block: this.$props.bem.block,
      element: this.$options.name.toLowerCase()
    };
  },
  computed: {
    attachments() {
      return this.$props.options;
    },
    cfArray() {
      return this.$props.customValues;
    },
    dragover() {
      return this.drag ? "dragover" : "";
    },
    uploadedRatio() {
      const ratio =
        (this.uploadedAttachmentsCount / this.attachmentsCount) * 100;
      return Math.floor(ratio);
    },
  },
  mounted() {
    this.buildCustomFields();
  },
  methods: {
    formatedFileSize(size) {
      const units = ["bytes", "kB", "MB", "GB", "TB", "PB", "EB", "ZB", "YB"];
      let l = 0;
      let n = parseInt(size, 10) || 0;
      while (n >= 1024 && ++l) {
        n = n / 1024;
      }
      return n.toFixed(n < 10 && l > 0 ? 1 : 0) + " " + units[l];
    },
    async handleAttachmentLoad(e) {
      if (!e && !this.$refs.file.files.length) return;
      const files =
        this.$refs.file.files.length > 0
          ? this.$refs.file.files
          : e.dataTransfer.files;
      if (!files.length) return;
      this.attachmentsCount = files.length;
      this.uploadedAttachmentsCount = 0;
      for (let i = 0; i < files.length; i++) {
        this.loading = true;
        const file = files.item(i);
        this.file = file;
        if (!this.file) return;
        if (file.size >= this.maxFilesize) {
          const err = {
            message: this.$store.state.allLocales.error_attachment_too_big.replace(
              / *\([^)]*\) */g,
              ""
            ),
          };
          this.$store.commit("setNotification", { err });
          return;
        }
        const self = this;
        const fileReader = new FileReader();
        const { token, errors } = await self.getAttachmnetToken(file);
        if (errors?.length) {
          this.loading = false;
          this.$store.commit("setNotification", { errors });
          return;
        }
        const id = self.$props.task.id;
        const dataLoad = this.newVersion
          ? this.newVersionPayload(file, token, id, this.currentAttachment)
          : this.createAttachmentPayload(file, token);
        fileReader.onloadend = ((file, dataLoad) => {
          const payload = dataLoad;
          this.uploadedAttachmentsCount = i + 1;
          return async function() {
            await self.$store.dispatch("saveIssueStateValue", payload);
            await self.getAttachments(id);
            // Reset input so we can take file from frag and drop event
            self.$refs.file.value = "";
            self.loading = false;
          };
        })(file, dataLoad);
        fileReader.readAsDataURL(file);
      }
    },
    datePretifier(date) {
      return this.dateFormat(date);
    },
    createAttachmentPayload(file, token, customPayload) {
      const options = {
        cfArray: this.cfArray,
        cfForm: this.$refs["attachments__cf-wrapper"],
        cfPrefix: "attachments"
      };
      let value = {
        filename: file.name,
        token,
        custom_field_values: options.cfForm ? this.getCFValues(options) : []
      };
      let payload = {
        value,
        reqBody: { attachments: [value] },
        reqType: "patch"
      };
      payload = customPayload ? { ...payload, ...customPayload } : payload;
      return payload;
    },
    newVersionPayload(file, token, id, attachment) {
      const value = {
        filename: file.name,
        token,
        custom_version_for_attachment_id: attachment.id
      };
      const payload = {
        value,
        reqBody: {
          container_id: id,
          attachments: [value],
          entity_type: "Issue",
          entity_id: id,
          format: "json"
        },
        reqType: "post",
        url: `/attachments/attach/Issue/${id}.json`
      };
      return this.createAttachmentPayload(file, token, payload);
    },
    addAttachment() {
      this.newVersion = false;
      this.$refs.file.click();
    },
    async deleteAttachment(id, i) {
      const payload = {
        reqType: "delete",
        reqBody: {
          id,
        },
        url: `${window.urlPrefix}/attachments/${id}.json`
      };
      await this.$store.dispatch("saveIssueStateValue", payload);
      this.deleteItem("attachments", i);
    },
    async getAttachmnetToken(file) {
      const request = new Request(`${window.urlPrefix}/uploads.json?filename=${file.name}`);
      const options = {
        method: "POST",
        headers: {
          "Content-Type": "application/octet-stream"
        },
        body: file,
        processData: false
      };
      const data = await fetch(request, options);
      const response = await data.json();
      const { errors, upload: { token } = {} } = response;
      return { errors, token };
    },
    showView(i) {
      this.$store.state.onlyModalContent = true;
      this.$store.state.preventModalClose = true;
      this.showFull = true;
      this.index = i;
      if (this.attachments.length === this.images.length) return;
      this.images = [];
      this.attachments.forEach(element => {
        if (element.contentUrl) {
          this.images.push(element.contentUrl);
        } else {
          this.images.push(element.thumbnailPath);
        }
      });
    },
    closeGallery() {
      this.$store.state.onlyModalContent = false;
      this.index = null;
    },
    onClosedGallery() {
      this.$store.state.preventModalClose = false;
    },
    createShortUrl(e, attachment, i, isMobile) {
      this.currentAttachment = attachment;
      const options = {
        topOffs: 20,
        rightOffs: 150
      };
      this.custom = {
        height: "320px !important",
      };
      this.alignment = this.getAlignment(e, options, isMobile);
      this.currentComponent = "ShortUrl";
      attachment.number = i;
      this.popUpOptions = this.currentAttachment;
      this.$set(this.popUpOptions.easyShortUrls, attachment.easyShortUrls);
    },
    onlineEdit(e, attachment, isMobile) {
      this.currentAttachment = attachment;
      const options = {
        topOffs: 17,
        rightOffs: 130
      };
      this.custom = {
        height: "200px !important",
      };
      this.alignment = this.getAlignment(e, options, isMobile);
      this.currentComponent = "OnlineEdit";
      this.popUpOptions = attachment;
    },
    closePopUp() {
      this.currentComponent = null;
      this.custom = "";
      this.versionsShow = false;
    },
    async getAttachments(id) {
      const payload = {
        name: "attachments",
        apolloQuery: {
          query: attachmentsQuery,
          variables: {
            id,
          }
        }
      };
      await this.$store.dispatch("fetchIssueValue", payload);
    },
    uploadNewVersion(attachment) {
      this.newVersion = true;
      this.currentAttachment = attachment;
      this.$refs.file.click();
    },
    showConfirm(e, attachment, action, isMobile) {
      const options = {
        topOffs: 20,
        rightOffs: 15
      };
      this.custom = {
        width: "auto",
        height: "95px !important",
        display: "flex",
        "align-items": "center",
      };
      this.alignment = this.getAlignment(e, options, isMobile);
      this.currentComponent = "Confirm";
      this.action = action;
      this.currentAttachment = attachment;
    },
    confirmAction(confirmed, i, attachment, action, inPopUp) {
      if (confirmed) {
        switch (action) {
          case "deleteAttachment": {
            if (!inPopUp) {
              this.deleteAttachment(attachment.id, i);
              break;
            } else {
              this.deleteAttachmentVersion(attachment.id, i);
              break;
            }
          }
          case "revertVersion": {
            this.revertVersion(attachment);
            break;
          }
        }
      }
      this.currentComponent = null;
    },
    buildCustomFields() {
      const options = {
        cfArray: this.cfArray,
        container: "attachments__cf-wrapper",
        classes: {}
      };
      this.customFieldsBuilder(options);
    },
    showVersionHistory(e, attachment, isMobile) {
      this.custom = {};
      const options = {
        topOffs: 13,
        rightOffs: 100
      };
      this.alignment = this.getAlignment(e, options, isMobile);
      this.currentAttachment = attachment;
      this.popUpOptions = attachment.versions;
      this.versionsShow = true;
      this.currentComponent = "Attachments";
    },
    async deleteAttachmentVersion(id, i) {
      const payload = {
        reqType: "get",
        reqBody: {
          id
        },
        url: `/attachments/${id}/destroy_version`
      };
      await this.$store.dispatch("saveIssueStateValue", payload);
      this.deleteItem("attachments", i);
    },
    async revertVersion(attachment) {
      const id = attachment.attachment.id;
      const payload = {
        reqType: "get",
        url: `${window.urlPrefix}/attachments/${id}/revert_to_version?version_num=${attachment.version}`
      };
      await this.$store.dispatch("saveIssueStateValue", payload);
      await this.getAttachments(this.$store.state.issue.id);
    }
  }
};
</script>
