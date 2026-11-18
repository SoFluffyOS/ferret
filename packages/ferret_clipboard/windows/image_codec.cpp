#include "image_codec.h"

#include <shlwapi.h>
#include <wincodec.h>
#include <wrl/client.h>

#include <cstring>

namespace ferret_clipboard {

namespace {

using Microsoft::WRL::ComPtr;

ComPtr<IWICImagingFactory> CreateFactory() {
  ComPtr<IWICImagingFactory> factory;
  HRESULT result = CoCreateInstance(CLSID_WICImagingFactory, nullptr,
                                    CLSCTX_INPROC_SERVER,
                                    IID_PPV_ARGS(&factory));
  if (FAILED(result)) {
    return nullptr;
  }
  return factory;
}

ComPtr<IWICBitmapFrameDecode> DecodeFirstFrame(IWICImagingFactory* factory,
                                               const uint8_t* bytes,
                                               size_t size) {
  ComPtr<IStream> stream;
  stream.Attach(SHCreateMemStream(bytes, static_cast<UINT>(size)));
  if (!stream) {
    return nullptr;
  }

  ComPtr<IWICBitmapDecoder> decoder;
  if (FAILED(factory->CreateDecoderFromStream(
          stream.Get(), nullptr, WICDecodeMetadataCacheOnDemand, &decoder))) {
    return nullptr;
  }

  ComPtr<IWICBitmapFrameDecode> frame;
  if (FAILED(decoder->GetFrame(0, &frame))) {
    return nullptr;
  }
  return frame;
}

std::optional<std::vector<uint8_t>> EncodePng(IWICImagingFactory* factory,
                                              IWICBitmapSource* source) {
  ComPtr<IWICFormatConverter> converter;
  if (FAILED(factory->CreateFormatConverter(&converter)) ||
      FAILED(converter->Initialize(source, GUID_WICPixelFormat32bppBGRA,
                                   WICBitmapDitherTypeNone, nullptr, 0.0,
                                   WICBitmapPaletteTypeCustom))) {
    return std::nullopt;
  }

  UINT width = 0;
  UINT height = 0;
  if (FAILED(converter->GetSize(&width, &height))) {
    return std::nullopt;
  }

  ComPtr<IStream> stream;
  stream.Attach(SHCreateMemStream(nullptr, 0));
  if (!stream) {
    return std::nullopt;
  }

  ComPtr<IWICBitmapEncoder> encoder;
  if (FAILED(factory->CreateEncoder(GUID_ContainerFormatPng, nullptr,
                                    &encoder)) ||
      FAILED(encoder->Initialize(stream.Get(), WICBitmapEncoderNoCache))) {
    return std::nullopt;
  }

  WICPixelFormatGUID format = GUID_WICPixelFormat32bppBGRA;
  ComPtr<IWICBitmapFrameEncode> frame;
  if (FAILED(encoder->CreateNewFrame(&frame, nullptr)) ||
      FAILED(frame->Initialize(nullptr)) ||
      FAILED(frame->SetSize(width, height)) ||
      FAILED(frame->SetPixelFormat(&format)) ||
      !IsEqualGUID(format, GUID_WICPixelFormat32bppBGRA) ||
      FAILED(frame->WriteSource(converter.Get(), nullptr)) ||
      FAILED(frame->Commit()) || FAILED(encoder->Commit())) {
    return std::nullopt;
  }

  STATSTG stat = {};
  if (FAILED(stream->Stat(&stat, STATFLAG_NONAME))) {
    return std::nullopt;
  }

  std::vector<uint8_t> png(static_cast<size_t>(stat.cbSize.QuadPart));
  LARGE_INTEGER start = {};
  ULONG read = 0;
  if (FAILED(stream->Seek(start, STREAM_SEEK_SET, nullptr)) ||
      FAILED(stream->Read(png.data(), static_cast<ULONG>(png.size()), &read)) ||
      read != png.size()) {
    return std::nullopt;
  }
  return png;
}

// Bytes between the start of a DIB and its pixels.
size_t PixelOffset(const BITMAPINFOHEADER& header) {
  size_t offset = header.biSize;
  if (header.biSize == sizeof(BITMAPINFOHEADER) &&
      header.biCompression == BI_BITFIELDS) {
    offset += 3 * sizeof(DWORD);
  }

  DWORD colors = header.biClrUsed;
  if (colors == 0 && header.biBitCount <= 8) {
    colors = 1u << header.biBitCount;
  }
  return offset + colors * sizeof(RGBQUAD);
}

}  // namespace

std::optional<std::vector<uint8_t>> DibToPng(const uint8_t* dib, size_t size) {
  if (dib == nullptr || size < sizeof(BITMAPINFOHEADER)) {
    return std::nullopt;
  }

  BITMAPINFOHEADER header;
  std::memcpy(&header, dib, sizeof(header));
  const size_t pixel_offset = PixelOffset(header);
  if (pixel_offset > size) {
    return std::nullopt;
  }

  BITMAPFILEHEADER file_header = {};
  file_header.bfType = 0x4D42;
  file_header.bfSize = static_cast<DWORD>(sizeof(file_header) + size);
  file_header.bfOffBits =
      static_cast<DWORD>(sizeof(file_header) + pixel_offset);

  std::vector<uint8_t> bmp(sizeof(file_header) + size);
  std::memcpy(bmp.data(), &file_header, sizeof(file_header));
  std::memcpy(bmp.data() + sizeof(file_header), dib, size);
  return ImageToPng(bmp);
}

std::optional<std::vector<uint8_t>> ImageToPng(
    const std::vector<uint8_t>& image) {
  ComPtr<IWICImagingFactory> factory = CreateFactory();
  if (!factory) {
    return std::nullopt;
  }

  ComPtr<IWICBitmapFrameDecode> frame =
      DecodeFirstFrame(factory.Get(), image.data(), image.size());
  if (!frame) {
    return std::nullopt;
  }
  return EncodePng(factory.Get(), frame.Get());
}

std::optional<std::vector<uint8_t>> ImageToDib(
    const std::vector<uint8_t>& image) {
  ComPtr<IWICImagingFactory> factory = CreateFactory();
  if (!factory) {
    return std::nullopt;
  }

  ComPtr<IWICBitmapFrameDecode> frame =
      DecodeFirstFrame(factory.Get(), image.data(), image.size());
  if (!frame) {
    return std::nullopt;
  }

  ComPtr<IWICFormatConverter> converter;
  if (FAILED(factory->CreateFormatConverter(&converter)) ||
      FAILED(converter->Initialize(frame.Get(), GUID_WICPixelFormat32bppBGRA,
                                   WICBitmapDitherTypeNone, nullptr, 0.0,
                                   WICBitmapPaletteTypeCustom))) {
    return std::nullopt;
  }

  UINT width = 0;
  UINT height = 0;
  if (FAILED(converter->GetSize(&width, &height)) || width == 0 ||
      height == 0) {
    return std::nullopt;
  }

  const UINT stride = width * 4;
  std::vector<uint8_t> top_down(static_cast<size_t>(stride) * height);
  if (FAILED(converter->CopyPixels(nullptr, stride,
                                   static_cast<UINT>(top_down.size()),
                                   top_down.data()))) {
    return std::nullopt;
  }

  BITMAPINFOHEADER header = {};
  header.biSize = sizeof(header);
  header.biWidth = static_cast<LONG>(width);
  header.biHeight = static_cast<LONG>(height);
  header.biPlanes = 1;
  header.biBitCount = 32;
  header.biCompression = BI_RGB;
  header.biSizeImage = static_cast<DWORD>(top_down.size());

  std::vector<uint8_t> dib(sizeof(header) + top_down.size());
  std::memcpy(dib.data(), &header, sizeof(header));
  uint8_t* pixels = dib.data() + sizeof(header);
  for (UINT row = 0; row < height; ++row) {
    std::memcpy(pixels + static_cast<size_t>(row) * stride,
                top_down.data() + static_cast<size_t>(height - 1 - row) * stride,
                stride);
  }
  return dib;
}

}  // namespace ferret_clipboard
