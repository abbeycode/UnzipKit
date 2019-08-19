#!/bin/sh

# Different styles of import statement need to be used for the Swift generated header,
# depending on the target type (static library or dynamic framework). This script reads
# the PACKAGE_TYPE environment variable Xcode sets to create the correct one at build
# time, allowing the library to be built as either type from CocoaPods

# static library:    com.apple.product-type.library.static
# dynamic framework: com.apple.package-type.wrapper.framework
[[ "${PACKAGE_TYPE}" = "com.apple.package-type.wrapper.framework" ]] \
    && SWIFTIMPORT="<${PRODUCT_MODULE_NAME}/${PRODUCT_MODULE_NAME}-Swift.h>" \
    || SWIFTIMPORT="\"${PRODUCT_MODULE_NAME}-Swift.h\""

if [ -z "$PODS_TARGET_SRCROOT" ]; then
    PODS_TARGET_SRCROOT=${SOURCE_ROOT}
    echo "Building in Xcode instead of CocoaPods. Overriding PODS_TARGET_SRCROOT with SOURCE_ROOT"
fi

_Import_text="
#ifndef GeneratedSwiftImport_h
#define GeneratedSwiftImport_h

#import ${SWIFTIMPORT}

#endif /* GeneratedSwiftImport_h */
"
echo "$_Import_text" > ${PODS_TARGET_SRCROOT}/Source/GeneratedSwiftImport.h
