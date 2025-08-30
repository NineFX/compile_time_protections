# Toy Service

This services wraps calls to a deliberately unsafe binary compiled with 
clang/llvm compile-time (and runtime) protections. The binary is called
using simple command-line arguments:

```sh
vulnerable_binary

# or, to deliberately cause a bad cast

vulnerable_binary bad_cast
```
