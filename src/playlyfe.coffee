request = require 'request-promise'
Promise = require 'bluebird'
_ = require 'lodash'

class Playlyfe

  constructor: (@options) ->
    if _.isUndefined @options then throw new Error('You must pass in options')
    if _.isUndefined @options.type then throw new Error('You must pass in type which can be code or client')
    if not _.contains(['code', 'client'], @options.type) then throw new Error('You must pass in type which can be code or client')
    if @options.type is 'code'
      if _.isUndefined @options.redirect_uri then throw new Error('You must pass in a redirect_uri for authoriztion code flow')
    if _.isUndefined @options.version then throw new Error( 'You must pass in version of the API you would like to use which can be v1 or v2')
    @code = null
    @refresh_token = null
    @options.strictSSL ?= true
    @options.store ?= (access_token) =>
      @access_token = access_token
      Promise.resolve()
    @options.load ?= =>
      Promise.resolve(@access_token)
    return

  getAuthorizationURI: ->
    "https://playlyfe.com/auth?#{require("querystring").stringify({response_type: 'code', redirect_uri: @options.redirect_uri, client_id: @options.client_id })}"

  makeRequest: (url, method, query, body, raw=false) ->
    request({
      url: url
      method: method.toUpperCase()
      qs: query
      headers: 'Content-Type': 'application/json'
      body: JSON.stringify(body)
      strictSSL: @options.strictSSL
      encoding: 'utf8'
      json: not raw
    })
    .catch (err) ->
      if typeof err.response?.body is 'object'
        Promise.reject(err.response.body)
      else
        Promise.reject(err)

  makeTokenRequest: (body) ->
    @makeRequest('https://playlyfe.com/auth/token', 'POST', {}, body)
    .then (token) =>
      token.expires_at = new Date(new Date().getTime() + (parseInt(token.expires_in) * 1000))
      @options.store(token)
      .then ->
        Promise.resolve(token)

  getAccessToken: (code) ->
    body = {
      client_id: @options.client_id
      client_secret: @options.client_secret
      grant_type: 'client_credentials'
    }
    if @options.type is 'code'
      body.grant_type = 'authorization_code'
      body.redirect_uri = @options.redirect_uri
      if code?
        body.code = code
        @makeTokenRequest(body)
      else
        body.grant_type = 'refresh_token'
        @options.load()
        .then (token) =>
          body.refresh_token = token.refresh_token
          @makeTokenRequest(body)
    else
      @makeTokenRequest(body)

  api: (method, url, query = {}, body = {}, raw=false, cb=null) ->
    if @options.player_id then query.player_id = @options.player_id
    @options.load()
    .then (token) =>
      unless token?
        @getAccessToken()
      else if new Date() > new Date(token.expires_at)
        @getAccessToken()
      else
        Promise.resolve(token)
    .then (token) =>
      query.access_token = token.access_token
      if cb?
        @makeRequest("https://api.playlyfe.com/#{@options.version}#{url}", method, query, body, raw).nodeify(cb)
      else
        @makeRequest("https://api.playlyfe.com/#{@options.version}#{url}", method, query, body, raw)

  get: (url, query, raw, cb) -> @api('GET', url, query, {}, raw, cb)
  post: (url, query, body, cb) -> @api('POST', url, query, body, false, cb)
  patch: (url, query, body, cb) -> @api('PATCH', url, query, body, false, cb)
  put: (url, query, body, cb) -> @api('PUT', url, query, body, false, cb)
  delete: (url, query, cb) -> @api('DELETE', url, query, {}, false, cb)

module.exports = Playlyfe
