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

  ddp.subscribe 'allJobs', [null], () ->
    console.log "allJobs Ready!"
    # console.log ddp.collections

  q = Job.processJobs "queue", "testJob", { pollInterval: 100000000 }, (job, cb) ->
     count = 0
     console.log "Starting job #{job.doc._id}"
     int = setInterval (() ->
        count++
        if count is 20
           clearInterval int
           console.log "Finished job #{job.doc._id}"
           job.done()
           cb()
        else
           job.progress count, 20, (err, res) ->
              console.log "Progress: #{100*count/20}%"
              if err or not res
                 clearInterval int
                 job.fail('Progress update failed', () -> cb())
     ), 500

  obs = ddp.observe 'queue.jobs'

  obs.added = (id) ->
    # console.log "Added: #{id}\n#{JSON.stringify(ddp.collections['queue.jobs'][id])}"
    if ddp.collections['queue.jobs'][id].status is 'ready'
      console.log "Triggering queue, added"
      q.trigger()

  obs.changed = (id, oldFields, clearedFields, newFields) ->
    # console.log "Changed: #{id}\n#{JSON.stringify(oldFields)}\n#{clearedFields}\n#{JSON.stringify(newFields)}"
    if newFields.status is 'ready'
      console.log "Triggering queue, changed"
      q.trigger()

  # DDPlogin ddp, (err, token) ->
  #   throw err if err

