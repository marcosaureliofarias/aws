<template>
  <div>
    <div v-if="newUrl || !shortUrls.length" :class="bem.ify(block, `${element}`)">
      <h4 :class="bem.ify(bem.block, `${element}-heading`) + ' popup-heading'">
        {{ translations.heading_easy_short_urls_new }}
      </h4>
      <div
        :class="bem.ify(block, `${element}-input-wrapper`)"
      >
        <label :class="bem.ify(block, `${element}-item-label`)">
          {{ translations.activerecord_attributes_easy_short_url_source_url }}
        </label>
        <input
          v-model="inputValue"
          type="text"
          :class="bem.ify(block, `${element}-input`)"
        />
        <label :class="bem.ify(block, `${element}-item-label`)">
          {{ translations.activerecord_attributes_easy_short_url_valid_to }}
        </label>
        <datetime
          v-model="date"
          popup-class="excluded"
          :format="format"
        />
        <label :class="bem.ify(block, `${element}-item-label`)">
          <input
            v-model="externalAccess"
            type="checkbox"
          />
          {{ translations.activerecord_attributes_easy_short_url_allow_external }}
        </label>
        <p>( {{ translations.text_short_url_allow_external }} )</p>
      </div>
      <div class="button-set">
        <button
          href="#"
          :class="
            bem.ify(block, `${element}-create-button`) + ' button-positive'
          "
          @click.stop="createUrl()"
        >
          {{ translations.button_create }}
        </button>
        <button
          href="#"
          :class="
            bem.ify(block, `${element}-create-button`) + ' button-negative'
          "
          @click="$emit('onBlur')"
        >
          {{ translations.button_cancel }}
        </button>
      </div>
    </div>
    <div v-else-if="newUrl || shortUrls.length" :class="bem.ify(block, `${element}`)">
      <div
        :class="bem.ify(block, `${element}-input-wrapper`)"
      >
        <h3 :class="bem.ify(bem.block, `${element}-heading`) + ' popup-heading'">
          {{ translations.heading_easy_short_urls_index }}
          <button
            :class="
              bem.ify(block, `${element}-create-button`) + ' button-positive excluded'
            "
            @click="createNewUrl()"
          >
            {{ translations.label_new }}
          </button>
        </h3>
        <div
          v-for="(shortUrl, i) in shortUrls"
          :key="i"
          :class="bem.ify(block, `${element}-item`)"
        >
          <div>
            <label :class="bem.ify(block, `${element}-item-label`)">
              {{ translations.heading_easy_short_urls_show }}
            </label>
            <div class="input-append tooltip">
              <input
                type="text"
                :value="shortUrl.shortUrl || shortUrl.sourceUrl"
              />
              <span
                v-if="copiedURLCount === i"
                :class="bem.ify(block, `${element}-item-copy`) + ' tooltip-content icon-checked'"
                style="display: block; right: 0; z-index: 2; top: 3px; line-height: 21px;"
              >{{ translations.label_copied }}</span>
              <a
                class="icon icon-copy"
                :title="translations.button_copy"
                @click.stop="copy(shortUrl.shortUrl, i)"
              />
            </div>
            <label :class="bem.ify(block, `${element}-item-label`)">
              {{ translations.activerecord_attributes_easy_short_url_allow_external }} :
              {{ shortUrl.allowExternal ? translations.general_text_yes : translations.general_text_no }}
            </label>
            <div>
              <label :class="bem.ify(block, `${element}-item-label`)">
                {{ translations.activerecord_attributes_easy_short_url_valid_to }}:
              </label>
              <span> {{ dateFormat(shortUrl.validTo) }}</span>
            </div>
          </div>
          <div :class="bem.ify(block, `${element}-item-qrcode`)">
            <img :src="`/easy_qr?size=100;t=${shortUrl.shortUrl}`" alt="qrcode" />
          </div>
        </div>
      </div>
    </div>
  </div>
</template>

<script>
import createShortUrl from "../../graphql/shortUrl";
import attachmentsQuery from "../../graphql/attachmnents";

  export default {
    name: "ShortUrl",
    props: {
      bem: Object,
      options: Object,
      translations: Object
    },
    data() {
      return {
        date: this.dateISOStringParseZone(new Date(new Date().setDate(new Date().getDate() + 15))),
        format: this.dateFormatString(),
        inputValue: this.sourcePath(),
        easyShortUrls: this.$props.options.easyShortUrls,
        externalAccess: 0,
        newUrl: false,
        copiedURLCount: null,
        block: this.$props.bem.block,
        element: this.$options.name.toLowerCase(),
      };
    },
    computed: {
      shortUrls() {
        return this.easyShortUrls;
      }
    },
    methods: {
      async createUrl(){
        const attachment = this.$props.options;
        const attributes = {
          sourceUrl: this.inputValue,
          validTo: this.dateFormatForRequest(this.date, "date"),
          allowExternal: !!this.externalAccess
        };
        const payload = {
          mutationName: "easyShortUrlCreate",
          apolloMutation: {
            mutation: createShortUrl,
            variables: {
              entityId: attachment.id,
              entityType: "Attachment",
              attributes
            }
          },
          pathToGet: ["easyShortUrlCreate", "easyShortUrl"],
          pathToSet: ["issue", "attachments", `${attachment.number}`, "easyShortUrls"]
        };
        await this.$store.dispatch("mutateValue", payload);
        await this.getAttachments(this.$store.state.issue.id);
        this.easyShortUrls = this.$store.state.issue.attachments[attachment.number].easyShortUrls;
        this.newUrl = false;
      },
      sourcePath() {
        const attachment = this.$props.options;
        attachment.sourcePath = `/attachments/${attachment.id}/${attachment.filename}`;
        return attachment.sourcePath;
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
      createNewUrl() {
        this.newUrl = true;
      },
      copy(url, i) {
        this.copyToClipboard(url);
        this.copiedURLCount = i;
        setTimeout(() => {
          this.copiedURLCount = null;
        }, 1500);
      }
    }
  };
</script>

<style lang="scss" scoped>

</style>
