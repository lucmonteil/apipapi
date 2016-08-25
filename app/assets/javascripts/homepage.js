var texts = ["Driver", "Meal", "Delivery"];
var count = 0;
function changeText() {
    $("#order_content").text(texts[count]);
    count < 3 ? count++ : count = 0;
}
setInterval(changeText, 1000);
