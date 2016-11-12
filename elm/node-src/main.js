// compile YourApp.elm with:
//		elm make YourApp.elm --output elm.js

const jsonfile = require('jsonfile');
const argv = require('minimist')(process.argv.slice(2));
const path = require('path');

require('dotenv').config({path: '../../../node.env'});

const queryName = argv['queryName'];
const jsonDirPath = process.env.JSON_DIR_PATH;
console.log('jsonDirPath', jsonDirPath);

// load Elm module
const elm = require('./elm.js');

const worker = elm.Project.worker({
    host: process.env.DB_HOST,
    port_: parseInt(process.env.DB_PORT),
    database: process.env.DB_NAME,
    user: process.env.DB_USER,
    password: process.env.DB_PASSWORD,
    queryName: queryName,
});

// get Elm ports
const ports = worker.ports;

// keep our app alive until we get an exitCode from Elm or SIGINT or SIGTERM (see below)
setInterval(id => id, 86400);

ports.exitNode.subscribe(exitCode => {
	console.log('Exit code from Elm:', exitCode);
	process.exit(exitCode);
});

function writeResults(results) {
  var filePath = path.resolve(jsonDirPath, queryName + ".json");
  jsonfile.writeFileSync(filePath, results, {spaces: 4});
  console.log(`${filePath} written`);
	process.exit(1);
}

ports.formattedNumReposCreatedPerMonthGenerated.subscribe( results => {
  writeResults(results);
});

ports.simpleTwoColumnGenerated.subscribe( results => {
  writeResults(results);
});

process.on('uncaughtException', err => {
	console.log(`Uncaught exception:\n`, err);
	process.exit(1);
});

process.on('SIGINT', _ => {
	console.log(`SIGINT received.`);
	process.exit(0);
});

process.on('SIGTERM', _ => {
	console.log(`SIGTERM received.`);
	process.exit(0);
});
