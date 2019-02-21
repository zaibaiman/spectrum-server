var express = require('express');
var app = express();
var fs = require('fs');

function base64_encode(filename) {
    return fs.readFileSync(filename, 'base64');
}

app.use(express.static('public'));

app.get('/', function (req, res) {
    const response = {
        imageUrl: '',
        message: null,
        error: null
    };
    const exec = require("child_process").exec
    exec("ls", (error, stdout, stderr) => {
        response.imageUrl = `${req.originalUrl} + /image.jpg`;
        response.message = stdout;
        response.error = stderr;
        res.send(JSON.stringify(response));
    })
});

app.listen(3000, function () {
    console.log('Example app listening on port 3000!');
    var base64str = base64_encode('./assets/image.jpg');
    console.log(base64str);
});
