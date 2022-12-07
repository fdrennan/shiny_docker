$(document).keyup(function(event) {
    if ($("#app-subreddit-subreddit").is(":focus") && (event.key == "Enter")) {
        $("#app-subreddit-go").click();
    }
});

