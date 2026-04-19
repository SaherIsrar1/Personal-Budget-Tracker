import 'package:cloud_firestore/cloud_firestore.dart';

class CategoryModel {
  final String id;
  final String name;
  final String icon;
  final String color; // hex string e.g. '#1BA589'
  final bool isDefault;

  const CategoryModel({
    required this.id,
    required this.name,
    required this.icon,
    required this.color,
    this.isDefault = false,
  });

  factory CategoryModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return CategoryModel(
      id: doc.id,
      name: data['name'] ?? '',
      icon: data['icon'] ?? '💰',
      color: data['color'] ?? '#1BA589',
      isDefault: data['isDefault'] ?? false,
    );
  }

  Map<String, dynamic> toFirestore() => {
    'name': name,
    'icon': icon,
    'color': color,
    'isDefault': isDefault,
  };

  // Default categories shipped with the app
  static List<CategoryModel> get defaults => [
    const CategoryModel(id: 'food',       name: 'Food',          icon: '🍴', color: '#FF6B6B', isDefault: true),
    const CategoryModel(id: 'transport',  name: 'Transport',     icon: '🚗', color: '#4ECDC4', isDefault: true),
    const CategoryModel(id: 'rent',       name: 'Rent',          icon: '🏠', color: '#45B7D1', isDefault: true),
    const CategoryModel(id: 'utilities',  name: 'Utility Bills', icon: '⚡', color: '#96CEB4', isDefault: true),
    const CategoryModel(id: 'shopping',   name: 'Shopping',      icon: '🛍️', color: '#FFEAA7', isDefault: true),
    const CategoryModel(id: 'health',     name: 'Healthcare',    icon: '💊', color: '#DDA0DD', isDefault: true),
    const CategoryModel(id: 'salary',     name: 'Salary',        icon: '💼', color: '#98FB98', isDefault: true),
    const CategoryModel(id: 'freelance',  name: 'Freelance',     icon: '💻', color: '#87CEEB', isDefault: true),
    const CategoryModel(id: 'other',      name: 'Other',         icon: '📦', color: '#D3D3D3', isDefault: true),
  ];
}
