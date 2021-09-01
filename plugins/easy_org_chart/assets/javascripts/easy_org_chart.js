(function($){
    var $orgChartUsersContainer = $('#easy-org-chart-users'),
        $orgChartUsersForm = $('#easy-org-chart-form'),
        $orgChartUsersSearch = $('#easy-org-chart-users-search'),
        $orgChartContainer = $('[data-role="easy-org-chart"]'),
        $orgChartDropZone = $('#easy-org-chart-users-drop-zone'),
        $buttonSave = $('[data-org-chart-action="save"]'),

        $withUsers = $('#easy-org-chart-with-user-id'),
        withUserIDs = [],
        $withoutUsers = $('#easy-org-chart-without-user-id'),
        withoutUserIDs = [],
        orgChartUsers = {};


    var orgChartOptions = {
        'draggable': true,
        'removable': true,
        'pan': false,
        'createNode': function($node, data, options) {
            var edges = $node.find('.edge');

            // hideOrgChartUser(data.id);
            $node.html(createOrgChartNode(data, options).html());
            $node.addClass('orgchart-user');
            $node.append(edges);
        }
    };

    var escapeText = function(text) {
        var tmp = document.createElement('div');
        tmp.appendChild(document.createTextNode(text));
        return tmp.innerHTML;
    };

    var createOrgChartNode = function(data, options) {
        var $node = $("<div draggable='true' id='" + data.id + "' class='node orgchart-user'></div>"),
            $orgchartUserCustomFields = $("<ul class='orgchart-user-custom-fields'></ul>"),
            options = $.extend({draggable: true}, options);

        if(data.avatar) {
            $node.append("<div class='orgchart-user-avatar'><img width='32' height='32' class='gravatar' src='"+data.avatar+"'></div>")
        }

        if(!options.draggable) {
            $node.append("<div class='orgchart-user-title'><a href='/users/"+data.user_id+"/profile' data-remote='true'>"+escapeText(data.name)+"</a></div>");
        } else {
            $node.append("<div class='orgchart-user-title'>"+escapeText(data.name)+"</div>");
        }

        if(data.custom_fields.length > 0) {
            for (var i = 0; i < data.custom_fields.length; i++) {
                $orgchartUserCustomFields.append("<li>"+data.custom_fields[i]+"</li>");
            }
            $node.append($orgchartUserCustomFields);
        }

        orgChartUsers[data.id] = data;

        return $node;
    };

    var loadUsers = function(reload) {
        if(reload === true) {
            $orgChartUsersSearch.val('');
        }
        $orgChartUsersForm.submit();
    };

    var extractUserIDFromGID = function(gid) {
        var decodedString = atob(gid),
            matchData = decodedString.match(/User\/(\d+)$/);

        return matchData ? parseInt(matchData[1]) : 0
    };

    var removeFromArray = function(array, element) {
        return array.filter(function(item) { return item !== element })
    };

    var hideOrgChartUser = function(gid) {
        var $userContainer = $("#easy-org-chart-user-"+gid),
            userID = extractUserIDFromGID(gid);

        $userContainer.addClass('org-chart-user-hidden').hide();

        withUserIDs = removeFromArray(withUserIDs, userID);
        withoutUserIDs.push(userID);

        $withUsers.val(withUserIDs);
        $withoutUsers.val(withoutUserIDs);
    };

    var showOrgChartUser = function(gid) {
        var $userContainer = $("#easy-org-chart-user-"+gid),
            userID = extractUserIDFromGID(gid);

        if($userContainer.length === 0 && orgChartUsers[gid]) {
            $userContainer = createOrgChartUser(orgChartUsers[gid]);
            $userContainer.removeClass('org-chart-user-removable');
        }

        $userContainer.removeClass('org-chart-user-hidden').show();

        withUserIDs.push(userID);
        withoutUserIDs = removeFromArray(withoutUserIDs, userID);

        $withUsers.val(withUserIDs);
        $withoutUsers.val(withoutUserIDs);
    };

    var updateOrgChartState = function() {
        $orgChartContainer.find('.node-parent').removeClass('node-parent');
        $orgChartContainer.find('table:has(.nodes) > tbody > tr:first-child .node').addClass('node-parent')
    };

    function orgChartZoom($container, action) {
        var zoom = parseFloat($container.data('zoom')) || 1;

        switch (action){
            case 'in':
                zoom += 0.1;
                break;
            case 'out':
                zoom -= 0.1;
                break;
            default:
                zoom = 1;
        }

        $container.data('zoom', zoom);
        $container.children().css({
            'transform': 'scale('+zoom+')',
            'transform-origin': 'top left'
        });
    }

    function initializeOrgChart() {
        $orgChartContainer.each(function(){
            var $orgChartContainerInstance = $(this),
                $orgChartContainerInstanceWrapper = $orgChartContainerInstance.parent(),
                orgChartDataPath = $orgChartContainerInstance.data('path'),
                orgChartEditable = $orgChartContainerInstance.data('org-chart-editable'),
                orgChartVerticalDepth = $orgChartContainerInstance.data('org-chart-vertical-depth');

            if(orgChartDataPath) {
                $.ajax({url: orgChartDataPath, dataType: 'json', cache: false})
                    .done(function(data){
                        if(!$.isEmptyObject(data)) {
                            $orgChartContainerInstance.orgchart($.extend(orgChartOptions, {data: data, draggable: orgChartEditable, verticalDepth: orgChartVerticalDepth}))
                        }
                    });
            }

            $orgChartContainerInstanceWrapper.on('click', '[data-org-chart-zoom]', function(event){
                event.preventDefault();

                orgChartZoom($orgChartContainerInstance, event.target.dataset.orgChartZoom);
            })
        });
    };

    function createOrgChartUser(data) {
        var $userContainer = $("<li class='link-list-item org-chart-user-list-item org-chart-user-removable' id='easy-org-chart-user-"+data.id+"' draggable='true'><span class='avatar-container'><img class='gravatar small' width='32' height='32' src='"+data.avatar+"'></span><div class='link-list-item-content link-list-item-ellipsis'>"+escapeText(data.name)+"</div></li>");

        $userContainer.data('org-chart-user', data);
        $orgChartUsersContainer.append($userContainer);

        return $userContainer;
    }

    $orgChartUsersSearch.on('keyup', $.debounce(loadUsers, 200));

    $orgChartContainer.on('drop', function(event){
        event.preventDefault();

        var originalEvent = event.originalEvent,
            $orgChartElement, orgChartData, orgChartData;

        $orgChartElement = $('#' + originalEvent.dataTransfer.getData('text'));
        orgChartData = $orgChartElement.data('org-chart-user');
        orgChartData = $.extend(orgChartOptions, {data: orgChartData});
        $orgChartContainer.orgchart(orgChartData);
        hideOrgChartUser(orgChartData.id);

    })
        .on('dragover', function(event){
            if(this.innerHTML === "") {
                event.preventDefault();
            }
        })
        .on('nodedropped.orgchart', function(event) {
            hideOrgChartUser(event.draggedNode.attr('id'));
            updateOrgChartState();
            $buttonSave.attr('disabled', false);
        })
        .on('nodedragstart.orgchart', function(event) {
            if(!event.childrenState.exist) {
                $orgChartDropZone.show();
            }
        })
        .on('nodedragend.orgchart', function(event) {
            $orgChartDropZone.hide();
        });

    $orgChartUsersContainer.on('dragstart', '.org-chart-user-list-item', function(event){
        var $this = $(this),
            originalEvent = event.originalEvent,
            $node, $nodeWrapper;

        if(!$this.is('.org-chart-user-list-item')) {
            $this = $this.closest('.org-chart-user-list-item');
        }

        $node = createOrgChartNode($this.data('org-chart-user'));
        $nodeWrapper = $('<td colspan="2"><table><tr><td></td></tr></table></td>');
        $nodeWrapper.find('td').append($node);

        $orgChartContainer.find('.orgchart').data('dragged', $node);

        originalEvent.dataTransfer.setDragImage($this[0], 16, 26);
        originalEvent.dataTransfer.setData('text', $this.attr('id'));

        $orgChartContainer.find('.node').addClass('allowedDrop');
    })
        .on('dragend', function(event){
            event.preventDefault();

            $orgChartContainer.find('.allowedDrop').removeClass('allowedDrop');
        });

    $orgChartDropZone.on('scroll touchmove mousewheel', function(event){
        event.preventDefault();
        event.stopPropagation();
        return false;
    })
        .on('dragover', function(event){
            event.preventDefault();
        })
        .on('drop', function(event){
            event.preventDefault();

            var originalEvent = event.originalEvent,
                userID = originalEvent.dataTransfer.getData('text'),
                $node;

            $node = $orgChartContainer.find("#" + userID);
            $orgChartContainer.orgchart('removeNodes', $node);

            showOrgChartUser(userID);
            updateOrgChartState();
            $buttonSave.attr('disabled', false);

            $orgChartDropZone.hide();
        });

    $buttonSave.on('click', function(){
        var $this = $(this),
            data = {};
        if($orgChartContainer.children('.orgchart').length) {
            data = $orgChartContainer.orgchart('getHierarchy');
        }

        $.ajax($this.data('path'), {
            type: 'post',
            data: {easy_org_chart: data}
        })
            .done(function(){
                showFlashMessage('notice', 'Organization structure has been successfully saved.').delay(1000).fadeOut();
            })
            .fail(function(){
                showFlashMessage('error', 'Server Error.')
            });

        $buttonSave.attr('disabled', true);
    });

    $('[data-org-chart-action="export"]').on('click', function(){
        var $orgChartContainerInstance = $(this).closest('.orgchart-wrapper').find('[data-role="easy-org-chart"]'),
            $orgChartInstance = $orgChartContainerInstance.find('.orgchart'),
            $body = $('body'),
            $orgChartClone,
            sourceChart,
            $indicator = $('#ajax-indicator');


        if ($orgChartInstance.length === 0)
            return false;

        $orgChartClone = $orgChartInstance.clone();

        $orgChartClone.css('transform', '');
        $orgChartClone.find('.gravatar').removeClass('gravatar');

        $body.append($orgChartClone);
        sourceChart = $orgChartClone.get(0);
        $indicator.show();

        html2canvas(sourceChart, {
            'width': sourceChart.clientWidth,
            'height': sourceChart.clientHeight,
            'onrendered': function(canvas){
                var isWebkit = 'WebkitAppearance' in document.documentElement.style,
                    isFF = !!window.sidebar,
                    isEdge = navigator.appName === 'Microsoft Internet Explorer' || (navigator.appName === "Netscape" && navigator.appVersion.indexOf('Edge') > -1);

                if ((!isWebkit && !isFF) || isEdge) {
                    window.navigator.msSaveBlob(canvas.msToBlob(), 'easy-org-chart.png');
                } else {
                    var $button = $body.children('.org-chart-download');
                    if($button.length === 0) {
                        $button = $('<a class="org-chart-download" download="easy-org-chart.png"></a>');
                        $body.append($button);
                    }

                    $button.attr('href', canvas.toDataURL()).get(0).click();
                }

                $orgChartClone.remove();
                $indicator.hide();
            }
        })
    });

    $('[data-org-chart-action="toggle"]').on('click', function(){
        var $this = $(this),
            $orgChartContainerInstance = $this.closest('.orgchart-wrapper').find('[data-role="easy-org-chart"]'),
            $orgChartInstance = $orgChartContainerInstance.find('.orgchart');

        if($orgChartInstance.length === 0) {
            return false;
        }

        if($this.data('status') === 'expanded') {
            var $node = $orgChartInstance.find('.node-root');
            $orgChartContainerInstance.orgchart('hideChildren', $node);

            $this.removeClass('icon-remove').addClass('icon-add').html($this.data('org-chart-expand'));

            $this.data('status', 'collapsed');
        } else {
            $this.removeClass('icon-add').addClass('icon-remove').html($this.data('org-chart-collapse'));

            $orgChartInstance.find('tr.hidden').removeClass('hidden');
            $orgChartInstance.find('.slide-up').removeClass('slide-up');

            $this.data('status', 'expanded');
        }

    });

    $('#easy-org-chart-form').on('ajax:success', function(event, data){
        $('#easy-org-chart-users').find('.org-chart-user-removable').remove();

        for(var i = 0; i < data.entities.length; i++) {
            createOrgChartUser(data.entities[i]);
        }
    });

    document.onkeydown = function(e) {
        if(e.shiftKey || e.ctrlKey) {
            var code = e.which || e.keyCode || e.charCode;

            if(code === 38) {
                orgChartZoom($orgChartContainer, 'in');
            }

            if(code === 40) {
                orgChartZoom($orgChartContainer, 'out');
            }
        }
    };

    EASY.schedule.late(function() {
        initializeOrgChart();
        loadUsers(true);
    });
})(jQuery);
