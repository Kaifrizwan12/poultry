import '../models/product_group.dart';
import '../services/product_groups_service.dart';
import 'base_settings_controller.dart';

class ProductGroupsController extends SettingsEntityController<ProductGroup> {
  ProductGroupsController() : super(service: ProductGroupsService(), searchableFields: const ['name', 'description']);
}
