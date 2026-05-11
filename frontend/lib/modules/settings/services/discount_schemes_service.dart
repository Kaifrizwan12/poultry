import '../models/discount_scheme.dart';
import 'json_settings_service.dart';

class DiscountSchemesService extends JsonSettingsService<DiscountScheme> {
  DiscountSchemesService()
      : super(entity: 'discount-schemes', parser: DiscountScheme.fromMap);
}
