// namespacing pattern taken from here
// http://enterprisejquery.com/2010/10/how-good-c-habits-can-encourage-bad-javascript-habits-part-1/

console.log("notifications_management.js is in assets and being served!");

// NJS - expand this
(function(notificationsManagement, $, undefined ) {

   notificationsManagement.showNotice = function(s) {
     $("div#notificationsPopup")
       .html("<p>" + s + "</p>")
       .popup() // initalize popup plugin
       .popup("open"); // actually open it
   };

   notificationsManagement.showError = function(s) {
     $("div#notificationsPopup")
       .html("<p>" + s + "</p>")
       .popup() // initalize popup plugin
       .popup("open"); // actually open it
   };

}(window.notificationsManagement = window.flashManagement || {}, jQuery ));