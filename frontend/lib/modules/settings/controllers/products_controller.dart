import '../models/product.dart';
import '../services/products_service.dart';
import 'base_settings_controller.dart';

class ProductsController extends SettingsEntityController<Product> {
  ProductsController() : super(service: ProductsService(), searchableFields: const ['name', 'code', 'description']);
}
