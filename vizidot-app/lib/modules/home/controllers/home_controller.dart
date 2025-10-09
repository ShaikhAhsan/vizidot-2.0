import 'package:get/get.dart';

class HomeController extends GetxController {
  final RxInt counter = 0.obs;
  final RxInt selectedIndex = 0.obs;

  void increment() {
    counter.value++;
  }

  void onNavTap(int index) {
    selectedIndex.value = index;
  }
}


