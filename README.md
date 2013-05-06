# httpthumbnailer

HTTP API server for image thumbnailing and format conversion.

It is using **ImageMagick** or **GraphicsMagick** via **RMagick** gem as the image processing library.

## Installing

You will need the following system packages installed: `imagemagick`, `pkg-config` and `make`.
For PNG support install `libpng`. You may want to consult **ImageMagick** installation guide for more information on supported formats and required libraries.

For Arch Linux you can use this commands:

    pacman -S imagemagick
    pacman -S libpng
    pacman -S pkg-config
    pacman -S make

Then you can install the gem as usual:

    gem install httpthumbnailer

## Usage

httpthumbnailer uses worker based server model (thanks to **unicorn** gem).

To start the thumbnailer use `httpthumbnailer` command.
By default it will start in background and will spawn CPU core number + 1 number of worker processes.
It will be listening on **localhost** port **3100**.

To start in foreground with verbose output use `httpthumbnailer --verbose --foreground`.
To see available switches and options use `httpthumbnailer --help`.

When running in background the master server process will store it's PID in `httpthumbnailer.pid` file. You can change pid file location with `--pid-file` option.
If running as root you can use `--user` option to specify user with whose privileges the worker processes will be running.

### Logging

`httpthumbnailer` logs to `httpthumbnailer.log` file in current directory by default. You can change log file location with `--log-file` option and verbosity with `--verbose` or `--debug` switch.
Additionally `httpthumbnailer` will log requests in common NCSA format to `httpthumbnailer_access.log` file. Use `--access-log-file` option to change location of access log.

### Supported operations

As operation type you can select one of the following options:
* fit - fit image within given dimensions keeping aspect ratio
* crop - cut image to fit within given dimensions keeping aspect ratio
* pad - fit scale image and pad image with background colour to given dimensions keeping aspect ratio
* limit - fit scale image to given dimensions if it is larger than that dimensions

### Supported formats

List of supported formats can be displayed with `httpthumbnailer --formats`.
Optionally format `input` can be used to use the same thumbnail format as input image.

### Thumbnail width and height

Width and height values are interpreted depending on operation.
`input` string can be used for width and/or height to use input image width or height.

### Thumbnail options

Following options can be used with thumbnail specification:
* quality - set output image quality; this is format specific: for JPEG 0 is maximum compression and 100 is maximum quality, for PNG first digit is zlib compression level and second one is filter level
* background-color - color in HTML notation or textual description ('red', 'green' etc.) used for background when processing transparent images or padding; by default white background is used

### API

#### Single thumbnail API

To generate single thumbnail send input image with **PUT** request to URI in format:

    /thumbnail/<operation type>,<width>,<height>,<format>[,<option key>:<option value>]*

Server will respond with thumbnail data with correct **Content-Type** header value.

For example the URI may look like this: 

    /thumbnails/pad,100,100,png,background-color:green

For detailed information about the API see [cucumber features](http://github.com/jpastuszek/httpthumbnailer/blob/master/features/thumbnail.feature).

#### Multipart API

To generate multiple thumbnails of single image send that image with **PUT** request to URI in format:

    /thumbnails/<operation type>,<width>,<height>,<format>[,<option key>:<option value>]*[/<operation type>,<width>,<height>,<format>[,<option key>:<option value>]*]*

Server will respond with **multi-part content** with each part containing **Content-Type** header and thumbnail data corresponding to format defined in the URL.

For example the URI may look like this: 

    /thumbnails/crop,16,16,png/crop,4,8,jpg/pad,16,32,jpeg

httpthumbnailer will generate 3 thumbnails: 
1. 16x16 cropped PNG
2. 4x8 cropped JPEG
3. 16x32 colour padded JPEG

For detailed information about the API see [cucumber features](http://github.com/jpastuszek/httpthumbnailer/blob/master/features/thumbnails.feature).

### API client

To make it easy to use this server [httpthumbnailer-client](http://github.com/jpastuszek/httpthumbnailer-client) gem is provided.

### Memory limits

Each worker uses **ImageMagick** memory usage limit feature.
By default it will use up to 128MiB of RAM and up to 1GiB of disk backed virtual memory.
To change this defaults use `--limit-memory` option for RAM limit and `--limit-disk` to control file backed memory mapping limit in MiB.

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

