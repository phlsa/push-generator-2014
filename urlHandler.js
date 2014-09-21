var updateLocationBar = function( text ) {
    text = text.split( ' ' ).join( '_' );
    url = location.protocol + '//' + location.host + location.pathname + '?push=' + encodeURIComponent( text );
    rawUrl = location.protocol + '//' + location.host + location.pathname + '?push=' + text;
    window.history.replaceState( null, "push.generator: " + text, url );
    // $( 'a.fb-share' ).attr( 'href', 'https://www.facebook.com/sharer/sharer.php?u=' + url );
    // $( 'a.tw-share' ).attr( 'href', 'https://twitter.com/share?text=I created something with the push.generator!' );
}
var getURLVars = function() {
  var vars = {}
  var parts = window.location.href.replace( /[?&]+([^=&]+)=([^&]*)/gi, function( m,key,value ) {
      vars[key] = value
  });
  return vars
}
var getURLText = function() {
  if ( window.getURLVars()['push'] && window.getURLVars()['push'] != '' ) {
    var text = decodeURIComponent( window.getURLVars()['push'] );
    if (text == undefined) { text = "" };
    text = text.split( '_' ).join( ' ' );
    if (text) {
      return text;
    } else {
      return "";
    }
  } else {
    return ""
  }
}