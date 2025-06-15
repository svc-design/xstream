// AUTO-GENERATED FFI BINDINGS
import 'dart:ffi' as ffi;
import 'package:ffi/ffi.dart';

typedef _StartNodeServiceNative = ffi.Pointer<ffi.Char> Function(ffi.Pointer<ffi.Char>);
typedef _StartNodeServiceDart = ffi.Pointer<ffi.Char> Function(ffi.Pointer<ffi.Char>);

typedef _StopNodeServiceNative = ffi.Pointer<ffi.Char> Function(ffi.Pointer<ffi.Char>);
typedef _StopNodeServiceDart = ffi.Pointer<ffi.Char> Function(ffi.Pointer<ffi.Char>);

typedef _WriteConfigFilesNative = ffi.Pointer<ffi.Char> Function(
  ffi.Pointer<ffi.Char>, ffi.Pointer<ffi.Char>,
  ffi.Pointer<ffi.Char>, ffi.Pointer<ffi.Char>,
  ffi.Pointer<ffi.Char>, ffi.Pointer<ffi.Char>,
  ffi.Pointer<ffi.Char>);
typedef _WriteConfigFilesDart = ffi.Pointer<ffi.Char> Function(
  ffi.Pointer<ffi.Char>, ffi.Pointer<ffi.Char>,
  ffi.Pointer<ffi.Char>, ffi.Pointer<ffi.Char>,
  ffi.Pointer<ffi.Char>, ffi.Pointer<ffi.Char>,
  ffi.Pointer<ffi.Char>);

typedef _CheckNodeStatusNative = ffi.Int32 Function(ffi.Pointer<ffi.Char>);
typedef _CheckNodeStatusDart = int Function(ffi.Pointer<ffi.Char>);

typedef _PerformActionNative = ffi.Pointer<ffi.Char> Function(
  ffi.Pointer<ffi.Char>, ffi.Pointer<ffi.Char>);
typedef _PerformActionDart = ffi.Pointer<ffi.Char> Function(
  ffi.Pointer<ffi.Char>, ffi.Pointer<ffi.Char>);

typedef _FreeCStringNative = ffi.Void Function(ffi.Pointer<ffi.Char>);
typedef _FreeCStringDart = void Function(ffi.Pointer<ffi.Char>);

class BridgeBindings {
  BridgeBindings(ffi.DynamicLibrary lib)
      : startNodeService = lib.lookupFunction<_StartNodeServiceNative, _StartNodeServiceDart>('StartNodeService'),
        stopNodeService = lib.lookupFunction<_StopNodeServiceNative, _StopNodeServiceDart>('StopNodeService'),
        writeConfigFiles = lib.lookupFunction<_WriteConfigFilesNative, _WriteConfigFilesDart>('WriteConfigFiles'),
        checkNodeStatus = lib.lookupFunction<_CheckNodeStatusNative, _CheckNodeStatusDart>('CheckNodeStatus'),
        performAction = lib.lookupFunction<_PerformActionNative, _PerformActionDart>('PerformAction'),
        freeCString = lib.lookupFunction<_FreeCStringNative, _FreeCStringDart>('FreeCString');

  final _StartNodeServiceDart startNodeService;
  final _StopNodeServiceDart stopNodeService;
  final _WriteConfigFilesDart writeConfigFiles;
  final _CheckNodeStatusDart checkNodeStatus;
  final _PerformActionDart performAction;
  final _FreeCStringDart freeCString;
}
