import 'package:flutter/material.dart';

import '../models/food.dart';
import '../repositories/food_repository.dart';

class FoodCatalogScreen extends StatefulWidget {
  const FoodCatalogScreen({
    super.key,
    required this.repository,
    required this.onSignOut,
  });

  final FoodRepository repository;
  final Future<void> Function() onSignOut;

  @override
  State<FoodCatalogScreen> createState() => _FoodCatalogScreenState();
}

class _FoodCatalogScreenState extends State<FoodCatalogScreen> {
  late final Future<List<Food>> _foods;
  bool _isSigningOut = false;

  @override
  void initState() {
    super.initState();
    _foods = widget.repository.getFoods();
  }

  String _nutrient(double? value, String unit) {
    if (value == null) return '—';
    final text = value.toString().replaceFirst(RegExp(r'\.0$'), '');
    return '$text $unit';
  }

  Future<void> _signOut() async {
    setState(() {
      _isSigningOut = true;
    });

    try {
      await widget.onSignOut();
    } catch (_) {
      if (!mounted) return;

      setState(() {
        _isSigningOut = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Nu am putut face deconectarea. Încearcă din nou.'),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Catalog alimente'),
        actions: [
          IconButton(
            onPressed: _isSigningOut ? null : _signOut,
            tooltip: 'Deconectare',
            icon: _isSigningOut
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.logout),
          ),
        ],
      ),
      body: FutureBuilder<List<Food>>(
        future: _foods,
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return const Center(child: Text('Nu am putut încărca alimentele.'));
          }

          final foods = snapshot.requireData;

          if (foods.isEmpty) {
            return const Center(child: Text('Nu există alimente în catalog.'));
          }

          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: foods.length,
            separatorBuilder: (context, index) => const Divider(),
            itemBuilder: (context, index) {
              final food = foods[index];

              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    food.name,
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  if (food.category != null)
                    Text('Categorie: ${food.category}'),
                  if (food.preparationState != null)
                    Text('Preparare: ${food.preparationState}'),
                  Text('per 100 ${food.nutritionBasisUnit}'),
                  Text('Energie: ${_nutrient(food.energyKcal, 'kcal')}'),
                  Text('Proteine: ${_nutrient(food.proteinG, 'g')}'),
                  Text('Carbohidrați: ${_nutrient(food.carbohydratesG, 'g')}'),
                  Text('Grăsimi: ${_nutrient(food.fatG, 'g')}'),
                ],
              );
            },
          );
        },
      ),
    );
  }
}
