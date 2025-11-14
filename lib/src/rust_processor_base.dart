// imported to resolve the path to the dynamic library, specifically for Android and Linux platforms.
// We seem to be missing apple platforms here.
import 'dart:io' show Platform;
import 'dart:ffi' as ffi;
import 'package:ffi/ffi.dart';
import 'dart:convert';

/// to be imported in the dart_test_connector.
/// typedefs for the Rust functions based on their signatures
/// namely the input and output types.
/// Input: ffi.Pointer<ffi.Int8> - a pointer to a C string (the string you want to process)
/// Output: ffi.Pointer<ffi.Int8> - a pointer to a C string (the processed string)
/// that of course is basic dart synatax migillix, so returnType Function(argType)
/// ffi.Pointer<ffi.Int8> is pointing to the first byte of a null-terminated string
/// so to the beginning of a sequence of Int8 values that represent the string's characters.
typedef ProcessStringNative = ffi.Pointer<ffi.Int8> Function(
    ffi.Pointer<ffi.Int8>);

/// Dart function type that corresponds to the native function signature.
/// This is here for definitory purposes, to map the native function to a Dart callable function.
/// NOT USED DIRECTLY.
typedef ProcessStringDart = ffi.Pointer<ffi.Int8> Function(
    ffi.Pointer<ffi.Int8>);

typedef FreeStringNative = ffi.Void Function(
    ffi.Pointer<ffi.Int8>); // <-- Change to Pointer<Int8>
typedef FreeStringDart = void Function(
    ffi.Pointer<ffi.Int8>); // <-- Change to Pointer<Int8>
// @ffi.Native<Void Function()>()
// external Future<void> kill_rust_process();

typedef KillRustProcessNative = ffi.Void Function();
typedef KillRustProcessDart = void Function();

class RustProcessor {
  late final ffi.DynamicLibrary lib;
  late final ProcessStringDart processString;
  late final FreeStringDart freeString;
  late final KillRustProcessDart killRustProcess;

  RustProcessor({required String proyname}) {
    lib = ffi.DynamicLibrary.open(_getLibraryPath(proyname));
    processString = lib.lookupFunction<ProcessStringNative, ProcessStringDart>(
        'process_string');
    freeString =
        lib.lookupFunction<FreeStringNative, FreeStringDart>('free_string');
    killRustProcess =
        lib.lookupFunction<KillRustProcessNative, KillRustProcessDart>(
            'kill_rust_process');
  }

  String processStringInRust(String input) {
    final inputPtr = input.toNativeUtf8().cast<ffi.Int8>();
    final resultPtr = processString(inputPtr);
    final result = resultPtr.cast<Utf8>().toDartString();
    calloc.free(inputPtr);
    freeString(resultPtr);
    return result;
  }

  Future<bool> killRustProcessDart() async {
    try {
      killRustProcess();
      return true;
    } catch (e) {
      print('Error in killRustProcessDart: $e');
      return false;
    }
  }
}

String _getLibraryPath(String proyname) {
  if (Platform.isAndroid) {
    return 'lib$proyname.so';
  } else if (Platform.isLinux) {
    return './test/linux_so/lib$proyname.so';
  } else {
    throw UnsupportedError('This platform is not supported.');
  }
}

abstract class JsonEncodable {
  Map<String, dynamic> toJson([Map<String, Object>? additionalFields]);
}

/// class to define reusable encoding and decoding methods
class Endecoder {
  /// central encoding method that takes an object implementing JsonEncodable
  /// and a map of additional fields to include in the JSON representation.
  /// These are should be written to the map returned by toJson method of the object
  /// after the putting the objects own fields into the map.
  /// USUALLY DART TO RUST
  static String centralEncodeFromDartToRust(
    JsonEncodable objectsWithToJson,
    Map<String, Object> additionalFields,
  ) {
    return jsonEncode(objectsWithToJson.toJson(additionalFields));
  }

  static T centralDecode<T>(T Function(String) fromJsonString, String toParse) {
    return fromJsonString(toParse);
  }

  static String applyEncodingContentRule(Object toS) {
    return "§$toS§";
  }
}
