url = require('url')

class StashApi
  constructor: (@options) ->
    @request = require('request')
    @logger = @options.logger || {
      log: (level, msg) -> console.log("#{level}: #{msg}")
      info: (msg) -> @log('INFO', msg)
      debug: (msg) -> @log('DEBUG', msg)
      error: (msg) -> @log('ERROR', msg)
    }

  makeUri: (pathname, basePath="rest/api/#{@options.apiVersion}/") ->
    uri = url.format(
      protocol: @options.protocol
      hostname: @options.host
      port: @options.port
      pathname: basePath + pathname
      )
    uri

  pullRequests: (projectKey, repositorySlug, callback) ->
    options = {
      uri: @makeUri("projects/#{projectKey}/repos/#{repositorySlug}/pull-requests")
      auth: {
        user: @options.username
        pass: @options.password
      }
      method: 'GET'
    }

    @request(options, (error, response, body) ->
      if (response.statusCode == 404)
        callback('Couldnt projectKey/repositorySlug combo.')
        return

      if (response.statusCode != 200)
        callback(response.statusCode + ': Unable to connect to Stash')
        return

      callback(null, JSON.parse(body))
    )

module.exports = exports = StashApi