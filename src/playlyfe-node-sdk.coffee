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
    }, (err, result) =>
      if err
        saveToken(err)
      else
        token = @client.AccessToken.create(result)
        saveToken(null, token)
    )

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
