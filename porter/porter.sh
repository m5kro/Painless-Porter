#!/bin/bash
cd /porter/
# Function to display usage information
function display_usage {
  echo "Usage: $0 [--folder] [--no-upload] [--no-compress] [--no-cleanup] <input_file>"
  exit 1
}

# Parse command line arguments
extract=true
upload=true
compress=true
cleanup=true

while [ "$#" -gt 0 ]; do
  case "$1" in
    --folder)
      extract=false
      ;;
    --no-upload)
      upload=false
      cleanup=false
      ;;
    --no-compress)
      compress=false
      upload=false
      cleanup=false
      ;;
    --no-cleanup)
      cleanup=false
      ;;
    -*)
      display_usage
      ;;
    *)
      input_file="$1"
      break
      ;;
  esac
  shift
done

# Check if input_file is provided
if [ -z "$input_file" ]; then
  display_usage
fi

input_file="$1"

# Clear out old links
rm -rf pixeldrain.txt
touch pixeldrain.txt
rm -rf gofile.txt
touch gofile.txt

# Check for nwjs files
if [ ! -f "nwjs-v0.83.0-linux-x64.tar.gz" ]; then
    echo "Downloading nwjs 0.83.0 Linux..."
    curl https://dl.nwjs.io/v0.83.0/nwjs-v0.83.0-linux-x64.tar.gz -o nwjs-v0.83.0-linux-x64.tar.gz
fi

if [ ! -f "nwjs-v0.83.0-osx-arm64.zip" ]; then
    echo "Downloading nwjs 0.83.0 MacOS arm64..."
    curl https://dl.nwjs.io/v0.83.0/nwjs-v0.83.0-osx-arm64.zip -o nwjs-v0.83.0-osx-arm64.zip
fi

if [ ! -f "nwjs-v0.83.0-osx-x64.zip" ]; then
    echo "Downloading nwjs 0.83.0 MacOS x64..."
    curl https://dl.nwjs.io/v0.83.0/nwjs-v0.83.0-osx-x64.zip -o nwjs-v0.83.0-osx-x64.zip
fi

# Extract nwjs files
tar -xzvf nwjs-v0.83.0-linux-x64.tar.gz
unzip nwjs-v0.83.0-osx-arm64.zip
unzip nwjs-v0.83.0-osx-x64.zip

# Prep Linux
cp cicpoffs ./nwjs-v0.83.0-linux-x64/lib/
cp mount.cicpoffs ./nwjs-v0.83.0-linux-x64/lib/

# Prep osx
mkdir nwjs-v0.83.0-osx-arm64/nwjs.app/Contents/Resources/app.nw
mkdir nwjs-v0.83.0-osx-x64/nwjs.app/Contents/Resources/app.nw

# Check if the input file exists
if [ ! -f "$input_file" ]; then
  echo "Error: Input file not found."
  exit 1
fi

# Make temporary folder for gamefiles
mkdir extracted

# Check if archive extraction is required
if [ "$extract" = true ]; then
  # Determine compression format
  case "$input_file" in
    *.zip)
      unzip "$input_file" -d ./extracted/ ;;
    *.7z)
      7z x "$input_file" "-o./extracted/" ;;
    *.rar)
      unrar x "$input_file" ./extracted/ ;;
    *.tar.gz)
      tar xvzf "$input_file" -C ./extracted/ ;;
    *)
      echo "Error: Unsupported compression format."
      exit 1 ;;
  esac
fi

# Look for the 'www' folder rpgmv
www_folder=$(find ./extracted/ -type d -name "www" -print -quit)

if [ -n "$www_folder" ]; then
  # If 'www' folder exists, copy it to the uncompressed nwjs folder
  cp -r "$www_folder" nwjs-v0.83.0-linux-x64/www
  cp -r "$www_folder" nwjs-v0.83.0-osx-arm64/nwjs.app/Contents/Resources/app.nw
  cp -r "$www_folder" nwjs-v0.83.0-osx-x64/nwjs.app/Contents/Resources/app.nw
  # Put the game name in package.json so it runs
  game_name=$(basename "$input_file" | sed 's/\(.*\)\..*/\1/')
  jq ".name = \"$game_name\"" package-template.json > package.json
  cp package.json nwjs-v0.83.0-linux-x64/
  cp package.json nwjs-v0.83.0-osx-arm64/nwjs.app/Contents/Resources/app.nw
  cp package.json nwjs-v0.83.0-osx-x64/nwjs.app/Contents/Resources/app.nw

