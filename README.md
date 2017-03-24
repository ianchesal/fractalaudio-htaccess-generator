# Fractal Audio .htaccess Generator Script

We've had problems with users using Tor to mask their IPs and then harass users on the forum. This script generates a dynamic, top-level .htaccess file for the site that blocks all the Tor exit nodes that can access `forum.fractalaudio.com` on ports `80` and `443`. Because this list of IPs is dynamic, changing, this script is meant to be run as a cron job every so often on the forum server.

To test the script on your OS X machine:

   ./htaccess-generator.rb --path . --user $(whoami) --group staff

Once run, you should see `.htaccess` file on disk that has a long list of `Deny` IP addresses in it that were gathered from the Tor project's master exit node catalog.

It's fairly generic Ruby and should run just fine with Ruby 2.0 and beyond which is the system Ruby on the Linux instance that runs the forum.

## Authors

* Ian Chesal <ian.chesal@gmail.com>
