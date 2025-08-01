import 'dart:io';
import 'package:flutter/material.dart';
import 'package:unity_ads_plugin/unity_ads_plugin.dart';

class AdManager {
  static late BuildContext _context;

  static DateTime? _lastInterstitialAdTime;
  static DateTime? _lastRewardedAdTime;
  static const Duration adCooldown = Duration(minutes: 2);

  static Future<String> getGameId() async {
    if (Platform.isAndroid) {
      return '5783672';
    } else if (Platform.isIOS) {
      return '5783673';
    } else {
      throw UnsupportedError('هذا النظام غير مدعوم');
    }
  }

  static Future<String> getInterstitialVideoAdPlacementId() async {
    if (Platform.isAndroid) {
      return 'Interstitial_Android';
    } else if (Platform.isIOS) {
      return 'Interstitial_iOS';
    } else {
      throw UnsupportedError('هذا النظام غير مدعوم');
    }
  }

  static Future<String> getRewardedVideoAdPlacementId() async {
    if (Platform.isAndroid) {
      return 'Rewarded_Android';
    } else if (Platform.isIOS) {
      return 'Rewarded_iOS';
    } else {
      throw UnsupportedError('هذا النظام غير مدعوم');
    }
  }

  static Future<String> getBannerAdPlacementId() async {
    if (Platform.isAndroid) {
      return 'Banner_Android';
    } else if (Platform.isIOS) {
      return 'Banner_iOS';
    } else {
      throw UnsupportedError('هذا النظام غير مدعوم');
    }
  }

  static final Map<String, bool> placements = {
    'Interstitial_Android': false,
    'Rewarded_Android': false,
    'Interstitial_iOS': false,
    'Rewarded_iOS': false,
  };

  static Map<String, int> adRetryCount = {
    'Interstitial_Android': 0,
    'Rewarded_Android': 0,
    'Interstitial_iOS': 0,
    'Rewarded_iOS': 0,
  };

  static const int maxRetryCount = 5;

  static Future<void> initializeAds(BuildContext context) async {
    _context = context;

    String gameId = await getGameId();
    UnityAds.init(
      gameId: gameId,
      testMode: false,
      onComplete: () {
        print('✅ تم تهيئة إعلانات Unity بنجاح');
      },
      onFailed: (error, message) {
        print('❌ فشل تهيئة إعلانات Unity: $error - $message');
      },
    );

    UnityAds.setPrivacyConsent(PrivacyConsentType.gdpr, true);
    UnityAds.setPrivacyConsent(PrivacyConsentType.ageGate, true);
    UnityAds.setPrivacyConsent(PrivacyConsentType.ccpa, true);
    UnityAds.setPrivacyConsent(PrivacyConsentType.pipl, true);
  }

  static Future<void> _loadAd(String placementId) async {
    try {
      await UnityAds.load(
        placementId: placementId,
        onComplete: (placementId) {
          print('✅ الإعلان جاهز: $placementId');
          placements[placementId] = true;
          adRetryCount[placementId] = 0;
        },
        onFailed: (placementId, error, message) async {
          print('❌ فشل تحميل الإعلان: $placementId - $error - $message');
          int currentRetryCount = adRetryCount[placementId] ?? 0;
          if (currentRetryCount < maxRetryCount) {
            adRetryCount[placementId] = currentRetryCount + 1;
            print('🔄 إعادة محاولة تحميل الإعلان: $placementId');
            await Future.delayed(Duration(seconds: 2));
            _loadAd(placementId);
          } else {
            print('⚠️ تم الوصول إلى الحد الأقصى لمحاولات التحميل: $placementId');
          }
        },
      );
    } catch (e) {
      print("⚠️ خطأ أثناء تحميل الإعلان: $e");
    }
  }

  static Future<bool> showInterstitialAd(BuildContext context) async {
    String placementId = await getInterstitialVideoAdPlacementId();

    if (_lastInterstitialAdTime != null &&
        DateTime.now().difference(_lastInterstitialAdTime!) < adCooldown) {
      print("⚠️ لم يمر المدة المحددة منذ آخر إعلان بيني، تخطي عرض الإعلان.");
      return false;
    }

    placements[placementId] = false;
    _showLoadingDialog(context, "جاري تحميل الإعلان...");

    while (placements[placementId] == false) {
      await _loadAd(placementId);
      await Future.delayed(Duration(seconds: 2));
    }

    Navigator.of(context, rootNavigator: true).pop();

    if (placements[placementId] == true) {
      try {
        await UnityAds.showVideoAd(
          placementId: placementId,
          onComplete: (placementId) {
            print('✅ الإعلان المكتمل: $placementId');
            _loadAd(placementId);
          },
          onFailed: (placementId, error, message) {
            print('❌ فشل تشغيل الإعلان: $placementId - $error - $message');
          },
        );

        _lastInterstitialAdTime = DateTime.now();
        return true;
      } catch (e) {
        print('⚠️ خطأ أثناء تشغيل الإعلان: $e');
        return false;
      }
    } else {
      print('⚠️ الإعلان غير جاهز');
      return false;
    }
  }

  static Future<bool> continueApp(BuildContext context) async {
    String placementId = await getRewardedVideoAdPlacementId();

    if (_lastRewardedAdTime != null &&
        DateTime.now().difference(_lastRewardedAdTime!) < adCooldown) {
      print("⚠️ لم يمر المدة المحددة منذ آخر إعلان مكافأة، تخطي عرض الإعلان.");
      return false;
    }

    placements[placementId] = false;
    _showLoadingDialog(context, "جاري تحميل الإعلان...");

    while (placements[placementId] == false) {
      await _loadAd(placementId);
      await Future.delayed(Duration(seconds: 2));
    }

    Navigator.of(context, rootNavigator: true).pop();

    if (placements[placementId] == true) {
      try {
        await UnityAds.showVideoAd(
          placementId: placementId,
          onComplete: (placementId) {
            print('✅ الإعلان المكتمل: $placementId');
            _loadAd(placementId);
          },
          onFailed: (placementId, error, message) {
            print('❌ فشل تشغيل الإعلان: $placementId - $error - $message');
          },
        );

        _lastRewardedAdTime = DateTime.now();
        return true;
      } catch (e) {
        print('⚠️ خطأ أثناء تشغيل الإعلان: $e');
        return false;
      }
    } else {
      print('⚠️ الإعلان غير جاهز');
      return false;
    }
  }

  static Future<Widget> getBannerAdWidget() async {
    String placementId = await getBannerAdPlacementId();

    return UnityBannerAd(
      placementId: placementId,
      onLoad: (id) => print('✅ تم تحميل بانر الإعلان: $id'),
      onClick: (id) => print('🖱️ تم الضغط على بانر الإعلان: $id'),
      onShown: (id) => print('📺 تم عرض بانر الإعلان: $id'),
      onFailed: (id, error, message) =>
          print('❌ فشل عرض بانر الإعلان: $id - $error - $message'),
    );
  }

  static void _showLoadingDialog(BuildContext context, String message) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return WillPopScope(
          onWillPop: () async => false,
          child: Dialog(
            shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.0)),
            backgroundColor: Colors.grey[900],
            child: Padding(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  CircularProgressIndicator(color: Colors.blue),
                  SizedBox(height: 16),
                  Text(
                    message,
                    style: TextStyle(fontSize: 16, color: Colors.white),
                  ),
                  SizedBox(height: 20),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
