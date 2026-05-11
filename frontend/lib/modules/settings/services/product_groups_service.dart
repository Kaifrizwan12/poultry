import '../models/product_group.dart';
import 'json_settings_service.dart';

class ProductGroupsService extends JsonSettingsService<ProductGroup> {
  ProductGroupsService()
      : super(entity: 'product-groups', parser: ProductGroup.fromMap);
}
