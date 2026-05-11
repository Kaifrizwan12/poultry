import '../models/customer.dart';
import 'json_settings_service.dart';

class CustomersService extends JsonSettingsService<Customer> {
  CustomersService() : super(entity: 'customers', parser: Customer.fromMap);
}
