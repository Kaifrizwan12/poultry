import '../models/company.dart';
import '../services/companies_service.dart';
import 'base_settings_controller.dart';

class CompaniesController extends SettingsEntityController<Company> {
  CompaniesController() : super(service: CompaniesService(), searchableFields: const ['name', 'phone', 'email', 'contactPerson']);
}
