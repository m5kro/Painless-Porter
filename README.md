# Painless-Porter
A tool to quickly port RPG Maker MV and MZ games to Linux and MacOS and upload to file hosters. <br>
No guarantee on the painless part.

# How to Use
Prerequisites: Docker
1. Clone the repo
2. Build the image <br>
```docker build -t painless-porter .```
3. Create a container <br>
```docker run -p 3000:3000 painless-porter```
4. Go to http://127.0.0.1:3000/ in your browser
5. Put in pixeldrain stuff or upload your file (zip,7z,rar,tar.gz supported)
6. Wait a while for it to finish running
7. Check container logs for the links

# Credits
nwjs team for nwjs <br>
docker team for docker <br>
pixeldrain for free api and file hosting<br>
gofile for free api and file hosting<br>
