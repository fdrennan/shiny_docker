// TODO MAKE THIS DYNAMIC SO MODULE CAN BE MOVED
function getCookies(id){
  var res = Cookies.get();
  Shiny.setInputValue(id, res);
}

Shiny.addCustomMessageHandler('cookie-set', function(msg){
  Cookies.set(msg.name, msg.value);
  getCookies(msg.id);
})

Shiny.addCustomMessageHandler('cookie-get', function(msg){
  console.log('cookie-get');
  var cookies = getCookies(msg.id);
  console.log(cookies);
  cookies;
})

Shiny.addCustomMessageHandler('cookie-remove', function(msg){
  console.log('cookie-remove');
  Cookies.remove(msg.name);
  getCookies(msg.id);
})

$(document).on('shiny:connected', function(ev){
  getCookies('frontend-signin-cookie');
});
