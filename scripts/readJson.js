const { readFile } = require('fs/promises');

const FILE_PATH = './deployed.json';

exports.readJson = async () => {
  let jsonString = '';
  let obj = {};
  try {
    jsonString = await readFile(FILE_PATH, 'utf-8');
    obj = JSON.parse(jsonString);
  } catch (e) {
    process.exit(1);
  }
  return obj;
};
