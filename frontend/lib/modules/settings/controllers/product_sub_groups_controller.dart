import '../models/product_sub_group.dart';
import '../services/product_sub_groups_service.dart';
import 'base_settings_controller.dart';

class ProductSubGroupsController extends SettingsEntityController<ProductSubGroup> {
  ProductSubGroupsController() : super(service: ProductSubGroupsService(), searchableFields: const ['name', 'description']);
}
