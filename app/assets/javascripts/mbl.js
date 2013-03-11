console.log("mbl.js is in assets and being served!");

$(function() {
// object for storing state for usage later - use cautiously as storing and manipulation
// too much state will quickly get messy
var state = {};
state['seatReservation'] = null;

var layoutPages = function(state, seat, hailStatus) {
  // layout the home page
  $("div#index_out div#states div").hide();
  $("div#home_paying_indicator").hide();

  if (state === "inAndSeated") {
    $("div#home_paying_indicator").show();

    $("div#index_out div#stateInAndSeated span#seat_number").html(seat);
    $("div#index_out div#stateInAndSeated").show();
  } else if (state === "inAndRoaming") {
    $("div#home_paying_indicator").show();

    $("div#index_out div#stateInAndRoaming").show();
  } else if (state === "seatRequested") {
    // request made but not confirmed by staff yet
    $("div#index_out div#stateSeatRequested").show();
  } else if (state === "seatReserved") {
    // request made and also confirmed by staff
    $("div#home_paying_indicator").show(); // should only show if actually reserved

    $("div#index_out div#stateSeatReserved").show();
  } else if (state === "out") {
    // only valid state where not being charged
    $("div#index_out div#stateOut").show();
  } else {
    console.log("unknown state!");
  }

  // layout the order page
  $("a#hailStaff").hide();
  $("a#cancelHail").hide();

  if (hailStatus === "hailPending") {
    $("a#cancelHail").show();
  } else if ((typeof seat !== 'undefined') && (seat !== null)) {
    // has seat
    $("a#hailStaff").show();
    $("a#hailStaff").removeClass('ui-disabled');
  } else {
    $("a#hailStaff").show();
    $("a#hailStaff").addClass('ui-disabled');
  }
};

var getCurrentStatusAndUpdateUI = function() {
  // NJS - make sure only one of these is running at a time using a lock of some sort
  // if some accumulate while one is running be sure to run once more afterwards to
  // get the latest
  $.ajax({url: "time_sheet/current_status", dataType: 'json', type: 'get'})
    .done(function(data) {
            state['seatReservation'] = data.seatReservation;
            layoutPages(data.status, data.currentSeat, data.hailStatus);
          })
    .fail(function() { console.log("error"); })
    .always(function() { });
};
getCurrentStatusAndUpdateUI();

// check in
var checkIn = function() {
  $.post("time_sheet/check_in",
              function(data, textStatus, jqXHR) {
                // NJS - handle errors from AJAX call
              }
             );
};

// check out
var checkOut = function() {
  $.post("time_sheet/check_out",
              function(data, textStatus, jqXHR) {
                // NJS - handle errors from AJAX call

                // display the visit summary dialog
                $.ajax({url: "bill/visit_summary", dataType: 'html', type: 'get'})
                  .done(function(data) {
                          $("div#visit_summary div[data-role='content']")
                            .html(data)
                            .trigger('create');
                          $.mobile.changePage($('div#visit_summary'), 'pop', true, true);
                        })
                  .fail(function() { console.log("error"); })
                  .always(function() { console.log("complete"); });
              }
             );
};

var tellUsHere = function(event) {
  $.post("time_sheet/tell_us_here",
              function(data, textStatus, jqXHR) {
                // NJS - handle errors from AJAX call
              }
        );

};

// update seat
var updateSeat = function(event) {
  // prevent the form from submitting with the default action
  event.preventDefault();
  $('div#seats .submit_button').attr("disabled", "disabled");

  var form$ = $("form#update_seat_form");
  $.ajax({
           type: 'POST',
           url: form$.attr("action"),
           data: form$.serialize(),
           success: function(data, textStatus, jqXHR) {
             if (data.error) {
               notificationsManagement.showError(data.error);
             } else {
               $('div#seats').dialog('close');
             }
           }
         });
};

// reserve a seat
$('div#reserve_seat td div.seat').on("click", function(e) {
                                       var target$ = $(e.target);
                                       $('div#reserve_seat td div.seat').removeClass('selected');
                                       if (!target$.hasClass('taken')) {
                                         // can't select a taken seat
                                         target$.addClass('selected');
                                       }

                                     });


var reserveSeat = function() {
  var seatID = $('div#reserve_seat td div.seat.selected').data('seat-id');
  $.post("seat_reservations",
         {seat_id: seatID},
         function(data, textStatus, jqXHR) {
           state['seatReservation'] = data.reservation_id;
         }
        );
};

var cancelSeatReservation = function() {
  $.ajax({
           type: 'PUT',
           url: "seat_reservations/" + state['seatReservation'],
           success: function(data, textStatus, jqXHR) {
             // NJS - actually do something w/ the result
           }
         });
};

var updateTakenSeats = function() {
  $.ajax({
         type: 'GET',
         url: "seat_reservations/taken_seats",
         success: function(data, textStatus, jqXHR) {
           $('div#reserve_seat td div.seat').removeClass('taken');
           $.each(data, function(index, value) {
                    $('div#reserve_seat td div.seat[data-seat-id="' + value + '"]')
                      .addClass('taken');
                  });
         }
         });
};

var hailStaff = function() {
  $.ajax({
         type: 'POST',
         url: "hails",
         // NJS - don't assume success
         success: function(data, textStatus, jqXHR) {
           notificationsManagement.showNotice("Staff has been hailed");
         }
  });
};

var updateHail = function() {
  $.ajax({
         type: 'PUT',
         url: "hails",
         // NJS - don't assume success
         success: function(data, textStatus, jqXHR) {
           notificationsManagement.showNotice("Hail has been cancelled");
         }
  });
};

$('a#check_out_roaming').on("click", checkOut);
$('a#check_out_seated').on("click", checkOut);
$('a#check_out_reserved').on("click", checkOut);
$('a#check_in').on("click", checkIn);

$('form#update_seat_form').submit(function(event) {
                                    updateSeat(event);
                                    return false;
                                  });
$('a#reserve_selected_seat').on("click", reserveSeat);
$('a#btn_confirm_cancel_rsvp').on("click", cancelSeatReservation);
$('a#btn_tell_us_here').on("click", tellUsHere);

$('a#hailStaff').on("click", hailStaff);
$('a#cancelHail').on("click", updateHail);

// make the "checked in" indicator flash
window.setInterval(function() {
                     $("div.paying_indicator").fadeOut("slow");
                     $("div.paying_indicator").fadeIn("slow");
                   }, 3000);

// subscribe push notifications for 
// 1) notifications on when the update the UI
// 2) messages to display to the user
(function() {
  $.ajax({url: "time_sheet/my_channel_id", dataType: 'json', type: 'get'})
    .done(function(data) { 
            PUBNUB.subscribe({
                               // make this channel more secure
                               channel : "customer_ui_update_available_" + data.channel_id,
                               callback : function(message) {
                                 getCurrentStatusAndUpdateUI();
                               }
                             });
            PUBNUB.subscribe({
                               // make this channel more secure
                               channel : "customer_messages_" + data.channel_id,
                               callback : function(message) {
                                 getCurrentStatusAndUpdateUI();
                                 notificationsManagement.showNotice(message);
                               }
                             });
          })
    .fail(function() { console.log("error getting channel id"); })
    .always(function() { });       
})();

}); // on ready

