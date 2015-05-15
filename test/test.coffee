{Playlyfe, PlaylyfeException} = require '../src/playlyfe'
assert = require 'assert'
Promise = require 'bluebird'
jwt = require 'jsonwebtoken'

player = { player_id: 'student1' }
access_token = null
client_id = "Zjc0MWU0N2MtODkzNS00ZWNmLWEwNmYtY2M1MGMxNGQ1YmQ4"
client_secret = "YzllYTE5NDQtNDMwMC00YTdkLWFiM2MtNTg0Y2ZkOThjYTZkMGIyNWVlNDAtNGJiMC0xMWU0LWI2NGEtYjlmMmFkYTdjOTI3"

describe 'The SDK Options and Flow', ->

  it 'should check whether right options are passed', (next) ->
    try
      pl = new Playlyfe({
        client_id: client_id
        client_secret: client_secret
        redirect_uri: 'https://playlyfe.com/mygame'
      })
    catch err
      assert.equal err.message, 'You must pass in type which can be code or client'
      try
        pl = new Playlyfe({
          type: 'code'
          client_id: client_id
          client_secret: client_secret
        })
      catch err
        assert.equal err.message, 'You must pass in a redirect_uri for authoriztion code flow'
        try
          pl = new Playlyfe({
            type: 'code'
            client_id: client_id
            client_secret: client_secret
            redirect_uri: 'https://playlyfe.com/mygame'
          })
        catch err
          assert.equal err.message, 'You must pass in version of the API you would like to use which can be v1 or v2'
          next()

  it 'should reload the access token', (next) ->
    pl = new Playlyfe({
      type: 'client',
      client_id: client_id
      client_secret: client_secret
      version: 'v1'
      store: (token, done) ->
        console.log 'Storing' # Storing is called once
        access_token = token
        done(null, access_token)
      load: (done) ->
        console.log 'Loading'
        done(null, access_token)
    })
    pl.get('/gege', player)
    .catch PlaylyfeException, (err) =>
      assert.equal(err.name, 'route_not_found')
      pl.get('/gege', player)
    .catch PlaylyfeException, (err) =>
      assert.equal(err.name, 'route_not_found')
      next()

  it 'should refresh an access token in client credential flow', (next) ->
    pl = new Playlyfe({
      type: 'client',
      client_id: client_id
      client_secret: client_secret
      version: 'v1'
      store: (token, done) ->
        console.log 'Storing'
        access_token = token
        done(null, access_token)
      load: (done) ->
        console.log 'Loading'
        if access_token? # It calls storing twice since the access token is force expired
          access_token.expires_at = new Date(new Date().getTime() - 50 * 1000)
        done(null, access_token)
    })
    pl.get('/gege', player)
    .catch PlaylyfeException, (err) =>
      assert.equal(err.name, 'route_not_found')
      pl.get('/gege', player)
    .catch PlaylyfeException, (err) =>
      assert.equal(err.name, 'route_not_found')
      next()

  it 'should check the login uri', (next) ->
    pl = new Playlyfe({
      type: 'code',
      client_id: client_id
      client_secret: client_secret
      version: 'v1'
      redirect_uri: 'https://playlyfe.com/mygame'
    })
    assert.equal(
      "https://playlyfe.com/auth?response_type=code&redirect_uri=https%3A%2F%2Fplaylyfe.com%2Fmygame&client_id=Zjc0MWU0N2MtODkzNS00ZWNmLWEwNmYtY2M1MGMxNGQ1YmQ4",
      pl.getAuthorizationURI()
    )
    next()

  it 'should create a jwt token', (next) ->
    token = Playlyfe.createJWT({ client_id: client_id, client_secret: client_secret, player_id: 'student1'})
    try
      decoded = jwt.verify(token, client_secret)
    catch err
      assert.equal(err.name, 'JsonWebTokenError')
      assert.equal(err.message, 'invalid token')
      try
        [cid, token] = token.split(':')
        decoded = jwt.verify(token, 'wrong_secret')
      catch err
        assert.equal(err.name, 'JsonWebTokenError')
        assert.equal(err.message, 'invalid signature')
        decoded = jwt.verify(token, client_secret)
        assert.equal(decoded.player_id, 'student1')
        next()

  it 'should check for expired jwt', (next) ->
    token = Playlyfe.createJWT({ client_id: client_id, client_secret: client_secret, player_id: 'student1', expires: 2 })
    [cid, token] = token.split(':')
    setTimeout( ->
      try
        decoded = jwt.verify(token, client_secret)
      catch err
        assert.equal(err.name, 'TokenExpiredError')
        assert.equal(err.message, 'jwt expired')
        next()
    , 5000)

  it.skip 'should exchange code', (next) ->

  it.skip 'should refresh an access token in authorization code flow', (next) ->
    next()

  it 'should refresh an invalid acccess token', (next) ->
    access_token = { access_token: "ABCDEFD", expires_at: new Date(new Date().getTime() + 86400), expires_in: 86400, type: 'Bearer' }
    pl = new Playlyfe({
      type: 'client',
      client_id: client_id
      client_secret: client_secret
      version: 'v1'
      store: (token, done) ->
        console.log 'Storing'
        access_token = token
        done(null, access_token)
      load: (done) ->
        console.log 'Loading'
        done(null, access_token)
    })
    pl.get('/player', player)
    .then (data) ->
      assert.equal(data.id, 'student1')
      next()

  it.skip 'should refresh an invalid access token in authorization code flow', (next) ->

