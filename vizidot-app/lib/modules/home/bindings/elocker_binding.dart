import 'package:get/get.dart';
import '../controllers/elocker_controller.dart';

class ELockerBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<ELockerController>(() => ELockerController());
  }
}

