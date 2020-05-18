# difftsv.cr

difftsv for [Crystal](http://crystal-lang.org/).

- crystal: 0.33.0

## Installation

1. Add the dependency to your `shard.yml`:

```yaml
dependencies:
  difftsv:
    github: maiha/difftsv.cr
    version: 0.2.0
```

2. Run `shards install`

## Usage

```crystal
require "difftsv"
```

## Development

```console
$ make compile  # => "bin/difftsv-dev" (dynamic link)
$ make release  # => "bin/difftsv" (static link; compiled with release flag)
```

## Contributing

1. Fork it (<https://github.com/maiha/difftsv.cr/fork>)
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create a new Pull Request

## Contributors

- [maiha](https://github.com/maiha) - creator and maintainer
