Arduino Library List
====================

This is the code repository that generates the [arduinolibraries.info] website.

It is a statically generated website.

The steps to generate the site are:

1. Download the ```library_index.json``` file from arduino.cc.
2. Convert the JSON file into indexes that make it easy to generate the site
3. Generate the HTML files for the homepage and each of the sections
4. Generate a sitemap listing all the files that were generated
5. Upload the files to the web server



## Development

The scripts that generate the website are written in [Ruby]. You may need to install a recent version of ruby of my computer before you can run the scripts.

First make sure you have [Bundler] installed:

    $ gem install bundler

Then install all the dependencies:

    $ bundle install

To build a copy of the website on your local machine run:

    $ rake build

This will download the required data, and generate all the HTML files.

You can then run a web-server locally on your machine to view the site:

    $ rake server

And then open the following URL in your browser: [http://localhost:3000/]

The files that define what the pages look like are in the `views` folder.


## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/njh/arduino-libraries. This project is intended to be a safe, welcoming space for collaboration, and contributors are expected to adhere to the [Contributor Covenant](http://contributor-covenant.org) code of conduct.


## License

The gem is available as open source under the terms of the [MIT License].



[arduinolibraries.info]:     https://arduinolibraries.info/
[MIT License]:               http://opensource.org/licenses/MIT
[Ruby]:                      http://ruby-lang.org/
[Bundler]:                   http://bundler.io/
[http://localhost:3000/]:    http://localhost:3000/
