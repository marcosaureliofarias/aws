(function () {

  window.easyMindMupClasses.WbsMoneyModals = WbsMoneyModals;

  function WbsMoneyModals (ysy) {
    this.ysy = ysy;
    /** @type {jQuery} */
    this.$target = null;
    /** @type {ModelEntity} */
    this.patch(ysy);
  }

  WbsMoneyModals.prototype.patch = function (ysy) {
    var self = this;
    ysy.eventBus.register("MapInited", function (mapModel) {
      ysy.eventBus.register('nodeBudgetDetailShow', $.proxy(self.showBudgetDetail, self));
    });
  };

  /***
   *
   * @param {ModelEntity} idea
   * @param {string} tab
   */
  WbsMoneyModals.prototype.showBudgetDetail = function (idea, tab) {
    var self = this;
    var ysy = this.ysy;
    ysy.money = ysy.money || {};
    if (!ysy.money.hasOwnProperty('partial')) {
      ysy.money.partial = {};
    }
    this.idea = idea;
    var entityType = idea.attr.entityType === "project" ? "Project" :
        idea.attr.entityType === "issue" ? "Issue" : false;
    this.params = {
      entity_type: entityType,
      entity_id: idea.attr.data.id,
      currency: ysy.settings.selectedCurrency,
      tab: tab
    };
    if (ysy.money.partial.hasOwnProperty(tab) && !(tab === 'overview')) {
      this.setBudgetDetail(ysy.money.partial[tab], tab);
    }
    else {
      $.ajax({
        url: this.ysy.settings.paths.getBudgetOverview,
        type: "POST",
        data: this.params,
        complete: function (data) {
          ysy.money.partial[self.params.tab] = data.responseText;
          self.setBudgetDetail(data.responseText, self.params.tab);
        }
      });
    }
  };

  /***
   *
   * @param {string} budgetData
   * @param {string} tab
   * @param url
   */
  WbsMoneyModals.prototype.setBudgetDetail = function (budgetData, tab, url) {
    this.$target = this.ysy.util.getModal("form-modal", "90%");
    this.params.tab = tab;
    this.finishDetailModal(tab, this.idea.attr.entityType, budgetData, url);
  };

  /***
   *
   * @param {string}tab
   * @param {string}entityType
   * @param {string}form
   * @param url
   */
  WbsMoneyModals.prototype.finishDetailModal = function (tab, entityType, form, url) {
    var $form = $(form);
    var ysy = this.ysy;
    var settings = ysy.settings;
    var self = this;
    var error = false;
    var innerTittleText = settings.labels.modals['detail_budget' + "_" + entityType];

    /*remodeling of the form*/
    if ($form.find('#money-type-select').length > 0) this.secondTabSelector($form);
    if ($form.find('.tablesaw').length > 0) $form.find('.tablesaw').removeClass('tablesaw');
    if ($form.find('.ending-buttons-fixed').length > 0) $form.find('.ending-buttons-fixed').remove();
    if ($form.find('.easy_money_form_title').length > 0) {
      var tittle = $form.find('.easy_money_form_title');
      if (tittle["0"].innerText !== undefined) innerTittleText = tittle["0"].innerText;
      tittle.hide();
    }
    if ($form.find('#easy_currency_code').length > 0) $form.find('#easy_currency_code').remove();
    if ($form.find('table > thead > tr > th > a').length > 0) $form.find('table > thead > tr > th > a').click(self, this.detailOfDetailModal);
    if (url && $form.find('.infinite-scroll-load-next-page-trigger').length > 0) $form.find('.infinite-scroll-load-next-page-trigger').attr({
      href: url,
      target: "_blank"
    });
    if (tab === 'overview') {
      $form.find('.index-link').click(self, this.detailOfDetailModal);
    }

    /*if backend send 403 partial*/
    if ($form.find('#errorExplanation').length > 0) {
      error = true;
      var backButton = $form.find('#errorExplanation').next('p');
      if (backButton.children()[0].className === 'button') backButton.remove();
    }

    var $target = this.$target;
    $target.empty().append($form);

    if (!settings.easyRedmine) {
      $form.contents().filter(function () {
        return this.nodeName === "A" || this.nodeType == 3;
      }).remove();
      $('<div class="issue_submit_buttons"></div>').append($form.find('input[type="submit"]')).appendTo($form);
    }

    $target.prepend($("<div class='tabs tab-container title-header'></div>"));
    $target.prepend($("<h3 class='title'>" + innerTittleText + "</h3>"));

    /*sets bookmarks*/
    var $targetHeader = $target.find('.title-header');
    $targetHeader.css('height', 65);
    this.addModalTabs($targetHeader);

    /*sets modal buttons*/
    $form.find(".form-actions").detach();
    var buttons = [];
    if (tab !== 'overview' && !error && tab !== 'overview_detail') {
      buttons.push(
        {
          class: "button button-positive",
          text: settings.labels.buttons.save,
          click: $.proxy(this.submitDetailModal, this)
        }
      )
    }
    buttons.push(
        {
          class: "button",
          text: settings.labels.buttons.close,
          click: $.proxy(this.closeDetailModal, this)
        }
    )
    showModal("form-modal");
    $('#form-modal').dialog('option', {
      buttons: buttons,
    });
    this.$target.on("dialogclose", $.proxy(this.closeDetailModal, this));
    $target.parent().find('.form-actions').detach();
    var $closeButton = $target.parent().find('.ui-dialog-titlebar-close');
    $closeButton.click($.proxy(this.closeDetailModal, this));
  };

  /***
   * attach event to radio button
   * @param {jQuery} $form
   */
  WbsMoneyModals.prototype.secondTabSelector = function ($form) {
    var ysy = this.ysy;
    var self = this;
    for (var i = 0; i < $form.length; i++) {
      if ($form[i].nodeName === 'SCRIPT') delete $form[i];
    }
    $form.find('#money-type-select input:radio').change(function () {
      ysy.eventBus.fireEvent('nodeBudgetDetailShow', self.idea, this.value)
    });
  };

  /***
   * open modal with a url
   * @param event
   * @return {boolean}
   */
  WbsMoneyModals.prototype.detailOfDetailModal = function (event) {
    var self = event.data;
    $.ajax({
      url: this.href,
      type: "GET",
      complete: function (data) {
        self.setBudgetDetail(data.responseText, 'overview_detail', this.url);
      }
    });
    return false
  };

  /***
   * sets bookmarks
   * @param {jQuery} $targetHeader
   */
  WbsMoneyModals.prototype.addModalTabs = function ($targetHeader) {
    var ysy = this.ysy;
    var self = this;
    if (ysy.money.hasOwnProperty('tabs')) {
      var tabs = ysy.money.tabs;
      var removeSelect = $(tabs).find('.selected')[0];
      var addSelect = $(tabs).find('[tab-value=' + this.params.tab + ']');
      if (removeSelect && removeSelect.getAttribute('tab-value') !== this.params.tab) {
        if (addSelect.length > 0) {
          $(addSelect[0]).addClass('selected');
          $(removeSelect).removeClass('selected');
        }
        else if (removeSelect.getAttribute('tab-value') === 'overview') {
          $(removeSelect).removeClass('selected');
        }
      } else if (addSelect.length > 0) {
        $(addSelect[0]).addClass('selected');
      }
      $(tabs).appendTo($targetHeader);
    }
    else {
      $.ajax({
        url: this.ysy.settings.paths.getBudgetLinks,
        type: "POST",
        data: this.params,
        dataType: "json",
        complete: function (data) {
          var links = data.responseJSON;
          var tabs = document.createElement('ul');

          /*create tabs*/
          for (var i = 0; i < links.length; i++) {
            var link = links[i];
            var tab = document.createElement('li');
            var tabElementA = document.createElement('a');
            tabElementA.innerHTML = link.label;
            tabElementA.setAttribute('tab-value', link.tab);
            tabElementA.style.cursor = "pointer";
            tabElementA.onclick = function () {
              ysy.eventBus.fireEvent('nodeBudgetDetailShow', self.idea, this.getAttribute('tab-value'));
            };
            if (self.params.tab === link.tab) {
              tabElementA.setAttribute('class', 'selected');
            }
            tab.appendChild(tabElementA);
            tabs.appendChild(tab);
          }

          $(tabs).appendTo($targetHeader);
          ysy.money.tabs = tabs;
        }
      });
    }
  };

  /***
   * save action
   * @param e
   * @return {boolean}
   */
  WbsMoneyModals.prototype.submitDetailModal = function (e) {
    var $target = this.$target;
    var $form = $target.find('form');
    var url = $form.attr('action');

    if (window.fillFormTextAreaFromCKEditor) {
      $target.find("textarea").each(function () {
        window.fillFormTextAreaFromCKEditor(this.id);
      });
    }

    var data = $target.parent().find("form").serialize();
    this.sendDataDetailModal(data, url);
    return false;
  };

  /***
   *
   * @param data
   * @param url
   */
  WbsMoneyModals.prototype.sendDataDetailModal = function (data, url) {
    var $target = this.$target;
    var self = this;
    var $form = $target.find('form');
    /***
     *
     * @param {string} message
     * @param {string} type
     * @return {boolean}
     */
    self._flashMessage = function (message, type) {
      $target.find('.flash').remove();
      var errorSpan = $('<span></span>').html(message);
      var closeButton = $('<a href="javascript:void(0)" class="easy-mindmup__icon easy-mindmup__icon--close mindmup_modal__flash_close"></a>').click(function (event) {
        $(this)
            .closest('.flash')
            .fadeOut(500, function () {
              $(this).remove();
            });
      });
      $target.prepend($('<div style="opacity: 0.2" class="flash ' + type + '"></div>').append(errorSpan, closeButton));
      $target.find('.flash').fadeTo("slow", 1);
      return false;
    };

    data = data + '&format=json';
    $.ajax({
      url: url,
      type: "POST",
      data: data,
      dataType: "json",
      success: function (data) {
        $form[0].reset();
        self._flashMessage(self.ysy.settings.labels.errors.allSaved, 'notice');
      },
      error: function (errorMessage) {
        self._flashMessage(errorMessage.responseJSON.errors.join("<br>"), 'error');
      }
    });
  };

  /***
   * close modal and reset all changed data
   */
  WbsMoneyModals.prototype.closeDetailModal = function () {
    var ysy = this.ysy;
    ysy.money.partial = {};
    delete ysy.money.tabs;
    var modelEntityIdea = ysy.mapModel.findIdeaById(this.idea.id);
    ysy.util.forAllParents(ysy.idea, modelEntityIdea, function (parent) {
      delete parent.attr.data.budgets;
      parent.attr.force = true;
    });
    delete modelEntityIdea.attr.data.budgets;
    modelEntityIdea.attr.force = true;

    ysy.idea.dispatchEvent("changed");
    if (this.$target.dialog("instance")) {
      this.$target.dialog('close');
    }
  };


})();
