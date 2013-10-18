/*
Copyright (c) 2013 Nathan Wittstock

Permission is hereby granted, free of charge, to any person obtaining a copy of
this software and associated documentation files (the "Software"), to deal in
the Software without restriction, including without limitation the rights to
use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of
the Software, and to permit persons to whom the Software is furnished to do so,
subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS
FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR
COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER
IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN
CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
*/


(function() {
  var app, aws, config, cookie_secret, express, fs, http, nconf, net, path, port, server, shutdown, sqs, twilio, unlinking, _ref;

  express = require('express');

  http = require('http');

  net = require('net');

  fs = require('fs');

  path = require('path');

  twilio = require('twilio');

  nconf = require('nconf');

  aws = require('aws-sdk');

  nconf.argv().env().file('config.json');

  app = express();

  port = process.env.PORT || 3000;

  app.set('port', port);

  app.use(express.logger('dev'));

  app.use(express.bodyParser());

  app.use(express.methodOverride());

  cookie_secret = (_ref = nconf.get('COOKIE_SECRET')) != null ? _ref : 'its a secret to everyone';

  app.use(express.cookieParser(cookie_secret));

  app.use(express.session());

  app.use(app.router);

  config = {};

  config.twilio = {};

  config.twilio.accountSid = nconf.get('TWILIO_ACCOUNT_SID');

  config.twilio.authToken = nconf.get('TWILIO_AUTH_TOKEN');

  config.sqs = {};

  config.sqs.apiVersion = nconf.get('AWS_API_VERSION');

  config.sqs.accessKeyId = nconf.get('AWS_ACCESS_KEY_ID');

  config.sqs.secretAccessKey = nconf.get('AWS_ACCESS_KEY_SECRET');

  config.sqs.endpoint = nconf.get('AWS_ENDPOINT_URL');

  config.sqs.region = nconf.get('AWS_REGION');

  sqs = new aws.SQS(config.sqs);

  app.post('/twiml', function(req, res) {
    var error, message;
    if (twilio.validateExpressRequest(req, config.twilio.authToken)) {
      message = {};
      message.QueueUrl = config.sqs.endpoint;
      console.log(req.body);
      try {
        message.MessageBody = req.body.Body + ' [' + req.body.From + ']';
      } catch (_error) {
        error = _error;
        console.error(error);
        res.send(400);
        process.exit(1);
      }
      return sqs.sendMessage(message, function(err, data) {
        if (err != null) {
          console.error(err);
          return res.send(500);
        } else {
          return res.send(200);
        }
      });
    } else {
      return res.send(403);
    }
  });

  server = http.createServer(app);

  unlinking = false;

  shutdown = function() {
    console.log('shutting down');
    return server.close();
  };

  process.on('SIGINT', shutdown);

  server.on('error', function(e) {
    var clientSocket, data;
    if (parseInt(port)) {
      console.error('port is in use: ' + port);
      process.exit(1);
    }
    if (e.code === 'EADDRINUSE') {
      clientSocket = new net.Socket();
      clientSocket.on('error', function(e) {
        if (e.code === 'ECONNREFUSED' && unlinking === false) {
          unlinking = true;
          fs.unlink(port, function(e) {
            return console.log('error unlinking file');
          });
          return server.listen(port, function() {
            return console.log('server recovered');
          });
        } else {
          return console.log('already unlinking');
        }
      });
      return clientSocket.connect((data = {
        path: port
      }), function() {
        console.log('server running, giving up...');
        return process.exit(1);
      });
    }
  });

  server.listen(port, function() {
    return console.log('Express server is running. Listening at: ' + port);
  });

}).call(this);
