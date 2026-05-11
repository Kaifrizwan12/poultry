import '../models/opening_receivable.dart';
import 'json_settings_service.dart';

class OpeningReceivablesService
    extends JsonSettingsService<OpeningReceivable> {
  OpeningReceivablesService()
      : super(
          entity: 'openings/receivables',
          parser: OpeningReceivable.fromMap,
        );
}
