import 'dart:async';
import 'dart:developer' as dev;

import 'package:flutter/material.dart';
import 'package:gallery_media_picker/src/presentation/pages/gallery_media_picker_controller.dart';
import 'package:gallery_media_picker/src/presentation/widgets/select_album_path/dropdown.dart';
import 'package:gallery_media_picker/src/presentation/widgets/select_album_path/overlay_drop_down.dart';
import 'package:oktoast/oktoast.dart';
import 'package:photo_manager/photo_manager.dart';

class GalleryFunctions {
  static FeatureController<T> showDropDown<T>({
    required BuildContext context,
    required DropdownWidgetBuilder<T> builder,
    double? height,
    Duration animationDuration = const Duration(milliseconds: 250),
    required TickerProvider tickerProvider,
  }) {
    final animationController = AnimationController(
      vsync: tickerProvider,
      duration: animationDuration,
    );
    final completer = Completer<T?>();
    var isReply = false;
    OverlayEntry? entry;
    void close(T? value) async {
      if (isReply) {
        return;
      }
      isReply = true;
      animationController.animateTo(0).whenCompleteOrCancel(() async {
        await Future.delayed(const Duration(milliseconds: 16));
        completer.complete(value);
        entry?.remove();
      });
    }

    /// overlay widget
    entry = OverlayEntry(
        builder: (context) => GestureDetector(
              behavior: HitTestBehavior.translucent,
              onTap: () => close(null),
              child: OverlayDropDown(
                  height: height!,
                  close: close,
                  animationController: animationController,
                  builder: builder),
            ));
    Overlay.of(context).insert(entry);
    animationController.animateTo(1);
    return FeatureController(
      completer,
      close,
    );
  }

  static onPickMax(GalleryMediaPickerController provider) {
    provider.onPickMax.addListener(() {
      dev.log('Maximum items picked: ${provider.max}',
          name: 'GalleryMediaPicker');
      showToast("Already pick ${provider.max} items.");
    });
  }

  static getPermission(setState, GalleryMediaPickerController provider,
      final RequestType requestType) async {
    /// request for device permission
    dev.log(
        'Requesting media permission with access level: ${IosAccessLevel.readWrite}',
        name: 'GalleryMediaPicker');
    var result = await PhotoManager.requestPermissionExtend(
        requestOption: const PermissionRequestOption(
            iosAccessLevel: IosAccessLevel.readWrite));
    if (result.isAuth) {
      /// load "recent" album
      dev.log('Permission granted successfully', name: 'GalleryMediaPicker');
      provider.setAssetCount();
      PhotoManager.startChangeNotify();
      dev.log('Started change notification listener',
          name: 'GalleryMediaPicker');
      PhotoManager.addChangeCallback((value) {
        dev.log('Media change detected, refreshing path list',
            name: 'GalleryMediaPicker');
        _refreshPathList(setState, provider, requestType);
      });

      if (provider.pathList.isEmpty) {
        dev.log('Path list is empty, performing initial refresh',
            name: 'GalleryMediaPicker');
        _refreshPathList(setState, provider, requestType);
      }
    } else {
      /// if result is fail, you can call `PhotoManager.openSetting();`
      /// to open android/ios application's setting to get permission
      dev.log('Permission denied. Auth state: ${result.toString()}',
          name: 'GalleryMediaPicker');
      PhotoManager.openSetting();
    }
  }

  static _refreshPathList(setState, GalleryMediaPickerController provider,
      final RequestType requestType) {
    dev.log('Refreshing path list for media type: ${requestType.toString()}',
        name: 'GalleryMediaPicker');
    PhotoManager.getAssetPathList(type: requestType).then((pathList) {
      /// don't delete setState
      dev.log('Retrieved ${pathList.length} media paths',
          name: 'GalleryMediaPicker');
      setState(() {
        provider.resetPathList(pathList);
        dev.log('Path list updated in provider', name: 'GalleryMediaPicker');
      });
    }).catchError((error) {
      dev.log('Error refreshing path list: $error',
          name: 'GalleryMediaPicker', error: error);
    });
  }

  /// get asset path
  static Future getFile(AssetEntity asset) async {
    dev.log('Getting file for asset: ${asset.id}', name: 'GalleryMediaPicker');
    try {
      var file = await asset.file;
      if (file != null) {
        dev.log('Successfully retrieved file: ${file.path}',
            name: 'GalleryMediaPicker');
        return file.path;
      } else {
        dev.log('Retrieved null file for asset: ${asset.id}',
            name: 'GalleryMediaPicker');
        return null;
      }
    } catch (e) {
      dev.log('Error getting file for asset ${asset.id}: $e',
          name: 'GalleryMediaPicker', error: e);
      return null;
    }
  }
}

class FeatureController<T> {
  final Completer<T?> completer;

  final ValueSetter<T?> close;

  FeatureController(this.completer, this.close);

  Future<T?> get closed => completer.future;
}
