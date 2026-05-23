# [Sqids Tcl](https://sqids.org/tcl)

Sqids (pronounced "squids") is a small library that lets you generate YouTube-looking IDs from numbers. It's good for link shortening, fast & URL-safe ID generation and decoding back into numbers for quicker database lookups.

## Getting started

place sqids-0.1.tm file in your module path.

ie in one of the folders listed in tcl::tm::list


## Examples

Simple encode and decode at the tclsh prompt:

```tcl
% package require sqids
  0.1
% sqids::idscope create s1
  ::s1
% s1 encode {1 2 3}
  86Rf07
% s1 decode 86Rf07
  1 2 3
```

## License

[MIT](LICENSE)
