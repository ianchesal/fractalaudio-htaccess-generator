# Fractal Audio .htaccess Generator Script

We've had problems with users using Tor to mask their IPs and then harass users on the forum. This script generates a dynamic, top-level .htaccess file for the site that blocks all the Tor exit nodes that can access `forum.fractalaudio.com` on ports `80` and `443`. Because this list of IPs is dynamic, changing, this script is meant to be run as a cron job every so often on the forum server.

## Testing

To test the script on your OS X machine:


```
./htaccess-generator.rb --user $(whoami) --group staff
```

Once run, you should see `.htaccess` file on disk that has a long list of `Deny` IP addresses in it that were gathered from the Tor project's master exit node catalog.

## Production

To run the script on the forum server, setup a cronjob for the `xenforo` user that looks like this:

```
0 * * * *  /path/to/htaccess-generator.rb --user xenforo --group xenforo --path /var/xenforo/www
```

This will run the script every hour and regenerate the `/var/xenforo/www/.htaccess` file. The file is moved in to place in a single, atomic `rename()` so there's never a point in time where the site is running without a top-level `.htaccess` file.

It's fairly generic Ruby and should run just fine with Ruby 2.0 and beyond which is the system Ruby on the Linux instance that runs the forum.

# Authors

* Ian Chesal <ian.chesal@gmail.com>
