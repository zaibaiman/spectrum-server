var express = require('express');
var app = express();

app.get('/', function (req, res) {
    const exec = require("child_process").exec
    exec("ls", (error, stdout, stderr) => {
        res.send(stdout);
    })
});

app.listen(3000, function () {
    console.log('Example app listening on port 3000!');

    // const { spawnSync } = require( 'child_process' ),
    // ls = spawnSync( 'ls', [ '-lh', '/usr' ] );
    // console.log( `stderr: ${ls.stderr.toString()}` );
    // console.log( `stdout: ${ls.stdout.toString()}` );

    // const exec = require("child_process").exec
    // exec("ls", (error, stdout, stderr) => {
    //     console.log(stdout);
    // })
});
