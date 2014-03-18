OAuth2 = require 'simple-oauth2'
request = require 'request'
_ = require 'lodash'

class Playlyfe

  constructor: (@options) ->
    @client = OAuth2({
      clientID: @options.client_id
      clientSecret: @options.client_secret
      site: "http://playlyfe.com"
      authorizationPath: "/auth"
      tokenPath: "/auth/token"
    })
    @endpoint = @options.endpoint ? "http://api.playlyfe.com/v1"
    return

  getAuthorizationURI: () ->
    @client.AuthCode.authorizeURL({
      redirect_uri: @options.redirect_uri
      state: Math.random() * 100
    })

  getToken: (code, saveToken) ->
    @client.AuthCode.getToken({
      code: code
      redirect_uri: @options.redirect_uri
    }, (err, result) ->
      if err
        saveToken(err)
      else
        token = result
        token.expires_at = new Date(
          new Date().getTime() + (parseInt(token.expires_in) * 1000)
        )
        saveToken(null, token)
    )

  isAccessTokenExpired: (token) ->
    new Date() > new Date(token.expires_at)

  refreshAccessToken: (token, callback) ->
    if (token.locked)
      token.callbacks.push callback
    else
      token.locked = true
      token.callbacks = [callback]
      @client.AccessToken.create(token).refresh((err, result) ->
        if err
          _.forEach(token.callbacks, (fn) -> fn(err))
          delete token.locked
          delete token.callbacks
        else
          _.forEach(token.callbacks, (fn) -> fn(null, result.token))
          delete token.locked
          delete token.callbacks
      )
    return

  api: (url, method, data = {}, access_token, callback) ->
    data = _.defaults data, {
      qs: {},
      body: {}
    }
    data.qs.access_token = access_token
    if @options.player_id then data.qs.player_id = @options.player_id

    request({
      url: "#{@endpoint}#{url}"
      method: method.toUpperCase()
      qs: data.qs
      headers:
        'Content-Type': 'application/json'
      body: JSON.stringify(data.body)
      encoding: null
    }, callback)
    return

module.exports = Playlyfe
