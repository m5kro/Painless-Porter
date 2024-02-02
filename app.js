const express = require('express');
const bodyParser = require('body-parser');
const fileUpload = require('express-fileupload');
const { exec } = require('child_process');
const path = require('path');

const app = express();
const port = 3000;

app.use(bodyParser.urlencoded({ extended: true }));
app.use(fileUpload());
app.use(express.static(path.join(__dirname, 'public')));

app.get('/', (req, res) => {
  res.sendFile(path.join(__dirname, 'public', 'index.html'));
});

app.post('/submit', (req, res) => {
  // Check if a file is uploaded
  if (req.files && req.files.file) {
    const fileName = req.files.file.name;
    req.files.file.mv(`./porter/${fileName}`, (err) => {
      if (err) return res.status(500).send(err);

      // Run porter.sh with options
      runPorter(fileName, req.body);
      res.send('File uploaded successfully!');
    });
  } else {
    // Check if text input boxes are filled
    const fileName = req.body.fileName;
    const code = req.body.code;

    if (!fileName || !code) {
      return res.status(400).send('Error: Both text input boxes must be filled.');
    }

    // Execute download.sh with text input values
    exec(`/bin/bash /porter/download.sh /porter/${fileName} ${code}`, (error, stdout, stderr) => {
      if (error) {
        return res.status(500).send(`Error: ${stderr}`);
      }

      // Run porter.sh with options
      runPorter(fileName, req.body);
      res.send('Download and porter.sh executed successfully!');
    });
  }
});

function runPorter(fileName, options) {
  let command = `/bin/bash /porter/porter.sh ${fileName}`;

  // Append options to the command
  if (options['no-upload']) command += ' --no-upload';
  if (options['no-compress']) command += ' --no-compress';
  if (options['no-cleanup']) command += ' --no-cleanup';

  // Execute porter.sh with options
  exec(command, (error, stdout, stderr) => {
    if (error) {
      console.error(`Error: ${stderr}`);
    } else {
      console.log(`porter.sh executed successfully: ${stdout}`);
    }
  });
}

app.listen(port, () => {
  console.log(`Server is running on port ${port}`);
});
