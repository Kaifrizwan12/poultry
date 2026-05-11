import '../models/company.dart';
import 'json_settings_service.dart';

class CompaniesService extends JsonSettingsService<Company> {
  CompaniesService() : super(entity: 'companies', parser: Company.fromMap);
}
