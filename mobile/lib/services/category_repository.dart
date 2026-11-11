import '../models/category.dart';
import 'api_service.dart';

class CategoryRepository {
  final ApiService api;
  CategoryRepository(this.api);

  Future<List<Category>> list({String? type}) async {
    final res = await api.get('/categories', query: {'type': type});
    return (res as List).map((e) => Category.fromJson(e)).toList();
  }

  Future<Category> create(String name, String type, {String color = '#6C5CE7'}) async {
    final res = await api.post('/categories', {'name': name, 'type': type, 'color': color});
    return Category.fromJson(res);
  }

  Future<Category> update(int id, String name, String type, {String color = '#6C5CE7'}) async {
    final res = await api.put('/categories/$id', {'name': name, 'type': type, 'color': color});
    return Category.fromJson(res);
  }

  Future<void> delete(int id) => api.delete('/categories/$id');
}
