abstract class SettingsServiceBase<T> {
  SettingsServiceBase(this.entity);

  final String entity;

  Future<List<T>> fetchAll();
  Future<T> create(Map<String, dynamic> body);
  Future<T> update(String id, Map<String, dynamic> body);
  Future<void> delete(String id);
}
