Playlyfe Node SDK
=================

Playlyfe API implementation in NodeJS. This module integrates seamlessly with the [passport-playlyfe](https://github.com/playlyfe/passport-playlyfe) module for authentication support.

Visit the complete [API reference](http://dev.playlyfe.com/docs/api)

To learn more about how you can build applications on Playlyfe visit the [official developer documentation](http://dev.playlyfe.com)


##Install
To get started simply run

```
npm install playlyfe-node-sdk
```

##Synopsis

```javascript
express = require('express');
Playlyfe = require('playlyfe-node-sdk')

// Put in your application details here.
var config = {
  client_id: 'YOUR CLIENT ID',
  client_secret: 'YOUR CLIENT SECRET',
  redirect_uri: 'http://localhost:8080/auth/redirect'
};

client = new Playlyfe(config);

app = express();
app.use(express.cookieParser());
app.use(express.session({ secret: 'TOP_SECRET' }));
app.use(express.static(__dirname+"/public"));
app.use(app.router);
app.use(express.logger());
app.use(express.errorHandler());

var auth = function (req, res, next) {
  if (req.session.logged_in) {
    return next();
  } else {
    return res.redirect(client.getAuthorizationURI());
  }
};

// start playlyfe oauth authorization code flow
app.get('/auth', auth, function (req, res) {
  return res.redirect('/home');
});

// get access token and save it
app.get('/auth/redirect', function (req, res) {
  if (req.query.code !== null) {
    client.getToken(req.query.code, function(err, token) {
      if (err) return res.json(500, err);
      req.session.auth = token;
      req.session.logged_in = true;
      res.redirect('/api/player');
    });
  } else {
    res.redirect('/api/player');
  }
});

// Proxy requests to playlyfe server.
// We keep the access token away from cheaters by using the authorization code flow.
app.all('/api/*', auth, function(req, res) {
  res.header("Cache-Control", "no-cache, no-store, must-revalidate");
  res.header("Pragma", "no-cache");
  res.header("Expires", 0);
  client.api(
    '/' + req.params[0],
    req.route.method.toUpperCase(),
    { qs: req.query, body: req.body },
    req.session.auth.token.access_token,
    function(err, response, body) {
      for (header in response.headers) {
        res.header(header, response.headers[header]);
      }
      res.end(body);
    }
  );
});

app.get('/logout', auth, function (req, res) {
  req.session.logged_in = false;
  delete req.session.auth;
  res.redirect('/');
});

app.listen(8080);
```

## Methods

### constructor (options)
The options object contains the configuration options for your playlyfe application.
These values can be found in the clients menu in the game builder on the [Playlyfe Platform](http://playlyfe.com).

    {
      clientID: 'YOUR_CLIENT_ID',
      clientSecret: 'YOUR_CLIENT_SECRET',
      redirectURI: 'REDIRECT_URI'
    }

The redirect URI must match exactly with any of the registered redirect endpoints or the oauth flow will fail.

### getAuthorizationURI
Get the Authorization URI for the app. 

### getToken (code, saveTokenFunction)
Exchange the Authorization Code for Access Token.

### api (url, method, data, access_token, callback)
Executes an API call. This method differs from the request helper in requiring the accessToken and refreshToken to be manually provided. Visit the complete [API reference](http://dev.playlyfe.com/docs/api)

## License

    Playlyfe NodeJS SDK v0.0.1
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

