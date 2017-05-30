#!/usr/bin/env ruby

# ssqdb.rb
# Author: William Woodruff
# ------------------------
# A tiny static quote DB, inspired by QDB.
# ssqdb expects the following quote file format:
#  %
#  <person1> witty comment
#  <person2> witty response
#  %
#  <person3> less witty comment
#  %
#  (etc)
# ------------------------
# This code is licensed by William Woodruff under the MIT License.
# http://opensource.org/licenses/MIT

require "erb"
require "cgi"
require "json"

VERSION = 3

HEADER = <<~EOS
<html>
  <head>
    <meta charset="UTF-8">
    <title>ssqdb <%= " - quote \\#\#{index}" if defined? index %></title>
    <style type="text/css">
      body {
        background-color: #F6F6F6;
        font-family: monospace;
        color: #222;
        max-width: 50em;
        margin: auto;
        padding: 1em;
      }

      a {
        color: #555;
      }

      pre {
        overflow: auto;
        white-space: pre-wrap;
      }

      .quote-link {
        text-decoration: none;
      }

      .quote-header {
        padding-left: 0.5em;
        padding-top: 0.5em;
        color: #555;
      }

      .quote-text {
        padding: 0 .5em .5em .5em;
      }

      .quote {
        padding: 0;
        margin: 0;
      }

      .quote:nth-of-type(odd) {
        background-color: #e0e0e0;
        padding-bottom: 0.1em;
        margin-bottom: -0.5em;
      }
    </style>
    <script type="text/javascript">
      function makeUrl(count) {
        var num = Math.floor(Math.random() * count);
        window.location = "quote" + num + ".html";
      }

      function randomQuote() {
        var req = new XMLHttpRequest();
        req.onreadystatechange = function() {
          if (req.readyState == 4 && req.status == 200) {
            makeUrl(req.responseText);
          }
        }

        req.open("GET", "count", true);
        req.send(null);
      }
    </script>
  </head>
  <body>
    <a href="index.html">all</a> /
    <a href="#" id="random" onclick="randomQuote();">random</a> /
    <a href="about.html">about</a>
EOS

FOOTER = <<~EOS
  </body>
  </html>
EOS

QUOTE = <<~EOS
  <div class="quote">
  <h5 class="quote-header">
    quote #<%= index %>
    <a class="quote-link" href="quote<%= index %>.html">(&rarr;)</a>
  </h5>
  <pre class="quote-text">
  <%= quote %>
  </pre>
  </div>
EOS

INDEX_PAGE = <<~EOS
  #{HEADER}

  <% html_quotes.each_with_index do |quote, index| %>
    #{QUOTE}
  <% end %>

  #{FOOTER}
EOS

QUOTE_PAGE = <<~EOS
  #{HEADER}

  #{QUOTE}

  #{FOOTER}
EOS

ABOUT_PAGE = <<~EOS
  #{HEADER}

  <p>
    ssqdb is a tiny static quote DB, inspired by QDB and its siblings.
  </p>

  <p>
    usage: <code>$ ssqdb.rb /path/to/your/quotes.txt</code>
  </p>

  <p>
    "quotes.txt" should be formatted as follows:
    <pre>
      %
      &lt;person1&gt; witty comment
      &lt;person2&gt; witty response
      %
      &lt;person3&gt; less witty comment
      %
      (etc)
    </pre>
  </p>

  #{FOOTER}
EOS

def help
  puts <<~EOS
    Usage: #{$PROGRAM_NAME} <quote file> [output directory] [options]
    Options:
      --json      Generate JSON files in addition to HTML
      --help      Print this help message
      --version   Print version information
  EOS

  exit 0
end

def version
  puts "ssqdb version #{VERSION}."

  exit 0
end

opts = {
  json: !!ARGV.delete("--json"),
  help: !!ARGV.delete("--help"),
  version: !!ARGV.delete("--version"),
}

help if opts[:help]
version if opts[:version]

quotes_file = ARGV.shift || abort("I need a file to load quotes from.")
output_dir = ARGV.shift || __dir__
abort("That isn't a file.") unless File.file?(quotes_file)
abort("Output directory doesn't exist.") unless Dir.exist?(output_dir)

quotes_string = File.read(quotes_file)
quotes = quotes_string.split(/^%$/).map(&:strip).reject(&:empty?)

abort("This file doesn't look like a quote DB.") if quotes.empty?

html_quotes = quotes.map do |quote|
  CGI.escapeHTML(quote)
end

File.write(File.join(output_dir, "count"), quotes.size)
File.write(File.join(output_dir, "index.html"), ERB.new(INDEX_PAGE).result(binding))
File.write(File.join(output_dir, "about.html"), ERB.new(ABOUT_PAGE).result(binding))

html_quotes.each_with_index do |quote, index|
  html_file = File.join(output_dir, "quote#{index}.html")
  File.write(html_file, ERB.new(QUOTE_PAGE).result(binding))
end

if opts[:json]
  quotes.each_with_index do |quote, index|
    json_file = File.join(output_dir, "quote#{index}.json")
    blob = { count: index, quote: quote }
    File.write(json_file, blob.to_json)
  end
end
