#!/bin/sh
#
#  build.sh – Convenience script for first-time building.

./Scripts/fetch-resources
swift build

echo "Done fetching resources and building"
echo "From now on, running 'swift build' is sufficient"
