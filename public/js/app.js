function updateClock(thetime) {
  var now = new Date().getTime();
  var then = thetime;//new Date(thetime);
  var diff = now - then;
  
  // debug
  debug.info("updateClock diff: " + diff );
  
  var sec = (diff >= 60000) ? diff % 60000 : diff;
  diff = (diff/60000);
  var min = (diff >= 60) ? diff % 60 : diff;
  diff = (diff/60);
  var hour = diff;
  
  // debug
  debug.info("msec, min, hour: " + sec + " " + min + " " + hour );
  clockvalue = (hour==0) ? Math.floor(min).toString() + " minutes" 
    : Math.floor(hour).toString() + " hours " + Math.floor(min).toString() + " minutes";
  
  return clockvalue;
}

/////////// END UTILITY FNS ////////////////////

function wscController() {
  // CONSTANTS
  var PROFILE_IMG_FILE = 'profpic.img';
  var QRCODE_IMG_FILE = 'qrimgstr.bin';
  
  var parentWin = null;
  var myself = null;
  // TODO: persist this in a data store and synch with server
  var startTime = null;
  var stopTime = null;
  var timer = null; // RAF: Ti doesn't seem to like webview DOM intervals...so use native
  var isStatusWebViewLoaded = false;
  var statusWebViewTimer = null;
  var qrcodeWebViewTimer = null;
  var isQRcodeWebViewLoaded = false;
  
  // THESE NEED TO BE SYNCH'D TO THE SERVER EVENTUALLY
  // TODO: RAF: replace this with abstraction for xbrowser and client-cache/server separation, e.g. Angular.js/persistence.js
  var qrstring = (localStorage[QRCODE_IMG_FILE] === 'false' || !localStorage[QRCODE_IMG_FILE])?false:localStorage[QRCODE_IMG_FILE];//Ti.Filesystem.getFile(Ti.Filesystem.applicationDataDirectory, QRCODE_IMG_FILE);
  var tableSelection = (localStorage.tableSelection === 'false' || !localStorage.tableSelection)?false:localStorage.tableSelection;
  var checkedIn = (localStorage.checkedIn === 'false' || !localStorage.checkedIn)?false:localStorage.checkedIn;
  var billData = (localStorage.billData === 'false' || !localStorage.billData)?false:jQuery.parseJSON(localStorage.billData);
  var orderId = localStorage.orderid;
  var profilePicImageView = null;
  var profilePicImageStr = null;
  var rsvpstate = (localStorage.rsvpstate === 'false' || !localStorage.rsvpstate)?false:localStorage.rsvpstate;

  // before we get status changes we should try to query login status
  var userid = (localStorage.userid === 'false' || !localStorage.userid)?false:localStorage.userid;
  // NJS - hardcode to Newton
  // var userid = '655485651';
  var username = (localStorage.username === 'false' || !localStorage.username)?false:localStorage.username;
  // NJS login - probably don't want this stored but rather check it dynamically
  var loggedIn = (localStorage.loggedIn === 'false' || !localStorage.loggedIn)?false:localStorage.loggedIn;
  var profilePic = (localStorage.profilePic === 'false' || !localStorage.profilePic)?false:localStorage.profilePic;
  // RAF: TODO: use bootstrap protocol to initialize this
  var Facebook_appid = "471322226234863";//; sandbox = "402814483106946";//wscm-alpha //dev-"485730331456582";
  
  // private member fns
  function localDataUpdate() {
    debug.info('APP: localDataUpdate: loggedIn: ' + loggedIn);
    
    // asynchronously load the data we need
    // receipt
    // my bill
    send_get_bill();
  }
  
  function setRsvpState(state) { rsvpstate = state; }
  
  function setOrderInfo(orderinfo) {
    orderId = orderinfo;//responseDict.orderid;
    try {
      localStorage.orderid = orderId;
      debug.info('APP: persisted localStorage.orderid = ' + orderId);
    } catch (e) {
      if (e == QUOTA_EXCEEDED_ERR) {
	debug.error('APP: Unable to save orderid: QUOTA_EXCEEDED_ERR');
      }
    }
  }

  function setLocationStatus(state) {
    // RAF: TODO: abstract this with Angular/Meteor/Parse or similar
    localStorage.checkedIn = state;
    checkedIn = state;
  }
  function setTableSelection(currval) {
    try {
      localStorage.tableSelection = currval;
      tableSelection = currval;
    } catch (e) {
      if (e == QUOTA_EXCEEDED_ERR) {
	debug.error('APP: Unable to save tableSelection: QUOTA_EXCEEDED_ERR');
      }
    }
  }
  
  function setBillData(newData) {
    try {
      localStorage.billData = JSON.stringify(newData);
      billData = newData;
      $(document).trigger('app:updateBillDisplay', billData );
    } catch (e) {
      if (e == QUOTA_EXCEEDED_ERR) {
	debug.error('APP: Unable to save bill data: QUOTA_EXCEEDED_ERR');
      }
    }
  }
  
  // NJS login- replace this
  function _getLoginInfo() {
    if ( !username || username === 'false' || !userid || userid === 'false') {
      return false;
    }
    else {
      return { username: username, userid: userid, profilePic: profilePic };
    }
  }

  
  function postHttpRequest(data, processResponseFn) {
    var msg = JSON.stringify(data);
    debug.info('APP: postHttpRequest send post to salesforce: ' + msg);
    
    var jqxhr = $.ajax( {
		          type: "POST",
		          url: "https://cafe-lx36x6d6.dotcloud.com",
		          dataType: "json",
		          data: msg,
		          timeout: 15000
		        } )
      .fail(function(jqXHR, textStatus) {
	      debug.error( "APP: XHR Request failed: " + textStatus + " CHECK SF CREDENTIALS?" );
	      $(document).trigger('app:err_xhr', {status:textStatus,check_in_status:checkedIn,xhr:jqXHR});
	    })
      .always(function() { debug.info("APP: XHR POST always called"); })
      .success(function(data) {
		 debug.info("APP: XHR Request POST success data: " + JSON.stringify(data));
		 if( data )
		 {
		   processResponseFn(data);
		 }
	       })
      .done(function() {
	      debug.info('APP: XHR Request POST done');
	    });
  }
  
  function send_cancel_rsvp(eventData) {
    debug.info("APP: send_cancel_rsvp called with data: "+eventData);
    var data = {};
    var datadict = {};
    var now = new Date();
    
    debug.info("APP: send_cancel_rsvp called with table selection: "+JSON.stringify(getTableSelection()));
    datadict["table"] = getTableSelection();
    datadict["orderid"] = orderId;
    datadict["fbuid"] = userid;
    datadict["fbusername"] = username;
    data["cancel_preorder"] = now;
    data["data_dict"] = datadict;
    
    postHttpRequest(data, function(response){
		      debug.info("APP: send_cancel_rsvp::postHttpRequest "+response.result);
		      // jquery seems to do this for json automagically: var responseDict = jQuery.parseJSON(response);
		      if( response.result === 'success' )
		      {
			setOrderInfo( null );//responseDict.orderid;
			setLocationStatus(false);				
			debug.info("APP: orderid: " + orderId + " successfully CANCELLED from send_cancel_rsvp POST" );
			
			// RAF: HACKME: real time hackery (really this is blowie!)
			$(document).trigger('app:updated_cancel_rsvp_status', {status:response.result,orderid:orderId,check_in_status:checkedIn});
		      }
		      else
		      {
			debug.info("APP: FAILURE received from send_check_in POST: " + JSON.stringify(response) );
			// TODO: $(document).trigger('app:updated_cancel_rsvp_status', {status:response.result});
		      }
                      
		    });
  }
  
  function send_payment(eventData) {
    debug.info("APP: send_payment called with data: "+eventData);
    var data = {};
    var datadict = {};
    var now = new Date();
    
    datadict["fbuid"] = userid;
    datadict["fbusername"] = username;
    datadict["amount"] = eventData.amount;
    
    data["payment_success"] = now;
    data["data_dict"] = datadict;
    
    postHttpRequest(data, function(response){
		      debug.info("APP: send_payment::postHttpRequest "+response.result);
		      // jquery seems to do this for json automagically: var responseDict = jQuery.parseJSON(response);
		      if( response.result === 'success' )
		      {
			debug.info("APP: send_payment successfully paid" );
			send_get_bill();
			// RAF: HACKME: real time hackery (really this is blowie!)
			$(document).trigger('app:updated_payment_status', {status:response.result,paymentid:response.paymentid});
		      }
		      else
		      {
			debug.info("APP: FAILURE received from send_payment POST: " + JSON.stringify(response) );
			// TODO
		      }
                      
		    });
  }
  
  function send_check_in(reserve, reserveData) {
    debug.info("APP: send_check_in called with reserve: "+reserve);
    var data = {};
    var datadict = {};
    var now = new Date();
    datadict["checkin"] = now;
    if( reserve ) {
      setRsvpState('pending');
      datadict["preorder"] = 1;
      
      debug.info("APP: send_check_in called with reserve data: "+JSON.stringify(reserveData));
      if( reserveData && reserveData.hasOwnProperty('table_selection') )
      {
	datadict["table"] = reserveData.table_selection;
	setTableSelection(reserveData.table_selection);
      }
      else
	datadict["table"] = tableSelection;
    }
    else {
      setRsvpState('none');      
    }
    
    datadict["fbuid"] = userid;
    datadict["fbusername"] = username;
    data["check_in"] = now;
    data["data_dict"] = datadict;
    
    postHttpRequest(data, function(response) {
		      debug.info("APP: send_check_in::postHttpRequest "+response.result);
		      // jquery seems to do this for json automagically: var responseDict = jQuery.parseJSON(response);
		      if (response.result === 'success') {
			setOrderInfo( response.orderid );//responseDict.orderid;				
			debug.info("APP: orderid: " + orderId + " successfully received from send_check_in POST" );
			
			// RAF: HACKME: real time hackery (really this is blowie!)
			if (reserve) {
                          $(document).trigger('app:updated_check_in_status', {status:response.result,orderid:orderId,check_in_status:checkedIn,reserve:true});
                        } else {
			  setLocationStatus(true);
			  $(document).trigger('app:updated_check_in_status', {status:response.result,orderid:orderId,check_in_status:checkedIn});
			}
		      } else {
			setLocationStatus(false);
			debug.info("APP: FAILURE received from send_check_in POST: " + JSON.stringify(response) );
			$(document).trigger('app:updated_check_in_status', {status:response.result,check_in_status:checkedIn});
		      }                      
		    });
  }

  function send_update_table(currval) {
    debug.debug("APP: send_update_table currval: " + currval);
    var data = {};
    var datadict = {};
    var now = new Date();
    datadict["table"] = currval;
    datadict["fbuid"] = userid;
    datadict["fbusername"] = username;
    datadict["orderid"] = orderId;
    data["update_table"] = now;
    data["data_dict"] = datadict;
    
    postHttpRequest(data, function(response) {
		      debug.debug("APP: send_update_table response: " + response);
		      if( response.result === 'success' )
		      {
			setTableSelection(currval);
			$(document).trigger('app:table_status_updated', {status:response, table:currval});
		      }
		    });
  }

  function send_check_out() {
    var data = {};
    var datadict = {};
    var now = new Date();
    datadict["table"] = tableSelection;
    datadict["fbuid"] = userid;
    datadict["fbusername"] = username;
    
    if (orderId)
      datadict["orderid"] = orderId;
    
    data["check_out"] = now;
    data["data_dict"] = datadict;
    
    postHttpRequest(data, function(response){
		      
		      debug.info('CORE: send_check_out: account balance : ' + response.user_balance);
		      var receiptData = {};
		      if(response && response.orderdata )
		      {
			for( i = 0; i < response.orderdata.length; i++ )
			{
			  // TODO: check currency type
			  // TODO: check rate units
			  receiptData["order_time"] = response.orderdata[i].order_time;
			  receiptData["order_rate"] = response.orderdata[i].order_rate;
			  receiptData["order_total"] = response.orderdata[i].order_total;
			}
		      }
		      if (response.user_balance) {
			receiptData["user_balance"] = "$"+response.user_balance;
		      }
		      
		      // reset the order id
		      setOrderInfo( null );
		      // reset the check in status
		      setLocationStatus(false);
		      // reset the table status
		      setTableSelection(false);
		      
		      $(document).trigger('app:updateReceipt', receiptData);
		      $(document).trigger('app:updated_check_out_status', response);		
                      
		      // update the bill - give it a chance to run in the background
		      setTimeout(function() {
				   send_get_bill();
			         }, 5000);
		    });
  }
  
  function send_get_bill() {
    debug.debug('APP: send_get_bill: current table : ' + tableSelection);
    
    var data = {};
    var datadict = {};
    var now = new Date();
    datadict["table"] = tableSelection;
    datadict["fbuid"] = userid;
    datadict["fbusername"] = username;
    data["get_orders"] = now;
    data["data_dict"] = datadict;
    
    postHttpRequest(data, function(response){
		      debug.debug('APP: send_get_bill: XHR response : ' + JSON.stringify(response));
		      var billData = {};
		      if( response && response.result === 'success' )
		      {
			debug.debug('APP: send_get_bill: XHR SUCCESS response : ' + response.orderdata + " " + response.user_balance);
			if( response.orderdata )
			{
			  billData["orders"] = response.orderdata;
			}
			if( response.user_balance === 0)
			{
			  billData["user_balance"] = "$0.00";
			}
			else
			{
			  billData["user_balance"] = "$"+response.user_balance;
			}
			// need to save
			setBillData(billData);
		      }
		      else
		      {
			debug.debug('APP: send_get_bill: XHR FAILED response : ' + JSON.stringify(response));
		      }			
		    });
  }
  
  function updateTableSelection(e) {
    var currval = null;
    if (e && e.hasOwnProperty('table_selection')) {
      currval = e.table_selection;
      debug.info('APP: updateTableSelection - table select web view sent us: ' + currval);
      
      send_update_table(currval);
    } else {
      debug.error('APP: updateTableSelection - INVALID TABLE SELECTION');      
    }
  }
  
  function updateQRcode(datatoencode) {
    debug.debug('APP: encode data: ' + datatoencode);
    debug.debug('APP: qr img file exists? ' + qrstring);
    if (!datatoencode) {
      localStorage[QRCODE_IMG_FILE] = false;
      qrstring = false;
    } else {
      // create qr code and save to cache
      var qr = qrcode(10, 'L');//typeNumber || 4, errorCorrectLevel || 'M');
      
      // RAF: TODO: SECURITY: we could encrypt with a key, or encrypt a hash only
      // and use this too look up the user in a list of hashed FBIDs
      qr.addData(datatoencode);
      
      // FIRE AWAY!!!
      qr.make();
      localStorage[QRCODE_IMG_FILE] = qr.createImgTag(4);
      debug.debug('APP: qr img cached: ' + localStorage[QRCODE_IMG_FILE]);
      debug.debug('APP: qr img cache size: ' + localStorage[QRCODE_IMG_FILE].length + ' bytes');
      qrstring = localStorage[QRCODE_IMG_FILE];
    }
    debug.info('APP: updated cached qr code: ' + qrstring);
    
    // RAF: moved this to the core
    //$(e).html(imgtagstr);
    $(document).trigger('app:updatedQR', []);
  } 
  
  function hideProfilePic() {
    // TODO
  }
  
  //
  // order status notifications from Salesforce/ordering system
  // when the user submits an order, they should receive an alert
  // when the user's order is confirmed, they should receive an alert
  // when the user pays, they should receive an alert
  // TODO: others?
  //
  function stopSubscription() {
    // TODO: RAF: stop subscription
  }

  function startSubscription() {
    if (userid) {
      // LISTEN FOR MESSAGES
      PUBNUB.subscribe({
			 channel    : "wsc-notifications-"+userid,      // CONNECT TO THIS CHANNEL.
		         
			 restore    : false,              // STAY CONNECTED, EVEN WHEN BROWSER IS CLOSED
			 // OR WHEN PAGE CHANGES.
		         
			 callback   : function(message) { // RECEIVED A MESSAGE.
			   debug.info('APP: PUBNUB Message received type: ' + typeof(message));
			   if( typeof(message) === 'object' && "order_status" in message)
			   {
			     debug.info('APP: PUBNUB order status received...');
                             
			     //message = jQuery.parseJSON( message );
			     var oArray = message.order_status;
			     // TODO: if order_status == confirm
			     for(i=0; i<oArray.length; i++ )
			     {
			       var order = oArray[i];
			       debug.debug('APP: PUBNUB order status::table name: ' + order.table_name);
			       debug.debug('APP: PUBNUB order status::table status: ' + order.table_status);
			       debug.debug('APP: PUBNUB order status::table rate: ' + order.table_rate_per_min);
			       debug.debug('APP: PUBNUB order status::table time: ' + order.invoiced_time);
			       debug.debug('APP: PUBNUB order status::table amount: ' + order.invoiced_amount);
			       debug.debug('APP: PUBNUB order status::start time: ' + order.order_start_time);
			       debug.debug('APP: PUBNUB order status::end time: ' + order.order_end_time);
			       debug.debug('APP: PUBNUB order status::orderid: ' + order.orderid);
			       
			       setOrderInfo(order.orderid);
			       setTableSelection(order.table_name);
			       
			       if( orderId )
			       {
				 debug.info("APP: PUBNUB EVENT: orderid: " + orderId + " status: " + order.table_status + " table: " + order.table_name + " was received by notification from server" );
				 setLocationStatus(true);
				 setRsvpState('confirm');
				 // notify the web app
				 $(document).trigger('app:order_notify', {orderid:orderId,
									  userid:userid,
									  table_name:order.table_name,
									  table_status:order.table_status,
									  table_rate_per_min:order.table_rate_per_min,
									  invoiced_time:order.invoiced_time,
									  invoiced_amount:order.invoiced_amount,
									  order_start_time:order.order_start_time,
									  order_end_time:order.order_end_time,
									 });
			       }
			       else // uh oh
			       {
				 debug.error("APP: order notfiy event was received from server MISSING ORDERID" );
			       }
			     } // end for
			     // TODO else if order_status == staff_cancel
			     // TODO: also need to support elsewhere an event for USER cancel
			     // setRsvpState('cancel');
			   }
			   // {"payment_status":[{"type":"payment","orderid":"a00E0000004uVp7IAE","amount":"50.00"}]}
			   else if( typeof(message) === 'object' && "payment_status" in message)
			   {
			     debug.info('APP: PUBNUB payment status received...');
                             
			     var oArray = message.payment_status;
			     // TODO: if order_status == confirm
			     for(i=0; i<oArray.length; i++ )
			     {
			       var order = oArray[i];
			       if( order.type === 'payment' )
			       {
				 debug.debug('APP: PUBNUB payment amount: ' + order.amount);
				 debug.debug('APP: PUBNUB payment payment id: ' + order.paymentid);
				 
				 // need to get a fresh bill
				 send_get_bill();
				 
				 // notify the web app
				 $(document).trigger('app:payment_notify', {paymentid:order.paymentid,
									    userid:userid,
									    amount:order.amount});
			       }
			       else if( order.type === 'refund' )
			       {
				 debug.debug('APP: PUBNUB refund amount: ' + order.amount);
				 debug.debug('APP: PUBNUB refund payment id: ' + order.paymentid);
				 // need to get a fresh bill
				 send_get_bill();
				 
				 // notify the web app
				 $(document).trigger('app:refund_notify', {paymentid:paymentid,
									   userid:userid,
									   amount:order.amount});
			       }
			     } // end for
			     // TODO else if order_status == staff_cancel
			     // TODO: also need to support elsewhere an event for USER cancel
			     // setRsvpState('cancel');
			   }
			   else if( typeof(message) === 'string' )
			   {
			     debug.info('string message: ' + message);
			   }
			 },
		         
			 disconnect : function() {        // LOST CONNECTION.
			   debug.debug(
			     "APP: PUBNUB Connection Lost." +
			       "Will auto-reconnect when Online."
			   );
			 },
		         
			 reconnect  : function() {        // CONNECTION RESTORED.
			   debug.debug("APP: PUBNUB And we're Back!");
			 },
		         
			 connect    : function() {        // CONNECTION ESTABLISHED.
			   debug.debug("APP: PUBNUB about to send test message...");
			   PUBNUB.publish({             // SEND A MESSAGE.
					    channel : "wsc-notifications-"+userid,
					    message : "Loaded Notification Channel for user: " + userid
					  });
			   debug.debug("APP: PUBNUB test message sent!");
			 }
		       }); // end subscribe call
    } // endif userid
  } // end fn definition
  
  // web:index_in.body.onload
  
  // add an event listener for the status web view
  $(document).bind('app:statusWebViewLoaded', function(e) {
    		     isStatusWebViewLoaded = true;
    		     debug.debug('APP: status web view signalled load complete!');
                   });
  
  $(document).bind('web:cancel_rsvp', function(e,data) {
		     debug.info('APP: table reservation canceled by app '+ data.time);
		     if (loggedIn) {
		       send_cancel_rsvp(data);
		     } // TODO: else error message or force login
	           });
  
  // reserve (remotely checkin) table event
  $(document).bind('web:table_selection_reserve', function(e,data) {
		     debug.info('APP: table reservation received by app '+ data.time);
		     if (loggedIn) {
		       send_check_in(true,data);
		     } // TODO: else error message or force login
		   });
  // after check in, onsite, select a table
  $(document).bind('web:table_selection', function(e,data) {
		     debug.info('APP: table change received by app '+ e.time);
		     if (loggedIn) {
		       // DO NOT SEND CHECK IN, SINCE THIS WILL HAPPEN BEFORE
		       updateTableSelection(data);
		     }
	           }); 							
  
  // check in button was checked
  $(document).bind('web:check_in', function(e,data) {
		     debug.info('APP: check_in event received: '+ data.time);
		     if (loggedIn) {
		       send_check_in(false);
		     }
		   });						
  // send_check_out()
  $(document).bind('web:check_out', function(e,data) {
		     debug.info('APP: check_out event received: '+ data.time);
		     if (loggedIn) {
		       send_check_out();                       
                     }
		   });
  // popup is loaded and reas=dy for qrcode
  $(document).bind('web:updateQRcode', function(e,data) {
		     debug.info('APP: received web:updateQRcode');
		     if (loggedIn) {
		       updateQRcode(data);
                     }
		   }
		  );
  // pay web:new_payment
  $(document).bind('web:new_payment', function(e,data) {
		     debug.info('APP: received web:new_payment');
		     if (loggedIn) {
                       send_payment(data); 
                     }
		   }
	          );
  
  $(document).bind('web:refresh_my_bill', function(e,data) {
		     debug.info('APP: web:refresh_my_bill event');
		     if (loggedIn) {
		       send_get_bill();                       
                     }
		   });


  //	
  // controller public interface
  //


  // NJS login - call this on page load  
  this.setLoginInfo = function(name,id,url) {
    try {
      localStorage.userid = id; // RAF: HACK: we should probably not cache this here but reauth
      // with facebook - TBD
      localStorage.username = name;
      localStorage.profilePic = url;
      localStorage.loggedIn = true;
      
      userid = id;
      username = name;
      profilePic = url;
      loggedIn = true;
      
      debug.debug("APP: setLoginInfo " + userid + " logged in and persisted in localStorage");
    } catch (e) {
      if (e == QUOTA_EXCEEDED_ERR) {
	debug.error('APP: Unable to save userid and loggedIn state: QUOTA_EXCEEDED_ERR');
      }
    }
  };

  this.clearLoginInfo = function() {
    localStorage.userid = false; 		// with facebook - TBD
    localStorage.username = false;
    userid = false;
    username = false;
    profilePic = false;
    localStorage.loggedIn = false;
    loggedIn = false;
    
    debug.debug("APP: clearLoginInfo ");
  };

  this.getLoginInfo = function() {
    return _getLoginInfo();
  };
  
  this.getCheckInStatus = function () {
    // the 'this' keyword refers to the object instance
    return checkedIn;
  };
  
  this.getTableSelection = function () {
    // the 'this' keyword refers to the object instance
    return tableSelection;
  };
  
  this.getBillData = function () {
    // the 'this' keyword refers to the object instance
    return billData;
  };

  this.getQrCodeStr = function() { return qrstring; };

  this.getRsvpState = function() {
    debug.info('APP: getRsvpState called ');
    return rsvpstate;
  };
  
  // end public interface
  
  // TODO: where to put ctor logic??
  if (userid) {
    startSubscription();    
  }
}

