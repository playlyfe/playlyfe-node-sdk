request = require 'request-promise'
Promise = require 'bluebird'
_ = require 'lodash'
jwt = require 'jsonwebtoken'

class PlaylyfeException extends Error

  constructor: (@name, @message, @status = 500, @headers, errors) ->
    if errors?
      @errors = errors
    Error.call @
    Error.captureStackTrace @, @constructor
    return

  toJSON: ->
    error =
      error: @name
      error_description: @message
    if @errors?
      error.data = @errors
    return error

class Playlyfe

  @createJWT: (options) ->
    {client_id, client_secret, player_id, scopes, expires} = options
    scopes ?= []
    expires ?= 3600
    payload = { player_id: player_id, scopes: scopes }
    token = jwt.sign(payload, client_secret, { algorithm: 'HS256', expiresInSeconds: expires })
    token = "#{client_id}:#{token}"
    token

  constructor: (@options) ->
    if _.isUndefined @options then throw new Error('You must pass in options')
    if _.isUndefined @options.type then throw new Error('You must pass in type which can be code or client')
    if not _.contains(['code', 'client'], @options.type) then throw new Error('You must pass in type which can be code or client')
    if @options.type is 'code' and _.isUndefined @options.redirect_uri then throw new Error('You must pass in a redirect_uri for authoriztion code flow')
    if _.isUndefined @options.version then throw new Error( 'You must pass in version of the API you would like to use which can be v1 or v2')
    @options.strictSSL ?= true
    @options.store ?= (access_token, done) =>
      @access_token = access_token
      done(null, @access_token)
    @options.load ?= (done) =>
      done(null, @access_token)
    @endpoint = "https://api.playlyfe.com/#{@options.version}"
    return

  _done: (err, result) ->
    if err
      Promise.reject(err)
    else
      Promise.resolve(result)

  getAuthorizationURI: ->
    "https://playlyfe.com/auth?#{require("querystring").stringify({response_type: 'code', redirect_uri: @options.redirect_uri, client_id: @options.client_id })}"

  makeRequest: (method, url, query, body, full_response = false) ->
    data = {
      url: url
      method: method.toUpperCase()
      qs: query
      headers: {
        'content-type': 'application/json'
      }
      body: JSON.stringify(body)
      strictSSL: @options.strictSSL
      encoding: null
      resolveWithFullResponse: true
    }
    request(data)
    .then (response) ->
      if /application\/json/.test(response.headers['content-type'])
        res_body = JSON.parse(response.body.toString())
      else
        res_body = response.body
      if full_response
        Promise.resolve({
          headers: response.headers
          status: response.statusCode
          body: response.body
        })
      else
        Promise.resolve(res_body)
    .catch (err) =>
      if err.response? and /application\/json/.test(err.response.headers['content-type'])
        res_body = JSON.parse(err.response.body.toString())
        if res_body.error is 'invalid_access_token'
          @getAccessToken()
          .then =>
            @api(method, url.replace(@endpoint, ''), query, body, full_response)
        else
          Promise.reject(new PlaylyfeException(res_body.error, res_body.error_description, err.response.statusCode, err.response.headers, res_body.data))
      else
        Promise.reject(err)

  makeTokenRequest: (body) ->
    @makeRequest('POST', 'https://playlyfe.com/auth/token', {}, body)
    .then (token) =>
      token.expires_at = new Date(new Date().getTime() + (parseInt(token.expires_in) * 1000))
      @options.store(token, @_done)
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
      @options.load(@_done)
      .then (token) =>
        if token?
          body.grant_type = 'refresh_token'
          body.refresh_token = token.refresh_token
        else
          body.grant_type = 'authorization_code'
          body.redirect_uri = @options.redirect_uri
          body.code = code
        @makeTokenRequest(body)
    else
      @makeTokenRequest(body)

  checkAccessToken: (query) ->
    if @options.player_id then query.player_id = @options.player_id
    @options.load(@_done)
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

  api: (method, url, query = {}, body = {}, full_response = false) ->
    @checkAccessToken(query)
    .then =>
      @makeRequest(method, "#{@endpoint}#{url}", query, body, full_response)

  get: (url, query, full_response) -> @api('GET', url, query, null, full_response)
  post: (url, query, body, full_response) -> @api('POST', url, query, body, full_response)
  patch: (url, query, body, full_response) -> @api('PATCH', url, query, body, full_response)
  put: (url, query, body, full_response) -> @api('PUT', url, query, body, full_response)
  delete: (url, query, full_response) -> @api('DELETE', url, query, null, full_response)
  upload: (url, query, formData, full_response) ->
    data = {
      url: @endpoint + url
      qs: query
      strictSSL: @options.strictSSL
      encoding: null
      resolveWithFullResponse: true
      formData: formData
    }
    @checkAccessToken(query)
    .then =>
      request.post(data)
    .then (response) ->
      if /application\/json/.test(response.headers['content-type'])
        res_body = JSON.parse(response.body.toString())
      else
        res_body = response.body
      if full_response
        Promise.resolve({
          headers: response.headers
          status: response.statusCode
          body: response.body
        })
      else
        Promise.resolve(res_body)
    .catch (err) =>
      if err.response? and /application\/json/.test(err.response.headers['content-type'])
        res_body = JSON.parse(err.response.body.toString())
        if res_body.error is 'invalid_access_token'
          @getAccessToken()
          .then =>
            @api(method, url.replace(@endpoint, ''), query, body, full_response)
        else
          Promise.reject(new PlaylyfeException(res_body.error, res_body.error_description, err.response.statusCode, err.response.headers, res_body.data))
      else
        Promise.reject(err)

module.exports = {
  Playlyfe: Playlyfe
  PlaylyfeException: PlaylyfeException
}
