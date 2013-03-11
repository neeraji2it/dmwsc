// simple utility method
function getParameterByName(name) {
  name = name.replace(/[\[]/, "\\\[").replace(/[\]]/, "\\\]");
  var regexS = "[\\?&]" + name + "=([^&#]*)";
  var regex = new RegExp(regexS);
  var results = regex.exec(window.location.search);
  if(results == null) {
    return "";    
  } else {
    return decodeURIComponent(results[1].replace(/\+/g, " "));    
  }  
}

function format_hours_mins(time) {
  var mom_dur = moment.duration(Math.round(parseFloat(time)), 'minutes');
  //$("#receipt_time").text(moment.duration(Math.round(parseFloat(data.order_time)), 'minutes').asMinutes() + ' min');
  var str_days = (mom_dur.days()>0)?(mom_dur.days() + ' d'):"";
  var str_zero_hours = (str_days.length>0)?"0h ":"";
  var str_hours = (mom_dur.hours()>0)?(mom_dur.hours() + 'h '):str_zero_hours;
  var str_zero_minutes = (str_days.length>0 || str_hours.length>0)?"0 m":"< 1m";
  var str_mins = (mom_dur.minutes()>0)?(mom_dur.minutes() + 'm'):str_zero_minutes;
  return (str_days + str_hours + str_mins);
}

function format_txn_table(txndate, row, rindex) {
  var strLine = '<tr ' + 
    (( rindex % 2 > 0 ) ? 'class="even"' : '') + // since we haven't incremented yet
    '><td><div id="my_bill_day">' +
    ((txndate) ? moment(txndate).format("M/D") : 'N/A')
    + '</div></td>';
  
  // depends on type
  if (row.type === "order") {
    strLine += '<td><div id="my_bill_start">' +
      ( (row.order_start_time) ? moment(row.order_start_time).format("hh:mm a") : 'N/A' ) +
      '</div></td><td><div id="my_bill_end">' + 
      ( (row.order_end_time) ? moment(row.order_end_time).format("hh:mm a") : 'N/A' ) +
      '</div></td><td><div id="my_bill_duration">' +
      ( (row.order_time) ? (format_hours_mins(row.order_time)) : 'N/A' ) + 
      '</div></td><td class="currency"><div id="my_bill_charge">' +
      ( (row.order_total) ? ("$"+row.order_total) : 'Free' ) + '</div></td></tr>';
  }
  else if (row.type === "payment") {
    var paymentAmt = '';
    if( row.payment_amount > 0 ) {
      paymentAmt = "$("+row.payment_amount+")";      
    } else {
      paymentAmt = "ERROR";      
    }
    
    strLine += '<td><div id="my_bill_start">' +
      ( (row.payment_time) ? moment(row.payment_time).format("hh:mm a") : 'N/A' ) +
      '</div></td><td><div id="my_bill_payment">Paid (Thanks!)</div></td><td><div id="my_bill_payment_noop"></div></td><td class="currency"><div id="my_bill_payment">' + 
      paymentAmt + '</div></td></tr>';
  }
  
  return strLine;
}

//
// this is the layout manager for the page
// TODO: need to encode this in a better rules FSM
//
function layoutPage() {
  debug.debug("CORE: layoutPage : has table: " + has_table + " - checked_in: " + checked_in + " rsvp state: " + rsvpPending	);
  
  // handle some initial state setup
  if( checked_in ) {
    $('#check_in').hide();
    $('#check_out').show();
    $('cancel_rsvp').hide();
    $('#reserve').hide();
    $('#change_table').show();
    
    // RAF: BUG HACK: jquery seems to inline buttons with show() ???
    $('#check_out').css("display", "block");
    $('#change_table').css("display", "block");
    $('#cancel_rsvp').css("display", "none");
    $('#check_in').css("display", "none");
    $('#reserve').css("display", "none");
  }
  else {
    if (rsvpPending === 'pending') {
      $('cancel_rsvp').show();
      $('#check_out').hide();
      $('#check_in').hide();
      $('#change_table').hide();
      $('#reserve').hide();
      
      // RAF: BUG HACK: jquery seems to inline buttons when show() ???
      $('#cancel_rsvp').css("display", "block");
      $('#check_out').css("display", "none");
      $('#change_table').css("display", "none");
      $('#check_in').css("display", "none");
      $('#reserve').css("display", "none");
    } else {
      $('#check_out').hide();
      $('#check_in').show();
      $('cancel_rsvp').hide();
      // I can't be checked out and have a table!
      $('#change_table').hide();
      $('#reserve').show();
      
      // RAF: BUG HACK: jquery seems to inline buttons when show() ???
      $('#check_out').css("display", "none");
      $('#change_table').css("display", "none");
      $('#cancel_rsvp').css("display", "none");
      $('#check_in').css("display", "block");
      $('#reserve').css("display", "block");
    }
  }
  // jqM needs a kick in the pants to get styles:
  $('#check_in_div').trigger("create");
  $('html, body').animate({
		            scrollTop: $('#index_out').offset().top
	                  });
}

