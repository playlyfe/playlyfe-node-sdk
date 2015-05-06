![Playlyfe Node SDK](./images/pl-node-sdk.png "Playlyfe Node SDK")

Playlyfe Node SDK [![NPM version](https://badge.fury.io/js/playlyfe-node-sdk.svg)](http://badge.fury.io/js/playlyfe-node-sdk)
=================

Playlyfe API implementation in NodeJS. This module integrates seamlessly with the [passport-playlyfe](https://github.com/playlyfe/passport-playlyfe) module for authentication support.

Visit the complete [API reference](http://dev.playlyfe.com/docs/api)

To learn more about how you can build applications on Playlyfe visit the [official developer documentation](http://dev.playlyfe.com)

##Install
To get started simply run

```
npm install playlyfe-node-sdk
```

# Documentation
You can initiate a client by giving the client_id and client_secret params
```js
new Playlyfe({
    type: 'client' or 'code',
    client_id: 'Your client id',
    client_secret: 'Your client Secret',
    version: 'v1',
    redirect_uri: 'The url to redirect to', //only for auth code flow
    store: function() {}, // The lambda which will persist the access token to a database. You have to persist the token to a database if you want the access token to remain the same in every request
    load: function() {}, // The lambda which will load the access token. This is called internally by the sdk on every request so the 
    //the access token can be persisted between requests
    strictSSL: true
})
```

In development the sdk caches the access token in memory so you dont need to provide the store and load functions. But in production it is highly recommended to persist the token to a database. It is very simple and easy to do it with redis. You can see the test cases for more examples.

**API**
All these methods return a bluebird Promise if you don't pass a callback.

```js
api(method, route, query, body, raw, callback)
```
**Get**
```js
get(route, query, body, raw, callback)
```
**Post**
```js
post(route, query, body, callback)
```
**Patch**
```js
patch(route, query, body, callback)
```
**Put**
```js
put(route, query, body, callback)
```
**Delete**
```js
post(route, query, callback)
```
**Get Login Url**
```js
getAuthorizationURI()
//This will return the url to which the user needs to be redirected for the user to login. You can use this directly in your views.
```

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
