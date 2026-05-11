import '../models/customer.dart';
import '../services/customers_service.dart';
import 'base_settings_controller.dart';

class CustomersController extends SettingsEntityController<Customer> {
  CustomersController() : super(service: CustomersService(), searchableFields: const ['name', 'code', 'phone', 'email']);
}
