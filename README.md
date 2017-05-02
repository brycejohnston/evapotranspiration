# Evapotranspiration

[![Gem Version](http://img.shields.io/gem/v/evapotranspiration.svg)][gem]
[![Build Status](http://img.shields.io/travis/CropQuest/evapotranspiration.svg)][travis]

[gem]: https://rubygems.org/gems/evapotranspiration
[travis]: http://travis-ci.org/CropQuest/evapotranspiration

Ruby library for calculating reference crop evapotranspiration (ETo), also referred to as potential evapotranspiration (PET), using the FAO-56 Penman-Monteith method. This was originally ported into Ruby from the [PyETo Python package from Mark Richards](https://github.com/woodcrafty/PyETo). The library provides numerous methods for estimating missing meteorological data.

Three methods for estimating ETo/PET are implemented:

- FAO-56 Penman-Monteith (Allen et al, 1998)
- Hargreaves (Hargreaves and Samani, 1982; 1985)
- Thornthwaite (Thornthwaite, 1948)

## Installation

Add this line to your application's Gemfile:

```ruby
gem 'evapotranspiration'
```

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install evapotranspiration

## Information

### Documentation

You can view the evapotranspiration documentation here: http://www.rubydoc.info/gems/evapotranspiration

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/CropQuest/evapotranspiration

### Development

After checking out the repo, run `bin/setup` to install dependencies. Then, run `rake spec` to run the tests. You can also run `bin/console` for an interactive prompt that will allow you to experiment. To install this gem onto your local machine, run `bundle exec rake install`.

## License

The gem is available as open source under the terms of the BSD 3-Clause License (see [LICENSE.txt](https://github.com/CropQuest/evapotranspiration/blob/master/LICENSE.txt)).

The original PyETo Python package it is based on was released under the BSD 3-Clause License (see [LICENSE-ORIGINAL.txt](https://github.com/CropQuest/evapotranspiration/blob/master/LICENSE-ORIGINAL.txt)).
