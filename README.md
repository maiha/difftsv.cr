# difftsv

Compare TSV files cell by cell with focus on similarity.

```console
$ difftsv foo.tsv bar.tsv
```

* [Features](#features)
* [Get started](#get-started)
* [Options](#options)
* [TODO](#todo)
* [Library](#library)

## Features

### Pros
* Support similarity (reports percentage of similarity)
* Support multiple columns for primary key
* Support Float (compares float values with delta)
* Fast (100% written in [Crystal](http://crystal-lang.org/))

### Cons
* Large amount of memory (ex. 1GB is required for two 35MB files)

## Get started

Static Binary is ready for x86_64 linux

- https://github.com/maiha/difftsv.cr/releases

Just put two TSV files. It will report the similarity.

```console
$ difftsv foo.tsv bar.tsv
```

## Options

### `-s` works in silent mode

This shows only the value of similarity.

```console
$ difftsv foo.tsv bar.tsv -s
100.0
```

### `-q` works in quiet mode

This shows nothing except error messages. It is useful when you want just status code.

```console
$ difftsv foo.tsv bar.tsv -q
```

## TODO

- specify the value fields to be compared
- handle duplicated keys
- write different rows and cols into file

## Library

As repository name says, it is available as Crystal library.
See [README.cr.md](./README.cr.md) for details.

## Contributors

- [maiha](https://github.com/maiha) - creator and maintainer
