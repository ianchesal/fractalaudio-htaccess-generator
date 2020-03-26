#!/usr/bin/env ruby
#
# See README.md for development, installation and use instructions!
#
require 'resolv'
require 'net/http'
require 'uri'
require 'optparse'
require 'etc'
require 'logger'
require 'fileutils'

# Template content written to top of .htaccess file
HTACCESS_TOP = <<-'htaccesstop'

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

  # This redirects everything to the SSL version of the site
  RewriteCond %{HTTPS} !=on
  RewriteCond %{REQUEST_URI} !^/[0-9]+\..+\.cpaneldcv$
  RewriteCond %{REQUEST_URI} !^/[A-F0-9]{32}\.txt(?:\ Comodo\ DCV)?$
  RewriteCond %{REQUEST_URI} !^/\.well-known/acme-challenge/[0-9a-zA-Z_-]+$
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

htaccesstop

# Template content written to bottom of .htaccess file
HTACCESS_BOT = <<-'htaccessbot'
htaccessbot

def open_url(url)
  Net::HTTP.get(URI.parse(url))
end

options = {
  path: '.',
  user: 'xenforo',
  group: 'xenforo',
  site: 'forum.fractalaudio.com',
  ports: %w(80 443),
  torurl: 'https://check.torproject.org/torbulkexitlist',
  debug: false
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

  opts.on('-s', '--site sitename', 'Site name') do |site|
    options[:site] = site
  end

  opts.on('-t', '--tor-url tor-url', 'Tor URL') do |torurl|
    options[:torurl] = torurl
  end

  opts.on('-d', '--debug', 'Debug messages') do |debug|
    options[:debug] = true
  end

  opts.on('-h', '--help', 'Displays Help') do
    puts opts
    exit
  end
end
parser.parse!

logger = Logger.new(STDOUT)
logger.level = Logger::INFO
logger.level = Logger::DEBUG if options[:debug]

IP = Resolv.getaddress(options[:site])
TMP_FILE = File.join(options[:path], '.htaccess.tmp')
REL_FILE = File.join(options[:path], '.htaccess')

logger.debug("Deleting #{TMP_FILE}") if File.exist?(TMP_FILE)
File.delete(TMP_FILE) if File.exist?(TMP_FILE)

logger.debug("Writing #{TMP_FILE}")
File.open("#{TMP_FILE}", 'w') do |htfile|
  htfile.write("# This file was automatically generated on #{Time.now()} by the\n")
  htfile.write("# #{File.expand_path(__FILE__)} script.\n")
  htfile.write("# Any edits made to this file will be automatically overwritten!\n")
  htfile.write(HTACCESS_TOP)
  htfile.write("<RequireAll>\n")
  htfile.write("\tRequire all granted\n")
  options[:ports].each do |port|
    url = "#{options[:torurl]}?ip=#{IP}&port=#{port}"
    logger.debug("Fetching contents from: #{url}")
    open_url(url).each_line do |line|
      htfile.write("\t" + line) if line.start_with?('#')
      next if line.start_with?('#')
      htfile.write("\tRequire not ip #{line}")
    end
  end
  htfile.write("</RequireAll>\n")
  htfile.write("\n")
  htfile.write(HTACCESS_BOT)
end

logger.debug("Done writing #{TMP_FILE}")
FileUtils.chown(options[:user], options[:group], TMP_FILE)
File.chmod(0644, TMP_FILE)
logger.debug("Renaming #{TMP_FILE} -> #{REL_FILE}")
File.rename(TMP_FILE, REL_FILE)

logger.info("New #{REL_FILE} written at #{Time.now()}")
exit(0)
