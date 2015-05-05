request = require 'request-promise'
Promise = require 'bluebird'
_ = require 'lodash'

class Playlyfe

  constructor: (@options) ->
    @options.type ?= 'code'
    @options.version ?= 'v2'
    @options.store ?= (access_token) =>
      @access_token = access_token
      Promise.resolve()
    @options.load ?= =>
      Promise.resolve(@access_token)
    return

  getAuthorizationURI: ->
    switch @options.type
      when 'code'
        @client.AuthCode.authorizeURL({
          redirect_uri: @options.redirect_uri
          state: Math.random() * 100
        })
      else
        throw new Error("No Authorization URI available for this oauth 2 flow")

  getAccessToken: (code) ->
    request({
      url: 'https://playlyfe.com/auth/token'
      method: 'POST'
      qs: {}
      body: {
        client_id: @options.client_id
        client_secret: @options.client_secret
        grant_type: 'client_credentials'
      }
      strictSSL: true
      json: true
      encoding: 'utf8'
    })
    .then (token) =>
      token.expires_at = new Date(new Date().getTime() + (parseInt(token.expires_in) * 1000))
      @options.store(token)
      .then ->
        Promise.resolve(token)
    # switch @options.type
    #   when 'code'
    #     key = 'AuthCode'
    #     params = {
    #       code: code
    #       redirect_uri: @options.redirect_uri
    #     }
    #   when 'client'
    #     key = 'Client'
    #     params = {}
    # @client[key].getToken(params)
    # .then (token) ->
    #
    #   @options.store(token)

  api: (url, method, query = {}, body = {}) ->
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
      @makeRequest(url, method, query, body)

  get: (url, query) ->
    @api(url, 'GET', query)

  post: (url, query, body) ->
    @api(url, 'POST', query, body)

  patch: (url, query, body) ->
    @api(url, 'PATCH', query, body)

  put: (url, query, body) ->
    @api(url, 'PUT', query, body)

  delete: (url, query) ->
    @api(url, 'DELETE', query)

  makeRequest: (url, method, query, body, raw=false) ->
    request({
      url: "https://api.playlyfe.com/#{@options.version}#{url}"
      method: method.toUpperCase()
      qs: query
      headers: 'Content-Type': 'application/json'
      body: JSON.stringify(body)
      strictSSL: true
      encoding: 'utf8'
      json: not raw
    })
    .catch (err) ->
      if typeof err.response?.body is 'object'
        Promise.reject(err.response.body)
      else
        Promise.reject(err)

module.exports = Playlyfe
