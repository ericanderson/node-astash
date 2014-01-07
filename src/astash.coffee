url = require('url')
_ = require('underscore')
Q = require 'q'

###
Includes all content from /rest/api/1.0/projects/{projectKey}/repos/{repositorySlug}/pull-requests/{pullRequestId}
as well as some additional methods
###
class StashPullRequest
  ###
  @param [Stash] _stash a properly configured stash instance
  @param [Object] details the results from a REST request for a pull request
  ###
  constructor: (@_stash, details) ->
    for key, value of details
      this[key] = value

    @project = @toRef.repository.project.name
    @repositorySlug = @toRef.repository.slug

  ###
  @return [String] a usable name for referencing this PR
  ###
  shortName: ->
    return "#{@toRef.repository.project.name}/#{@toRef.repository.slug}/#{@id}"

  ###
  Attempts to merge this pull request

  @return [Promise] a promise for the merge call
  ###
  attemptMerge: ->
    @_stash.mergePullRequest(@project, @repositorySlug, @id, @version)

  ###

  @return [Promise] a promise that provides a true or a false
  ###
  canMerge: ->
    @_stash.canMergePullRequest(@project, @repositorySlug, @id)

httpError = (statusCode, originalBody) ->
  error = new Error("Http error code #{statusCode}")
  error.statusCode = statusCode
  error.originalBody = originalBody
  error.name = "HttpError"
  console.log originalBody
  return error

class Stash
  ###
  @param [Object] options the stash options
  @option options [String] protocol http or https
  @option options [String] host
  @option options [Number] port port to connect to
  @option options [String] username
  @option options [String] password
  @option options [String] ca a ca certificate or an array of certs for verifying https
  @option options [Object] logger an object that accepts a call to log(level, msg...)
  ###
  constructor: (@options) ->
    @request = require('request')
    @_requestPool = {maxSockets: 5}
    @logger = @options.logger || {
      log: (level, msg...) -> console.log("#{level}: #{msg}")
    }

  ###
  @private
  ###
  _makeUri: (pathname) ->
    uri = url.format({
      protocol: @options.protocol
      hostname: @options.host
      port: @options.port
      pathname: pathname
    })

  ###
  @private
  ###
  _createRequestOptions: (method, uri, options={}) ->
    defaultOptions = {
      uri: @_makeUri(uri)
      auth: {
        user: @options.username
        pass: @options.password
      }
      method: method
      ca: @options.ca
      pool: @_requestPool
    }

    return _.extend({}, defaultOptions, options)

  ###
  @private
  ###
  _restRequest: (options, successCodes=[200]) ->
    deferred = Q.defer()
    @logger.log('debug', "#{options.method} #{options.uri}", {qs: options.qs})
    logger = @logger
    @request(options, (error, response, body) ->
      return deferred.reject(error) if error?

      if response.statusCode not in successCodes
        return deferred.reject(httpError(response.statusCode, body))

      return deferred.resolve() unless body
      deferred.resolve(JSON.parse(body))
    )
    deferred.promise

  ###
  @private
  ###
  _pagedRequest: (options, callback, wrapperClass = null) ->
    options.deferred ?= Q.defer()
    options.collectedPromises ?= []
    self = @
    @_restRequest(options)
    .then((body) ->
      for value in body.values
        value = new wrapperClass(self, value) if wrapperClass?
        options.collectedPromises.push(callback(value))

      if body.isLastPage
        options.deferred.resolve(Q.all(options.collectedPromises))
      else
        options.qs ?= {}
        options.qs.start = body.nextPageStart
        options.qs.limit = body.limit
        self._pagedRequest(options, callback, wrapperClass)
    )
    .fail((error) ->
      options.deferred.reject(error)
    ).done()

    return options.deferred.promise

  canMergePullRequest: (projectKey, repositorySlug, pullRequestId) ->
    @_restRequest(
      @_createRequestOptions(
        'GET',
        "rest/api/1.0/projects/#{projectKey}/repos/#{repositorySlug}/pull-requests/#{pullRequestId}/merge",
      )
    )

  eachPullRequest: (projectKey, repositorySlug, callback) ->
    options = @_createRequestOptions(
      'GET',
      "rest/api/1.0/projects/#{projectKey}/repos/#{repositorySlug}/pull-requests",
      {qs: {limit: 6}}
    )

    @_pagedRequest(options, callback, StashPullRequest)

  pullRequests: (projectKey, repositorySlug) ->
    @_restRequest(
      @_createRequestOptions(
        'GET',
        "rest/api/1.0/projects/#{projectKey}/repos/#{repositorySlug}/pull-requests",
        {qs: {limit: 3}}
      )
    )

  mergePullRequest: (projectKey, repositorySlug, pullRequestId, version = -1) ->
    @_restRequest(
      @_createRequestOptions(
        'POST',
        "rest/api/1.0/projects/#{projectKey}/repos/#{repositorySlug}/pull-requests/#{pullRequestId}/merge",
        {qs: {version: version}}
      )
    )

  deleteBranch: (projectKey, repositorySlug, branch, atRev) ->
    req = {
      name: branch
    }
    req['endPoint'] ?= atRev if atRev?

    @_restRequest(
      @_createRequestOptions(
        'DELETE',
        "/rest/branch-utils/1.0/projects/#{projectKey}/repos/#{repositorySlug}/branches",
        {json: req}
      ),
      [204]
    )

module.exports = exports = Stash