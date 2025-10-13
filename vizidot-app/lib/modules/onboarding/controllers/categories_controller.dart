import 'package:get/get.dart';

class CategoryItem {
  final String name;
  final String asset;
  CategoryItem(this.name, this.asset);
}

class CategoriesController extends GetxController {
  final items = <CategoryItem>[
    CategoryItem('Country', 'assets/categories/Country.png'),
    CategoryItem('Hip-Hop', 'assets/categories/Hip-Hop.png'),
    CategoryItem('Hard Rock', 'assets/categories/Hard Rock.png'),
    CategoryItem('Indie', 'assets/categories/Indie.png'),
    CategoryItem('Chill out', 'assets/categories/Chill out.png'),
    CategoryItem('R&B', 'assets/categories/R&B.png'),
    CategoryItem('Pop', 'assets/categories/Pop.png'),
    CategoryItem('Metallic', 'assets/categories/Metallic.png'),
    CategoryItem('Rock', 'assets/categories/Rock.png'),
  ].obs;

  final selected = <int>{}.obs;

  bool get canContinue => selected.length >= 3;

  void toggle(int index) {
    if (selected.contains(index)) {
      selected.remove(index);
    } else {
      selected.add(index);
    }
    // Ensure observers rebuild immediately
    selected.refresh();
  }
}


