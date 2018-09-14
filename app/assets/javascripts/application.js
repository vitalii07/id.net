// This is a manifest file that'll be compiled into including all the files listed below.
// Add new JavaScript/Coffee code in separate files in this directory and they'll automatically
// be included in the compiled file accessible from http://example.com/assets/application.js
// It's not advisable to add code directly here, but if you do, it'll appear at the bottom of the
// the compiled file.
//
//= require jquery
//= require jquery_ujs
//= require jquery-ui
//= require foundation
//= require underscore-min
//= require backbone-min
//= require_tree ./templates
//= require jquery.cookie.js
//= require swfobj
//= require swfobject
//= require main
//= require search
//= require feeds
//= require dropdown
//= require tooltip_bubble
//= require applications
//= require certifications
//= require documents
//= require jquery.fancybox
//= require jquery.fancybox-buttons
//= require validation
//= require notifications
//= require confirmations
//= require identities
//= require identities_menu
//= require chosen.jquery
//= require helpers/chosen
//= require helpers/file
//= require email_confirmation_reminder
//= require i18n
//= require i18n/translations
//= require flexmenu.min
//= require scroll_top
//= require ga
//= require perfect-scrollbar-0.4.8.with-mousewheel.min
//= require cookie_policy_accept
//= require mailcheck.min

// Backbone initialization
Models = {};
Views = {};

// run javascript only on specific pages
$(function() {

  var $email_hint = $('#email_hint');
  var $login_email = $('#login_email'); // index page
  if ($login_email.length < 1) {
    $login_email = $('#account_email'); // reg page
  }
  if ($login_email.length < 1) {
    $login_email = $('#meta_email'); // widget
  }

  $login_email.on('blur', function() {
    $(this).mailcheck({
        suggested: function(element, suggestion) {
          if (!$email_hint.html()) {
            var suggestion =
              I18n.translate('frontend_js.email.hint') + ": <a href='#'><span class='suggestion'><span class='address'>"
              + suggestion.address + "</span>"
              + "@<span class='domain'>" + suggestion.domain + "</span></a></span>?";
            $email_hint.html(suggestion).fadeIn(150);
          } else {
            // Subsequent errors
            $(".address").html(suggestion.address);
            $(".domain").html(suggestion.domain);
          }
        },
        empty: function(element) {
          $email_hint.html('').fadeIn(150);
        }
    })
  });

  $email_hint.on('click', '.suggestion', function() {
    // On click, fill in the field with the suggestion and remove the hint
    $login_email.val($(".suggestion").text());
    $email_hint.fadeOut(200, function() {
      $(this).empty();
    });
    return false;
  });

  var page = $("body").data("page");
  if(typeof window[page] == 'function')
    try{
      window[page]();
    }catch(e){
      var tmpFunc = window[page];
      tmpFunc();
    }

  // another implementation, better for namespaces & underscored names
  var controller = $("body").data("controller");
  var action = $("body").data("action");
  if(typeof window[controller] == "object" && typeof window[controller][action] == "function")
    window[controller][action]();

  // flexmenu for identities
  $('ul.menu.flex').flexMenu();

  /* ===== header dropdown menu ===== */

  $(".top-nav-dropdown-menu .dropdown").hover(function() {
    $(this).parent().addClass("hover");
  }, function() {
    $(this).parent().removeClass("hover");
  });

  // Perfect scroll for drive folder-tree
  $('.folder-tree').perfectScrollbar({
    suppressScrollY: true
  });

  $(".folder-tree .folder-tree-show").on('click', function(){
    $(".folder-tree").perfectScrollbar('update');
  })

  $("#logout").click(function(){
    logout();
  });

  /* ==================================== */
  expressInstallUrl = $('#swf-object').data('express-install-url');
  swfUrl = $('#swf-object').data('swf-url');

  var saveFlashCookie = function(e){
    if (!e.success){
      return;
    }
    var self = this;
    flashInterval = null;
    var tryCount = 0;
    var saveCookie = function(){
      var swf = e.ref;
      self.flashCookie = e.ref;
        try {
          var data =  {};
          data.sessionCookie = $('meta[name="_flC"]').attr('content');
          swf.setUserObject(JSON.stringify(data));
          clearInterval(flashInterval);
        }
        catch (error) {
          // fail and retry
          // console.log(error);
          tryCount++;
          if(tryCount >= 40){
            clearInterval(flashInterval);
          }
        }
    };
    flashInterval = setInterval(saveCookie, 500);
  };

  logout = function(){
    if(this.flashCookie){
      try {
        this.flashCookie.destroy();
      }catch (e){
        // flash not installed or enabled
      }
    }
  };
  swfobject.embedSWF(swfUrl, 'swf-object', '1', '1', '11', expressInstallUrl, {}, {allowScriptAccess: 'always'}, {style: 'width:0px;height:0px;display:block;'}, saveFlashCookie);
});
