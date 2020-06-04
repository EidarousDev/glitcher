import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:loading_gifs/loading_gifs.dart';

//enum CacheImageShape {
//  Rounded,
//  Rectangular,
//}

class CacheThisImage extends StatefulWidget {
//  final CacheImageShape imageShape;
  final String imageUrl;
  final BoxShape imageShape;
  final double width;
  final double height;
  final String defaultAssetImage;

  const CacheThisImage({
    Key key,
    this.imageUrl,
    this.imageShape,
    this.width,
    this.height,
    this.defaultAssetImage,
  }) : super(key: key);
//  const CacheThisImage(
//      {Key key,
//      this.imageUrl,
//      this.width,
//      this.height,
//      this.defaultAssetImage,
//      this.imageShape = CacheImageShape.Rounded})
//      : super(key: key);

  @override
  _CacheThisImageState createState() => _CacheThisImageState();
}

class _CacheThisImageState extends State<CacheThisImage> {
  @override
  Widget build(BuildContext context) {
    return _cacheRoundedImage(widget.imageUrl, widget.imageShape, widget.width,
        widget.height, widget.defaultAssetImage);
  }

  Widget _cacheRoundedImage(String imageUrl, BoxShape boxShape, double width,
      double height, String defaultAssetImage) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        shape: boxShape,
      ),
      child: imageUrl != null
          ? CachedNetworkImage(
              imageUrl: imageUrl,
              imageBuilder: (context, imageProvider) => Container(
                width: width,
                height: height,
                decoration: BoxDecoration(
                  shape: boxShape,
                  image:
                      DecorationImage(image: imageProvider, fit: BoxFit.cover),
                ),
              ),
              placeholder: (context, loggedInProfileImageURL) => Center(
                  child: Image.asset(
                'assets/images/glitcher_loader.gif',
                height: 80,
                width: 80,
              )),
              errorWidget: (context, loggedInProfileImageURL, error) =>
                  Icon(Icons.error),
            )
          : Container(
              width: width,
              height: height,
              decoration: BoxDecoration(
                shape: boxShape,
                image: DecorationImage(
                    image: AssetImage(defaultAssetImage), fit: BoxFit.cover),
              ),
            ),
    );
  }
}
