![Playlyfe Node SDK](./images/pl-node-sdk.png "Playlyfe Node SDK")

Playlyfe Node SDK [![NPM version](https://badge.fury.io/js/playlyfe-node-sdk.svg)](http://badge.fury.io/js/playlyfe-node-sdk)
=================

Playlyfe API implementation in NodeJS. This module integrates seamlessly with the [passport-playlyfe](https://github.com/playlyfe/passport-playlyfe) module for authentication support.

Visit the complete [API reference](http://dev.playlyfe.com/docs/api)

To learn more about how you can build applications on Playlyfe visit the [official developer documentation](http://dev.playlyfe.com)

##Install
To get started simply run

```sh
npm install playlyfe
```

The Playlyfe class allows you to make rest api calls like GET, POST, .. etc
```js
var Playlyfe = require('playlyfe').Playlyfe;
var PlaylyfeException = require('playlyfe').PlaylyfeException;
var pl = new Playlyfe({
    type: 'client'
    version: 'v1',
    client_id: "Your client id",
    client_secret: "Your client secret"
});

// To get infomation of the player johny
pl.get('/player',{ player_id: 'johny' }) 
.then(function(player) {
    console.log(player);
})
.catch(PlaylyfeException, function(err) {
    console.log('Name', err.name);
    console.log('Message', err.message);
    console.log('Status', err.status);
})
.catch(function(err) {
    console.log(err);
    console.log(err.response);
});

pl.post("/definitions/processes/collect", { 'player_id': 'johny' }, { 'name': 'My First Process' })
.then(function(process) {
    console.log(process);
});

```

## Usage
### Create a client
  If you haven't created a client for your game yet just head over to [Playlyfe](http://playlyfe.com) and login into your account, and go to the game settings and click on client
  **1.Client Credentials Flow**
    In the client page click on whitelabel client
    ![Creating a Whitelabel Client](./images/client.png "Creating a Whitelabel Client")

  **2.Authorization Code Flow**
    In the client page click on backend client and specify the redirect uri this will be the url where you will be redirected to get the token
    ![Creating a Backend Client](./images/auth.png "Creating a Backend Client")

And then note down the client id and client secret you will need it later for using it in the sdk

## 1. Client Credentials Flow
A typical express application should contain something like this
```js
var Playlyfe = require('playlyfe').Playlyfe;
var PlaylyfeException = require('playlyfe').PlaylyfeException;
var pl = new Playlyfe({
    type: 'client'
    version: 'v1',
    client_id: "Your client id",
    client_secret: "Your client secret"
});
```
## 2. Authorization Code Flow
```js
var Playlyfe = require('playlyfe').Playlyfe;
var PlaylyfeException = require('playlyfe').PlaylyfeException;
var pl = new Playlyfe({
    type: 'code'
    version: 'v1',
    client_id: "Your client id",
    client_secret: "Your client secret",
    redirect_uri: 'https://playlyfe.com/redirect'
});
```

In this Flow you need to pass in the authorization code to the sdk by calling 
```js 
exchangeCode(code)
```
atleast once. After this you can make any requests as the user has to be authenticated first.


# Documentation
You can initiate a client by giving the client_id and client_secret params
```js
var Playlyfe = require('playlyfe').Playlyfe;
var PlaylyfeException = require('playlyfe').PlaylyfeException;
var pl = new Playlyfe({
    type: 'client' or 'code',
    client_id: 'Your client id',
    client_secret: 'Your client Secret',
    version: 'v1',
    redirect_uri: 'The url to redirect to', //only for auth code flow
    store: function(access_token, done) {
        // The function which will persist the access token to a database. You have to persist the token to a database if you want the access token to remain the same in every request
        done(null, access_token)
    }, 
    load: function(done) {
        // The function which will load the access token. This is called internally by the sdk on every request so the the access token can be persisted between requests
       done(null, access_token)
    }
});
```

In development the sdk caches the access token in memory so you dont need to provide the store and load functions. But in production it is highly recommended to persist the token to a database. It is very simple and easy to do it with redis. You can see the test cases for more examples.

```js
var Playlyfe = require('playlyfe').Playlyfe;
var PlaylyfeException = require('playlyfe').PlaylyfeException;
var redis = require('ioredis');

var pl = new Playlyfe({
    type: 'client' or 'code',
    client_id: 'Your client id',
    client_secret: 'Your client Secret',
    version: 'v1',
    store: function(access_token, done) {
        redis.hmset("access_token", access_token)
        .then (access_token) ->
            done(null, access_token)
    }, 
    load: function(done) {
        redis.hmgetall("access_token")
        .then (access_token) ->
            done(null, access_token)
    }
});
```

## Methods
All these methods return a bluebird Promise.
All these methods return the request data only when full_response is false
but return `headers`, `status`, `body` of the response when full_response is true.

**api (method, route, query, body, full_response = false)**
This will allow you to make any HTTP method request to the Playlyfe API

**get (route, query, full_response = false)**
This will make a GET request to the Playlyfe API

**post (route, query, body, full_response = false)**
This will make a POST request to the Playlyfe API

**patch (route, query, body, full_response = false)**
This will make a PATCH request to the Playlyfe API

**put (route, query, body, full_response = false)**
This will make a PUT request to the Playlyfe API

**delete (route, query, full_response = false)**
This will make a DELETE request to the Playlyfe API

**getAuthorizationURI ()**
This will return the url to which the user needs to be redirected to login.
This doesn't need

**exchangeCode (code)**
This is used in the auth code flow so that the sdk can get the access token.
Before any request to the playlyfe api is made this has to be called atleast once.This should be called in the the route/controller which you specified in your redirect_uri.

**PlaylyfeException**  
This is thrown whenever an error occurs in each call. The Error contains the `name`, `message`, `status`, `headers` and `data` fields which can be used to determine the type of error that occurred.

License
=======
Playlyfe NodeJS SDK v0.4.0  
http://dev.playlyfe.com/  
Copyright(c) 2013-2014, Playlyfe IT Solutions Pvt. Ltd, support@playlyfe.com  

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in
all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
THE SOFTWARE.
