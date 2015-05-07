request = require 'request-promise'
Promise = require 'bluebird'
_ = require 'lodash'

class PlaylyfeException extends Error

  constructor: (@name, @message, @status = 500, @errors) ->
    Error.call @
    Error.captureStackTrace @, @constructor
    return

  handle: (res) ->
    error =
      error: @name
      error_description: @message
    if @errors?
      error.data = @errors
    res.statusCode = @status
    res.body = error
    res.status(@status).json error
    return

class Playlyfe

  constructor: (@options) ->
    if _.isUndefined @options then throw new Error('You must pass in options')
    if _.isUndefined @options.type then throw new Error('You must pass in type which can be code or client')
    if not _.contains(['code', 'client'], @options.type) then throw new Error('You must pass in type which can be code or client')
    if @options.type is 'code' and _.isUndefined @options.redirect_uri then throw new Error('You must pass in a redirect_uri for authoriztion code flow')
    if _.isUndefined @options.version then throw new Error( 'You must pass in version of the API you would like to use which can be v1 or v2')
    @options.strictSSL ?= true
    @options.store ?= (access_token) =>
      @access_token = access_token
      Promise.resolve()
    @options.load ?= =>
      Promise.resolve(@access_token)
    @endpoint = "https://api.playlyfe.com/#{@options.version}"
    return

  getAuthorizationURI: ->
    "https://playlyfe.com/auth?#{require("querystring").stringify({response_type: 'code', redirect_uri: @options.redirect_uri, client_id: @options.client_id })}"

  makeRequest: (method, url, query, body, cb) ->
    data = {
      url: url
      method: method.toUpperCase()
      qs: query
      strictSSL: @options.strictSSL
      encoding: 'utf8'
      json: true
    }
    if body?
      data.body = body
    request(data)
    .catch (err) =>
      if typeof err.response?.body is 'object' and err.response.body.error?
        if err.response.body.error is 'invalid_access_token'
          @getAccessToken()
          .then =>
            @api(method, url.replace(@endpoint, ''), query, body, cb)
        else
          Promise.reject(new PlaylyfeException(err.response.body.error, err.response.body.error_description, err.response.statusCode))
      else
        Promise.reject(err)

  makeProxy: (method, url, query, body, cb) ->
    request({
      url: url
      method: method.toUpperCase()
      qs: query
      headers: 'Content-Type': 'application/json'
      body: JSON.stringify(body)
      strictSSL: @options.strictSSL
      encoding: null
      resolveWithFullResponse: true
    })
    .then (response) ->
      Promise.resolve(response)
    .catch (err) =>
      if typeof err.response?.body
        try
          json = JSON.parse(err.response.body.toString())
          if json.error?
            if json.error is 'invalid_access_token'
              @getAccessToken()
              .then =>
                @apiProxy(method, url.replace(@endpoint, ''), query, body, cb)
            else
              Promise.reject(new PlaylyfeException(json.error, json.error_description, err.response.statusCode))
          else
            Promise.reject(err)
        catch
          Promise.reject(err)
      else
        Promise.reject(err)

  makeTokenRequest: (body) ->
    @makeRequest('POST', 'https://playlyfe.com/auth/token', {}, body)
    .then (token) =>
      token.expires_at = new Date(new Date().getTime() + (parseInt(token.expires_in) * 1000))
      @options.store(token)
      .then ->
        Promise.resolve(token)

  exchangeCode: (code) ->
    @getAccessToken(code)

  getAccessToken: (code) ->
    body = {
      client_id: @options.client_id
      client_secret: @options.client_secret
      grant_type: 'client_credentials'
    }
    if @options.type is 'code'
      @options.load()
      .then (token) =>
        if token?
          body.grant_type = 'refresh_token'
          body.refresh_token = token.refresh_token
          @makeTokenRequest(body)
        else
          body.grant_type = 'authorization_code'
          body.redirect_uri = @options.redirect_uri
          body.code = code
        @makeTokenRequest(body)
    else
      @makeTokenRequest(body)

  checkAccessToken: (query) ->
    if @options.player_id then query.player_id = @options.player_id
    @options.load()
    .then (token) =>
      unless token?
        if @options.type is 'code'
          Promise.reject(error: "Initialize the Authorization Code Flow by exchanging the code")
        else
          @getAccessToken()
      else if new Date() > new Date(token.expires_at)
        @getAccessToken()
      else
        Promise.resolve(token)
    .then (token) =>
      query.access_token = token.access_token
      Promise.resolve()

  api: (method, url, query = {}, body = {}, cb=null) ->
    @checkAccessToken(query)
    .then =>
      if cb?
        @makeRequest(method, "#{@endpoint}#{url}", query, body, cb).nodeify(cb)
      else
        @makeRequest(method, "#{@endpoint}#{url}", query, body)

  apiProxy: (method, url, query = {}, body = {}, cb=null) ->
    @checkAccessToken(query)
    .then =>
      if cb?
        @makeProxy(method, "#{@endpoint}#{url}", query, body, cb).nodeify(cb)
      else
        @makeProxy(method, "#{@endpoint}#{url}", query, body)

  get: (url, query, cb) -> @api('GET', url, query, null, cb)
  post: (url, query, body, cb) -> @api('POST', url, query, body, cb)
  patch: (url, query, body, cb) -> @api('PATCH', url, query, body, cb)
  put: (url, query, body, cb) -> @api('PUT', url, query, body, cb)
  delete: (url, query, cb) -> @api('DELETE', url, query, null, cb)

module.exports = {
  Playlyfe: Playlyfe
  PlaylyfeException: PlaylyfeException
}
