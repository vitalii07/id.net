window.IDnet = window.IDnet || {};

var $, root;

root = typeof exports !== "undefined" && exports !== null ? exports : this;

root.redirect_opener = function(href) {
  try {
    opener.location = href;
  } catch (e) {
    document.location = href;
  }
  return false;
};

$ = jQuery;

jQuery(function() {
  $("select[data-refresh='true']").on('change', function() {
    var href, target, value;
    href = $(this).attr('data-href');
    target = $(this).attr('data-target');
    value = $(this).value;
    $(target).attr('action', href);
    return $(target).submit();
  });
  return $('.notice .close').live('click', function(e) {
    $(this).parent('.notice').slideToggle();
    return e.preventDefault();

  });
});


// Resizing .main-content for design purposes
$(document).ready(function() {
  var body_height = $("body").outerHeight();
  var header_height = $("#header").outerHeight();
  var submenu_height = $(".submenu").outerHeight();
  var root_footer_height = $("#root_footer").outerHeight();
  var footer_height = $("#footer").outerHeight();
  var footer_body_height = $("#footer .js-footer-body-height").outerHeight();

  if (footer_body_height > footer_height) {
    $('.js-footer-body-height').css('padding-bottom', 16 + 'px');
    var footer_height = $("#footer .js-footer-body-height").outerHeight();
    var root_footer_height = footer_height;
    $('#footer, #root_footer').css('height', footer_height + 'px');
    $('#root').css('margin-bottom', '-' + footer_height + 'px');
  }
  main_content_height = body_height - (header_height + footer_height + submenu_height + root_footer_height);
  $(".js-main-content-bg").css("min-height", main_content_height);
});

// Removing background for Feeds
$(document).ready(function() {
  if($('body').attr('data-page') == 'FeedsIndex') {
    $('body').addClass('feed-page');
  }
});

// Iovation callback. Autopopulation of iobb field no longer works as we now have two forms on the home page,
// so only first element with id=ioBB is populated.
window.io_bb_callback = function(bb) {
  $(".ioBB").val(bb);
  $("#ioBB").val(bb);           // compatibility with autopopulate for other pages
}
