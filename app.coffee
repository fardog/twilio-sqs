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
    message.MessageBody = req.body.body + '[' + req.body.from + ']'
    sqs.sendMessage message, (err, data) ->
      if err?
        console.log err

    res.send(200)
  else
    res.send(403)


(http.createServer(app)).listen app.get('port'), ->
  console.log('Express server listening on port ' + app.get('port'))

