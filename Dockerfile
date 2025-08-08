# Use an official Node.js runtime as a parent image
FROM node:20-slim

# Set the working directory in the container
WORKDIR /usr/src/app

# Create a directory for the audio file
RUN mkdir -p /usr/src/app/audio

# Copy package.json and package-lock.json
COPY package*.json ./

# Install app dependencies
RUN npm install

# Copy the server script
COPY server.js .

# Set the default audio file path environment variable
ENV AUDIO_FILE_PATH /usr/src/app/audio/music.mp3

# Expose port 8020
EXPOSE 8020

# Define the command to run your app
CMD [ "node", "server.js" ]
