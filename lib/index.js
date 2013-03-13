OAuth2 = require('oauth').OAuth2;

function Playlyfe(options) {
  this.options = options;
  this._oauth2 = new OAuth2(options.clientID, options.clientSecret, 'http://playlyfe.com/auth', 'http://playlyfe.com/auth/token', options.customHeaders);
}

// Internal oauth request
Playlyfe.prototype._request = function(method, url, headers, data, accessToken, refreshToken, callback) {
  var self = this;
  this._oauth2._request(method, url, headers, data, accessToken, function(err, result, response) {
    // Perform refresh token flow if error is encountered
    if(err) {
      try {
        err.data = JSON.parse(err.data);
        if( err.data.error === 'invalid_access_token' && refreshToken) {
          //Request new access token
          self._oauth2.getOAuthAccessToken(
            refreshToken,
            { grant_type: 'refresh_token' },
            function(err, newAccessToken, newRefreshToken, results) {
              if (err ) {
                return callback(err);
              } else {
                // Store new access token
                req.session[self.options.clientID + '_playlyfe_access_token'] = newAccessToken;
                req.session[self.options.clientID + '_playlyfe_refresh_token'] = newRefreshToken;
                // Retry with new access token
                self._oauth2._request(method, url, headers, data, newAccessToken, function(err, result, response) {
                  if(err) {
                    try{
                      err.data = JSON.parse(err.data);
                      return callback(err, result, response);
                    } catch (e) {
                      err.error = 'bad_response';
                      return callback(err, result, response);
                    }
                  } else {
                    try {
                      result = JSON.parse(result);
                    } catch (e) {
                      err = { error: 'bad_response', data: result };
                    }
                  }
                  return callback(err, result, response);
                });
              }
            }
          );
        } else {
          return callback(err, result, response);
        }
      } catch (e) {
        console.error(e);
        err.error = 'bad_response';
        return callback(err, result, response);
      }
    } else {
      try {
        result = JSON.parse(result);
        return callback(err, result, response);
      } catch (e) {
        err = { error: 'bad_response', data: result };
        return  callback(err, result, response);
      }
    }
  });
};

// api (url, method, data, callback)
Playlyfe.prototype.api = function(url, method, data, accessToken, refreshToken, callback) {
  var headers = {};
  if(method === 'GET' || method === 'DELETE') {
    data = null;
    self._request(method, 'http://api.playlyfe.com/' + url, headers, data, accessToken, refreshToken, callback);
  } else {
    try {
      data = JSON.stringify(data);
      headers = { 'Content-Type' : 'application/json' };
      self._request(method, 'http://api.playlyfe.com/' + url, headers, data, accessToken, refreshToken, callback);
    } catch (err) {
      callback(err);
    }
  }
};

Playlyfe.prototype.utils = function(req, res) {
  self = this;
  return {
    // api (url, method, data, callback)
    api: function(url, method, data, callback) {
      var accessToken = null, refreshToken = null;
      accessToken = req.session[self.options.clientID + '_playlyfe_access_token'];
      refreshToken = req.session[self.options.clientID + '_playlyfe_refresh_token'];
      if (arguments.length === 2) {
        url = arguments[0];
        method = 'GET';
        data = null;
        callback = arguments[1];
      } else if (arguments.length === 3) {
        url = arguments[0];
        method = arguments[1];
        data = null;
        callback = arguments[2];
      } else if (arguments.length === 4) {
        url = arguments[0];
        method = arguments[1];
        data = arguments[2];
        callback = arguments[3];
      }
      self.api(url, method, data, accessToken, refreshToken, callback);
    },
    logout: function(next) {
      res.redirect('http://playlyfe.com/logout?next='+next);
    }
  };
};

Playlyfe.prototype.connect = function() {
  var self = this;
  return function(req, res, next) {
    req.playlyfe = self.utils(req, res);
    next();
  };
};

module.exports = Playlyfe;
