Playlyfe = require '../src/playlyfe-node-sdk'
assert = require 'assert'
Promise = require 'bluebird'

Promise.promisifyAll(Playlyfe.prototype)

token = null
player = { player_id: 'student1' };

pl = new Playlyfe({
  type: 'client',
  client_id: "Zjc0MWU0N2MtODkzNS00ZWNmLWEwNmYtY2M1MGMxNGQ1YmQ4",
  client_secret: "YzllYTE5NDQtNDMwMC00YTdkLWFiM2MtNTg0Y2ZkOThjYTZkMGIyNWVlNDAtNGJiMC0xMWU0LWI2NGEtYjlmMmFkYTdjOTI3",
  redirect_uri: 'http://localhost:8080/auth/redirect',
  version: 'v1'
});

pl.getTokenAsync()
.then (tk) ->
  token = tk
  pl.apiAsync('/gege', 'GET', { qs: player, body: {} }, token.access_token)
.spread (response) ->
  assert.equal(response.error, 'route_not_found')
  pl.apiAsync('/player', 'GET', { qs: player, body: {} }, token.access_token)
.spread (player) ->
  assert.equal(player.id, 'student1')
  assert.equal(player.enabled, true)
  pl.apiAsync('/game/players', 'GET', { qs: {}, body: {} }, token.access_token)
.spread (players) ->
  assert(players.data.length > 0)
  Promise.all([
    pl.apiAsync('/definitions/processes', 'GET', { qs: player, body: {} }, token.access_token)
    pl.apiAsync('/definitions/teams', 'GET', { qs: player, body: {} }, token.access_token)
    pl.apiAsync('/processes', 'GET', { qs: player, body: {} }, token.access_token)
    #pl.apiAsync('/teams', 'GET', { qs: player, body: {} }, token.access_token)
  ])
.then ->
  pl.apiAsync('/definitions/processes/module1', 'POST', { qs: player, body: {} }, token.access_token)
.spread (new_process) ->
  assert.equal(new_process.definition, 'module1')
  assert.equal(new_process.state, 'ACTIVE')
  pl.apiAsync("/processes/#{new_process.id}", 'PATCH', { qs: player, body: { name: 'patched_process', access: 'PUBLIC' } }, token.access_token)
.spread (patched_process) ->
  assert.equal(patched_process.name, 'patched_process')
  assert.equal(patched_process.access, 'PUBLIC')
  pl.apiAsync("/processes/#{patched_process.id}", 'DELETE', { qs: player, body: {} }, token.access_token)
.spread (response) ->
  assert(response.message.indexOf('Process') > -1)
.catch (err) ->
  console.log 'ERROR', err
