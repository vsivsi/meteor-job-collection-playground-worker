### jcPlaygroundWorker

This is a sample app demonstrating a standalone plain node.js worker that can connect to the Meteor hosted [job collection playground server](http://jcplayground.meteorapp.com) and work on jobs.

To install:

```
git clone https://github.com/vsivsi/meteor-job-collection-playground-worker.git jcpWorker
cd jcpWorker
npm install
```

To run (unauthenticated) simply: `coffee worker.coffee`

To run as an authenticated user:

First, visit [http://jcplayground.meteorapp.com](http://jcplayground.meteorapp.com) and setup an account.

Now authenticate and stash the login credentials in the environment:
```
# Type the email and password for the account you created above when prompted
export METEOR_TOKEN=$(./node_modules/ddp-login/bin/ddp-login --host jcplayground.meteorapp.com --port 80)
```

Now when the worker starts it will authenticate using the token from the environment to work on your private jobs:
```
coffee worker.coffee
```
