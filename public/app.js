"use strict";
/* cribbed from http://nullstyle.com/2007/06/02/caching-time_ago_in_words */
function seconds_ago(to, from) {
    return ((to  - from) / 1000);
}

function distance_of_time_in_words(to, from) {
    var minutes_ago = Math.floor(seconds_ago(to, from) / 60);

    if (minutes_ago <= 0) { return "less than a minute"; }
    if (minutes_ago == 1) { return "a minute"; }
    if (minutes_ago < 45) { return minutes_ago + " minutes"; }
    if (minutes_ago < 90) { return "1 hour"; }
    if (minutes_ago < 1440) { return Math.round(minutes_ago / 60) + " hours"; }
    if (minutes_ago < 2880) { return "1 day"; }
    if (minutes_ago < 43200) { return Math.round(minutes_ago / 1440) + " days"; }
    if (minutes_ago < 86400) { return "1 month"; }
    if (minutes_ago < 525960) { return Math.round(minutes_ago / 43200) + " months"; }
    if (minutes_ago < 1051920) { return "1 year"; }
    return "over " + Math.round(minutes_ago / 525960) + " years";
}

function time_ago_in_words(from) {
    return distance_of_time_in_words(new Date(), new Date(from));
}

function clearField(e) {
    if (e.cleared) { return; }
    e.cleared = true;
    e.value = '';
    e.style.color = '#333';
}
