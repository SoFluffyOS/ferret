import 'dart:ffi';

/// `WAVEFORMATEX` from `mmreg.h`.
@Packed(1)
final class WaveFormat extends Struct {
  @Uint16()
  external int formatTag;

  @Uint16()
  external int channels;

  @Uint32()
  external int samplesPerSecond;

  @Uint32()
  external int averageBytesPerSecond;

  @Uint16()
  external int blockAlign;

  @Uint16()
  external int bitsPerSample;

  @Uint16()
  external int extraSize;
}

/// `WAVEHDR` from `mmsystem.h`.
final class WaveHeader extends Struct {
  external Pointer<Uint8> data;

  @Uint32()
  external int bufferLength;

  @Uint32()
  external int bytesRecorded;

  @IntPtr()
  external int user;

  @Uint32()
  external int flags;

  @Uint32()
  external int loops;

  external Pointer<WaveHeader> next;

  @IntPtr()
  external int reserved;
}

typedef _OpenNative = Uint32 Function(
  Pointer<IntPtr> handle,
  Uint32 deviceId,
  Pointer<WaveFormat> format,
  IntPtr callback,
  IntPtr instance,
  Uint32 flags,
);
typedef _OpenDart = int Function(
  Pointer<IntPtr> handle,
  int deviceId,
  Pointer<WaveFormat> format,
  int callback,
  int instance,
  int flags,
);
typedef _HeaderNative = Uint32 Function(
  IntPtr device,
  Pointer<WaveHeader> header,
  Uint32 size,
);
typedef _HeaderDart = int Function(
  int device,
  Pointer<WaveHeader> header,
  int size,
);
typedef _DeviceNative = Uint32 Function(IntPtr device);
typedef _DeviceDart = int Function(int device);

/// The few waveOut calls of Windows' `winmm.dll` that playing samples
/// needs.
class WinMm {
  WinMm._(DynamicLibrary library)
    : open_ = library.lookupFunction<_OpenNative, _OpenDart>('waveOutOpen'),
      prepareHeader = library.lookupFunction<_HeaderNative, _HeaderDart>(
        'waveOutPrepareHeader',
      ),
      write = library.lookupFunction<_HeaderNative, _HeaderDart>(
        'waveOutWrite',
      ),
      unprepareHeader = library.lookupFunction<_HeaderNative, _HeaderDart>(
        'waveOutUnprepareHeader',
      ),
      reset = library.lookupFunction<_DeviceNative, _DeviceDart>(
        'waveOutReset',
      ),
      close = library.lookupFunction<_DeviceNative, _DeviceDart>(
        'waveOutClose',
      );

  factory WinMm.open() => WinMm._(DynamicLibrary.open('winmm.dll'));

  /// `MMSYSERR_NOERROR`.
  static const int noError = 0;

  /// `WAVE_MAPPER`: whatever output the user picked in Windows.
  static const int defaultDevice = 0xFFFFFFFF;

  /// `WAVE_FORMAT_PCM`.
  static const int pcmFormat = 1;

  /// `WHDR_DONE`: Windows finished playing the buffer.
  static const int headerDone = 0x00000001;

  final _OpenDart open_;
  final _HeaderDart prepareHeader;
  final _HeaderDart write;
  final _HeaderDart unprepareHeader;
  final _DeviceDart reset;
  final _DeviceDart close;
}
