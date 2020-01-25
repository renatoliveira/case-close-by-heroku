# Close case app

This repository contains the code for two applications: one is a Salesforce simple configuration and another is a Heroku-based Python application that is used by Salesforce and external consumers.

The goal is to provide an easy to understand example of how one can leverage the Heroku platform as a simple service to detect if the user clicked a link, and use this action to automatically close a case on Salesforce (as in a "close the case" button in an email, for example).

## Basic idea

Whenever a case is created on Salesforce, it will have its own ID, starting with `500`. When we send an email to a customer, it will contain a link labeled "close the case" which will point to the Heroku app. The link will contain the org's Id and the case's Id (in a similar way as the thread Id used by Salesforce itself). When clicked, a HTTP request will be sent to the Heroku server running our Python application. The Heroku application will then connect to the Salesforce org and check if the case exists. Then it will close it and redirect the user to another page we specify.

## The Heroku App

The Heroku app should be as dumb as possible. It just needs to connect to the Salesforce org using OAuth 2 and make a request to a custom Apex endpoint (because we don't want business logic in this dumb app).

### OAuth 2 Token Example (Web Server Flow)

The Heroku app uses the OAuth 2.0 web server flow because the application will need to connect to our Salesforce instance even when we are not looking (offline access and refresh token) or online.

The `token_example.py` shows how the OAuth 2.0 workflow works on obtaining the tokens required for further access (the `refresh_token` and `access_token`).

#### `token_example.py` output sample:

```
$ close-case-url-example python3 herokuapp/main.py
INFO:root:Client ID: 3MVG9PE4xB9wtoY.__W7rYBRsZNVvMgFUA0do4jUzKBKhgY4LUIVZJxH.jkJloq2hLGiB5tk6hNQEAfvQxVux
INFO:root:Client Secret: 4F332C7B12138FFE8895EEA5032376F354659459BEF17077E894FF398D98899F
INFO:root:Client Refresh Token: https://login.salesforce.com/
https://test.salesforce.com/services/oauth2/authorize?response_type=code&client_id=3MVG9PE4xB9wtoY.__W7rYBRsZNVvMgFUA0do4jUzKBKhgY4LUIVZJxH.jkJloq2hLGiB5tk6hNQEAfvQxVux&redirect_uri=https%3A%2F%2Flogin.salesforce.com%2F&scope=refresh_token+api+web&state=zBLzYlNdCMQFLpVicKPICr4UsQBauy
Enter callback URL: https://login.salesforce.com/?code=aPrxj7Ryaw0lCYJFH0gR8OH.GXPBgduXjVXJVQ4GcwjJjnPhpII5vgrihTmQF0FILhQJcxy2aQ%3D%3D&state=zBLzYlNdCMQFLpVicKPICr4UsQBauy
INFO:root:Refresh token: {'access_token': '00D3D000000AZjy!AQ4AQLoqwuGDhtugo8Oz.9GKjq8tW1Y0S80cCIA0titUgO7Pn_ITuXnQE0t84xTvf2awB.QFMs1v1SmQ3AZZXi_BCWvsOr9K', 'refresh_token': '5Aep861OeIX6GiNvi1fM7xt1MTTftnkgIRSGJSiO3D65H_0IgH258Io0VmDUbZ6fbeuOA3jhIUqM1rAh0hrEXNz', 'signature': 'KPF77AGB8EmUh6rbFMDL9O9GbtvtEWFLor4itBIYTno=', 'scope': ['refresh_token', 'web', 'api'], 'instance_url': 'https://innovation-nosoftware-1915-dev-ed.cs70.my.salesforce.com', 'id': 'https://test.salesforce.com/id/00D3D000000AZjyUAG/0053D000002i6QMQAY', 'token_type': 'Bearer', 'issued_at': '1579918634792'}
<Response [200]>
```

But this is just an example of how things work, running in your computer. We want to set this up in a way that the tokens are persisted in our server (on Heroku or any other provider). Only doing this will ensure that the application can keep calling Salesforce over and over again without the need of reauthentication. For this, the Heroku application will have a special endpoint called "authorize" in which the administrator will be able to log in. Same logic in `token_example.py` will be used, but instead of displaying the URL on a terminal, the admin will be **redirected**. And instead of relying on them to paste the callback URL content, the callback will call the application itself, which will process it and appropriately redirect the user right after (or display an error message).

NOTE: This app is not production-ready! This repository is meant to be just an example on how to lay the basic structure. In a real world scenario you'd want to host this with a paid Heroku dyno and store the tokens in a database (such as a PostgreSQL or Redis).

### Configuration

The app can be configured with the following environment variables:

|var|description|
|---|---|
|SF_CLIENT_ID|Your org's Connected App's Client ID|
|SF_CLIENT_SECRET|Your org's Connected App's Client Secret|
|SF_CLIENT_REDIRECT_URI|The URL that the authorization server will post the authorization token (in this case: the URL in which Salesforce will post the authorization info, such as the refresh and access tokens)|
|SF_ENV|The environment that this is running. The default is `login` and if running with a sandbox, this should be changed to `test` (as in the login URL, `https://[login|test].salesforce.com`)|
|PORT|The port in which the app will run in production. Heroku has its own value for this variable, so you don't need to do anything with it. By default the server runs on port 8080 when run from a terminal.|

### Before running the server

Get your org's credentials (username and password) in a place where you can easily access. When the app is restarted it forgets the tokens and you need to restart the process.

With a scratch org, it really helps to use the `sfdx force:user:display` command:

![display user info][user_display]

Now it is easy to get the username, password and other information that might be useful while debugging.

### Run the server locally

To run the Flask server, just use the following command:

```shell
python3 herokuapp/server.py
```

It will start the server on port 8080 in your machine.

### Usage

The app, when started, will know nothing about your Salesforce application (except from the clients Id and Secret). You'll have to hit `/authorize` in your browser (or on the Heroku server) to authenticate with Salesforce. When this URL is accessed, the app will redirect the browser to Salesforce's login URL (the "authorization screen"). After the input of the user's credentials, the callback URL will be hit (`/token` in this case) and the access token, refresh token and the instance's full URL will be stored in global variables (instead of a database - remember: this isn't production-ready).

Thinking just a little bit about security, the server script also deletes the `access_token` and `refresh_token` entries from Salesforce's response, as seen below:

![success obtaining the token!][token_success]

If one needs/wants the tokens to be displayed, just remove the `del` lines at lines 75 and 76 of `server.py`.

Every time your application is restarted (if you modify the `.py` file or restart the server) the credentials will be lost and you'll need to do the login process once again.

### The "close the case" route ("/<org id>/<record id>")

For this application the URL to close the cases is defined at line 80 of `server.py`. It receives the org's Id and the case's Id in a similar way the thread ID works for cases in the standard Salesforce application. The org's Id isn't validated, nor the "reason" parameter of the request is used for now. On line 93 there is a string assigned to this attribute as an example if a developer wanted to assign that content to a custom field on the case (in this case, just edit the wrapper class in Apex to add the attribute as needed, and then copying its value to the case record).

After updating the case on Salesforce, the application returns a `CloseCaseResult` and one can even optionally redirect the user to another page (the class has the `redirect_url` pointing to Google's home page as example). This is a great UX for when the user clicks on a link in one of your emails and then lands in your home page or - even better - on a page that is made specially to display a "thank you" message.

![case update success!][case_update_success]

## The Salesforce App

The Salesforce app should contain the logic used by consumer (the endpoint that the Heroku app will call). This way we can also modify other things on the case as necessity arises. The Salesforce app isn't an app per se, it is more of a single web service.

# Sources

https://oauthlib.readthedocs.io/en/latest/oauth2/server.html#oauth2-0-provider-flows
https://medium.com/@darutk/the-simplest-guide-to-oauth-2-0-8c71bd9a15bb
https://requests-oauthlib.readthedocs.io/en/latest/oauth2_workflow.html#web-application-flow
https://trailhead.salesforce.com/en/content/learn/projects/build-a-connected-app-for-api-integration/implement-the-oauth-20-web-server-authentication-flow
https://help.salesforce.com/articleView?id=remoteaccess_oauth_web_server_flow.htm&type=5
https://flask.palletsprojects.com/en/1.1.x/quickstart/

[case_update_success]: images/case_update_success.png
[token_success]: images/token_success.png
[user_display]: images/user_display.png
