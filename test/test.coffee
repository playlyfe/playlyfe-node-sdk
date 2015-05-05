Playlyfe = require '../src/playlyfe-node-sdk'
assert = require 'assert'
Promise = require 'bluebird'

player = { player_id: 'student1' }
access_token = null

describe 'The SDK', ->

  it 'should reload the access token', (next) ->
    pl = new Playlyfe({
      type: 'client',
      client_id: "Zjc0MWU0N2MtODkzNS00ZWNmLWEwNmYtY2M1MGMxNGQ1YmQ4",
      client_secret: "YzllYTE5NDQtNDMwMC00YTdkLWFiM2MtNTg0Y2ZkOThjYTZkMGIyNWVlNDAtNGJiMC0xMWU0LWI2NGEtYjlmMmFkYTdjOTI3",
      redirect_uri: 'http://localhost:8080/auth/redirect',
      version: 'v1'
      store: (token) ->
        console.log 'Storing' # Storing is called only once
        access_token = token
        Promise.resolve(access_token)
      load: ->
        console.log 'Loading', access_token
        Promise.resolve(access_token)
    })
    pl.get('/gege', player)
    .catch (err) ->
      assert.equal(err.error, 'route_not_found')
      pl.get('/gege', player)
    .catch (err) ->
      assert.equal(err.error, 'route_not_found')
      next()

  it 'should refresh an access token in client credential flow', (next) ->
    pl = new Playlyfe({
      type: 'client',
      client_id: "Zjc0MWU0N2MtODkzNS00ZWNmLWEwNmYtY2M1MGMxNGQ1YmQ4",
      client_secret: "YzllYTE5NDQtNDMwMC00YTdkLWFiM2MtNTg0Y2ZkOThjYTZkMGIyNWVlNDAtNGJiMC0xMWU0LWI2NGEtYjlmMmFkYTdjOTI3",
      redirect_uri: 'http://localhost:8080/auth/redirect',
      version: 'v1'
      store: (token) ->
        console.log 'Storing'
        access_token = token
        Promise.resolve(access_token)
      load: ->
        console.log 'Loading', access_token
        if access_token? # It calls storing twice since the access token is force expired
          access_token.expires_at = new Date(new Date().getTime() - 50 * 1000)
        Promise.resolve(access_token)
    })
    pl.get('/gege', player)
    .catch (err) ->
      assert.equal(err.error, 'route_not_found')
      pl.get('/gege', player)
    .catch (err) ->
      assert.equal(err.error, 'route_not_found')
      next()

describe 'The v1 API', ->

  before (next) ->
    @pl = new Playlyfe({
      type: 'client',
      client_id: "Zjc0MWU0N2MtODkzNS00ZWNmLWEwNmYtY2M1MGMxNGQ1YmQ4",
      client_secret: "YzllYTE5NDQtNDMwMC00YTdkLWFiM2MtNTg0Y2ZkOThjYTZkMGIyNWVlNDAtNGJiMC0xMWU0LWI2NGEtYjlmMmFkYTdjOTI3",
      redirect_uri: 'http://localhost:8080/auth/redirect',
      version: 'v1'
    });
    next()

  it 'should get an error on unknown route', (next) ->
    @pl.get('/gege', player)
    .catch (err) ->
      assert.equal(err.error, 'route_not_found')
      next()

  it 'should read a player profile', (next) ->
    @pl.get('/player', player)
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
      @pl.get('/definitions/processes', player)
      @pl.get('/definitions/teams', player)
      @pl.get('/processes', player)
      @pl.get('/teams', player)
    ])
    .then ->
      next()

  it 'should CRUD a process', (next) ->
    @pl.post('/definitions/processes/module1', player)
    .then (new_process) =>
      assert.equal(new_process.definition, 'module1')
      assert.equal(new_process.state, 'ACTIVE')
      @pl.patch("/processes/#{new_process.id}", player, { name: 'patched_process', access: 'PUBLIC' })
    .then (patched_process) =>
      assert.equal(patched_process.name, 'patched_process')
      assert.equal(patched_process.access, 'PUBLIC')
      @pl.delete("/processes/#{patched_process.id}", player)
    .then (response) ->
      assert(response.message.indexOf('Process') > -1)
      next()

describe 'The v2 API', ->

  before (next) ->
    @pl = new Playlyfe({
      type: 'client',
      client_id: "Zjc0MWU0N2MtODkzNS00ZWNmLWEwNmYtY2M1MGMxNGQ1YmQ4",
      client_secret: "YzllYTE5NDQtNDMwMC00YTdkLWFiM2MtNTg0Y2ZkOThjYTZkMGIyNWVlNDAtNGJiMC0xMWU0LWI2NGEtYjlmMmFkYTdjOTI3",
      redirect_uri: 'http://localhost:8080/auth/redirect',
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
