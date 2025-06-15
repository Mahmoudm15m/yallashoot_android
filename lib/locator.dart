import 'package:get_it/get_it.dart';
import 'package:yallashoot/api/main_api.dart';
import 'package:yallashoot/settings_provider.dart';

final locator = GetIt.instance;

void setupLocator(SettingsProvider settingsProvider) {

  locator.registerSingleton<SettingsProvider>(settingsProvider);

  locator.registerSingleton<ApiData>(ApiData());
}