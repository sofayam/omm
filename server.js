const express = require('express');
const app = express();
const fs = require('fs');
const path = require('path');

// Use an environment variable for the audio file path, with a default
const audioFilePath = process.env.AUDIO_FILE_PATH || path.join(__dirname, 'audio', 'music.mp3');

app.get('/stream', (req, res) => {
  // Check if the file exists
  if (!fs.existsSync(audioFilePath)) {
    console.error(`Audio file not found at: ${audioFilePath}`);
    return res.status(404).send('Audio file not found.');
  }

  const stat = fs.statSync(audioFilePath);
  const fileSize = stat.size;
  const range = req.headers.range;

  if (range) {
    const parts = range.replace(/bytes=/, "").split("-");
    const start = parseInt(parts[0], 10);
    const end = parts[1] ? parseInt(parts[1], 10) : fileSize - 1;
    const chunksize = (end - start) + 1;
    const file = fs.createReadStream(audioFilePath, {start, end});
    const head = {
      'Content-Range': `bytes ${start}-${end}/${fileSize}`,
      'Accept-Ranges': 'bytes',
      'Content-Length': chunksize,
      'Content-Type': 'audio/mpeg',
    };
    res.writeHead(206, head);
    file.pipe(res);
  } else {
    const head = {
      'Content-Length': fileSize,
      'Content-Type': 'audio/mpeg',
    };
    res.writeHead(200, head);
    fs.createReadStream(audioFilePath).pipe(res);
  }
});

const port = 3000;
app.listen(port, () => {
  console.log(`Server listening on port ${port}`);
  console.log(`Serving audio from: ${audioFilePath}`);
});
