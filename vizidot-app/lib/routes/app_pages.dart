import 'package:get/get.dart';

import '../modules/home/views/home_view.dart';
import '../modules/home/views/details_view.dart';

part 'app_routes.dart';

class AppPages {
  static final routes = <GetPage<dynamic>>[
    GetPage(
      name: AppRoutes.home,
      page: () => const HomeView(),
    ),
    GetPage(
      name: AppRoutes.details,
      page: () => const DetailsView(),
      transition: Transition.cupertino,
    ),
  ];
}


