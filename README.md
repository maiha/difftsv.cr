# difftsv [![Build Status](https://travis-ci.org/maiha/difftsv.cr.svg?branch=master)](https://travis-ci.org/maiha/difftsv.cr)

Compare TSV files cell by cell with focus on similarity.

```console
$ difftsv foo.tsv bar.tsv
[Similarity distribution] (9 rows)
  100%: [|||||||||||||||||||||||       ] 7/9 ( 77%)
   95%: [|||                           ] 1/9 ( 11%)
   90%: [                              ] 0/9 (  0%)
   80%: [                              ] 0/9 (  0%)
   ---: [|||                           ] 1/9 ( 11%)
Similarity: 88.9% (0.0 sec) MEM:5.2MB
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

### `-H`, `--header` : Use first line as header

Treats the first row as the column names.

```tsv
date	value
01/29	2
01/30	5
```

##### NOTE
If the first line starts with `#`, it is automatically recognized as a header, regardless of this option.
```tsv
#date	value
...
```

### `-f`, `--fields=KEYS` : primary keys

This specifies primary keys by 1-origin indexes.
Accepts the same format as **cut(1)**. Default is 1.

```console
$ difftsv -f 1-3,5 ...
```

### `--delta FLOAT` : Threshold for the same float value
Compares float values with this delta. Default is `0.001`.

```console
$ difftsv ...
Similarity: 99.993 (0.0 sec) MEM:5.1MB

$ difftsv --delta 0.1 ...
Similarity: 100 (0.0 sec) MEM:5.2MB
```

### `-s` works in silent mode

This outputs only float values of similarity to **STDOUT**.
If an error occurs, the content of the error is output to **STDERR**, and nothing is output to **STDOUT**.

```console
$ difftsv -s ...
100.0
```

### `-q` works in quiet mode

This shows nothing except error messages. It is useful when you want just status code.

```console
$ difftsv -q ...
```

### `-L`, `--loader` : loading strategy

By default, the CSV parser is used, so handling data files with strings containing double quotes,
for example, may result in an error.

```text
Expecting comma, newline or end, not '-' at 27029:97
```

In that case, use the "donkey mode", which may be slow but is a simple process of analysis.

```console
$ difftsv -L donkey ...
```

## TODO

- cli: Specify the value keys
- lib: handle duplicated keys (skip or raise)
- lib: write different rows and cols into file

## Library

As repository name says, it is available as Crystal library.
See [README.cr.md](./README.cr.md) for details.

## Contributors

- [maiha](https://github.com/maiha) - creator and maintainer
