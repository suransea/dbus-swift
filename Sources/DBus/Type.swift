public enum Type: Int32 {
    /** Type code that is never equal to a legitimate type code */
    case invalid = 0

    /* Primitive types */
    /** Type code marking an 8-bit unsigned integer */
    case byte = 121 // 'y'
    /** Type code marking a boolean */
    case boolean = 98 // 'b'
    /** Type code marking a 16-bit signed integer */
    case int16 = 110 // 'n'
    /** Type code marking a 16-bit unsigned integer */
    case uint16 = 113 // 'q'
    /** Type code marking a 32-bit signed integer */
    case int32 = 105 // 'i'
    /** Type code marking a 32-bit unsigned integer */
    case uint32 = 117 // 'u'
    /** Type code marking a 64-bit signed integer */
    case int64 = 120 // 'x'
    /** Type code marking a 64-bit unsigned integer */
    case uint64 = 116 // 't'
    /** Type code marking an 8-byte double in IEEE 754 format */
    case double = 100 // 'd'
    /** Type code marking a UTF-8 encoded, nul-terminated Unicode string */
    case string = 115 // 's'
    /** Type code marking a D-Bus object path */
    case objectPath = 111 // 'o'
    /** Type code marking a D-Bus type signature */
    case signature = 103 // 'g'
    /** Type code marking a unix file descriptor */
    case unixFD = 104 // 'h'

    /* Compound types */
    /** Type code marking a D-Bus array type */
    case array = 97 // 'a'
    /** Type code marking a D-Bus variant type */
    case variant = 118 // 'v'

    /** STRUCT and DICT_ENTRY are sort of special since their codes can't
     * appear in a type string, instead
     * DBUS_STRUCT_BEGIN_CHAR/DBUS_DICT_ENTRY_BEGIN_CHAR have to appear
     */
    /** Type code used to represent a struct; however, this type code does not appear
     * in type signatures, instead #DBUS_STRUCT_BEGIN_CHAR and #DBUS_STRUCT_END_CHAR will
     * appear in a signature.
     */
    case structType = 114 // 'r'
    /** Type code used to represent a dict entry; however, this type code does not appear
     * in type signatures, instead #DBUS_DICT_ENTRY_BEGIN_CHAR and #DBUS_DICT_ENTRY_END_CHAR will
     * appear in a signature.
     */
    case dictEntry = 101 // 'e'
}
