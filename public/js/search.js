"use strict";

var search_index = new Bloodhound({
    identify: function (obj) {
        return obj.key;
    },
    datumTokenizer: function (datum) {
        return Bloodhound.tokenizers.whitespace(datum.name + " " + datum.sentence);
    },
    queryTokenizer: Bloodhound.tokenizers.whitespace,
    prefetch: {
        url: '/search-index.json',
        cache: false
    }
});

$('#search-box').typeahead({
    minLength: 2,
    hint: false,
    highlight: true,
}, {
    name: "arduino-libraries",
    source: search_index,
    limit: 10,
    display: function (library) {
        return library.name
    },
    templates: {
        suggestion: function (library) {
            return "<div>" + library.name + "</div>";
        },
        empty: function () {
            return "<p class='text-muted'>No results found.</p>";
        }
    }
});

$('#search-box').bind('typeahead:select', function (ev, suggestion) {
    window.location = "/libraries/" + suggestion.key;
});