else
  # If 'www' folder does not exist, look for specific folders and files for rpgmz
  for folder in audio css js img data effects fonts icon; do
    folder_path=$(find ./extracted/ -type d -name "$folder" -print -quit)
    if [ -n "$folder_path" ]; then
      cp -r "$folder_path" nwjs-v0.83.0-linux-x64/"$folder"
      cp -r "$folder_path" nwjs-v0.83.0-osx-arm64/nwjs.app/Contents/Resources/app.nw
      cp -r "$folder_path" nwjs-v0.83.0-osx-x64/nwjs.app/Contents/Resources/app.nw
    fi
  done

  # If movies folder exists
  movies_path=$(find ./extracted/ -type d -name movies -print -quit)
  if [ -n "$movies_path" ]; then
    cp -r "$movies_path" nwjs-v0.83.0-linux-x64/movies
    cp -r "$movies_path" nwjs-v0.83.0-osx-arm64/nwjs.app/Contents/Resources/app.nw
    cp -r "$movies_path" nwjs-v0.83.0-osx-x64/nwjs.app/Contents/Resources/app.nw
  fi

  # Look for index.html and copy it if found
  index_html=$(find ./extracted/ -type f -name "index.html" -print -quit)
  if [ -n "$index_html" ]; then
    cp "$index_html" nwjs-v0.83.0-linux-x64
    cp "$index_html" nwjs-v0.83.0-osx-arm64/nwjs.app/Contents/Resources/app.nw
    cp "$index_html" nwjs-v0.83.0-osx-x64/nwjs.app/Contents/Resources/app.nw
  fi

  # Find the topmost instance of package.json and copy it to the nwjs folder
  package_json=$(find ./extracted/ -type f -name "package.json" -print -quit)
  if [ -n "$package_json" ]; then
    cp "$package_json" nwjs-v0.83.0-linux-x64
    cp "$package_json" nwjs-v0.83.0-osx-arm64/nwjs.app/Contents/Resources/app.nw
    cp "$package_json" nwjs-v0.83.0-osx-x64/nwjs.app/Contents/Resources/app.nw
  fi
fi

# Copy start.sh to the uncompressed nwjs folder
cp start.sh nwjs-v0.83.0-linux-x64

# Extract name without extension and append -Linux
new_linux_folder_name=$(basename "$input_file" | sed 's/\(.*\)\..*/\1/')"-Linux"
mv nwjs-v0.83.0-linux-x64 "$new_linux_folder_name"

new_osx_arm64_folder_name=$(basename "$input_file" | sed 's/\(.*\)\..*/\1/')"-macos-arm64.app"
mv nwjs-v0.83.0-osx-arm64/nwjs.app "$new_osx_arm64_folder_name"

new_osx_x64_folder_name=$(basename "$input_file" | sed 's/\(.*\)\..*/\1/')"-macos-x64.app"
mv nwjs-v0.83.0-osx-x64/nwjs.app "$new_osx_x64_folder_name"

rm -rf nwjs-v0.83.0-osx-arm64
rm -rf nwjs-v0.83.0-osx-x64

echo "Unpacking and copying completed successfully."
if [ "$compress" = true ]; then
  echo "Compressing"
fi

if [ "$compress" = true ]; then
  new_linux_archive_name=$(basename "$input_file" | sed 's/\(.*\)\..*/\1/')"-Linux.7z"
  7z a -mx1 -mf- -m0=lzma2:a0 "$new_linux_archive_name" ./"$new_linux_folder_name"
  if [ "$upload" = true ]; then
    json_data=$(curl -s https://api.gofile.io/getServer)
    store_value=$(echo "$json_data" | jq -r '.data.server')
    echo https://pixeldrain.com/u/$(curl -T "$new_linux_archive_name" https://pixeldrain.com/api/file/ | jq -r '.id') >> pixeldrain.txt &
    curl -F file=@"$new_linux_archive_name" https://"$store_value".gofile.io/uploadFile | jq -r '.data.downloadPage'>> gofile.txt &
  fi

  new_osx_arm64_archive_name=$(basename "$input_file" | sed 's/\(.*\)\..*/\1/')"-macos-arm64.7z"
  7z a -mx1 -mf- -m0=lzma2:a0 "$new_osx_arm64_archive_name" ./"$new_osx_arm64_folder_name"
  if [ "$upload" = true ]; then
    json_data=$(curl -s https://api.gofile.io/getServer)
    store_value=$(echo "$json_data" | jq -r '.data.server')
    echo https://pixeldrain.com/u/$(curl -T "$new_osx_arm64_archive_name" https://pixeldrain.com/api/file/ | jq -r '.id') >> pixeldrain.txt &
    curl -F file=@"$new_osx_arm64_archive_name" https://"$store_value".gofile.io/uploadFile | jq -r '.data.downloadPage' >> gofile.txt &
  fi

  new_osx_x64_archive_name=$(basename "$input_file" | sed 's/\(.*\)\..*/\1/')"-macos-x64.7z"
  7z a -mx1 -mf- -m0=lzma2:a0 "$new_osx_x64_archive_name" ./"$new_osx_x64_folder_name"
  if [ "$upload" = true ]; then
    json_data=$(curl -s https://api.gofile.io/getServer)
    store_value=$(echo "$json_data" | jq -r '.data.server')
    echo https://pixeldrain.com/u/$(curl -T "$new_osx_x64_archive_name" https://pixeldrain.com/api/file/ | jq -r '.id') >> pixeldrain.txt &
    #last one not put in background to keep script alive, useful for timing
    curl -F file=@"$new_osx_x64_archive_name" https://"$store_value".gofile.io/uploadFile | jq -r '.data.downloadPage' >> gofile.txt
  fi
  
  wait
  
  echo "Uploading Complete!"
fi


# Cleanup
if [ "$cleanup" = true ]; then
  echo "Cleaning Up!"
  rm -rf extracted
  rm -rf "$new_linux_folder_name"
  rm -rf "$new_osx_arm64_folder_name"
  rm -rf "$new_osx_x64_folder_name"
  rm -f "$new_linux_archive_name"
  rm -f "$new_osx_arm64_archive_name"
  rm -f "$new_osx_x64_archive_name"
  rm -f "$input_file"
fi
echo "Completed Successfully."
echo "Pixeldrain Links:"
cat pixeldrain.txt
echo "GoFile Links:"
cat gofile.txt
