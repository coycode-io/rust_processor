import 'dart:io' show Platform;
import 'dart:ffi' as ffi;
import 'package:ffi/ffi.dart';

typedef ProcessStringNative = ffi.Pointer<ffi.Int8> Function(
    ffi.Pointer<ffi.Int8>);
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
    return './test/linux_so/lib${proyname}_rust.so';
  } else {
    throw UnsupportedError('This platform is not supported.');
  }
}
