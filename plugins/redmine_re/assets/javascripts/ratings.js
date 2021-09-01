$(document).ready(function () {
    $('form.rating').change(function () {
        $('form.rating').submit();
    });
});

$(function () {
    var checkedId = $('form.rating > input:checked').attr('id');
    $('form.rating > label[for=' + checkedId + ']').prevAll().addBack().addClass('bright');
});

$(document).ready(function () {
    $('form.rating > label').hover(
        function () {
            $(this).prevAll().addBack().addClass('glow');
        }, function () {
            $(this).siblings().addBack().removeClass('glow');
        });

    $('form.rating > label').click(function () {
        $(this).siblings().removeClass("bright");
        $(this).prevAll().addBack().addClass("bright");
    });

    $('form.rating').change(function () {
        $('form.rating').submit();
    });
});