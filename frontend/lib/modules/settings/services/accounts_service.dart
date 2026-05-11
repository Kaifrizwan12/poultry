import '../models/account.dart';
import 'json_settings_service.dart';

class AccountsService extends JsonSettingsService<Account> {
  AccountsService() : super(entity: 'accounts', parser: Account.fromMap);
}
