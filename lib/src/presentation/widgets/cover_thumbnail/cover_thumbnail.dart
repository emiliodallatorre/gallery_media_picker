import 'package:flutter/material.dart';
import 'package:gallery_media_picker/src/core/decode_image.dart';
import 'package:gallery_media_picker/src/core/functions.dart';
import 'package:gallery_media_picker/src/presentation/pages/gallery_media_picker_controller.dart';
import 'package:photo_manager/photo_manager.dart';

class CoverThumbnail extends StatefulWidget {
  final int thumbnailQuality;
  final double thumbnailScale;
  final BoxFit thumbnailFit;
  final RequestType requestType;

  const CoverThumbnail({
    Key? key,
    required this.requestType,
    this.thumbnailQuality = 120,
    this.thumbnailScale = 1.0,
    this.thumbnailFit = BoxFit.cover,
  }) : super(key: key);

  @override
  State<CoverThumbnail> createState() => _CoverThumbnailState();
}

class _CoverThumbnailState extends State<CoverThumbnail> {
  /// create object of PickerDataProvider
  final provider = GalleryMediaPickerController();

  @override
  void initState() {
    GalleryFunctions.getPermission(setState, provider, widget.requestType);
    super.initState();
  }

  @override
  void dispose() {
    if (mounted) {
      provider.pickedFile.clear();
      provider.picked.clear();
      provider.pathList.clear();
      PhotoManager.stopChangeNotify();
      super.dispose();
    }
  }

  @override
  Widget build(BuildContext context) {
    return provider.pathList.isNotEmpty
        ? Image(
            image: DecodeImage(provider.pathList[0],
                thumbSize: widget.thumbnailQuality,
                index: 0,
                scale: widget.thumbnailScale),
            fit: widget.thumbnailFit,
            filterQuality: FilterQuality.high,
          )
        : Container();
  }
}
