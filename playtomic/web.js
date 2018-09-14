require('newrelic');
var express = require("express"),
querystring = require("querystring"),
v1 = require(__dirname + "/v1/router.js");
var config = require(__dirname + "/api/config.js");

if(config.node.socket){
    require(__dirname + '/socket.js');
}

require(__dirname + "/api/database.js"); // to trigger the setup

var app = express();
var router = express.Router();

if (process.env.NODE_ENV === 'development'){
    // route middleware that will happen on every request
    router.use(function(req, res, next) {

        // log each request to the console
        console.log(req.body);

        // continue doing what we were doing and go to the route
        next();
    });
}

// Basic request preparation and stuffing post data into req
var prepareRequests = function(request, response, next) {
    request.ip = request.headers["x-forwarded-for"] || request.connection.remoteAddress;

    // cross-origin request headers
    response.header("Access-Control-Allow-Origin", "*");
    response.header("Access-Control-Allow-Methods", "GET,PUT,POST,DELETE,OPTIONS");
    response.header("Access-Control-Allow-Headers", "X-Requested-With,Content-Type");

    // post data
    if(request.method != "POST" || (request.body)) {
        next();
        return;
    }

    var chunk = "";

    request.on("data", function (data) {
        chunk += data;
    });

    request.on("end", function () {
        request.body = chunk;
        next();
    });
};

var bodyParser = require('body-parser');


// Configuration
if (process.env.NODE_ENV === 'production'){
    process.on("uncaughtException", function (exceptionmessage) {
        console.log("EXCEPTION: \n" + exceptionmessage);
    });
}

// cross domain
var crossdomain = '<?xml version="1.0"?><!DOCTYPE cross-domain-policy SYSTEM "http://www.adobe.com/xml/dtds/cross-domain-policy.dtd"><cross-domain-policy><site-control permitted-cross-domain-policies="master-only" /><allow-access-from domain="*" to-ports="*" secure="false" /><allow-http-request-headers-from domain="*" headers="*" /></cross-domain-policy>';
var XML_HEADER = {"Content-Type": "text/xml"};

router.all("/crossdomain.xml", function(request, response) {
    response.writeHead(200, XML_HEADER);
    response.end(crossdomain);
});

// everything else
router.all("/v1", v1.router);

app.use(prepareRequests);
app.use(bodyParser.urlencoded({extended: true}));
app.use(bodyParser.json());
app.use('/', router);

// start
if(config.node.api){
    var port = config.node.apiport;

    app.listen(port, function() {
        console.log("API Listening on " + port + ", env: " + process.env.NODE_ENV );
    });
}
