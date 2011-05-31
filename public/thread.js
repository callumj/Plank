function get_latest_posts()
{
  $.getJSON("/thread/" + thread_key + ".json?since=" + recent_data, function(return_json) {
    
    posts = return_json.data.posts;
    posts.reverse();   
    $.each(posts, function(index, value) {
      post_div = $("<div class=\"post\"></div>");
      if ((index + 1) == posts.length)
      {
        $(".post").each(function(post_index, post_value) {
            post_value.style.cssText = "";
        });
        
        post_div.css("background-color", "#edf4f4");
        post_div.hide();
      }
      post_div.append("<p class=\"contents\">" + value.contents + "</p>");
      post_div.append("<p class=\"details\">" + value.user + " " + value.easy_date + "</p>");
      $("#posts").prepend(post_div);
      
      if ((index + 1) == posts.length)
      {
        post_div.fadeIn();
      }
      
      recent_data = value.created_at;
    });
    
    schedule_refresh();
  });
}

function schedule_refresh() {
  window.setTimeout(function() {
   get_latest_posts();
  }, 3000);
}

$(function() {
  schedule_refresh();
});