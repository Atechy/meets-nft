const fs = require('fs').promises;
const path = require('path');
const config = require('config');


const storeDataToFile = async (jsonData) => {
  try {
    const filePath = path.join(__dirname, config.get('ipfsFile.location'));
    const ipfsFileExists = await fileExists(filePath);
    if (!ipfsFileExists) {
      console.log('ipfsFileExists: ', ipfsFileExists);
      await fs.writeFile(filePath, JSON.stringify([]));
    }
    const data = await fs.readFile(filePath, 'utf8');
    const json = JSON.parse(data);
    json.push(jsonData);
    await fs.writeFile(filePath, JSON.stringify(json));
  } catch (err) {
    console.log('Error occured while storing data to file', err);
  }
};

async function fileExists(path) {
  try {
    const res = await fs.access(path);
    return true;
  } catch (err) {
    if (err.code == 'ENOENT') {
      return false;
    }

    throw err;
  }
}

module.exports = {
  storeDataToFile,
  fileExists,
};
