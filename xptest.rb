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

def autodetectMode(args) 
	# TODO: actually autodetect things.
	:file
end

def getFile(fileName)
	File.read(fileName)
end

def getURL(url)
	# add default protocol here.
	result = ""	
	open(url) do |data|
		result = data.read
	end
	printExtraVerbose(result)
	printExtraVerbose("Read in from " + url)
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
	
	$options[:mode] = :autodetect
	opts.on('-f', '--file', "Override autodetection, force [file/url] to be treated as a file.") do
		$options[:mode] = :file
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

$options[:mode] = autodetectMode(ARGV) if $options[:mode] == :autodetect

# TODO: detect which order they were passed in more intelligently
#	to support user brainfarts... this is a convenience tool.
input = ARGV[0]
xpath_query = ARGV[1]

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

doc = Nokogiri::XML(data)
results = doc.xpath(xpath_query)

puts results
puts "\n"
puts "Showing " + results.length.to_s + " results for \"" + xpath_query + "\"."
# } 

