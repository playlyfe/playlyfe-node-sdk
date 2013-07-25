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

###Use with passport-playlyfe module

This is the recommended way to go for most users. For a complete example implementation check out the sample [Playlyfe Express Application](https://github.com/playlyfe/playlyfe-express-app)


    express = require('express');
    passport = require('passport');
    PlaylyfeOAuth2Strategy = require('passport-playlyfe');
    Playlyfe = require('playlyfe-node-sdk');

    // Put in your application details here.
    var config = {
      clientID: 'CLIENT_ID',
      clientSecret: 'CLIENT_SECRET',
      redirectURI: 'REDIRECT_URI'
    };

    app = express();
    app.use(express.cookieParser());
    app.use(express.session({ secret: 'TOP_SECRET' }));
    app.use(passport.initialize());
    app.use(passport.session());

    // use playlyfe middleware
    app.use(new Playlyfe(config).connect());

    app.use(app.router);
    app.use(express.errorHandler());

    passport.use(new PlaylyfeOAuth2Strategy(config, function(accessToken, refreshToken, profile, done) {
      // Custom application code goes here
      done(null, profile);
    }));

    passport.serializeUser(function(user, done) {
      done(null, user);
    });

    passport.deserializeUser(function(user, done) {
      done(null, user);
    });

    // we render a simple login link on the home route
    app.get('/', function(req, res) {
      res.send('<a href="/auth">Login</a>');
    })

    // start playlyfe oauth authorization code flow
    app.get('/auth', passport.authenticate('playlyfe'), function(req, res, next) {
      // redirect to player profile if successful.
      res.redirect('/api/me');
    }, function(err, req, res, next) {
      res.json(err);
    });

    // Proxy requests to playlyfe server.
    // We keep the access token away from cheaters by using the authoirization code flow.
    // This can be integrated with the Playlyfe Javascript SDK to provide secure transparent endpoint for browser clients.

    app.all('/api/*', function(req, res) {
      res.header("Cache-Control", "no-cache, no-store, must-revalidate");
      res.header("Pragma", "no-cache");
      res.header("Expires", 0);
      req.playlyfe.api(
        '/' + req.params[0],
        req.route.method.toUpperCase(),
        req.body,
        function(err, result, response) {
          if(err) {
            if(err.error === 'bad_response') {
              return res.send(err.statusCode, 'An error occured while contacting playlyfe.com');
            } else {
              return res.json(err.statusCode, err.data);
            }
          }
          res.json(result);
        }
      );
    });

    app.get('/logout', function (req, res) {
      req.logout();
      req.playlyfe.logout('http://games.playlyfe.com/pomodoro');
    });

    app.listen(3000);

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

### connect()

Returns a connect style middleware which attaches a helper function on every incoming request.


### api (url, method, data, accessToken, refreshToken, callback)
Executes an API call. This method differs from the request helper in requiring the accessToken and refreshToken to be manually provided. Visit the complete [API reference](http://dev.playlyfe.com/docs/api)

### utils (req, res)
Attaches helper methods to a request object for easier access within routes.

## Request Helper Methods

These methods are attached to the request object and can be accessed inside application routes using the playlyfe key on the request.

####Example
    Playlyfe = require('playlyfe-node-sdk')
    ...
    ...
    app.use(Playlyfe.connect(config));
    ...
    ...
    app.get('/logout', function(req, res) {
       req.playlyfe.logout('http://www.google.com');
    }


### api (url, method, data, callback)
Executes an API call. Visit the complete [API reference](http://dev.playlyfe.com/docs/api)

### logout(next)
Logout the user from Playlyfe and then redirect to the provided 'next' url.

## License

    Playlyfe NodeJS SDK v0.0.1
    http://dev.playlyfe.com/
    Copyright(c) 2013-2014, Playlyfe Technologies, developers@playlyfe.com

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

