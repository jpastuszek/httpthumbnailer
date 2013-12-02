# HTTP Thumbnailer

HTTP API server for image thumbnailing and format conversion.

It is using [ImageMagick](http://www.imagemagick.org) or [GraphicsMagick](http://www.graphicsmagick.org) via [RMagick](http://rmagick.rubyforge.org) gem as the image processing library.

## Features

* thumbnailing images with different aspect ratio keeping methods
* identification of image foramt and size
* support of many input and output formats
* efficient API for generating multiple thumbnails from single input image with just one request
* many image scaling and loading performance optimizations
* efficient memory usage
* memory limits and disk memory offloading support
* based on [Unicorn HTTP server](http://unicorn.bogomips.org) with UNIX socket communication support

## Changelog

### 1.1.0

* added identification API for image mime type and size identification
* stripping user meta data from input image further reducing output image size
* providing image size headers for input image and all generated thumbnails
* X-Input-Image-Content-Type header is now deprecated in favour of X-Input-Image-Content-Type
* not using [ImageMagick](http://www.imagemagick.org) for input image mime type resolution since it is accessing disk and behaves very inefficiently

## Installing

You will need the following system packages installed: `imagemagick`, `pkg-config` and `make`.
For PNG support install `libpng`. You may want to consult [ImageMagick](http://www.imagemagick.org) installation guide for more information on supported formats and required libraries.

For Arch Linux you can use this commands:

```bash
pacman -S imagemagick
pacman -S libpng
pacman -S pkg-config
pacman -S make
```

Then you can install the gem as usual:

```bash
gem install httpthumbnailer
```

Optionally install Ruby client library and tool:

```bash
gem install httpthumbnailer-client
```

## Usage

### Getting started

```bash
# install httpthumbnailer (see above)
# install httpthumbnailer-client
gem install httpthumbnailer-client

# start thumbnailing server in foreground (to stop hit Ctlr-C)
httpthumbnailer --foreground --verbose

# in another console thumbnail to standard output
cat ~/Pictures/compute.jpg | httpthumbnailer-client -t crop,100,200,png > thumbnail.png

# generate multiple thumbnails
cat ~/Pictures/compute.jpg | httpthumbnailer-client -t crop,100,200,jpeg,quality:100 -t pad,200,200,png thumbnail1.jpg thumbnail2.png
```

In this example we use [httpthumbnailer-client](http://github.com/jpastuszek/httpthumbnailer-client) gem CLI tool that will use HTTP API of the server to generate thumbnails.

### Running the server

HTTP Thumbnailer uses worker based server model thanks to [Unicorn HTTP server](http://unicorn.bogomips.org) gem.

To start the thumbnailer use `httpthumbnailer` command.
By default it will start in background and will spawn CPU core number + 1 number of worker processes.
It will be listening on **localhost** port **3100**.

To start in foreground with verbose output use `httpthumbnailer --verbose --foreground`.
To see available switches and options use `httpthumbnailer --help`.

When running in background the master server process will store it's PID in `httpthumbnailer.pid` file. You can change pid file location with `--pid-file` option.
If running as root you can use `--user` option to specify user with whose privileges the worker processes will be running.

### Logging

`httpthumbnailer` logs to `httpthumbnailer.log` file in current directory by default. You can change log file location with `--log-file` option and verbosity with `--verbose` or `--debug` switch.

Additionally `httpthumbnailer` will log requests in [common NCSA format](http://en.wikipedia.org/wiki/Common_Log_Format) to `httpthumbnailer_access.log` file. Use `--access-log-file` option to change location of access log.

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

    /thumbnail/pad,100,100,png,background-color:green

For detailed information about the API see [cucumber features](http://github.com/jpastuszek/httpthumbnailer/blob/master/features/thumbnail.feature).

#### Multipart API

To generate multiple thumbnails of single image send that image with **PUT** request to URI in format:

    /thumbnails/<operation type>,<width>,<height>,<format>[,<option key>:<option value>]*[/<operation type>,<width>,<height>,<format>[,<option key>:<option value>]*]*

Server will respond with **multi-part content** with each part containing **Content-Type** header and thumbnail data corresponding to format defined in the URI.

For example the URI may look like this: 

    /thumbnails/crop,16,16,png/crop,4,8,jpg/pad,16,32,jpeg

HTTP Thumbnailer will generate 3 thumbnails: 
 1. 16x16 cropped PNG
 2. 4x8 cropped JPEG
 3. 16x32 colour padded JPEG

For detailed information about the API see [cucumber features](http://github.com/jpastuszek/httpthumbnailer/blob/master/features/thumbnails.feature).

#### Identification API

You can identify image mime type, width and height with **PUT** request to URI in format:

    /identify

Server will respond with **JSON** containing **contentType**, **width** and **height** fields:

    {"mimeType":"image/jpeg","width":1239,"height":1750}

For detailed information about the API see [cucumber features](http://github.com/jpastuszek/httpthumbnailer/blob/master/features/identify.feature).

### Ruby API client

To make it easier to use this server [httpthumbnailer-client](http://github.com/jpastuszek/httpthumbnailer-client) gem provides useful class.

### Memory limits

Each worker uses [ImageMagick](http://www.imagemagick.org) memory usage limit feature.
By default it will use up to 128MiB of RAM and up to 1GiB of disk backed virtual memory.
To change this defaults use `--limit-memory` option for RAM limit and `--limit-disk` to control file backed memory mapping limit in MiB.

## Status codes

HTTP Thumbnailer will respond with different status codes on different situations.
If all goes well 200 OK will be returned otherwise:

### 400

* requested thumbnail method is not supported
* at least one image dimension is zero in thumbnail spec
* missing option key or value in thumbnail spec
* missing argument in in thumbnail spec
* bad argument value

### 413

* request body is too long
* input image is too big to fit in memory
* memory or pixel cache limit has been exceeded

### 415

* unsupported media type - see **Supported formats** section

### 500

* unexpected error has occurred - see the log file

### Multipart API

In multipart API when error relates to single thumbnail `Content-Type: plain/text` header will be used for that part.
In addition `Status` header will be set for failing part with number corresponding to above status codes.
The body will contain description of the error.

## Statistics API

HTTP Thumbnailer comes with statistics API that shows various runtime collected statistics.
It is set up under `/stats` URI. You can also request single stat with `/stats/<stat name>` request.

Example:

```bash
$ curl 127.0.0.1:3100/stats
total_requests: 119
total_errors: 1
calling: 1
writing: 0
total_images_loaded: 115
total_images_reloaded: 30
total_images_downscaled: 30
total_thumbnails_created: 147
images_loaded: 0
max_images_loaded: 3
max_images_loaded_worker: 3
total_images_created: 312
total_images_destroyed: 312
total_images_created_from_blob: 115
total_images_created_initialize: 53
total_images_created_resize: 101
total_images_created_crop: 13
total_images_created_sample: 30
total_write_multipart: 16
total_write: 101
total_write_part: 48
total_write_error: 1
total_write_error_part: 0

$ curl 127.0.0.1:3100/stats/total_write_multipart
16
```

## See also

[HTTP Image Store](https://github.com/jpastuszek/httpimagestore) service is configurable image storage and processing HTTP API server that uses this service as thumbnailing backend. 

## Known Issues

* When 413 error is reported due to memory limit exhaustion the disk offloading won't work any more and only requests that can fit in the memory can be processed without getting 413 - this is due to a bug in ImageMagick v6.8.6-8 (2013-08-06 6.8.6-8) or less
* Mime type generated for images may not be the official mime type assigned for given format; please let me know of any inconsistencies or send a patch to get better output in efficient way

## TODO

* Save input image data for images that has failed processing to allow further investigation
* Allow for specifying different quality values for different image types, e.g.: quality[jpeg]:97,quality[png]:85

## Contributing to HTTP Thumbnailer
 
* Check out the latest master to make sure the feature hasn't been implemented or the bug hasn't been fixed yet
* Check out the issue tracker to make sure someone already hasn't requested it and/or contributed it
* Fork the project
* Start a feature/bugfix branch
* Commit and push until you are happy with your contribution
* Make sure to add tests for it. This is important so I don't break it in a future version unintentionally.
* Please try not to mess with the Rakefile, version, or history. If you want to have your own version, or is otherwise necessary, that is fine, but please isolate to its own commit so I can cherry-pick around it.

## Copyright

Copyright (c) 2013 Jakub Pastuszek. See LICENSE.txt for
further details.

