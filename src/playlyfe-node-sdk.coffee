OAuth2 = require 'simple-oauth2'
request = require 'request'
_ = require 'lodash'

class Playlyfe

  constructor: (@options) ->
    @options.type ?= 'code'
    @client = OAuth2({
      clientID: @options.client_id
      clientSecret: @options.client_secret
      site: "https://playlyfe.com"
      authorizationPath: "/auth"
      tokenPath: "/auth/token"
      proxy: @options.proxy
      strictSSL: @options.strictSSL
    })
    @endpoint = @options.endpoint ? "https://api.playlyfe.com/v1"
    return

  getAuthorizationURI: () ->
    switch @options.type
      when 'code'
        @client.AuthCode.authorizeURL({
          redirect_uri: @options.redirect_uri
          state: Math.random() * 100
        })
      else
        throw new Error("No Authorization URI available for this oauth 2 flow")

  getToken: (code, saveToken) ->
    switch @options.type
      when 'code'
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
      when 'client'
        saveToken = code
        @client.Client.getToken({}, (err, result) ->
          if err
            saveToken(err)
          else
            token = result
            token.expires_at = new Date(
              new Date().getTime() + (parseInt(token.expires_in) * 1000)
            )
            saveToken(null, token)
        )
    return

  isAccessTokenExpired: (token) ->
    new Date() > new Date(token.expires_at)

  refreshAccessToken: (token, callback) ->
    switch @options.type
      when 'code'
        @client.AccessToken.create(token).refresh(callback)
      when 'client'
        @client.Client.getToken({}, callback)
    return

  api: (url, method, data = {}, access_token, callback) ->
    data = _.defaults data, {
      qs: {},
      body: {}
    }
    data.qs.access_token = access_token
    if @options.player_id then data.qs.player_id = @options.player_id
    request(_.extend(_.pick(@options, 'proxy', 'auth', 'strictSSL'), {
      url: "#{@endpoint}#{url}"
      method: method.toUpperCase()
      qs: data.qs
      headers:
        'Content-Type': 'application/json'
      body: JSON.stringify(data.body)
      encoding: null
    }), (err, response) ->
      if err
        callback(err)
      else if /application\/json/.test(response.headers['content-type'])
        callback(null, JSON.parse(response.body.toString()), response)
      else if /^image\//.test(response.headers['content-type'])
        callback(null, response.body, response)
      else
        callback(null, response.body, response)
    )
    return

module.exports = Playlyfe
