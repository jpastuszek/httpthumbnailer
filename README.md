# HTTP Thumbnailer

HTTP API server for image thumbnailing, editing and format conversion.

It is using [ImageMagick](http://www.imagemagick.org) or [GraphicsMagick](http://www.graphicsmagick.org) via [RMagick](http://rmagick.rubyforge.org) gem as the image processing library.

## Features

* thumbnailing images with different aspect ratio keeping methods
* applying image edits like rotate, crop, blur, pixelate, etc.
* identification of image format and size
* support of many input and output formats
* efficient API for generating multiple thumbnails from single input image with just one request
* many image scaling and loading performance optimizations
* efficient memory usage
* memory limits and disk memory offloading support
* custom plugin support
* based on [Unicorn HTTP server](http://unicorn.bogomips.org) with UNIX socket communication support

## Changelog

### 1.3.0
* added edits support
* added performance statistics
* added plugin support
* switches to control optimizations
* using downsampling by default when image gets upscaled on load

### 1.2.0
* added `float-x` and `float-y` option support
* added `interlace` option support
* syslog logging
* transaction ID tracking

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

# applay edits to the image and thumbnail - pixelate middle of the image and draw blue rectangle at the bottom of it
cat ~/Pictures/compute.jpg | httpthumbnailer-client -t 'fit,280,280,png!pixelate,0.3,0.2,0.4,0.4!rectangle,0.04,0.8,0.92,0.17,color:blue' > thumbnail.png
```

### Ruby API client

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

Syslog logging can be enabled with `--syslog-facility` option followed by name of syslog facility to use. When enabled log files are not created and both application logs and access logs are sent to syslog.
Access logs will gain meta information that will include `"type":"http-access"` that can be used to filter access log entries out from application log entries.

With `--xid-header` option name of HTTP request header can be specified. Value of this header will be logged in meta information tag `xid` along side all request related log entries.

Using `--perf-stats` switch will enable logging of performance statistics. This log entries will be logged with `"type":"perf-stats"`.

### Thumbnailing methods

For method you can use one of the following value:
* `fit` - fit image within given dimensions keeping aspect ratio
* `crop` - cut image to fit within given dimensions keeping aspect ratio
* `pad` - fit resize image and pad image with background colour to given dimensions keeping aspect ratio
* `limit` - fit resize image to given dimensions if it is larger than that dimensions

### Supported formats

List of supported formats can be displayed with `httpthumbnailer --formats`.
Optionally format `input` can be used to use the same thumbnail format as input image.

### Thumbnail width and height

Width and height values are in pixels and are interpreted depending on method used.
`input` string can be used for width and/or height to use input image width or height.

### Thumbnail options

Following options can be used with thumbnail specification:
* `quality` - set output image quality; this is format specific: for JPEG 0 is maximum compression and 100 is maximum quality, for PNG first digit is zlib compression level and second one is filter level
* `background-color` - color in HTML notation or textual description ('red', 'green' etc.) used for background when processing transparent images or padding; by default white background is used
* `float-x` and `float-y` - value between 0.0 and 1.0; can be used with `crop` and `pad` methods to move cropping view or image over background left to right or top to bottom (0.0 to 1.0); both default to 0.5 centering the view or image
* `interlace` - one of `UndefinedInterlace`, `NoInterlace`, `LineInterlace`, `PlaneInterlace`, `PartitionInterlace`, `GIFInterlace`, `JPEGInterlace`, `PNGInterlace`; some formats support interlaced output format; use `JPEGInterlace` or `LineInterlace` or `PlaneInterlace` with `jpeg` format to produce progressive JPEG; defaults to `NoInterlace`

### Edits

Edits are applied on input image (after possibly being downsampled) and before the final thumbnail is generated.
Relative vector values are relative to input image dimensions (width and hight), scalar values are relative to input image diagonal. This way edits will look more or less the same no matter what the input or output image resolution is. Also client does not need to know the resolution of input image.

One or more edits can be used with thumbnailing specification:
* `resize_crop` - cut image to fit within given dimensions keeping aspect ratio
	* arguments: width, height - dimensions to resize and crop image to in pixels
	* options:
		* `float-x`, `float-y` - value between 0.0 and 1.0; move cropping view left to right or top to bottom (0.0 to 1.0); default: 0.5 (center)
* `resize_fit` - fit image within given dimensions keeping aspect ratio
	* arguments: width, height in pixels
* `resize_limit` - same as `resize_fit` but applied only if image is larger than given dimensions
	* arguments: width, height - dimension to limit image to in pixels
* `crop`
	* arguments: x, y, width, height - values between 0.0 and 1.0; region of image starting from relative position to image width from left (x) and height from top (y) with relative width and height
* `pixelate` - pixelate (sample) given region of image
	* arguments: box_x, box_y, box_widthd, box_height - values between 0.0 and 1.0; region of image starting from relative position to image width from left (x) and height from top (y) with relative width and height
	* options:
		* `size` - size of the pixel (relative to imgae diagonal); default: 0.01
* `blur` - blur region of image
	* arguments: x, y, width, height - values between 0.0 and 1.0; region of image starting from relative position to image width from left (x) and height from top (y) with relative width and height
	* options:
		* `sigma` - amount of blur (relative to imgae diagonal); resulting value is capped to 50 pixels
		* `radius` - radius of the blur (0.0 - calculated for given sigma) (relative to image diagonal); resulting value is capped to 50 pixels; default: 0.0
* `rectangle` - draw rectangle over image
	* arguments: box_x, box_y, box_width, box_height - values between 0.0 and 1.0; rectangle over image starting from relative position to image width from left (x) and height from top (y) with relative width and height
	* options:
		* `color` - color of the rectangle; default: black
* `rotate` - rotate image clockwise by given angle filling any new image surface with color
	* arguments: angle - rotation angle in degree
	* options:
		* `background-color` - color of the background (when not 90x rotation is used); default: thumbnail `background-color` option or transparent

## API

### Single thumbnail API

To generate single thumbnail send input image with **PUT** request to URI in format:

    /thumbnail/<method>,<width>,<height>,<format>[,<option key>:<option value>]*[!<edit name>[,<edit arg>]*[,<edit option>:<edit option value>]*]*

Server will respond with thumbnail data with correct **Content-Type** header value.

For example the URI may look like this:

    /thumbnail/pad,100,100,png,background-color:green

With additional edits:

	/thumbnail/pad,100,100,png,background-color:green!blur,0.2,0.1,0.6,0.6,size:0.03!rectangle,0.1,0.8,0.8,0.1,color:blue

For detailed information about the API see [cucumber features](http://github.com/jpastuszek/httpthumbnailer/blob/master/features/thumbnail.feature).

### Multipart API

To generate multiple thumbnails of single image send that image with **PUT** request to URI in format:

    /thumbnails/<method>,<width>,<height>,<format>[,<option key>:<option value>]*[!<edit name>[,<edit arg>]*[,<edit option>:<edit option value>]*]*[/<method>,<width>,<height>,<format>[,<option key>:<option value>]*]*[!<edit name>[,<edit arg>]*[,<edit option>:<edit option value>]*]*

Server will respond with **multi-part content** with each part containing **Content-Type** header and thumbnail data corresponding to format defined in the URI.

For example the URI may look like this:

	/thumbnails/crop,16,16,png/crop,4,8,jpg/pad,16,32,jpeg

With additional edits:

	/thumbnails/crop,16,16,png!blur,0.2,0.1,0.6,0.6,size:0.03!rectangle,0.1,0.8,0.8,0.1,color:blue/crop,4,8,jpg/pad,16,32,jpeg!rotate,90!pixelate,0.3,0.2,0.4,0.4

HTTP Thumbnailer will generate 3 thumbnails:
 1. 16x16 cropped PNG
 2. 4x8 cropped JPEG
 3. 16x32 colour padded JPEG

For detailed information about the API see [cucumber features](http://github.com/jpastuszek/httpthumbnailer/blob/master/features/thumbnails.feature).

### Identification API

You can identify image mime type, width and height with **PUT** request to URI in format:

    /identify

Server will respond with **JSON** containing **contentType**, **width** and **height** fields:

    {"mimeType":"image/jpeg","width":1239,"height":1750}

For detailed information about the API see [cucumber features](http://github.com/jpastuszek/httpthumbnailer/blob/master/features/identify.feature).

### Error status codes

HTTP Thumbnailer will respond with different status codes on different situations.
If all goes well 200 OK will be returned otherwise:

#### 400

* requested thumbnail method is not supported
* at least one image dimension is zero in thumbnail spec
* missing option key or value in thumbnail spec
* missing argument in in thumbnail spec
* bad argument value

#### 413

* request body is too long
* input image is too big to fit in memory
* memory or pixel cache limit has been exceeded

#### 415

* unsupported media type - see **Supported formats** section

#### 500

* unexpected error has occurred - see the log file

### Error handling with multipart API

With multipart API when error relates to single thumbnail `Content-Type: plain/text` header will be used for that part.
In addition `Status` header will be set for failing part with number corresponding to above status codes.
The body will contain description of the error.

### Statistics API

HTTP Thumbnailer comes with statistics API that shows various runtime collected statistics.
It is set up under `/stats` URI. You can also request single stat with `/stats/<stat name>` request.

Example:

```bash
$ curl 127.0.0.1:3100/stats
workers: 5
total_requests: 18239789
total_errors: 903
calling: 1
writing: 0
total_images_loaded: 17633702
total_images_reloaded: 0
total_images_downscaled: 21805
total_thumbnails_created: 17633090
images_loaded: 0
max_images_loaded: 101
max_images_loaded_worker: 101
total_images_created: 50178054
total_images_destroyed: 50178054
total_images_created_from_blob: 17634825
total_images_created_initialize: 9763067
total_images_created_resize: 16261541
total_images_created_crop: 6496816
total_images_created_sample: 21805
total_write_multipart: 0
total_write: 18238885
total_write_part: 0
total_write_error: 903
total_write_error_part: 0

$ curl 127.0.0.1:3100/stats/total_thumbnails_created
17633106
```

## Memory limits

Each worker uses [ImageMagick](http://www.imagemagick.org) memory usage limit feature.
By default it will use up to 128MiB of RAM and up to 1GiB of disk backed virtual memory.
To change this defaults use `--limit-memory` option for RAM limit and `--limit-disk` to control file backed memory mapping limit in MiB.

## Plugins

Custom thumbnailing methods and edits can be programed using plugin API.
By default HTTP Thumbnailer will look for plugins in `/usr/share/httpthumbnailer/plugins`. Options `--plugins` can be used to point to different directory; it can also be specified multiple times to point to more than one directory.
Plugin file needs to end with `.rb` extension to be found anywhere within directory structure pointed by `--plugins` option (or in default directory).

### Defining new thumbnailing methods

To define new thumbnailing method provide block like this:

```ruby
thumbnailing_method('method_name') do |image, width, height, options|
	# do something with image
end
```

Name of the method is defined by value of `thumbnailing_method` method argument (string).

Server will pass following objects:
* `image` - [RMagick::Image](https://rmagick.github.io/index.html) object
* `width` and `height` - integers representing required width and height of the thumbnail
* `options` - key-value map, where keys and values are strings, passed to request specification

Block should return (last value or with `next` keyword) new image or the image passed with `image` argument or `nil` if no change was done.

### Defining new edits

To define new edit provide block like this:

```ruby
edit('edit_name') do |image, arg1, arg2, argN, options, thumbnail_spec|
	# do something with image
end
```

Name of the edit is defined by value of `edit` method argument (string).

Server will pass following objects:
* `image` - [RMagick::Image](https://rmagick.github.io/index.html) object; input image or output of previous edit
* all arguments as passed to the API; you can capture as many as you need
* `options` - key-value map, where keys and values are strings, passed to request with edit specification
* `thumbnail_spec` - object representing thumbnail specification; you can call following methods:
	* `method` - name of the thumbnailing method
	* `width` and `height` - integers representing required width and height of the thumbnail
	* `format` - requested output format (e.g. `png` or `jpeg`)
	* `options` - key-value map of thumbnailing options
	* `edits` - array representing all edits; each edit has following methods:
		* `name` - name of the edit
		* `args` - array of edit arguments
		* `options` - key-value map of edit options

Block should return (last value or with `next` keyword) new image or the image passed with `image` argument or `nil` if no change was done.

### Processing images

If more than one image is created during processing it is important to call `get` on every newly created image (unless it is the one being returned). This method will pass the image to first block argument and will ensure that image is destroyed after use or on exception. Returning `nil` or same image as input will make `get` to return the input image without destroying it.

Example of `get` usage:

```ruby
	image.crop(cut_x * image.columns, cut_y * image.rows, cut_w * image.columns, cut_h * image.rows, true).get do |image|
		image.resize_to_fit(width, height) if image.columns != width or image.rows != height
	end
```

For examples see built-in thumbnailing methods and edits defined in [built_in_plugins.rb](lib/httpthumbnailer/plugin/thumbnailer/service/built_in_plugins.rb).

### Helper functions

Following helper functions are available in plugin context:
* `int!(name, arg, default = nil)` - returns integer from given `arg` string; `name` is used for reporting errors; if `arg` is an empty string returns `default` if not `nil` or fail with **400 Bad Request**
* `uint!(name, arg, default = nil)` - returns positive integer from given `arg` string; `name` is used for reporting errors; if `arg` is an empty string returns `default` if not `nil` or fail with **400 Bad Request**
* `float!(name, arg, default = nil)` - returns float from given `arg` string; `name` is used for reporting errors; if `arg` is an empty string returns `default` if not `nil` or fail with **400 Bad Request**
* `ufloat!(name, arg, default = nil)` - returns positive float from given `arg` string; `name` is used for reporting errors; if `arg` is an empty string returns `default` if not `nil` or fail with **400 Bad Request**
* `offset_to_center(x, y, w, h)` - returns center (`[x, y]`) of the given region
* `center_to_offset(center_x, center_y, w, h)` - returns offset (`[x, y]`) of given region center (`center_x`, `center_y`) and `width` and `height`
* `normalize_region(x, y, width, height)` - returns normalized relative (values between 0.0 and 1.0) region offset and dimensions (`[x, y, width, height]`) that fits within normal values so that width and height will never be 0.0 (`Float::EPSILON` instead), `x + width` and `y + height` will never be grater than 1.0 and all values will not be negative

Additional [RMagick::Image](https://rmagick.github.io/index.html) object methods are provided:
* `RMagick::Image.new_8bit(width, height, background_color = 'none')` - create new image of given dimensions and background color (which can be described by pallet color name like **black** of by hex value)
* `render_on_background(background_color, width = nil, height = nil, float_x = 0.5, float_y = 0.5)` - overlay current image on top of new image (with optionally different dimensions and floating) of given color
* `float_to_offset(float_width, float_height, float_x = 0.5, float_y = 0.5)` - calculated offset (`[x, y]`) of image with given dimensions (`float_width`, `float_height`) on top of this image given `float_x` and `float_y` values
* `pixelate_region(x, y, w, h, size)` - pixelate region given with offset (`x`, `y`) and dimensions (`w`, `h`) in pixels of pixel diagonal size (`size`) also in pixels
* `blur_region(x, y, w, h, radius, sigma)` - blur region given with offset (`x`, `y`) and dimensions (`w`, `h`) in pixels using effect `radius` and `sigma` in pixels
* `render_rectangle(x, y, w, h, color)` - draw rectangle given with offset (`x`, `y`) and dimensions (`w`, `h`) in pixels
* `with_background_color(color, &block)` - do **RMagick** image operation that uses background color in given block and restore previous background color when finished
* `rel_to_px_pos(x, y)` - convert relative offset to offset represented in pixels (using `Float#floor` value)
* `rel_to_px_dim(width, height)` - convert relative width and height to width and height in pixels  (using `Float#ceil` value)
* `rel_to_diagonal(v)` - convert relative diagonal to diagonal in pixels (using `Float#ceil` value)
* `width` - alias for `#columns`
* `height` - alias for `#height`
* `diagonal` - calculate diagonal in pixels (using `Float#ceil` value)

### Memory usage and leaks

To avoid memory leaks (leaked images) make use of `get` method on intermediate images.
Observe value of `total_images_reloaded` - if it is increasing and not dropping to 0 after you used the thumbnailing API you have a leak!

```bash
$ curl 127.0.0.1:3100/stats/images_loaded
0
```

Also avoid keeping too many images loaded at the same time. Chain `get` calls rather than nest them:

```ruby
	image.get do |image|
		# image is the input image
		# image processing step 1
	end.get do |image|
		# image is now result of step 1
		# image processing step 2
	end.get do |image|
		# image is now result of step 2
		# image processing final step
	end
```

## See also

[HTTP Image Store](https://github.com/jpastuszek/httpimagestore) service is configurable image storage and processing HTTP API server that uses this service as thumbnailing backend.

## Known Issues

* When 413 error is reported due to memory limit exhaustion the disk offloading won't work any more and only requests that can fit in the memory can be processed without getting 413 - this is due to a bug in ImageMagick v6.8.6-8 (2013-08-06 6.8.6-8) or less; recommended version is 6.8.7-8
* Mime type generated for images may not be the official mime type assigned for given format; please let me know of any inconsistencies or send a patch to get better output in efficient way
* CMYK profile JPEGs may render negative

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

Copyright (c) 2013 - 2015 Jakub Pastuszek. See LICENSE.txt for further details.

