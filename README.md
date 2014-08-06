Fluentd: Open-Source Data Collector
===================================

[<img src="https://travis-ci.org/fluent/fluentd.png" />](https://travis-ci.org/fluent/fluentd) [![Code Climate](https://codeclimate.com/github/fluent/fluentd/badges/gpa.svg)](https://codeclimate.com/github/fluent/fluentd)


[Fluentd](http://fluentd.org/) collects events from various data sources and writes them to files, database or other types of storages. You can simplify your data stream, and have robust data collection mechanism instantly:

<p align="center">
<img src="http://docs.fluentd.org/images/fluentd-architecture.png" width="500px"/>
</p>

An event consists of *tag*, *time* and *record*. Tag is a string separated with '.' (e.g. myapp.access). It is used to categorize events. Time is a UNIX time recorded at occurrence of an event. Record is a JSON object.


## Quick Start

    $ gem install fluentd
    $ fluentd -s conf
    $ fluentd -c conf/fluent.conf &
    $ echo '{"json":"message"}' | fluent-cat debug.test

## Fluentd UI: Admin GUI

[Fluentd UI](https://github.com/fluent/fluentd-ui) is a graphical user interface to start/stop/configure Fluentd.

## More Information

- Website: http://fluentd.org/
- Documentation: http://docs.fluentd.org/
- Source repository: http://github.com/fluent
- Discussion: http://groups.google.com/group/fluentd
- Newsletters: http://get.treasuredata.com/Fluentd_education
- Author: Sadayuki Furuhashi
- Copyright: (c) 2011 FURUHASHI Sadayuki
- License: Apache License, Version 2.0

## Contributors:

Patches contributed by [great developers](https://github.com/fluent/fluentd/contributors).

[<img src="https://ga-beacon.appspot.com/UA-24890265-6/fluent/fluentd" />](https://github.com/fluent/fluentd)

