# Use an official Node.js runtime as a parent image
FROM node:14

# Set the working directory in the container
WORKDIR /usr/src/app

# Install dependencies
RUN npm install express body-parser express-fileupload
RUN apt-get update && apt-get install -y \
    libpng-dev unzip unrar-free p7zip-full curl jq

# Copy the application files into the container
COPY app.js .
COPY public ./public/
COPY porter /porter/

# Expose the port the app runs on
EXPOSE 3000

# Run the application
CMD ["node", "app.js"]
