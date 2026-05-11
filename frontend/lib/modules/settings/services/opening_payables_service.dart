import '../models/opening_payable.dart';
import 'json_settings_service.dart';

class OpeningPayablesService extends JsonSettingsService<OpeningPayable> {
  OpeningPayablesService()
      : super(entity: 'openings/payables', parser: OpeningPayable.fromMap);
}
