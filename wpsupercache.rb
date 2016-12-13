###################################################################################################
#
# wpsupercache-mruby
#
# Mruby script allowing the use of WP Super Cache with the h2o web server.
#
# wpsupercache-mruby is a fork of wfcache-mruby, which provided support for
# Wordfence's Falcon Cache. wfcache-mruby was based on the nginx configuration 
# for the Falcon Cache (https://www.wordfence.com/txt/nginxConf.txt)
# and also on Wordfence's .htaccess for the Falcon Cache
# (https://github.com/wp-plugins/wordfence/blob/master/lib/wfCache.php)
# The Falcon Cache was removed from Wordfence as of version 6.2.8 (published
# on 12 December 2016).
#
# The cache-hit headers were inspired by Maxime Jobin's Rocket-Nginx 
# (https://github.com/maximejobin/rocket-nginx)
#
# Author: Uwe Trenkner
# URL: https://github.com/utrenkner/wpsupercache-mruby
#
# License: BSD (2-Clause)
#
# Version 0.1
#
###################################################################################################

lambda do |env|
	
	#### START CONFIGRUATION ####
	# Absolute path to the supercache on the server
	cache_dir = "/path/to/wordpress/wp-content/cache/supercache/"
	
	# URL of supercache base
	cache_base = "https://www.example.com/wp-content/cache/supercache"
	
	# Should HTTPS be cached? OFF (0) by default
	cache_tls = 0
	
	# Set max-age header for static assets to this number of seconds or 0 (OFF)
	static_max_age = 31536000                               
	
	# Which files are considered "static"
	static_suffices = "css|js|svg|png|jpe?g|gif|ico|eot|otf|woff2?|ttf" 

    # For security: block addresses containing these strings
    # Default: block WP's main config file, 
    # and dot-files/directories (except .well-known used by letsencrypt)
    blockable_addresses = "wp\-config\.php|\/[\.](?!well\-known)(?=[a-zA-Z0-9_]+)"
	#### END CONFIGRUATION ####

	# Set max-age headers for static assets
	headers = {}
	if /\.(#{static_suffices})$/i.match(env["PATH_INFO"]) and #{static_max_age} > 0
		headers["cache-control"] = "max-age=#{static_max_age}"
	end
	
	# Do not apply caching code on cached files themeselves
	if /(wp\-content\/cache\/supercache)/ !~ env["PATH_INFO"]
		# Wordfence Cache ON by default
		cache_on = 1
		
		# Don't cache form submissions 
		if env["REQUEST_METHOD"] == "POST"
			cache_on = 0
			cache_hit_message = "NO HIT because POST request"
		end
		
		# Don't cache any queries
		if /(.+)/.match(env["QUERY_STRING"])
			cache_on = 0
			cache_hit_message = "NO HIT because non-empty query string"
		end
		
		# Only cache URL's ending in /
		if /([^\/]$)/.match(env["PATH_INFO"])
			cache_on = 0
			cache_hit_message = "NO HIT because URL not ending in /"
		end
		
		# Don't cache any cookies with this in their names e.g. users who are logged in
		if env["HTTP_COOKIE"]
			if /(comment_author|wp\-postpass|wordpress_logged_in|wptouch_switch_toggle|wpmp_switcher)/.match(env["HTTP_COOKIE"])
				cache_on = 0
				cache_hit_message = "NO HIT because Special cookies set"
			end
		end
		
		# Is SSL used ?
		if env["SERVER_PORT"] == "443" and #{cache_tls} == 1
			if cache_on == 1
				cache_https = "-https"
			end
		end
		if cache_on == 1
			if match =   env["PATH_INFO"].match(/^\/*(index.php\/)?(.*)\/$/)
				index, uri = match.captures
				server_name = /^([^\:]*)/.match(env["SERVER_NAME"])
				cache_file = "#{server_name}/#{uri}/index#{cache_https}.html"
				cache_hit_message = "NO HIT because no cached file #{cache_file}"
				if File.file?("#{cache_dir}/#{cache_file}")
					return [307, {"x-reproxy-url" => "#{cache_base}/#{cache_file}"}, []]
				end 
			end
		end
	else
	    # Apply suitable headers to cached files
	    headers["Vary"] = "Accept-Encoding, Cookie"
		cache_hit_message = "HIT cached file #{$2}"
	end    
	headers["cache-hit"] = "#{cache_hit_message}"
        if /.*(#{blockable_addresses}).*/ !~ env["PATH_INFO"]
		return [399, headers, []]
	end
	[403, {'content-type' => 'text/plain'}, ["access forbidden\n"]]
end
