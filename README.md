### jcPlaygroundWorker

This is a sample app demonstrating a standalone plain node.js worker that can connect to the Meteor hosted [job collection playground server](https://jcplayground.meteor.com) and work on jobs.

To install:

```
git clone https://github.com/vsivsi/meteor-job-collection-playground-worker.git jcpWorker
cd jcpWorker
npm install
```

To run (unauthenticated) simply: `coffee worker.coffee`

To run as an authenticated user:

First, visit https://jcplayground.meteor.com and setup an account.

Next, install the [ddp-login](https://www.npmjs.com/package/ddp-login) npm package:
```
# You may need to run this with sudo
npm install -g ddp-login
```

Now authenticate and stash the login credentials in the environment:
```
# Type the email and password for the account you created above when prompted
export METEOR_TOKEN=$(ddp-login --host jcplayground.meteor.com --port 443 --ssl)
```

Now when the worker starts it can authenticate and work on your private jobs:
```
coffee worker.coffee
```
