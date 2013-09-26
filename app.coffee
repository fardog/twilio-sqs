express = require 'express'
http = require 'http'
path = require 'path'
twilio_client = require 'twilio'
nconf = require 'nconf'
aws = require 'aws-sdk'


app = express()

app.set 'port', process.env.PORT || 3000
app.use express.favicon()
app.use express.logger('dev')
app.use express.bodyParser()
app.use express.methodOverride()
app.use express.cookieParser('its a secret to everyone')
app.use express.session()
app.use app.router

nconf.argv().env().file('config.json')

# Create a configuration object
config = {}

# Set up Twilio
config.twilio = {}
config.twilio.accountSid = nconf.get 'TWILIO_ACCOUNT_SID'
config.twilio.authToken = nconf.get 'TWILIO_AUTH_TOKEN'

twilio = new twilio_client(config.twilio.accountSid, config.twilio.authToken)

# Set up AWS
config.sqs = {}
config.sqs.apiVersion = nconf.get 'AWS_API_VERSION'
config.sqs.accessKeyId = nconf.get 'AWS_ACCESS_KEY_ID'
config.sqs.secretAccessKey = nconf.get 'AWS_ACCESS_KEY_SECRET'
config.sqs.endpoint = nconf.get 'AWS_ENDPOINT_URL'
config.sqs.region = nconf.get 'AWS_REGION'

sqs = new aws.SQS(config.sqs)

app.post '/twiml', (res, req) ->
  if twilio_client.validateExpressRequest req, config.twilio.authToken
    # resp = new twilio.TwimlResponse()
    # resp.say 'Hello, Twilio.'

    # res.type 'text/xml'
    # res.send resp.toString()

    # send message to SQS
    message = {}
    message.QueueUrl = config.sqs.endpoint
    message.MessageBody = req.body.body + '[' + req.body.from + ']'
    sqs.sendMessage message, (err, data) ->
      if err?
        console.log err

    res.status(200).send
  else
    res.status(403).send 'Not accepted.'


(http.createServer(app)).listen app.get('port'), ->
  console.log('Express server listening on port ' + app.get('port'))