var doneWithBillProcessing = false;

function updateBillDisplay(event, data) {
  debug.debug("CORE: update bill display called: event: " + event);// + JSON.stringify(data));
  if( data )
  {
    if( event === "my_bill" && doneWithBillProcessing )
      return; // we are good already - no new data to process!
    
    if( event === "my_bill" )
      showLoadingPage(true);
    
    // remove current content
    $('#billDivAccordion').empty();
    
    try {
      var currentMonth = new Date().getMonth(); // already 0 based
      if( data["user_balance"] )
      {
	$('#my_bill_balance').text(data["user_balance"]);
      }
      
      var counts = [12];
      
      // build table headers for current and other months
      // add table, then add row
      var m = currentMonth;
      while( m != currentMonth+1 )
      {
	counts[m] = 0;
	var tblheader = null;
	var table = null;
	var topdiv = null;
	if( m === currentMonth )
	{
	  topdiv = $('<div data-role="collapsible" data-theme="c" data-content-theme="d" data-mini="true" data-collapsed="false"  data-icon="arrow-u" data-iconpos="right" />');
	  tblheader = $('<h3>This Month</h3>');
	  table = $('<table id="currMonthTable"/>');
	}
	else
	{
	  topdiv = $('<div class="billTableDiv" id="billDiv_' + m + '" data-role="collapsible" data-theme="c" data-content-theme="d" data-mini="true" data-icon="arrow-d" data-iconpos="right" style="display:none" />');
	  tblheader = $('<h3>'+ moment().month(m+1).format('MMM') +'</h3>' );// month name - MMM
	  table = $('<table id="billTable_' + m + '"/>');
	}
	topdiv.append(tblheader);
	var tbody = $('<tbody/>');
	tbody.append('<tr><th>Date</th><th>In</th><th>Out</th><th>Time</th><th class="currency">Charges</th></tr>');
	table.append(tbody);
	topdiv.append(table);

	// append data
	debug.debug( "CORE: updateBillDisplay append table " + m );
	$('#billDivAccordion').append(topdiv); // should append the current month first
	
	var next = m-1; // rotate in reverse
	if( next < 0 )
	  m = 12 + next;
	else
	  m = next;
      }
      
      for( i = 0; i < data.orders.length; i++ )
      {
	// TODO: check currency type
	// TODO: check rate units
	// TODO: RAF: HACK: consolidate all this row as a string nonsense
	var txndate = null;
	if( "type" in data.orders[i] && data.orders[i].type === 'order')
	{
	  txndate = new Date(Date.parse(data.orders[i].order_end_time));
	  debug.info("CORE: updateBillDisplay got order billdate: " + txndate.toString() );
	  
	}
	else if( "type" in data.orders[i] && data.orders[i].type === 'payment')
	{
	  txndate = new Date(Date.parse(data.orders[i].payment_time));
	  debug.info("CORE: updateBillDisplay got payment payment_time: " + txndate.toString() );
	}
	
	var row = data.orders[i];
	var mIndex = txndate.getMonth()-1;
	counts[mIndex]++;
	if( txndate.getMonth() === currentMonth )
	{
	  // RAF: TODO: HACK: use template engine
	  debug.debug("CORE: updateBillDisplay got bill row for current month: " + currentMonth);
	  var strLine = format_txn_table(txndate, row, counts[mIndex]);
	  debug.debug("CORE: updateBillDisplay new CURRENT month row : " + strLine);
	  
	  $('#currMonthTable > tbody:last').append(strLine);
	}
	else if( !isNaN(txndate.getMonth()) )// not current month, but valid
	{
	  debug.debug( "CORE: updateBillDisplay bill row month: " + txndate.getMonth() );
	  // add row to the table
	  var strLine = format_txn_table(txndate, row, counts[mIndex]);
	  debug.debug("CORE: updateBillDisplay new row : " + strLine);

	  $('#billTable_' + txndate.getMonth() + ' > tbody:last').append(strLine);
	} // is we is or is we aint the current month
      }// end for orders
      
      // jquery needs this for new dynamic content - refresh is for existing once you've done this
      $('#billDivAccordion').trigger( "create" );
      
      if( event === 'my_bill' )
	doneWithBillProcessing = true; // we processed the latest data so set the cache flag
      else
	doneWithBillProcessing = false; // reset the cache flag if this was from the server - new data
    } // end try
    catch (err) {
      debug.error("CORE: updateBillDisplay unexpected error fetching billing data: " + err);
      $('#my_bill_balance').text("UNAVAILABLE AT THE MOMENT");
      var strLine = '<tr><td>APOLOGIES...SERVER ERROR...HAL OPEN THE BAY DOOR...HAL?</td></tr>';
      $('#currMonthTable > tbody:last').append(strLine);
    }
    //if( event === "my_bill")
    showLoadingPage(false);
  } else {
    showLoadingPage(true);    
  }
}

