$(function() {
  $(".left.pane").resizable({
    handles: "e, w",
    stop: function(event, ui) {
      setWidthInPercent(ui.element);
    }
  });
  $(".right.pane").resizable({
    handles: "e, w",
    resize: function(event, ui) {
      ui.position.left = 0;
    },
    stop: function(event, ui) {
      setWidthInPercent(ui.element);
    }
  });
  $(".top-content").resizable({
    handles: "s",
    stop: function(event, ui) {
      ui.element.width("");
    }
  });

  function setWidthInPercent(element) {
    var percentageWidth = (element.width() / element.parent().width()) * 100;
    element.width(percentageWidth + '%');
  }
