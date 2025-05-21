import 'dart:async';
import 'dart:io';
import 'package:google_mobile_ads/google_mobile_ads.dart';

class AdHelper {
  // اضبط القيمتين كما يناسبك
  static const int _maxRetry     = 3;             // أقصى عدد للمحاولات
  static const Duration _delay  = Duration(seconds: 30); // الفاصل بين المحاولات

  static String get bannerAdUnitId {
    if (Platform.isAndroid) {
      return 'ca-app-pub-9181001319721306/8061809496';
    } else if (Platform.isIOS) {
      return 'ca-app-pub-9181001319721306/2581056562';
    } else {
      return '';
    }
  }

  /// إعلان بمقاس ثابت (٣٢٠×٥٠). لا حاجة لتمرير `context`.
  static BannerAd loadFixedBanner({
    required Function(BannerAd) onLoaded,
    required Function(LoadAdError) onPermanentFail,
  }) {
    return _load(
      adSize: AdSize.banner,
      onLoaded: onLoaded,
      onPermanentFail: onPermanentFail,
    );
  }

  /// إعلان بمقاس Adaptive بعرض ممرَّر من خارج الكلاس.
  /// - `width` هو العرض المنطقى (logical pixels).
  static BannerAd loadAdaptiveBanner({
    required int width,
    required Function(BannerAd) onLoaded,
    required Function(LoadAdError) onPermanentFail,
  }) {
    return _load(
      adSize: AdSize(width: width, height: 80),
      onLoaded: onLoaded,
      onPermanentFail: onPermanentFail,
    );
  }


  static BannerAd _load({
    required AdSize adSize,
    required Function(BannerAd) onLoaded,
    required Function(LoadAdError) onPermanentFail,
    int attempt = 0,
  }) {
    late BannerAd banner;

    banner = BannerAd(
      adUnitId: bannerAdUnitId,
      size: adSize,
      request: const AdRequest(),
      listener: BannerAdListener(
        onAdLoaded: (ad) => onLoaded(ad as BannerAd),
        onAdFailedToLoad: (ad, error) {
          ad.dispose();

          if (attempt < _maxRetry) {
            Future.delayed(_delay, () {
              _load(
                adSize: adSize,
                onLoaded: onLoaded,
                onPermanentFail: onPermanentFail,
                attempt: attempt + 1,
              );
            });
          } else {
            onPermanentFail(error);
          }
        },
      ),
    )..load();

    return banner;
  }
}
