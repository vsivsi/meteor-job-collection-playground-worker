DDP = require 'ddp'
DDPlogin = require 'ddp-login'
Job = require 'meteor-job'
 
# See DDP package docs for options here... 
ddp = new DDP
  host: "jcplayground.meteor.com"
  port: 80
  use_ejson: true
 
Job.setDDP ddp
 
ddp.connect (err) ->
  throw err if err

  console.log "Connected!"

  q = Job.processJobs "queue", "testJob", { pollInterval: 1000 }, (job, cb) ->
     count = 0
     int = setInterval (() ->
        count++
        if count is 20
           clearInterval int
           console.log "Done!"
           job.done()
           cb()
        else
           job.progress count, 20, (err, res) ->
              console.log "Progress: #{100*count/20}%"
              if err or not res
                 clearInterval int
                 job.fail('Progress update failed', () -> cb())
     ), 500
 
  # DDPlogin ddp, (err, token) ->
  #   throw err if err 
  
