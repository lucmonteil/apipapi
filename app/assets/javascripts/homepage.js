

var texts = ["Driver", "Meal", "Delivery"];
var count = 0;
function changeText() {
    $("#order_content").text(texts[count]);
    count < 3 ? count++ : count = 0;
}
setInterval(changeText, 1200);

$(document).ready(function() {
  $('#num')
    .keyboard({
      layout : 'num',
      restrictInput : true, // Prevent keys not in the displayed keyboard from being typed in
      preventPaste : true,  // prevent ctrl-v and right click
      autoAccept : true
    })
    .addTyping();
})
