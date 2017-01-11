"use strict";

var fuse = new Fuse([], {
    keys: ['key', 'name', 'sentence'],
    minMatchCharLength: 2,
    shouldSort: true,
    threshold: 0.2,
    tokenize: true
});

/* FIXME: provide feedback on AJAX progress/failure? */
$.getJSON( "/search-index.json", function( data ) {
    fuse.set(data);
});

$('#search-box').typeahead({
    minLength: 2,
    hint: false,
    highlight: true,
}, {
    name: "arduino-libraries",
    limit: 10,
    source: function(query, syncResults) {
        syncResults(fuse.search(query));
    },
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
