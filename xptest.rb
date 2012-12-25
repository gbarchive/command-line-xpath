#!/usr/bin/env ruby
###	xptest.rb - a command line XPath tester script.
###		by Giuseppe Burtini <joe@truephp.com>
###	
###	Run xptest.rb -h for quick synopsis. XPTest allows you to
### 	quickly test XPath queries on a file (HTML/XML) or URL to
###	see what they return. This is useful when developing scrapers
###	or other tools. 

require 'optparse'
require 'rubygems'
require 'nokogiri'	# XML/XPath parsing
require 'open-uri'	# handles FTP/HTTP[S] URLs

DEFAULT_MODE = :file
DEFAULT_USER_AGENT = "Ruby/#{RUBY_VERSION}"
USER_AGENT_SHORTCUTS = {
	:ie 		=> "Mozilla/5.0 (Windows; U; MSIE 9.0; Windows NT 9.0; en-US)",
	:ff 		=> "Mozilla/5.0 (Windows NT 6.2; Win64; x64; rv:16.0.1) Gecko/20121011 Firefox/16.0.1",
	:chrome		=> "Mozilla/5.0 (Windows NT 6.2; WOW64) AppleWebKit/537.14 (KHTML, like Gecko) Chrome/24.0.1292.0 Safari/537.14",
	:ios		=> "Mozilla/5.0 (iPad; CPU OS 6_0 like Mac OS X) AppleWebKit/536.26 (KHTML, like Gecko) Version/6.0 Mobile/10A5355d Safari/8536.25",
	:android	=> "Mozilla/5.0 (Linux; U; Android 2.3.5; en-us; HTC Vision Build/GRI40) AppleWebKit/533.1 (KHTML, like Gecko) Version/4.0 Mobile Safari/533.1",
	:safari		=> "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_7_3) AppleWebKit/534.55.3 (KHTML, like Gecko) Version/5.1.3 Safari/534.53.10",
	:wget		=> "Wget/1.9.1",
	:googlebot	=> "Mozilla/5.0 (compatible; Googlebot/2.1; +http://www.google.com/bot.html)"
}

def printVerbose(string) 
	if ($options[:verbose] or $options[:extra_verbose]) then
		$stderr.puts string
	end
end

def printExtraVerbose(string)
	if ($options[:extra_verbose]) then
		$stderr.puts string
	end
end

def autodetectMode(fn) 
	if File.exists?(fn) then
		:file
	elsif fn =~ URI::regexp
		:url
	else
		DEFAULT_MODE
	end
end

def autodetectUserAgent(input) 
	symbol = input.downcase.to_sym
	printVerbose("Checking " + symbol.to_s + " for valid user agent shortcut.")
	if USER_AGENT_SHORTCUTS.key?(symbol) then
		printVerbose("Valid user agent shortcut, user agent is " + USER_AGENT_SHORTCUTS[symbol])
		USER_AGENT_SHORTCUTS[symbol]
	else
		printVerbose("Invalid user agent shortcut, using " + input + " as user agent.")
		input
	end
end

def getFile(fileName)
	File.read(fileName) if File.exists?(fileName)
end

def getURL(url)
	# TODO: add default protocol here.
	# TODO: add referrer support.

	result = ""	
	open(url, "User-Agent" => $options[:user_agent]) do |data|
		printVerbose("Read in " + data.base_uri.to_s + " (" + data.content_type.to_s + ").")
		result = data.read
	end
	printExtraVerbose(result)
	printVerbose("Read in from " + url)
	result
end

# int main() { 
$options = {}
opts = OptionParser.new do |opts|
	opts.banner = "Usage: xptest [-v] [-w] [file/url] [query]"
	
	$options[:verbose] = false;
	$options[:extra_verbose] = false;
	opts.on('-v', '--verbose', "Output more information.") do
		$options[:verbose] = true
	end
	opts.on('-w', '--extra-verbose', "Output even more information.") do
		$options[:extra_verbose] = true
	end

	$options[:parser] = :html
	opts.on('-x', '--xml', "Use the XML parser instead of HTML.") do
		$options[:parser] = :xml 
	end

	$options[:mode] = :autodetect
	opts.on('-f', '--file', "Override autodetection, force [file/url] to be treated as a file.") do
		$options[:mode] = :file
	end
	
	$options[:user_agent] = DEFAULT_USER_AGENT
	opts.on('-a', '--user-agent [agent]', "Set user agent. Valid shortcuts include {" + USER_AGENT_SHORTCUTS.keys.map { |key| key.to_s } .join(',') + "}") do |ua|
		$options[:user_agent] = autodetectUserAgent(ua)
	end
	
	opts.on('-u', '--url', "Override autodetection, force [file/url] to be treated as a URL.") do
		$options[:mode] = :url
	end

	opts.on_tail( '-h', '--help', 'Display this screen.' ) do
     		puts opts
   		Process.exit
	end
end
opts.parse!


# TODO: detect which order they were passed in more intelligently
#	to support user brainfarts... this is a convenience tool.
input = ARGV[0]
xpath_query = ARGV[1]

$options[:mode] = autodetectMode(input) if $options[:mode] == :autodetect

if (input.nil?) then
	abort "Error: Please specify an input file."
end
if (xpath_query.nil?) then
	abort "Error: Please specify a query."
end

printVerbose("Opening " + input + " for XPathing.")

case $options[:mode]
	when :file
		data = getFile(input)
	when :url
		data = getURL(input)
	else
		printVerbose("Error condition: :mode is unknown, value given was " + $options[:mode])
		abort "I'm not sure what to do, exiting. (:mode is invalid)"
end

if data.nil? or data.empty? then
	abort "Error: Specified " + $options[:mode].to_s + " had no content."
end

case $options[:parser] 
	# TODO: implement the reverse XPath stuff provided by Nokogiri::CSS, possibly.

	when :html
		doc = Nokogiri::HTML(data)
	when :xml
		doc = Nokogiri::XML(data)
	else
		abort "I'm not sure which parser to use."
end

results = doc.xpath(xpath_query)

puts results
puts "\n"
puts "Showing " + results.length.to_s + " results for \"" + xpath_query + "\"."
# } 

