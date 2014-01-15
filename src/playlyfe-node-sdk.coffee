{OAuth2} = require 'oauth'

class Playlyfe
  constructor: (@options) ->
    @options.version or= 'v1'
    @_oauth2 = new OAuth2(@options.clientID, @options.clientSecret,
      'http://playlyfe.com',
      '/auth',
      '/auth/token',
      @options.customHeaders
    )
    return

  _request: (method, url, headers, data, accessToken, refreshToken, callback) ->
    @_oauth2._request method, url, headers, data, accessToken,
      (err, result, response) =>
        # Perform refresh token flow if an error is encountered
        if err and @options.redirectURI?
          try
            err.data = JSON.parse err.data
            if err.data.error is 'invalid_access_token' and refreshToken
              # Request a new refresh token
              @_oauth2.getOAuthAccessToken(refreshToken, {
                grant_type: 'refresh_token'
              }, (err, newAccessToken, newRefreshToken, results) =>
                if err
                  @clearTokens @options.clientID
                  try
                    err.data = JSON.parse err.data
                    return callback(err, result, response)
                  catch e
                    return callback(err)
                else
                  # Store new access token
                  @storeTokens(
                    @options.clientID,
                    newAccessToken,
                    newRefreshToken
                  )
                  # Retry with a new access token
                  @_oauth2._request(method, url, headers, data, newAccessToken,
                    (err, result, response) ->
                      if err
                        try
                          err.data = JSON.parse err.data
                          return callback(err, result, response)
                        catch e
                          err.error = 'bad_response'
                          return callback(err, result, response)
                      else
                        try
                          result = JSON.parse result
                        catch e
                          err = { error: 'bad_response', data: result }
                      return callback(err, result, response)
                  )
                  return
              )
            else
              return callback(err, result, response)
          catch e
            err.error = 'bad_response'
            return callback(err, result, response)

        else if (err)
          # Perform client credentials flow
          @_oauth2.getOAuthAccessToken('', {
            client_id: @options.clientID
            client_secret: @options.clientSecret
            grant_type: 'client_credentials'
          }, (err, newAccessToken) =>
            if err
              @clearTokens @options.clientID
              return callback(err)
            else
              @storeTokens(@options.clientID, newAccessToken)
              # Retry with new access token
              @_oauth2._request(method, url, headers, data, newAccessToken,
                (err, result, response) ->
                  if err
                    try
                      err.data = JSON.parse err.data
                      return callback(err, result, response)
                    catch e
                      err.error = 'bad_response'
                      return callback(err, result, response)
                  else
                    try
                      result = JSON.parse(result)
                    catch e
                      err = {error: 'bad_response', data: result}
                  return callback(err, result, response)
              )
              return
          )
        else
          try
            if /^image\//.test response.headers['content-type']
              return callback(err, result, response)
            result = JSON.parse result
            return callback(err, result, response)
          catch e
            err = {error: 'bad_response', data: result}
            return callback(err, result, response)
    return

  api: (url, method, data, accessToken, refreshToken, callback) ->
    headers = {}
    if method in ['GET', 'DELETE']
      data = null
      @_request(
        method,
        "http://api.playlyfe.com/#{@options.version}#{url}",
        headers,
        data,
        accessToken,
        refreshToken,
        callback
      )
    else
      try
        data = JSON.stringify(data)
        headers =
          'Content-Type': 'application/json'
        @_request(
          method,
          "http://api.playlyfe.com/#{@options.version}#{url}",
          headers,
          data,
          accessToken
          refreshToken
          callback
        )
      catch err
        callback err
    return

  utils: (req, res) ->
    api: (url, method, data, callback) =>
      {accessToken, refreshToken} = @getTokens(@options.clientID)
      switch arguments.length
        when 2
          [url, callback] = arguments
          method = 'GET'
          data = null
        when 3
          [url, method, callback] = arguments
          data = null
        when 4
          [url, method, data, callback] = arguments
      @api(url, method, data, accessToken, refreshToken, callback)

    logout: (next) ->
      res.redirect("http://playlyfe.com/logout?next=#{next}")

  connect: ->
    (req, res, next) =>
      req.playlyfe = @utils(req, res)
      next()

module.exports = Playlyfe