describe 'The SDK Errors', ->

  before (next) ->
    @pl = new Playlyfe({
      type: 'client',
      client_id: client_id
      client_secret: client_secret
      version: 'v1'
    })
    next()

  it 'should display validation errors', (next) ->
    @pl.get('/assets/players/:gs', player)
    .catch PlaylyfeException, (err) =>
      assert.equal(err.name, 'validation_exception')
      assert.equal(err.message, 'Invalid request')
      assert.equal(err.status, 400)
      assert(err.headers isnt null)
      assert.equal(err.errors.valid, false)
      next()

  it 'should get an error on unknown route', (next) ->
    @pl.get('/gege', player)
    .catch PlaylyfeException, (err) =>
      assert.equal(err.name, 'route_not_found')
      assert.equal(err.message, 'This route does not exist')
      assert.equal(err.status, 404)
      @pl.get('/player', player)
    .then (data) =>
      assert.equal(data.id, 'student1')
      @pl.get("/assets/players/#{player.id}", player)
    .catch PlaylyfeException, (err) =>
      assert.equal(err.name, 'image_not_found')
      assert.equal(err.message, 'The player has no display image')
      assert.equal(err.status, 404)
      @pl.get("/assets/game", player)
    .then (data) =>
      @pl.get("/assets/game", player, true)
    .then (data) =>
      next()

  it 'should get a network error', (next) ->
    @pl.endpoint = "https://google.com"
    @pl.get('/gege', player)
    .catch PlaylyfeException, (err) =>
      console.log 'PlaylyfeException Occured'
    .catch (err) =>
      assert.equal(err.name, 'StatusCodeError')
      assert.equal(err.statusCode, 400)
      @pl.api('GET', '/gege', player)
    .catch PlaylyfeException, (err) =>
      console.log 'PlaylyfeException Occured'
    .catch (err) =>
      assert.equal(err.name, 'StatusCodeError')
      assert.equal(err.statusCode, 400)
      next()

describe 'The v1 API', ->

  before (next) ->
    @pl = new Playlyfe({
      type: 'client',
      client_id: client_id
      client_secret: client_secret
      version: 'v1'
      player_id: 'student1'
    })
    next()

  it 'should read a player profile', (next) ->
    @pl.get('/player')
    .then (player) ->
      assert.equal(player.id, 'student1')
      assert.equal(player.enabled, true)
      next()

  it 'should read all players', (next) ->
    @pl.get('/game/players')
    .then (players) ->
      assert(players.data.length > 0)
      next()

  it 'should read many routes', (next) ->
    Promise.all([
      @pl.get('/definitions/processes')
      @pl.get('/definitions/teams')
      @pl.get('/processes')
      @pl.get('/teams')
    ])
    .then ->
      next()

  it 'should CRUD a process', (next) ->
    @pl.post('/definitions/processes/module1')
    .then (new_process) =>
      assert.equal(new_process.definition, 'module1')
      assert.equal(new_process.state, 'ACTIVE')
      @pl.patch("/processes/#{new_process.id}", {}, { name: 'patched_process', access: 'PUBLIC' })
    .then (patched_process) =>
      assert.equal(patched_process.name, 'patched_process')
      assert.equal(patched_process.access, 'PUBLIC')
      @pl.delete("/processes/#{patched_process.id}")
    .then (response) ->
      assert(response.message.indexOf('Process') > -1)
      next()

describe 'The v2 API', ->

  before (next) ->
    @pl = new Playlyfe({
      type: 'client',
      client_id: client_id
      client_secret: client_secret
      version: 'v2'
    });
    next()

  it 'should read all players', (next) ->
    @pl.get('/admin/players')
    .then (players) ->
      assert(players.data.length > 0)
      next()

  it 'should read many routes', (next) ->
    Promise.all([
      @pl.get('/runtime/definitions/processes', player)
      @pl.get('/runtime/definitions/teams', player)
      @pl.get('/runtime/processes', player)
      @pl.get('/runtime/teams', player)
    ])
    .then ->
      next()

  it 'should CRUD a process', (next) ->
    @pl.post('/runtime/processes', player, { definition: 'module1' })
    .then (new_process) =>
      assert.equal(new_process.definition.id, 'module1')
      assert.equal(new_process.state, 'ACTIVE')
      @pl.patch("/runtime/processes/#{new_process.id}", player, { name: 'patched_process', access: 'PUBLIC' })
    .then (patched_process) =>
      assert.equal(patched_process.name, 'patched_process')
      assert.equal(patched_process.access, 'PUBLIC')
      @pl.delete("/runtime/processes/#{patched_process.id}", player)
    .then (response) ->
      assert(response.message.indexOf('Process') > -1)
      next()

  it 'should create and delete a metric', (next) ->
    @pl.post('/design/versions/latest/metrics', player, {id: 'apple', name: 'apple', type: 'point' })
    .then (metric) =>
      assert.equal(metric.id, 'apple')
      @pl.delete('/design/versions/latest/metrics/apple', player)
    .then (deleted_metric) ->
      assert.equal(deleted_metric.message, "The metric 'apple' has been deleted successfully")
      next()
