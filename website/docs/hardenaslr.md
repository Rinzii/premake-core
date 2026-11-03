Specifies whether to enable Address Space Layout Randomization (ASLR).

```lua
hardenaslr "value"
```

### Parameters ###

*value* selects the ASLR setting:

| Value   | [GCC][2] and [Clang][3] (GNU/Linux)                                                             | [GCC][4] (Windows, link)  | [MSVC][1] and [Clang][3] (Windows, link) | Description             |
|---------|-------------------------------------------------------------------------------------------------|---------------------------|------------------------------------------|-------------------------|
| Default |                                                                                                 |                           |                                          | Add no ASLR override.   |
| Off     | Executables: -fno-PIE (compile and link), -no-pie (link).                                       | -Wl,--disable-dynamicbase | /DYNAMICBASE:NO                          | Request disabling ASLR. |
| On      | Executables: -fPIE (compile and link), -pie (link). Libraries: -fPIC (compile and shared link). | -Wl,--dynamicbase         | /DYNAMICBASE                             | Request enabling ASLR.  |

Linux executables with Off and pic On use -fPIC instead of -fno-PIE.

Windows Clang uses an MSVC-compatible linker and forwards its options with -Xlinker.

### Applies To ###

Project configurations.

### Availability ###

Premake 5.0.1 or later.

Supports GNU Make/Ninja/CodeLite with GCC/Clang on GNU/Linux and Windows. Windows support also includes Ninja/CodeLite with MSVC and Visual Studio's supported MSVC/Clang toolsets (VS2005 requires SP1).

Fully static Linux executables, Off for Linux libraries and distinct per-file ASLR values are currently unsupported.

### Limitations ###

On GNU/Linux, On conflicts with pic Off.

Windows does not allow disabling ASLR on ARM, ARM64 or ARM64EC targets.

### Examples ###

```lua
filter "configurations:Release"
	hardenaslr "On"
```

### See Also ###

* [pic](pic.md)

[1]: https://learn.microsoft.com/en-us/cpp/build/reference/dynamicbase-use-address-space-layout-randomization
[2]: https://gcc.gnu.org/onlinedocs/gcc/Link-Options.html
[3]: https://clang.llvm.org/docs/ClangCommandLineReference.html
[4]: https://sourceware.org/binutils/docs/ld/Options.html
