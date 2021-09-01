EASY.utils.setInfiniteScrollDefaults();

$('table.list.projects:first > tbody').infinitescroll({
    navSelector: '.pagination',
    nextSelector: '.pagination .next > a',
    itemSelector: 'table.list.projects:first > tbody > tr, .pagination .next > a'
}, function (data, opts) {
    var a = $(data.pop());
    if (a.is('a')) {
        opts.path = [a.attr('href')];
        a.remove();
    } else {
        data.push(a[0]);
        opts.state.isPaused = true;
        $(".infinite-scroll-load-next-page-trigger").parent().hide();
    }
    initEasyInlineEdit();
    LazyLoader.refresh();
});

$('.list.projects').easytreeview();

$(document).on('click', '.infinite-scroll-load-next-page-trigger', function (e) {
    $('table.list.projects:first > tbody').infinitescroll('retrieve', {});
    $(e.target).remove();
});
