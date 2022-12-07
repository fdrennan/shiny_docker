shinyjs.fullScreen = function(id) {
  var elem = document.getElementById(id);
  if (elem.requestFullscreen) {
    elem.requestFullscreen();
  }
};
