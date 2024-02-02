#!/bin/bash
if command -v fusermount > /dev/null 2>&1; then
    echo "FUSE found! Moving to case insensitive."
    www_folder=$(find . -type d -name "www" -print -quit)
    if [ -n "$www_folder" ]; then
    	echo "RPG MV detected!"
    	mv "www" "www-case"
    	mkdir "www"
    	./lib/cicpoffs "./www-case" "./www"
    else
    	echo "RPG MZ detected! (kinda)"
    	for folder in audio css js img data effects fonts icon; do
			mv "$folder" "$folder"-case
        	mkdir "$folder"
        	./lib/cicpoffs ./"$folder"-case "$folder"
      	done
      	movies_folder=$(find . -type d -name "movies" -print -quit)
      	if [ -n "$movies_folder" ]; then
      		mv "movies" "movies-case"
      		mkdir "movies"
      		./lib/cicpoffs "./movies-case" "movies"
        fi
    fi
    echo "Waiting for FUSE"
    sleep 3
else
    echo "FUSE not found! Sticking with case sensitive."
fi

if [[ "$XDG_SESSION_TYPE" == "wayland" ]]; then
echo "wayland detected"
./nw --ozone-platform=wayland
else
echo "wayland not detected, starting in x11"
./nw --ozone-platform=x11
fi

if command -v fusermount > /dev/null 2>&1; then
    www_folder=$(find . -type d -name "www" -print -quit)
    if [ -n "$www_folder" ]; then
    	fusermount -u "./www"
    	rm -rf www
    	mv "www-case" "www"
    else
    	for folder in audio css js img data effects fonts icon; do
        	fusermount -u ./"$folder"
        	rm -rf ./"$folder"
        	mv "$folder"-case "$folder"
      	done
      	movies_folder=$(find . -type d -name "movies-case" -print -quit)
      	if [ -n "$movies_folder" ]; then
      		fusermount -u "./movies"
      		rm -rf movies
      		mv "movies-case" "movies"
        fi
    fi
fi
