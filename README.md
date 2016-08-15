# Overpass for Node.js

[![Build Status]](https://travis-ci.org/IcecaveStudios/overpass-js)
[![Test Coverage]](https://coveralls.io/r/IcecaveStudios/overpass-js?branch=develop)
[![SemVer]](http://semver.org)

**Overpass** is a basic pub/sub and RPC system. The [original version](https://github.com/IcecaveStudios/overpass)
was written for PHP. This package provides a JavaScript implementation.

* Install via [NPM](http://npmjs.org) package [overpass](https://www.npmjs.org/package/overpass)
* Read the [API documentation](http://icecavestudios.github.io/overpass-js/artifacts/documentation/api/)

## Message Brokers

* [Rabbit MQ / AMQP](src/amqp)
* Redis (not yet implemented)

## Examples

* Pub/Sub
  * [Publisher](examples/pubsub-publisher)
  * [Subscriber](examples/pubsub-subscriber)
* RPC
  * [Client](examples/rpc-client)

## Contact us

* Follow [@IcecaveStudios](https://twitter.com/IcecaveStudios) on Twitter
* Visit the [Icecave Studios website](http://icecave.com.au)
* Join `#icecave` on [irc.freenode.net](http://webchat.freenode.net?channels=icecave)

<!-- references -->
[Build Status]: http://img.shields.io/travis/IcecaveStudios/overpass-js/develop.svg?style=flat-square
[Test Coverage]: http://img.shields.io/coveralls/IcecaveStudios/overpass-js/develop.svg?style=flat-square
[SemVer]: http://img.shields.io/:semver-0.3.0-yellow.svg?style=flat-square
