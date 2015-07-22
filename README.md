![Playlyfe Node SDK](https://dev.playlyfe.com/images/assets/pl-node-sdk.png "Playlyfe Node SDK")

Playlyfe Node SDK [![NPM version](https://badge.fury.io/js/playlyfe.svg)](https://www.npmjs.com/package/playlyfe)
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
If you haven't created a client for your game yet just head over to [Playlyfe](http://playlyfe.com) and login into your account, and go to the game settings and click on client.

## 1. Client Credentials Flow
In the client page select Yes for both the first and second questions
![client](https://cloud.githubusercontent.com/assets/1687946/7930229/2c2f14fe-0924-11e5-8c3b-5ba0c10f066f.png)
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
You just need to create a new Playlyfe Client and then make calls using it.
## 2. Authorization Code Flow
In the client page select yes for the first question and no for the second
![auth](https://cloud.githubusercontent.com/assets/1687946/7930231/2c31c1fe-0924-11e5-8cb5-73ca0a002bcb.png)
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

## 3. Custom Login Flow using JWT(JSON Web Token)
In the client page select no for the first question and yes for the second
![jwt](https://cloud.githubusercontent.com/assets/1687946/7930230/2c2f2caa-0924-11e5-8dcf-aed914a9dd58.png)
```js
var token = Playlyfe.createJWT({
    client_id: 'your client_id', 
    client_secret: 'your client_secret', 
    player_id: 'johny', // The player id associated with your user
    scopes: ['player.runtime.read', 'player.runtime.write'], // The scopes the player has access to
    expires: 3600; // 1 hour
})
```
This is used to create jwt token which can be created when your user is authenticated. This token can then be sent to the frontend and or stored in your session. With this token the user can directly send requests to the Playlyfe API as the player.

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
        //This function which will persist the access token to a database.
        //You  have to persist the token to a database if you want the access
        //token to remain the same in every request
        done(null, access_token);
    }, 
    load: function(done) {
        //This function which will load the access token. This is called 
        //internally by the sdk on every request so the the access token can 
        //be  persisted between requests
       done(null, access_token);
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
        .then(function(access_token) {
            done(null, access_token);
        });
    }, 
    load: function(done) {
        redis.hmgetall("access_token")
        .then(function(access_token) {
            done(null, access_token);
        });
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

**upload (url, query, formData, full_response)**  
This will upload any formData you want to send to the server like files, images etc.
Files need to be sent as streams like this,
`upload("/runtime/player/image", req.query, {file: fs.createReadStream(path) })`
This uses the [request](https://github.com/request/request) library so the pattern should be the same

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
Playlyfe NodeJS SDK v0.4.2  
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
