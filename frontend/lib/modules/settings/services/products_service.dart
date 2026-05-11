import '../models/product.dart';
import 'json_settings_service.dart';

class ProductsService extends JsonSettingsService<Product> {
  ProductsService() : super(entity: 'products', parser: Product.fromMap);
}
