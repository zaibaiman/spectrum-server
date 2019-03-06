var express = require('express');
var app = express();
var fs = require('fs');
var path = require('path');
var multer = require('multer')

function base64_encode(filename) {
    return fs.readFileSync(filename, 'base64');
}

async function saveBase64Image(base64Data) {
    return new Promise((resolve, reject) => {
        fs.writeFile("./assets/sample.jpg", base64Data, 'base64', function(err) {
            if (err) reject(err);
            else resolve();
        });
    })
}

async function createDataView(xLens, yLens, xPer, yPer) {
    return new Promise((resolve, reject) => {
        const exec = require("child_process").exec
        const cmd = `echo '{"xLens":${xLens}, "yLens":${yLens}, "xPer":${xPer}, "yPer":${yPer}}' > assets/view.json`;
        exec(cmd, (error, stdout, stderr) => {
            if (error) {
                reject(stderr)
            } else {
                resolve(stdout);
            }
        })
    })
}

async function compileTemplate(xLens, yLens, xPer, yPer) {
    return new Promise((resolve, reject) => {
        const exec = require("child_process").exec
        const cmd = `./node_modules/mustache/bin/mustache assets/view.json assets/app.m > assets/app2.m`;
        exec(cmd, (error, stdout, stderr) => {
            if (error) {
                reject(stderr)
            } else {
                resolve(stdout);
            }
        })
    })
}

async function execSpectrum() {
    return new Promise((resolve, reject) => {
        const exec = require("child_process").exec
        const cmd = `docker run --rm -v $(pwd)/assets:/source -w /source --entrypoint octave zaibaiman/spectrum /source/app2.m`;
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
app.use(express.json());
app.use(express.urlencoded());

var storage = multer.diskStorage({
    destination: function (req, file, cb) {
        cb(null, 'assets/');
    },
    filename: function (req, file, cb) {
        cb(null, `sample.${file.originalname.split('.').pop()}`);
    }
})
// var upload = multer({ dest: 'uploads/' });
var upload = multer({ storage: storage });

app.post('/', upload.single('pictureFile'), async function(req, res) {
    console.log(req.file);
    console.log(req.body);
    const response = {
        imageUrl: 'http://ec2-54-89-61-89.compute-1.amazonaws.com/image.jpg',
        error: null
    };
    try {
        await createDataView(req.body['xLens'], req.body['yLens'], req.body['xPer'], req.body['yPer']);
        await compileTemplate();
        await execSpectrum();
        await clearPublicTmpAssets();
        await copyImageToPublic();
    } catch (error) {
        response.error = error;
    }

    if (response.error) {
        res.send(JSON.stringify(response));
    } else {
        res.redirect('/results.html');
    }
});

app.post('/api/process', async function(req, res) {
    let statusCode = 200;
    try {
        await saveBase64Image(req.body.image);
        await createDataView(100, 100, 50, 50);
        await compileTemplate();
        await execSpectrum();
        await clearPublicTmpAssets();
        await copyImageToPublic();
    } catch (error) {
        statusCode = 500;
    }

    res.sendStatus(statusCode);
});

app.listen(3000, function () {
    console.log('Example app listening on port 3000!');
});
