# This script will run load test
# It will download Gatling and 126MiB of test images
#
# Environment variables:
#	MAX_USERS - how many users to rump up to (default 20)
#	HTTP_THUMBNAILER_ADDR - can be used to specify other already running instance
#	HTTP_THUMBNAILER_OPTS - can be used to specify additional startup options for HTTP Thumbnailer
#
set -e

GATLING_HOME=gatling-charts-highcharts-bundle-2.1.6
set_up_gatling() {
	[[ -d gatling-charts-highcharts-bundle-2.1.6 ]] || (
		wget --continue https://repo1.maven.org/maven2/io/gatling/highcharts/gatling-charts-highcharts-bundle/2.1.6/gatling-charts-highcharts-bundle-2.1.6-bundle.zip
		unzip gatling-charts-highcharts-bundle-2.1.6-bundle.zip
		rm -f gatling-charts-highcharts-bundle-2.1.6-bundle.zip
	)
}

set_up_image_db() {
	[[ -d 101_ObjectCategories ]] || (
		wget --continue http://www.vision.caltech.edu/Image_Datasets/Caltech101/101_ObjectCategories.tar.gz
		tar xf 101_ObjectCategories.tar.gz
		rm -f 101_ObjectCategories.tar.gz
	)

	[[ -f index.csv ]] || (
		echo "Indexing test data files"
		echo "file_name" > index.csv
		find 101_ObjectCategories -type f | rev | sort | rev >> index.csv
	)
}

set_up_gatling
set_up_image_db

finish() {
	echo
	echo "HTTPThumbnailer stats:"
	curl -s 127.0.0.1:3150/stats
	kill `cat /tmp/httpthumbnailer.pid`
}

start_thumbnailer() {
	echo "Starting HTTPThumbnailer..."
	(
		cd ../../httpthumbnailer
		bin/httpthumbnailer $HTTP_THUMBNAILER_OPTS --listener 127.0.0.1:3150 --pid-file /tmp/httpthumbnailer.pid --log-file /tmp/httpthumbnailer.log --access-log-file /tmp/httpthumbnailer_access.log
		while ! curl -s -o /dev/null 127.0.0.1:3150/; do sleep 1; echo .; done
	)
}

if [[ -z "$HTTP_THUMBNAILER_ADDR" ]]; then
	HTTP_THUMBNAILER_ADDR="http://127.0.0.1:3150"
	trap finish EXIT
	start_thumbnailer
else
	echo "Using HTTP Thumbnailer at ${HTTP_THUMBNAILER_ADDR}"
fi
export HTTP_THUMBNAILER_ADDR

[[ -z "$MAX_USERS" ]] && MAX_USERS=12
export MAX_USERS
echo "Ramping up test to ${MAX_USERS} users"

RUN_TAG=`date -u +%Y%m%d_%H%M%S`-`git describe --always`
CLASS=$1
if [[ -z "$CLASS" ]]; then
   CLASS=LoadTest
else
	shift
fi

$GATLING_HOME/bin/gatling.sh \
	--data-folder `pwd` \
	--results-folder `pwd`/results \
    --bodies-folder `pwd`/bodies \
    --simulations-folder `pwd`/simulations \
	--simulation $CLASS \
	--output-name "HTTPThumbnailer-$CLASS-$RUN_TAG" \
	$@
