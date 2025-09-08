import 'package:flutter/material.dart';

/// Keys used in domain: keep these stable.
class CategoryPresets {
  static const income = <String, String>{
    'salary': 'Salary',
    'bonus': 'Bonus',
    'interest': 'Interest',
    'other_income': 'Other',
  };

  static const expense = <String, String>{
    'groceries': 'Groceries',
    'rent': 'Rent',
    'bills': 'Bills',
    'transport': 'Transport',
    'entertainment': 'Entertainment',
    'health': 'Health',
    'shopping': 'Shopping',
    'uncategorized': 'Uncategorized',
  };

  static IconData iconFor(String key, {required bool isIncome}) {
    if (isIncome) {
      switch (key) {
        case 'salary': return Icons.work;
        case 'bonus': return Icons.card_giftcard;
        case 'interest': return Icons.savings;
        default: return Icons.account_balance_wallet;
      }
    } else {
      switch (key) {
        case 'groceries': return Icons.local_grocery_store;
        case 'rent': return Icons.home_filled;
        case 'bills': return Icons.receipt_long;
        case 'transport': return Icons.directions_bus_filled;
        case 'entertainment': return Icons.movie;
        case 'health': return Icons.health_and_safety;
        case 'shopping': return Icons.shopping_bag;
        default: return Icons.category;
      }
    }
  }

  static Color colorFor(String key, {required bool isIncome}) {
    if (isIncome) return Colors.green;
    // simple palette for expenses
    switch (key) {
      case 'groceries': return Colors.orange;
      case 'rent': return Colors.blueGrey;
      case 'bills': return Colors.indigo;
      case 'transport': return Colors.teal;
      case 'entertainment': return Colors.purple;
      case 'health': return Colors.red;
      case 'shopping': return Colors.pink;
      default: return Colors.grey;
    }
  }
}
