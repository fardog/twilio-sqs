###
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
###


express = require 'express'
http = require 'http'
path = require 'path'
twilio = require 'twilio'
nconf = require 'nconf'
aws = require 'aws-sdk'


app = express()

app.set 'port', process.env.PORT || 3000
app.use express.logger('dev')
app.use express.bodyParser()
app.use express.methodOverride()
cookie_secret = (nconf.get 'COOKIE_SECRET') ? 'its a secret to everyone'
app.use express.cookieParser(cookie_secret)
app.use express.session()
app.use app.router

nconf.argv().env().file('config.json')

# Create a configuration object
config = {}

# Set up Twilio
config.twilio = {}
config.twilio.accountSid = nconf.get 'TWILIO_ACCOUNT_SID'
config.twilio.authToken = nconf.get 'TWILIO_AUTH_TOKEN'

# Set up AWS
config.sqs = {}
config.sqs.apiVersion = nconf.get 'AWS_API_VERSION'
config.sqs.accessKeyId = nconf.get 'AWS_ACCESS_KEY_ID'
config.sqs.secretAccessKey = nconf.get 'AWS_ACCESS_KEY_SECRET'
config.sqs.endpoint = nconf.get 'AWS_ENDPOINT_URL'
config.sqs.region = nconf.get 'AWS_REGION'

sqs = new aws.SQS(config.sqs)

app.post '/twiml', (req, res) ->
  if twilio.validateExpressRequest req, config.twilio.authToken
    message = {}
    message.QueueUrl = config.sqs.endpoint
    if not (req.body.Body? or req.body.From?)
      return res.send(400)
    message.MessageBody = req.body.Body + ' [' + req.body.From + ']'
    sqs.sendMessage message, (err, data) ->
      if err?
        console.error err
        return res.send(500)
      else
        return res.send(200)

    res.send(400)
  else
    res.send(403)


(http.createServer(app)).listen app.get('port'), ->
  console.log('Express server listening on port ' + app.get('port'))

