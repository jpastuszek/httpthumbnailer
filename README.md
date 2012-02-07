# httpthumbnailer

HTTP API server for image thumbnailing and format conversion.

It is using **ImageMagick** as the image processing library.

## Installing

You will need the following system packages installed: `imagemagick`, `libpng`, `pkg-config`, `make`.
Optionally you may want to install `fcgi` package and gem to be able to use it as **FastCGI** backend.

For Arch Linux you can use this commands:

    pacman -S imagemagick
    pacman -S libpng
    pacman -S pkg-config
    pacman -S make

Then you can install the gem as usual:

    gem install httpthumbnailer

## Usage

It can be started as a stand alone server or as FastCGI backend.

### Stand alone server

This mode is useful for testing.
By default **Mongrel** will be used as HTTP handling library (you can use --server option to specify different server that is supported by Sinatra).

To start it in that mode run:

    httpthumbnailer

By default it will be listening on **localhost** port **3100**.

### FastCGI

In this mode you can run many **httpthumbnailer** instances so that requests will be load balanced between them equally.
Since it is single threaded (some ImageMagick operations may be multithreaded) it will be able to max out only single CPU core.
Therefore it is recommended to run as many instances as there are CPU cores available.

Make sure you have FastCGI system library installed.

For Arch Linux you can use this command:

    pacman -S fcgi

And you have `fcgi` gem installed with:

    gem install fcgi

Here is an example **Lighttpd** configuration:

    $SERVER["socket"] == ":3100" {
        server.reject-expect-100-with-417 = "disable" 
    	fastcgi.debug = 1
    	fastcgi.server    = ( "/" =>
    		((
    			"socket" => "/var/run/lighttpd/httpthumbniler.sock",
    			"bin-path" => "/usr/bin/httpthumbnailer -s fastcgi --no-bind --no-logging",
    			"max-procs" => 2,
    			"check-local" => "disable",
    			"fix-root-scriptname" => "enable",
    		))
    	)
    }

The `"max-procs" => 2` controls the number of instances started.
In case that the `httpthumbnailer` process crashes (may happen since it is using native libraries) it will be restarted by Lighttpd.

### API

Basically it works like that:

1. PUT your image data to the server with URI describing thumbnail format (one or more)
2. the server will respond with **multi-part content** with parts containing data of your thumbnails in order with proper **Content-type** headers set

For example the URI may look like this: 

    /thumbnail/crop,16,16,PNG/crop,4,8,JPG/pad,16,32,JPEG

It will generate 3 thumbnails: 

1. 16x16 cropped PNG
2. 4x8 cropped JPEG
3. 16x32 colour padded JPEG

For detailed information about the API see [cucumber features](http://github.com/jpastuszek/httpthumbnailer/blob/master/features/httpthumbnailer.feature).

### API client

To make it easy to use this server there is [httpthumbnailer-client](http://github.com/jpastuszek/httpthumbnailer-client) gem provided.

## Contributing to httpthumbnailer
 
* Check out the latest master to make sure the feature hasn't been implemented or the bug hasn't been fixed yet
* Check out the issue tracker to make sure someone already hasn't requested it and/or contributed it
* Fork the project
* Start a feature/bugfix branch
* Commit and push until you are happy with your contribution
* Make sure to add tests for it. This is important so I don't break it in a future version unintentionally.
* Please try not to mess with the Rakefile, version, or history. If you want to have your own version, or is otherwise necessary, that is fine, but please isolate to its own commit so I can cherry-pick around it.

## Copyright

Copyright (c) 2012 Jakub Pastuszek. See LICENSE.txt for
further details.

