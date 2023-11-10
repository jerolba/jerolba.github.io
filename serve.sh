#!/bin/bash
docker run --rm -p 4000:4000 --volume="$PWD:/srv/jekyll"  --volume="$PWD/bundle:/usr/local/bundle" -it jekyll/jekyll jekyll serve