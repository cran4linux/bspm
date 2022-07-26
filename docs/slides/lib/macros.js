remark.macros.scale = function (percentage) {
  var url = this;
  return '<img src="' + url + '" style="width: ' + percentage + '" />';
};

document.addEventListener("DOMContentLoaded", function(event) {
  var video = document.getElementById("video");
  video.addEventListener("click", function(event) {
    if (video.paused == true)
         video.play();
    else video.pause();
  });
});
