#!/usr/bin/env ruby
require 'resolv'
require 'net/http'
require 'uri'
require 'optparse'

# Template content written to top of .htaccess file
HTACCESS_TOP = <<htaccesstop
ErrorDocument 401 default
ErrorDocument 403 default
ErrorDocument 404 default
ErrorDocument 405 default
ErrorDocument 406 default
ErrorDocument 500 default
ErrorDocument 501 default
ErrorDocument 503 default


<IfModule mod_rewrite.c>
	RewriteEngine On

	#	If you are having problems with the rewrite rules, remove the "#" from the
	#	line that begins "RewriteBase" below. You will also have to change the path
	#	of the rewrite to reflect the path to your XenForo installation.
	#RewriteBase /xenforo

	#	This line may be needed to enable WebDAV editing with PHP as a CGI.
	#RewriteRule .* - [E=HTTP_AUTHORIZATION:%{HTTP:Authorization}]

	# This redirects everything to the SSL version of the site
  RewriteCond %{HTTPS} !=on
	RewriteRule ^/?(.*) https://forum.fractalaudio.com/$1 [R=301,L]

	# This is for VBSEO URL rewriting. It keeps thread links from the old VB4
	# forum "alive" on the new Xenforo forum.
  RewriteCond %{REQUEST_URI} !^/[0-9]+\..+\.cpaneldcv$
  RewriteCond %{REQUEST_URI} !^/[A-F0-9]{32}\.txt(?:\ Comodo\ DCV)?$
  RewriteCond %{REQUEST_URI} !^/\.well-known/acme-challenge/[0-9a-zA-Z_-]+$
	RewriteRule [^/]+/([\d]+)-.+-([\d]+).html showthread.php?t=$1&page=$2 [NC,L]
  RewriteCond %{REQUEST_URI} !^/[0-9]+\..+\.cpaneldcv$
  RewriteCond %{REQUEST_URI} !^/[A-F0-9]{32}\.txt(?:\ Comodo\ DCV)?$
  RewriteCond %{REQUEST_URI} !^/\.well-known/acme-challenge/[0-9a-zA-Z_-]+$
	RewriteRule [^/]+/([\d]+)-.+.html showthread.php?t=$1 [NC,L]
  RewriteCond %{REQUEST_URI} !^/[0-9]+\..+\.cpaneldcv$
  RewriteCond %{REQUEST_URI} !^/[A-F0-9]{32}\.txt(?:\ Comodo\ DCV)?$
  RewriteCond %{REQUEST_URI} !^/\.well-known/acme-challenge/[0-9a-zA-Z_-]+$
	RewriteRule [^/]+/.*?/([\d]+)-.+.html showthread.php?t=$1 [NC,L]

	RewriteCond %{REQUEST_FILENAME} -f [OR]
	RewriteCond %{REQUEST_FILENAME} -l [OR]
	RewriteCond %{REQUEST_FILENAME} -d
  RewriteCond %{REQUEST_URI} !^/[0-9]+\..+\.cpaneldcv$
  RewriteCond %{REQUEST_URI} !^/[A-F0-9]{32}\.txt(?:\ Comodo\ DCV)?$
  RewriteCond %{REQUEST_URI} !^/\.well-known/acme-challenge/[0-9a-zA-Z_-]+$
	RewriteRule ^.*$ - [NC,L]
  RewriteCond %{REQUEST_URI} !^/[0-9]+\..+\.cpaneldcv$
  RewriteCond %{REQUEST_URI} !^/[A-F0-9]{32}\.txt(?:\ Comodo\ DCV)?$
  RewriteCond %{REQUEST_URI} !^/\.well-known/acme-challenge/[0-9a-zA-Z_-]+$
	RewriteRule ^(data/|js/|styles/|install/|favicon\.ico|crossdomain\.xml|robots\.txt) - [NC,L]
  RewriteCond %{REQUEST_URI} !^/[0-9]+\..+\.cpaneldcv$
  RewriteCond %{REQUEST_URI} !^/[A-F0-9]{32}\.txt(?:\ Comodo\ DCV)?$
  RewriteCond %{REQUEST_URI} !^/\.well-known/acme-challenge/[0-9a-zA-Z_-]+$
	RewriteRule ^.*$ index.php [NC,L]
</IfModule>

Order Deny,Allow
htaccesstop

# Template content written to bottom of .htaccess file
HTACCESS_BOT = <<htaccessbot

htaccessbot

IP = Resolv.getaddress('forum.fractalaudio.com')
PORTS = %w(80 443)
TOR_CHECK_URL = 'https://check.torproject.org/cgi-bin/TorBulkExitList.py'

def open_url(url)
  Net::HTTP.get(URI.parse(url))
end

options = {
  path: '/var/xenforo/public_html',
  user: 'xenforo',
  group: 'xenforo'
}

parser = OptionParser.new do |opts|
	opts.banner = "Usage: htaccess-generator.rb [options]"
	opts.on('-p', '--path path', 'Path') do |path|
		options[:path] = path;
	end

	opts.on('-u', '--user user', 'User') do |user|
		options[:user] = user;
	end

	opts.on('-g', '--group group', 'Group') do |group|
		options[:group] = group;
	end

	opts.on('-h', '--help', 'Displays Help') do
		puts opts
		exit
	end
end
parser.parse!

puts "Writing #{options[:path]}/.htaccess.tmp..."
File.open("#{options[:path]}/.htaccess.tmp", 'w') do |htfile|
  htfile.write(HTACCESS_TOP)
  PORTS.each do |port|
    url = "#{TOR_CHECK_URL}?ip=#{IP}&port=#{port}"
    puts "Fetching contents from: #{url}"
    open_url(url).each_line do |line|
      htfile.write(line) if line.start_with?('#')
      next if line.start_with?('#')
      htfile.write("Deny from #{line}")
    end
  end
  htfile.write(HTACCESS_BOT)
end

puts "Done writing .htaccess.tmp"
puts "Renaming #{options[:path]}/.htaccess.tmp -> #{options[:path]}/.htaccess"
system("mv #{options[:path]}/.htaccess.tmp #{options[:path]}/.htaccess")
system("chown #{options[:user]}:#{options[:group]} #{options[:path]}/.htaccess")

puts "Done"
exit(0)
