var express = require('express');
var app = express();
var fs = require('fs');

function base64_encode(filename) {
    return fs.readFileSync(filename, 'base64');
}

async function execSpectrum() {
    return new Promise((resolve, reject) => {
        const exec = require("child_process").exec
        const cmd = `docker run --rm -v $(pwd)/assets:/source -w /source --entrypoint octave zaibaiman/spectrum /source/app.m`;
        exec(cmd, (error, stdout, stderr) => {
            if (error) {
                reject(stderr)
            } else {
                resolve(stdout);
            }
        })
    })
}

async function clearPublicTmpAssets() {
    return new Promise((resolve, reject) => {
        const exec = require("child_process").exec
        const cmd = `rm -f public/image.jpg`;
        exec(cmd, (error, stdout, stderr) => {
            if (error) {
                reject(stderr)
            } else {
                resolve(stdout);
            }
        })
    });
}

async function copyImageToPublic() {
    return new Promise((resolve, reject) => {
        const exec = require("child_process").exec
        const cmd = `cp assets/image.jpg public`;
        exec(cmd, (error, stdout, stderr) => {
            if (error) {
                reject(stderr)
            } else {
                resolve(stdout);
            }
        })
    });
}

app.use(express.static('public'));

app.get('/', async function (req, res) {
    const response = {
        imageUrl: 'http://ec2-54-89-61-89.compute-1.amazonaws.com/image.jpg',
        error: null
    };
    try {
        await execSpectrum();
        await clearPublicTmpAssets();
        await copyImageToPublic();
    } catch(error) {
        response.error = error;
    }
    res.send(JSON.stringify(response));
});

app.listen(3000, function () {
    console.log('Example app listening on port 3000!');
});
