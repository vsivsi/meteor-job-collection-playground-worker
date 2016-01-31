############################################################################
#     Copyright (C) 2015-2016 by Vaughn Iverson
#     This is free software released under the MIT/X11 license.
#     See included LICENSE file for details.
############################################################################

DDP = require 'ddp'
DDPlogin = require 'ddp-login'
Job = require 'meteor-job'

# See DDP package docs for options here...
ddp = new DDP
  host: "jcplayground.meteor.com"
  port: 443
  use_ejson: true
  use_ssl: true

Job.setDDP ddp

ddp.connect (err) ->
  throw err if err

  console.log "Connected!"

  DDPlogin ddp, { method: 'token' }, (err, userInfo) ->
    if not err and userInfo
      console.log "Authenticated as userId: #{userInfo.id}"
      proceed userInfo.id
    else proceed()

proceed = (userId = null) ->
  ddp.subscribe 'allJobs', [userId], () ->
    console.log "allJobs Ready!"

  ddp.subscribe 'clientStats', [userId], () ->
    console.log "clientStats Ready!"


  suffix = if userId then "_#{userId.substr(0,5)}" else ""
  myType = "testJob#{suffix}"
  q = Job.processJobs "queue", myType, { pollInterval: false, workTimeout: 60*1000 }, (job, cb) ->
    count = 0
    console.log "Starting job #{job.doc._id} run #{job.doc.runId}"
    int = setInterval (() ->
      count++
      if count is 20
        clearInterval int
        console.log "Finished job #{job.doc._id} run #{job.doc.runId}"
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

  stats = ddp.observe 'jobStats'

  stats.added = (id) ->
    # console.log "Added: #{id}\n#{JSON.stringify(ddp.collections['queue.jobs'][id])}"
    console.log "Status added: #{JSON.stringify(ddp.collections['jobStats'][id])}"

  stats.changed = (id, oldFields, clearedFields, newFields) ->
    # console.log "Changed: #{id}\n#{JSON.stringify(oldFields)}\n#{clearedFields}\n#{JSON.stringify(newFields)}"
    console.log "Status changed: #{JSON.stringify(ddp.collections['jobStats'][id])}"

  shutdown = (level = 'soft') ->
    console.log "Attempting to shutdown", level
    q.shutdown { level: level }, () ->
      console.log "Shutdown!"
      ddp.close()

  onError = (err) ->
    console.error "Socket error!", err
    shutdown 'hard'

  ddp.on 'socket-error', onError

  onClose = (code, message) ->
    console.warn "Socket closed!", code, message
    obs.stop()
    stats.stop()
    ddp.removeListener 'socket-close', onClose
    ddp.removeListener 'socket-error', onError

  ddp.on 'socket-close', onClose

  process.on 'SIGINT', do () ->
   memory = 0
   return (signum) ->
     console.log "Attempting to shutdown"
     switch memory++
       when 0
         shutdown 'soft'
       when 1
         shutdown 'normal'
       when 2
         shutdown 'hard'
       else
         ddp.close()
         process.exit 1

  process.on 'SIGQUIT', (signum) ->
    shutdown 'normal'

  process.on 'SIGTERM', (signum) ->
    shutdown 'hard'