function showLoadingPage(show) {
  debug.debug("CORE: showLoadingPage: " + show);
  if(show) {
    $.blockUI({
		showOverlay: false,
		css: { 
		  border: 'none', 
		  backgroundColor:'transparent',
		  left: '10%', right: '90%'
		},
		message: $('#loadingShiny') 
	      });
  } else {
    $.unblockUI();
  }
}

//
// TODO: support L10N - http://ajaxian.com/archives/l10n-js-js-localization-library
// http://norbertlindenberg.com/2012/06/ecmascript-internationalization-api/index.html
//	
/*
var strings = 
{
	"en-US": {
        "%reservationButton": "Make Reservation",
        "%selectTableButton": "Choose Your Table"
    },
    "en-GB: {
        "%reservationButton": "Pop In",
        "%selectTableButton": "Jolly Good Seat"
    }
};
*/

var table_context = "";
function setTableContext(str) { 
  debug.debug("CORE: setTableContext: " + str);

  table_context = str; 
  if( str === 'reserve' ) {
    $("#close_table_selector").text('Reserve Your Seat');     
  } else {
    $("#close_table_selector").text('Choose Your Seat');
  } 
}

// this mobileinit documented here http://jquerymobile.com/test/docs/api/globalconfig.html
$(document).bind("mobileinit", function(){
                   //apply overrides here
                   debug.debug("CORE: mobileinit called");
                 });

// our controller
var thecontroller = new wscController();
//RAF: no joy on iphone - thecontroller.initDb();
var rsvpPending = thecontroller.getRsvpState();
var checked_in = thecontroller.getCheckInStatus();
var has_table = thecontroller.getTableSelection();
debug.debug('CORE: instantiated controller: checked_in: ' + checked_in + ' has_table: ' + has_table );

var logged_in = thecontroller.getLoginInfo();
	
function update_user_profile(show) {
  debug.debug("CORE: update_user_profile show: " + show);
  
  if (show) {
    $('auth-displayname').html( logged_in.username );
    
    // RAF: TODO: if we don't get a profile pic from the login, ask them to upload!
    // user (like me) may not have profile pic in all services
    if (logged_in.profilePic) {
      $('#fbprofilepic').html('<img src="'+ logged_in.profilePic + '" />');
      $('#fbprofilepic').addClass("avatar");
    } else {
      $('#fbprofilepic').html('<div>Hi, '+ logged_in.username + '</div>');
      $('#fbprofilepic').addClass("avatar");
    }
  }
  else {
    $('auth-displayname').empty('');
    $('#fbprofilepic').empty();
  }
}

function clear_receipt_display() {
  $("#receipt_time").text("Loading...");
  $("#receipt_rate").text("Loading...");
  $("#receipt_order_total").text("Loading...");
  $("#receipt_account_balance").text("Loading...");
}

