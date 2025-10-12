import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

class AdHelper {
  static InterstitialAd? _interstitialAd;
  static bool _isAdLoaded = false;
  static DateTime? _lastAdShownTime;

  static final String _realAdUnitId = Platform.isAndroid? 'ca-app-pub-2506270690918503/1748305985' : 'ca-app-pub-2506270690918503/9098621893';


  static final String _testAndroidAdUnitId = 'ca-app-pub-3940256099942544/1033173712';
  static final String _testIosAdUnitId = 'ca-app-pub-3940256099942544/4411468910';

  static void preloadInterstitialAd() {
    if (_isAdLoaded) return;

    final adUnitId = _realAdUnitId;

    InterstitialAd.load(
      adUnitId: adUnitId,
      request: const AdRequest(),
      adLoadCallback: InterstitialAdLoadCallback(
        onAdLoaded: (ad) {
          _interstitialAd = ad;
          _isAdLoaded = true;
          debugPrint('InterstitialAd preloaded successfully.');
        },
        onAdFailedToLoad: (error) {
          _isAdLoaded = false;
          debugPrint('Failed to preload interstitial ad: ${error.message}');
        },
      ),
    );
  }

  static void showAdThenNavigate(BuildContext context, VoidCallback onAdDismissed) {
    if (_lastAdShownTime != null && DateTime.now().difference(_lastAdShownTime!).inMinutes < 2) {
      debugPrint("Ad was shown recently. Navigating directly.");
      onAdDismissed();
      return;
    }

    if (_interstitialAd != null && _isAdLoaded) {
      _configureAndShowAd(onAdDismissed);
    } else {
      _showLoadingDialog(context);

      final adUnitId = _realAdUnitId;

      InterstitialAd.load(
        adUnitId: adUnitId,
        request: const AdRequest(),
        adLoadCallback: InterstitialAdLoadCallback(
          onAdLoaded: (ad) {
            if (!context.mounted) return;
            Navigator.of(context, rootNavigator: true).pop();

            _interstitialAd = ad;
            _isAdLoaded = true;
            _configureAndShowAd(onAdDismissed);
          },
          onAdFailedToLoad: (error) {
            if (!context.mounted) return;
            Navigator.of(context, rootNavigator: true).pop();

            _isAdLoaded = false;
            debugPrint('Failed to load ad: ${error.message}');
            onAdDismissed();
          },
        ),
      );
    }
  }

  static void _configureAndShowAd(VoidCallback onAdDismissed) {
    if (_interstitialAd == null) return;

    _interstitialAd!.fullScreenContentCallback = FullScreenContentCallback(
      onAdShowedFullScreenContent: (ad) {
        _lastAdShownTime = DateTime.now();
      },
      onAdDismissedFullScreenContent: (ad) {
        SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
        ad.dispose();
        _isAdLoaded = false;
        preloadInterstitialAd();
      },
      onAdFailedToShowFullScreenContent: (ad, error) {
        SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
        ad.dispose();
        _isAdLoaded = false;
        debugPrint('Failed to show ad: $error');
      },
    );

    onAdDismissed();
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
    _interstitialAd!.show();
  }

  static void _showLoadingDialog(BuildContext context) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return const Dialog(
          child: Padding(
            padding: EdgeInsets.all(20.0),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                CircularProgressIndicator(),
                SizedBox(width: 20),
                Text("جاري تحميل الإعلان..."),
              ],
            ),
          ),
        );
      },
    );
  }
}