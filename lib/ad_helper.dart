import 'dart:io';
import 'package:google_mobile_ads/google_mobile_ads.dart';


class AdHelper {
  static String get bannerAdUnitId {
    if (Platform.isAndroid) {
      return 'ca-app-pub-9181001319721306/8061809496';
    } else if (Platform.isIOS){
      return "ca-app-pub-9181001319721306/2581056562" ;
    } else {
      return "";
    }
  }

  static BannerAd loadBannerAd({
    required Function(Ad) onAdLoaded,
    required Function(Ad, LoadAdError) onAdFailedToLoad,
  }) {
    return BannerAd(
      adUnitId: bannerAdUnitId,
      size: AdSize.largeBanner,
      request: const AdRequest(),
      listener: BannerAdListener(
        onAdLoaded: onAdLoaded,
        onAdFailedToLoad: onAdFailedToLoad,
      ),
    )..load();
  }
}