function display_welcome_notification() {
  $('#current_notifications').html('Welcome to The WorkShop!');
  $('#current_notifications').fadeOut(20000);
}
function display_checkout_notification() {
  $('#current_notifications').html('You have been checked out. Thank you!');
  $('#current_notifications').fadeOut(20000);
}
function display_payment_notification(amount) {
  $('#current_notifications').html('Your payment of $' + amount + ' has been received. You Rock! Thank you!');
  $('#current_notifications').fadeOut(20000);
}
function display_rsvp_notification() {
  var str = '';
  rsvpPending = thecontroller.getRsvpState();
  debug.debug("CORE: update_rsvp_notification state:" + rsvpPending);

  // RAF: TODO: use templating
  if( rsvpPending === 'pending' )
    str = 'Please wait for Staff Confirmation for ' + thecontroller.getTableSelection();
  else if( rsvpPending === 'cancel' )
  str = 'Your reservation has been canceled.';
  else if( rsvpPending === 'confirm' )
  str = 'Your reservation has been confirmed!';
  
  if( str )	
  {
    $('#current_notifications').html('<div class="status">' + str + '</div>');
    $('#current_notifications').fadeOut(20000);
  }
}

//
// when we're ready to go do a few things
// 1) layout the page and register the layout call back for future use
// 2) register the login state callbacks and do an initial check for logged in state and get setup if we are
// 3) register a few misc callbacks, e.g. QR code, data binding
// 4) HACK: then we have the whole bloody event processing for all pages, button clicks, etc. This should be moved
//    into some lightweight MVC framework (Angular, Meteor, etc)
//
$(function() {
    debug.debug("CORE: document ready: begin ready handler");
    // CRAP: this doesn't work...selector IS correct...blowie! $('#payment_popup > a.ui-dialog.ui-header.ui-btn-icon-notext').remove();
    
    // TODO: can we prerender and cache? templating engine?
    update_user_profile(true);
    
    // Listen for any attempts to call changePage().
    //$(document).bind( "pagebeforechange", function( e, data ) {
    //	debug.debug('CORE: pagebeforechange handler: toPage:' + data.toPage + ' pageContainer: ' + JSON.stringify(data.pageContainer) );
    //});
    
    layoutPage();
    
    $('#index_out').bind( '__updatelayout', function(){
		            debug.debug("CORE: received updatelayout event");
		            layoutPage();
	                  });
    
    $(document).bind('data:init', function(event, e) {
		       debug.info("CORE: SHOULD NEVER GET THIS...data init event received: " + e.message);
		       if ($('#count').length == 1)
			 $('#count').html(e.message);
	             });
    //app:payment_notify
    $(document).bind('app:payment_notify',function( event, e ) {
	               
		       debug.info("CORE: order notify event: " + e.paymentid + " received for uid: " + e.userid + " orderid: " + e.orderid + " amount: " + e.amount );
		       
		       display_payment_notification(e.amount);
		       
	             } );
    
    // salesforce gave us a confirmation
    $(document).bind('app:order_notify',function( event, e ) {
	               
		       debug.info("CORE: order notify event: " + e.table_status + " received for uid: " + e.userid + " orderid: " + e.orderid + " table: " + e.table_name );
		       
		       // RAF: TODO: make this coded vs string compare
		       if (e.table_status === "Confirmed") {	
			 has_table = thecontroller.getTableSelection(); 
			 checked_in = thecontroller.getCheckInStatus(); // by policy Rich wants them to start paying
			 display_rsvp_notification();
			 clear_receipt_display();
			 debug.info("CORE: order CONFIRMED event: has table: " + has_table + " checked in: " + checked_in + ' rsvp pending:' + rsvpPending );
			 
			 layoutPage();
		       } else {
			 debug.info("CORE: order NOTIFY FAILED event: has table");
                       }

	             } );
    
    $(document).bind('app:table_status_updated', function( event, e) {
		       debug.info("CORE table_status_updated event received : " + e.status);
		       has_table = thecontroller.getTableSelection();
		       layoutPage();
		       //hide the page loader
		       showLoadingPage(false);
	             });
    
    $(document).bind('app:updatedQR', function(event) {
		       debug.debug("CORE app:updated QR event received");
		       // RAF: removed 09-27-2012
		       //$('#btn_close_qrcode').removeClass('ui-disabled');
		       //debug.info("CORE: enabled close button for QR page");
		       //$('btn_close_qrcode').trigger("create");
		       qrReady = true;
		       showLoadingPage(false);
	             });
    
    $("#btn_confirm_cancel_rsvp").live("click",
		                       function() {
				         var nowinner = new Date().getTime();
				         debug.debug('CORE: cancel_rsvp on click: ' + this.id + ' ' + nowinner);
				         
				         // TODO: without local storage this needs to be atomic
				         // RAF: look at DerbyJS
				         $(document).trigger('web:cancel_rsvp', {time:nowinner});
                                         
		                       }
	                              );
    
    // QR CODE PAGE
    $("#btn_close_qrcode").live("click",
		                function() {
				  var nowinner = new Date().getTime();
				  debug.debug('CORE: btn_close_qrcode on click: ' + this.id + ' ' + nowinner);
				  
				  showLoadingPage(true);
				               
				  // TODO: without local storage this needs to be atomic
				  // RAF: look at DerbyJS
				  $(document).trigger('web:check_in', {time:nowinner});
				  $('#current_notifications').html(''); // clear the notifications
		                }
                               );
    
    //
    // This occurs if an ajax post fails
    //
    $(document).bind('app:err_xhr', function( event, data ) {
		       checked_in = thecontroller.getCheckInStatus();
		       has_table = thecontroller.getTableSelection(); // Rich wants to assume a default table, before tell us - the "floor"
		       debug.error("CORE: err_xhr received: data: " + JSON.stringify(data) + "checked_in: " +  checked_in + " has_table: " + has_table);
		       
		       // hide loading page
		       showLoadingPage(false);
		       
		       // TODO: define friendly ERROR page
		       
		       return true;
		     }
	            );
    // This occurs after the server processes the check in
    //
    $(document).bind('app:updated_check_in_status', function( event, data ) {
		       rsvpPending = thecontroller.getRsvpState();
		       checked_in = thecontroller.getCheckInStatus();
		       has_table = thecontroller.getTableSelection(); // Rich wants to assume a default table, before tell us - the "floor"
		       debug.info("CORE: updated_check_in_status received: data: " + JSON.stringify(data) + "checked_in: " +  checked_in + " has_table: " + has_table);
                       
		       if( checked_in && data.status === 'success' )// clear the receipt display
		       {
			 clear_receipt_display();
			 
			 if("reserve" in data)
			   display_rsvp_notification();
			 else
			 {
			   display_welcome_notification();
			 }
		       }
		       
		       layoutPage();
		       // hide loading page
		       showLoadingPage(false);
		       
		       return true;
		     }
	            );
    
    $(document).bind('app:updated_cancel_rsvp_status', function( event, data ) {
		       checked_in = thecontroller.getCheckInStatus();
		       has_table = thecontroller.getTableSelection(); // Rich wants to assume a default table, before tell us - the "floor"
		       debug.info("CORE: updated_cancel_rsvp_status received: data: " + JSON.stringify(data) + "checked_in: " +  checked_in + " has_table: " + has_table);
                       
		       if( data.status === 'success' )// clear the receipt display
		       {
			 display_rsvp_notification();
			 layoutPage();
			 // hide loading page
			 showLoadingPage(false);
		       }
		       
		       return true;
		     }
	            );
    
    //
    // payment
    // NJS - this'll all get replaced w/ straight Stripe stuff all on the same server
    $('#payment_popup').bind( 'pageinit', function() {	
		                /*
		                 $( "#payment_popup iframe" )
                                 .attr( "width", 0 )
                                 .attr( "height", 0 );
		                 
		                 $( "#payment_popup iframe" ).contents().find( "#payment_form" )
			         .css( { "width" : 0, "height" : 0 } );
				 
		                 $( "#payment_popup" ).on({
			         popupbeforeposition: function() {
				 var size = scale( 480, 320, 0, 1 ),
				 w = size.width,
				 h = size.height;

				 $( "#payment_popup iframe" )
				 .attr( "width", w )
				 .attr( "height", h );
				 
				 $( "#payment_popup iframe" ).contents().find( "#payment_form" )
				 .css( { "width": w, "height" : h } );
			         },
			         popupafterclose: function() {
				 $( "#payment_popup iframe" )
				 .attr( "width", 0 )
				 .attr( "height", 0 );
				 
				 $( "#payment_popup iframe" ).contents().find( "#payment_form" )
				 .css( { "width": 0, "height" : 0 } );
			         }
		                 });
		                 */
		                var billData = thecontroller.getBillData();
		                var bal = billData["user_balance"].replace("$", "");
		                //var stramt = bal.strip('$');
		                $('#gateway_iframe').attr('src', 'http://damp-sierra-3582.herokuapp.com/stripe?cust_id=' + logged_in.userid + '&amount=' + bal);
		                $('#payment_popup').trigger("create");
	                      });
    $("#btn_close_paydlg").live("click",
		                function() {
			          // no need to check login status
			          var nowinner = new Date().getTime();
			          debug.debug('CORE: btn_close_paydlg on click: ' + this.id + ' ' + nowinner);
			          
			          // apply payment to SF 
			          // TODO: HACK: FIXME: billData["user_balance"]
			          var billData = thecontroller.getBillData();
			          var bal = billData["user_balance"].replace("$", "");
			          //var stramt = bal.strip('$');
			          $(document).trigger('web:new_payment', {time:new Date().getTime(),amount:bal,userid:logged_in.userid});
	                        });
    
    //
    // QR CODE
    //
    var qrReady = false;
    $('#qrcode_page').bind( 'pagebeforeshow', function(e, data) 
	                    {
                              
	                    });
    $('#qrcode_page').bind( 'pageinit', function() 
	                    {
		              var qrcodestr = thecontroller.getQrCodeStr();
                              
		              debug.info("CORE: qrcode_page pageinit qrReady: " + qrReady + ' qrcodestr: ' + qrcodestr);
		              if( qrReady  )
		              {
			        if( qrcodestr )
			        {
				  $("#qrimg").html(qrcodestr);
				  qrReady = false;
			        }
			        // TBD - $('#btn_close_qrcode').removeClass('ui-disabled');
			        // RAF: TODO: else nice error message or default QR code...		
		              }
		              else if( qrcodestr && $("#qrimg").find('img').length === 0 )
		              {
			        $("#qrimg").html(qrcodestr);
		              }
	                    });
    
    // My Bill Page - this 
    $('#my_bill').bind( 'pagebeforeshow', function(e, data) 
	                {
		          debug.info("CORE: my_bill pagebeforeshow...");
		          updateBillDisplay("my_bill",thecontroller.getBillData());
	                });
    // this will fire when the server sends new data
    $(document).bind('app:updateBillDisplay', updateBillDisplay);
    
    // CHECK OUT/RECEIPT PAGE
    // QR CODE PAGE
    $(document).bind('app:updateReceipt', function(event, data) {
		       debug.info("CORE: updateReceipt event received: order time: " + data.order_time + " order rate: " + data.order_rate + " order total: " + data.order_total + " user balance: " + data.user_balance );
		       if (data.order_time) {	
			 var str_time = format_hours_mins(data.order_time);
			 $("#receipt_time").text(str_time);
		       } else{
			 $("#receipt_time").text('N/A');                         
                       }

		       if (data.order_rate) {
			 $("#receipt_rate").text(Math.round(parseFloat(data.order_rate)*60));                         
                       } else {
			 $("#receipt_rate").text('2');                         
                       }
		       
		       if (data.order_total) {
			 $("#receipt_order_total").text('$'+data.order_total);                         
                       } else {
			 $("#receipt_order_total").text('Free');                         
                       }

		       if (data.user_balance) {
                         $("#receipt_account_balance").text(data.user_balance);
                       }
		     });
    
    $("#btn_close_recipt").live("click",
		                function() {
			          var nowinner = new Date().getTime();
			          debug.debug('CORE: btn_close_recipt on click: ' + this.id + ' ' + nowinner);			          
		                });
    
    $(document).bind('app:updated_check_out_status', 
		     function( event, data) {
		       debug.debug('CORE: app:updated_check_out_status received: ' + JSON.stringify(data) );
                       
		       // TODO: without local storage this needs to be atomic
		       // RAF: look at DerbyJS, Meteor, etc.
		       checked_in = thecontroller.getCheckInStatus();
		       has_table = thecontroller.getTableSelection();
		       
		       layoutPage();
		       showLoadingPage(false);
		       
		       // L10N FIXME:
		       display_checkout_notification();
                       
		       return true;
		     }
	            );
    $('#receipt').bind('pagebeforeload', function(e, data) {
		          debug.info("CORE: receipt pagebeforeload event received");
	                });
    $('#check_out').live("click", function() {
	                   // RAF: TODO: inject this into a base function...
		           if (!thecontroller.getLoginInfo()) {
			     $.mobile.changePage($('#login'), 'pop', false, true);
			     return false;
		           }
		           //cue the page loader
		           showLoadingPage(true);
		           $(document).trigger('web:check_out', {time:new Date().getTime()});
                           return true;
	                 });
        
    // TABLE SELECTION/RESERVE PAGE
    var currenttable = null;
    $("#close_table_selector").live("click",
		                    function() {
			              var nowinner = new Date().getTime();
			              debug.debug('CORE: close_table_selector on click: ' + this.id + ' ' + nowinner);
			              
			              // TODO: without local storage this needs to be atomic
			              // RAF: look at DerbyJS
			              if (currenttable) {
				        var strEvent = "web:table_selection";
				        debug.debug("CORE: table selection event: current table id: " + $(this).attr('id'));
				        // RAF: HACK: don't bind to the string name
				        if( table_context === 'reserve' ) {
					  strEvent += "_reserve";
					  debug.debug('CORE: table reserve was initiated');
				        }
				        debug.debug('CORE: about to send app table event: ' + strEvent);
				        $(document).trigger(strEvent, {
							      time:nowinner,
							      table_selection:currenttable.id
							    });
			              }
			              $('#current_notifications').html('');
			              //cue the page loader
			              showLoadingPage(true);
                                      
			              return true;
		                    }
	                           );

    // class="ui-btn-active ui-state-persist
    $('#index_out, #more').bind('__pagebeforeshow', function(event) {
		                  var myid = $('a.ui-btn-active').attr('id');
		                  $('.navitem').each( function( index ) {
			                                if ($(this).attr('id') !== myid) {
				                          $(this).removeClass('ui-btn-active');                                                          
                                                        }
				                        $(this).removeClass('ui-state-persist');
		                                      });
		                  debug.info('navbar item selected id: ' + myid);
		                  $('#'+myid).each(function() {
			                              $(this).addClass('ui-btn-active');
			                              $(this).addClass('ui-state-persist');
		                                    });
	                        });
    
    $('#tables').bind( 'pageshow', function(e, data) {
		         debug.info("CORE: table selection dialog pageshow");
		         // TODO: RAF: adjust the current table status style using realtime status from server (SF cometd)
		         
		         // clear current selections/disable submit until selection made
		         //$('#close_select_table').attr('disabled','disabled'); // this doesnt work on jQM
		         $('#close_select_table').addClass('ui-disabled');
		         
		         // DISABLE ME IF YOU WANT TO: highlight current table if this is a "swicheroo"
		         $('#table_container a').each(function(index) {
			                                debug.debug('clear table ' + index + ': ' + $(this).text());
			                                $(this).removeClass('selected');
		                                      });
	               });

    // pageinit is a jQuery mobile thing
    // http://jquerymobile.com/test/docs/api/events.html
    $('#tables').bind('pageinit', function(event) {
		        var now = new Date().getTime();
		        debug.info("tables page pageinit : " + now + ' ' + event);
		        // TODO: RAF: support multi-select
		        //if( !localStorage.tableSelections )
		        //	localStorage.tableSelections = new Array(); // blowie to you fanboys of [] - respect OOP dammit
			
		        // update current selection from map click
		        $('#table_container').on("click", 'a',
			                         function() {
				                   // RAF: TODO: inject this into a base function...
				                   var nowinner = new Date().getTime();
				                   debug.debug('on click: ' + this.id + ' ' + nowinner);
				                   
				                   // this handles toggle events
				                   var classList = $(this).attr('class').split(/\s+/);
				                   var foundit = false;
				                   for (var i = 0; i < classList.length; i++) {
				                     if (classList[i] === 'selected') {
						       $(this).removeClass('selected');
						       foundit = true;
				                     }
				                   }
				                   // this clears all others
				                   // TODO: RAF support multiselect if (!multiselect ) ...
				                   if (!foundit) {
					             // enable the button
					             $('#close_select_table').removeClass('ui-disabled');
					             
					             $(this).addClass('selected');
					             
					             currenttable = this;
					             $('#table_container a').each(function(index) {
						                                    if( this !== currenttable )
						                                    {
							                              debug.debug('clear table ' + index + ': ' + $(this).text());
							                              $(this).removeClass('selected');
						                                    }
					                                          });
				                   }
				                   return true;
			                         }
		                                ); // end table map click
	              }); // end table page init
    
  }); // end ready