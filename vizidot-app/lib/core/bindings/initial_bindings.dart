import 'package:get/get.dart';

import '../../modules/home/controllers/home_controller.dart';
import '../utils/theme_controller.dart';
import '../utils/app_config.dart';

class InitialBindings extends Bindings {
  @override
  void dependencies() {
    Get.put<ThemeController>(ThemeController(), permanent: true);
    Get.put<AppConfig>(AppConfig.fromEnv(), permanent: true);
    Get.lazyPut<HomeController>(() => HomeController(), fenix: true);
  }
}


