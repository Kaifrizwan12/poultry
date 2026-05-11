import '../models/town.dart';
import '../services/towns_service.dart';
import 'base_settings_controller.dart';

class TownsController extends SettingsEntityController<Town> {
  TownsController() : super(service: TownsService(), searchableFields: const ['name', 'district', 'province']);
}
