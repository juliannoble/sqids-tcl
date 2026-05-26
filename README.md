# [Sqids Tcl](https://sqids.org/tcl)

Sqids (pronounced "squids") is a small library that lets you generate YouTube-looking IDs from numbers. It's good for link shortening, fast & URL-safe ID generation and decoding back into numbers for quicker database lookups.

## Getting started
Generate versioned .tm file(s) from src/modules using:
```
tclsh src/make.tcl
```

Either:  
* copy the sqids-XXX.tm file to a Tcl module path  
   (ie add to one of the existing folders as shown by the command: tcl::tm::list)  
*  add this folder to your module path during script run  
   e.g  
   ```tcl
   tcl::tm::add /projects/squids-tcl/modules
   package require sqids
   ...
   ```
*  update your default module path by setting the appropriate env var  
  e.g   
  set the variable TCL9_0_TM_PATH  to /projects/squids-tcl/modules  



## Examples

Simple encode and decode at the tclsh prompt:
```tcl
% package require sqids
  0.3.1
% sqids::idscope create s1
  ::s1
% s1 encode {1 2 3}
  86Rf07
% s1 decode 86Rf07
  1 2 3
```

simple encode with non-default parameters:
```tcl
package require sqids
sqids::idscope create s2 -alphabet {abcdef0123456789} -minlength 6 -blocklist {} 
set idstring [s2 encode {1 2 3}] ;#a83a2e
```

Tcl can support arbitrarily large integers (bignum)
The default MAX_SAFE_INTEGER for sqids is set to 1 Googol (1 with 100 zeros)
which is a huge number but can still be encoded within a couple of hundred microseconds.

Numbers can be arbitrarily large at the cost of memory and encode/decode speed.

To globally configure the default for all sqids::idscope intances to a smaller
number to match some other language
e.g
```tcl
set ::sqids::data::MAX_SAFE_INTEGER [expr {2**128}]
```

Alternatively the value can be configured per idscope instance: 
```tcl
sqids::idscope create s3 -maxsafeinteger [expr {2**64}]
```

## License

[MIT](LICENSE)
