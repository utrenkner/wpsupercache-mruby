# wpsupercache-mruby
Mruby script allowing the use of WP Super Cache with the h2o web server.

wpsupercache-mruby is a fork of wfcache-mruby, which provided support for Wordfence's Falcon Cache. wfcache-mruby was based on the nginx configuration for the Falcon Cache (https://www.wordfence.com/txt/nginxConf.txt) and also on Wordfence's .htaccess for the Falcon Cache (https://github.com/wp-plugins/wordfence/blob/master/lib/wfCache.php). The Falcon Cache was removed from Wordfence as of version 6.2.8 (published on 12 December 2016).

The cache-hit headers were inspired by Maxime Jobin's Rocket-Nginx (https://github.com/maximejobin/rocket-nginx)

#Usage
To use wpsupercache-mruby as an mruby-handler in h2o, add something like this to your path in h2o.conf
```
paths:
  "/":
    reproxy: ON
    mruby.handler-file: /path/to/wpsupercache.rb
    file.dir: "/path/to/wordpress-dir"   # serve static files if found
    redirect:                            # if not found, internally redirect to /index.php/<path>
      url: /index.php/
      internal: YES 
      status: 307
```
If you want to take advantage of WP Super Cache's pre-compressed (.gz) files, add ``file.send-compressed: ON`` to your h2o configuration. h2o then serves these .gz files directly.

# License
wpsupercache-mruby is licensed under the 2-clause BSD license. Please feel free to contribute patches.
