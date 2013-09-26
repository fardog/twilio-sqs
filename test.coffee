aws = require 'aws-sdk'
nconf = require 'nconf'

nconf.argv().env().file('config.json')

config = {}

# Set up AWS
config.sqs = {}
config.sqs.apiVersion = nconf.get 'AWS_API_VERSION'
config.sqs.accessKeyId = nconf.get 'AWS_ACCESS_KEY_ID'
config.sqs.secretAccessKey = nconf.get 'AWS_ACCESS_KEY_SECRET'
config.sqs.endpoint = nconf.get 'AWS_ENDPOINT_URL'
config.sqs.region = nconf.get 'AWS_REGION'

sqs = new aws.SQS(config.sqs)

message = {}
message.QueueUrl = config.sqs.endpoint
message.MessageBody = "Test Message"

sqs.sendMessage message, (err, data) ->
  if err?
    console.log "there was an error"
    console.log err

  console.log "got data"
  console.log data