/////////////////////////// pageinit /////////////////////////////

// fires when each pseudo-page is loaded
$(document).bind('pageinit', function() {
  console.log("document pageinit called");
}); // document page init

$('div#index_out').live('pageinit', function(event) {
console.log("pageinit called for index_out");
}); // index_out page init


$('div#seats').live('pageinit', function(event) {
console.log("pageinit called for our_seats");

$('div#seats').on('pageshow', function(event, ui) {
  // reset the form to no seat so the user has to select something
  $("select#seat_numbers").val("").selectmenu("refresh");

  // renable the submit button
  $('div#seats .submit_button').removeAttr("disabled");
});
}); // seats page init

$('div#reserve_seat').live('pageinit', function(event) {
console.log("pageinit called for reserve_seat");

// some prviate stuff for newSeatInit
var zoomBoxSize = 0;
var boxOffset = 0;
var boxMaxSize = 350; //Don't change connected with CSS seat positions
var seatStartPos = new Object();
var seatStartSize = new Object();
var fs = true;

$('div#reserve_seat').on('pageshow',appInit);
$(window).resize(redrawZoomArea);

function appInit() {
  $('#reserveTip').hide();
  $('#infoTip').hide();
  $('.seatSelected').removeClass('seatSelected');
  $('.normalArea').removeClass('activeZoom');
  $('.zoomedArea').not('#zoomedAreaHelp').css('visibility','hidden');
  $('#zoomedAreaHelp').width(0).height(0).addClass('active').css('left','0px').css('top','0px').css('z-index','1000').css('visibility','visible');
  $('.seatNew').addClass('seatFree');

  $('#zoomedAreaContainer').css('visibility','visible');
  if(fs){
    fs=false;
    $('.seatNew').each(function(){
                         var seatPos = $(this).position();
                         seatStartPos[$(this).attr('id')] = seatPos;
                         seatStartSize[$(this).attr('id')] = $(this).width();
                       });
  }
  redrawZoomArea();
  loadFreeSeats();
}

function loadFreeSeats() {
  $.ajax({
           type: 'GET',
           url: "seat_reservations/taken_seats",
           success: function(data, textStatus, jqXHR) {
             $.each(data, function(index, value) {
                      $('#seat'+value).removeClass('seatFree').addClass('seatTaken');
                    });
           }
         });
}

function redrawZoomArea() {
  zoomBoxSize = $('#zoomedAreaContainer').width()>boxMaxSize?boxMaxSize:$('#zoomedAreaContainer').width();
  boxOffset = $('#zoomedAreaContainer').width()>zoomBoxSize?($('#zoomedAreaContainer').width()-zoomBoxSize)/2:0;
  $('.zoomedArea.active').width(zoomBoxSize).height(zoomBoxSize).css('left',boxOffset+'px');
  $('#zoomedAreaContainer').height(zoomBoxSize);
  $('.zoomedArea.active .seatNew').each(function() {
                                          var zoomRatio = zoomBoxSize/boxMaxSize;
                                          var newX = seatStartPos[$(this).attr('id')].left*zoomRatio;
                                          var newY = seatStartPos[$(this).attr('id')].top*zoomRatio;
                                          var newSize = seatStartSize[$(this).attr('id')]*zoomRatio;
                                          $(this).css('top',newY+'px');
                                          $(this).css('left',newX+'px');
                                          $(this).width(newSize).height(newSize);
                                        });
  var offset = ($('#zoomedAreaContainer').width()-$('#zoomedAreaContainer').height())/2;
  $('#reserveTip').css('left',parseInt($('.seatSelected').css('left'))+$('.seatSelected').width()/2-$('#reserveTip').outerWidth( true )/2+offset+'px');
  $('#reserveTip').css('top',parseInt($('.seatSelected').css('top'))+$('.seatSelected').height()/2-$('#reserveTip').outerHeight( true )+'px');
}

$("div#reserve_seat").swiperight(function() {
  if ($('.normalArea.active').length == 0)
    $('.normalArea').first().click();
  else {
    if ($('.normalArea.active').next('.normalArea').length === 0)
       $('.normalArea').first().click();
    else
      $('.normalArea.active').next('.normalArea').click();
  }
});
$("div#reserve_seat").swipeleft(function() {
  if ($('.normalArea.active').length == 0)
    $('.normalArea').last().click();
  else {
    if ($('.normalArea.active').prev('.normalArea').length === 0)
      $('.normalArea').last().click();
    else
      $('.normalArea.active').prev('.normalArea').click();
  }
});

$('.normalArea').click(function(e) {
  var areaId = $(e.target).attr('id').substr(10);
  if($('.zoomedArea.active').attr('id').substr(10)==areaId) return false;

  $('#infoTip').hide();
  $('.normalArea').removeClass('activeZoom');
  $(this).addClass('activeZoom');

  $('.normalArea').removeClass('active');
  $(this).addClass('active');
  $('.normalArea').not(e.target).not('.active').mouseleave();

  $('.zoomedArea').not('#zoomedArea'+areaId).css('z-index',100);
  $('#zoomedArea'+areaId).css('z-index',1000);
  $('#reserveTip').hide();
  $('.seatNew').hide();
  $('.zoomedArea').not('#zoomedArea'+areaId).dequeue().removeClass('active').animate({
    width:0,
    height:0,
    top:$('#zoomedAreaContainer').height()/2,
    left:$('#zoomedAreaContainer').width()/2
  }, 500, function(){
    $(this).css('visibility','hidden');
  });
  $('#zoomedArea'+areaId).stop().dequeue().css('visibility','visible').css('left',boxOffset+zoomBoxSize/2+'px').css('top',zoomBoxSize/2+'px').addClass('active').animate({
    width:zoomBoxSize,
    height:zoomBoxSize,
    left:boxOffset,
    top:0
  }, 250, function(){
    redrawZoomArea();
    $('.seatNew').show();
    var submited = $(this).children('.seatSelected');
    if(submited.length > 0){
      $('#reserveTip').show();
      submited.hide();
    }
  });
  return true;
});

$('.zoomedArea').not('.seatNew').on('click', function(e) {
    $('#reserveTip').hide();
    $('.seatSelected').removeClass('seatSelected').show();
});

$('.seatNew').on('click', function(e) {
  e.stopPropagation();
  if($(e.target).hasClass('seatTaken') || $(e.target).hasClass('seatSelected')){
    $('#infoTip').show();
    var offset = ($('#zoomedAreaContainer').width()-$('#zoomedAreaContainer').height())/2;
    $('#infoTip').css('left',parseInt($(e.target).css('left'))+$(e.target).width()/2-$('#infoTip').outerWidth( true )/2+offset+'px');
    $('#infoTip').css('top',parseInt($(e.target).css('top'))+$(e.target).height()/2-$('#infoTip').outerHeight( true )+'px');
    setTimeout(function(){
      $('#infoTip').hide();
    },3000);
    return false;
  }
  $('#reserveTip').show();
  var offset = ($('#zoomedAreaContainer').width()-$('#zoomedAreaContainer').height())/2;
  $('#reserveTip').css('left',parseInt($(e.target).css('left'))+$(e.target).width()/2-$('#reserveTip').outerWidth( true )/2+offset+'px');
  $('#reserveTip').css('top',parseInt($(e.target).css('top'))+$(e.target).height()/2-$('#reserveTip').outerHeight( true )+'px');
  $('.seatSelected').removeClass('seatSelected').show();
  $(e.target).addClass('seatSelected').hide();

  return true;
});

$('#submitSeat').on('click', function(e) {
  if ($('.seatSelected').length == 0){
    alert('Choose your seat to submit');
    return false;
  }
  var seatId = $('.seatSelected').attr('id').substr(4);
  $.ajax({
    type: 'POST',
    url: "seat_reservations",
    data:{
      seat_id: seatId
    },
    success:function(data){
      $.mobile.changePage('#index_out');
    }
  });
  return true;
});

}); // reserve_seat page init

$('div#order').live('pageinit', function(event) {
console.log("pageinit called for order");
}); // order page init

$('div#my_bill').live('pageinit', function(event) {
console.log("pageinit called for my_bill");
// load the latest bill
$('div#my_bill').on('pageshow', function(event, ui) {
  $("div#my_bill div[data-role='content']").html('Loading ...');

  $.ajax({url: "bill/current_bill", dataType: 'html', type: 'get'})
    .done(function(data) {
            $("div#my_bill div[data-role='content']")
              .html(data)
              .trigger('create');
          })
    .fail(function() { console.log("error"); })
    .always(function() { console.log("complete"); });
});
}); // my_bill page init

$('div#community').live('pageinit', function(event) {
console.log("pageinit called for community");
}); // community page init

$('div#more').live('pageinit', function(event) {
console.log("pageinit called for more");
}); // more page init

$('div#our_people').live('pageinit', function(event) {
console.log("pageinit called for our_people");
}); // our_people page init