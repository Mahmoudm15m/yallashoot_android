import 'dart:io';
import 'package:flutter/material.dart';
import 'package:unity_ads_plugin/unity_ads_plugin.dart';

class AdManager {
  static late BuildContext _context;

  static const String _androidGameId = '5963384';
  static const String _androidBannerId = 'Banner_Android';
  static const String _androidInterstitialId = 'Interstitial_Android';
  static const String _androidRewardedId = 'Rewarded_Android';

  static const String _iosGameId = '5963385';
  static const String _iosBannerId = 'Banner_iOS';
  static const String _iosInterstitialId = 'Interstitial_iOS';
  static const String _iosRewardedId = 'Rewarded_iOS';

  static DateTime? _lastInterstitialAdTime;
  static DateTime? _lastRewardedAdTime;
  static const Duration adCooldown = Duration(minutes: 3);

  static String getGameId() => Platform.isIOS ? _iosGameId : _androidGameId;
  static String getBannerAdPlacementId() => Platform.isIOS ? _iosBannerId : _androidBannerId;
  static String getInterstitialVideoAdPlacementId() => Platform.isIOS ? _iosInterstitialId : _androidInterstitialId;
  static String getRewardedVideoAdPlacementId() => Platform.isIOS ? _iosRewardedId : _androidRewardedId;

  static final Map<String, bool> placements = {
    _androidInterstitialId: false,
    _androidRewardedId: false,
    _iosInterstitialId: false,
    _iosRewardedId: false,
  };

  static Map<String, int> adRetryCount = {
    _androidInterstitialId: 0,
    _androidRewardedId: 0,
    _iosInterstitialId: 0,
    _iosRewardedId: 0,
  };

  static const int maxRetryCount = 5;

  static Future<void> initializeAds(BuildContext context) async {
    _context = context;

    UnityAds.init(
      gameId: getGameId(),
      testMode: false,
      onComplete: () => print('✅ تم تهيئة إعلانات Unity بنجاح'),
      onFailed: (error, message) => print('❌ فشل تهيئة إعلانات Unity: $error - $message'),
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

  /// 🎬 عرض إعلان بيني (Interstitial)
  static Future<bool> showInterstitialAd(BuildContext context) async {
    String placementId = getInterstitialVideoAdPlacementId();

    if (_lastInterstitialAdTime != null &&
        DateTime.now().difference(_lastInterstitialAdTime!) < adCooldown) {
      print("⏳ تم تخطي الإعلان — لم تمر 3 دقائق منذ آخر إعلان بيني.");
      return false; // ✅ لا تظهر الإعلان ولا تفتح الحوار
    }

    placements[placementId] = false;
    _showLoadingDialog(context);

    int attempts = 0;
    while (placements[placementId] != true && attempts < 5) {
      await _loadAd(placementId);
      await Future.delayed(const Duration(seconds: 2));
      attempts++;
    }

    Navigator.of(context, rootNavigator: true).pop();

    if (placements[placementId] == true) {
      try {
        await UnityAds.showVideoAd(
          placementId: placementId,
          onComplete: (placementId) {
            print('✅ الإعلان المكتمل: $placementId');
            _lastInterstitialAdTime = DateTime.now();
            _loadAd(placementId);
          },
          onFailed: (placementId, error, message) {
            print('❌ فشل تشغيل الإعلان: $placementId - $error - $message');
          },
          onSkipped: (placementId) {
            print('⏭️ تم تخطي الإعلان: $placementId');
            _lastInterstitialAdTime = DateTime.now();
          },
        );
        return true;
      } catch (e) {
        print('⚠️ خطأ أثناء تشغيل الإعلان: $e');
        return false;
      }
    } else {
      print('⚠️ الإعلان غير جاهز بعد عدة محاولات');
      return false;
    }
  }

  /// 🎁 عرض إعلان مكافأة (Rewarded)
  static Future<bool> continueApp(BuildContext context) async {
    String placementId = getRewardedVideoAdPlacementId();

    if (_lastRewardedAdTime != null &&
        DateTime.now().difference(_lastRewardedAdTime!) < adCooldown) {
      print("⏳ تم تخطي الإعلان — لم تمر 3 دقائق منذ آخر إعلان مكافأة.");
      return false; // ✅ لا تظهر الإعلان
    }

    placements[placementId] = false;
    _showLoadingDialog(context);

    int attempts = 0;
    while (placements[placementId] != true && attempts < 5) {
      await _loadAd(placementId);
      await Future.delayed(const Duration(seconds: 2));
      attempts++;
    }

    Navigator.of(context, rootNavigator: true).pop();

    if (placements[placementId] == true) {
      try {
        await UnityAds.showVideoAd(
          placementId: placementId,
          onComplete: (placementId) {
            print('✅ الإعلان المكتمل: $placementId');
            _lastRewardedAdTime = DateTime.now();
            _loadAd(placementId);
          },
          onFailed: (placementId, error, message) {
            print('❌ فشل تشغيل الإعلان: $placementId - $error - $message');
          },
          onSkipped: (placementId) {
            print('⏭️ تم تخطي الإعلان: $placementId');
            _lastInterstitialAdTime = DateTime.now();
          },
        );
        return true;
      } catch (e) {
        print('⚠️ خطأ أثناء تشغيل الإعلان: $e');
        return false;
      }
    } else {
      print('⚠️ الإعلان غير جاهز بعد عدة محاولات');
      return false;
    }
  }

  static void _showLoadingDialog(BuildContext context) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return WillPopScope(
          onWillPop: () async => false,
          child: Dialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(15.0),
            ),
            backgroundColor: Colors.black.withOpacity(0.8),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 24.0, horizontal: 20.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const CircularProgressIndicator(
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    strokeWidth: 3,
                  ),
                  const SizedBox(height: 20),
                  const Text(
                    "لحظات من فضلك...",
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 17,
                      color: Colors.white,
                      fontWeight: FontWeight.w300,
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
