# Overview
This project is a member of the [CommsChampion Ecosystem](https://commschamp.github.io/).
It provides necessary [CommsDSL](https://commschamp.github.io/commsdsl_spec) schemas as well as
extra injection code to define the structure of the
[X.509](https://datatracker.ietf.org/doc/html/rfc5280) public key infrastructure certificate.


# How to Build
This project uses CMake as its build system. Please open main
[CMakeLists.txt](CMakeLists.txt) file and review available options as well as mentioned available parameters,
which can be used in addition to standard ones provided by CMake itself, to modify the default build.

This project also has external dependencies. The build process expects to find them in the
provided **CMAKE_PREFIX_PATH** (**CMAKE_PROGRAM_PATH** can also be used for path to the commsdsl code generators).
The required dependencies are:

- [COMMS Library](https://github.com/commschamp/comms)
- [commsdsl](https://github.com/commschamp/commsdsl) code generators.
- [cc.asn1.commsdsl](https://github.com/commschamp/cc.asn1.commsdsl) for the ASN.1 definitions.

```
$> cd /path/to/cc.x509.commsdsl
$> mkdir build && cd build
$> cmake .. -DCMAKE_INSTALL_PREFIX=./install -DCMAKE_BUILD_TYPE=Release \
    -DCMAKE_PREFIX_PATH=/path/to/comms/install\;/path/to/commsdsl/install\;/path/to/asn1/install
$> cmake --build . --config Release
```

The build process generates another CMake project (hosted as [cc.x509.generated](https://github.com/commschamp/cc.x509.generated))
and builds it. As the result the installation directory will contain only the X.509
certificate definition headers (without the [COMMS Library](https://github.com/commschamp/comms)).

To achieve the same output the [cc.x509.generated](https://github.com/commschamp/cc.x509.generated) can
be used directly. Its only (optional) dependency is the [COMMS Library](https://github.com/commschamp/comms).

There is also a testing application available, which is basically generated by the
**commsdsl2test** code generator. To add it to the build add `-DCC_X509_BUILD_APPS=ON` to the cmake
invocation:
```
$> cmake .. -DCC_X509_BUILD_APPS=ON ...
```

The project's cmake configuration [options](CMakeLists.txt) allow building
bindings to other high level programming languages using [swig](https://www.swig.org/)
and [emscripten](https://emscripten.org/), see relevant commsdsl's
[documentation](https://github.com/commschamp/commsdsl/tree/master/doc) pages for details.

# How to Use
The [generated](https://github.com/commschamp/cc.x509.generated) code has a definition of the certificate
field in [include/cc_x509/field/Certificate.h](https://github.com/commschamp/cc.x509.generated/blob/master/include/cc_x509/field/Certificate.h).
It was defined with strict adherence to its definition in [section 4.1](https://datatracker.ietf.org/doc/html/rfc5280#section-4.1) of
the [RFC-5280](https://datatracker.ietf.org/doc/html/rfc5280).

The CommsDSL schema definition uses ASN.1 definitions provided by the [cc.asn1.commsdsl](https://github.com/commschamp/cc.asn1.commsdsl).
Please refer to it for guidance on how ASN.1 encoding is performed and how to access required values.

The [certificate](https://github.com/commschamp/cc.x509.generated/blob/master/include/cc_x509/field/Certificate.h) field definition
uses infrastructure provided by the [COMMS Library](https://github.com/commschamp/comms). Please refer to the
official [tutorial](https://github.com/commschamp/cc_tutorial) and [tutorial2](https://github.com/commschamp/cc_tutorial/tree/master/tutorials/tutorial2)
in particular for details how to use the field definitions.

When the X.509 certificate needs to be decoded, just use inherited **read()** member function.
```cpp
using Certificate = cc_x509::field::Certificate<>;
Certificate cert;
std::vector<std::uint8_t> buf = {...}; // contains binary encoding of the certificate;
auto readIter = &buf[0];
auto es = cert.read(readIter, buf.size());
if (es != comms::ErrorStatus::Success) {
    ... // Invalid certificate data
    return;
}

// Certificate is successfully decoded, access its fields
...
```

When the X.509 certificate needs to be encoded, update all the values and call **refresh()** to update the
`Length` information in every field before performing **write()**.
```
using Certificate = cc_x509::field::Certificate<>;
Certificate cert;

// Set all the fields' values, remember that most of them are TLV triplets and
// their `Value` field needs to be accessed first. Then use value() member function
// to get an access to the actual storage type.

...
auto& signatureValue = cert.field_value().field_signatureValue(); // Access signatureValue member.
auto& signatureValueData = signatureValue.field_value().value(); // Access the storage of the signatureValue data
signatureValueData = ...; // Assign raw bytes of the signature storage vector.

// After update is complete, update the Length values
cert.refresh();

std::vector<std::uint8_t> encodedData;
encodedData.reserve(cert.length());
auto writeIter = std::back_inserter(encodedData);

auto es = cert.write(writeIter, buf.max_size());
if (es != comms::ErrorStatus::Success) {
    ... // Serialization failed, should not really happen
    return;
}

// Successfully encoded
...
```

# How to (Fuzz) Test
The [commsdsl](https://github.com/commschamp/commsdsl) project provides **commsdsl2test** code
generator. It generates a code for the test application which is suitable for [AFL](https://lcamtuf.coredump.cx/afl/)
testing. Is is used to generate the code for the **cc_x509_input_test** testing application.

The testing application just expects data from the standard input and tries to decode the certificate.
If the certificate is successfully decoded, then its contents are dumped to standard output. The
testing application also performs the **write** (encoding) of the same decoded certificate to the
temporary buffer to make sure the write operation is also successful.

Compiling the application with instrumentation may look like this:
```
$> CC=afl-gcc CXX=afl-g++ cmake .. -DCC_X509_BUILD_APPS=ON -DCMAKE_INSTALL_PREFIX=./install \
    -DCMAKE_BUILD_TYPE=Debug \
    -DCMAKE_PREFIX_PATH=/path/to/comms/install\;/path/to/commsdsl/install\;/path/to/asn1/install
$> cmake --build . --config Debug
```

Debug build is recommended to enable assertions.

When the instrumented **cc_x509_input_test** binary is compiled, use
[AFL testing instructions](https://github.com/google/AFL#6-fuzzing-binaries) to
perform the fuzz testing. Put one or more certificate files into the input directory
to help with the testing.

In case fuzz testing reports any crash, it means a bug in either [COMMS Library](https://github.com/commschamp/comms)
or the generated code was discovered. Please submit an issue with the crash file attached. Any hang reports
can safely be ignored. It means insufficient input data was provided to the standard input to decode
the certificate.

See also [Testing Generated Protocol Code](https://github.com/commschamp/commsdsl/blob/master/doc/TestingGeneratedProtocolCode.md)
for more details.
