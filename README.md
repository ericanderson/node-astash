# AStash for Node

Provides an (incomplete) node library for communicating with Atlassian Stash.

## Quick Resources

| Branch        | Build Status                                | Coffee Docs                 |
| --------------|---------------------------------------------|-----------------------------|
| **master**    | [![Master Build Status][]][travis project]  | [Coffee Docs][develop docs] |

[travis project]: https://travis-ci.org/ericanderson/node-astash
[Develop Build Status]: https://travis-ci.org/ericanderson/node-astash.png?branch=develop
[Master Build Status]: https://travis-ci.org/ericanderson/node-astash.png?branch=master
[master docs]: http://coffeedoc.info/github/ericanderson/node-astash/master
[develop docs]: http://coffeedoc.info/github/ericanderson/node-astash/develop

## Overview

This library provides little over the direct Stash REST API, however the little it
provides makes your life so much easier.

The two primary features are:

* [Q][] promsies for code legibility
* Automatic handling of paged requests for iterator/generator style access

### Example

```coffee
# Look at all open pull requests for MYPROJ/myrepo
promise = stash.eachPullRequest "MYPROJ", "myrepo", (pr) ->
  pr.canMerge().done () ->
    pr.attemptMerge()

promise.done(-> console.log('Finished processing requests'))
```

### Documentation

* [AStash CoffeeDoc][]

[Q]: https://github.com/kriskowal/q
[AStash CoffeeDoc]: http://coffeedoc.info/github/ericanderson/node-astash
