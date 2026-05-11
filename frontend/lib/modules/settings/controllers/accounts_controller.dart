import '../models/account.dart';
import '../services/accounts_service.dart';
import 'base_settings_controller.dart';

class AccountsController extends SettingsEntityController<Account> {
  AccountsController() : super(service: AccountsService(), searchableFields: const ['accountName', 'accountCode', 'accountType']);
}
