import '../models/product_sub_group.dart';
import 'json_settings_service.dart';

class ProductSubGroupsService extends JsonSettingsService<ProductSubGroup> {
  ProductSubGroupsService()
      : super(entity: 'product-sub-groups', parser: ProductSubGroup.fromMap);
}
