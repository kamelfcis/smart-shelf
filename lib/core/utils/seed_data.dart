import '../../data/datasources/supabase_client.dart';

/// Inserts demo shelves + items (5 per shelf) for the currently signed-in user.
/// Safe to call multiple times — each call creates a new independent set.
class SeedData {
  SeedData._();

  static Future<void> insert() async {
    final userId = supabase.auth.currentUser?.id;
    if (userId == null) return;

    // ── 3 demo shelves ──────────────────────────────────────────────────────
    final shelves = await supabase
        .from('shelves')
        .insert([
          {
            'user_id': userId,
            'name': 'Kitchen Pantry',
            'location': 'Kitchen — Cabinet A',
            'sensor_id': 'esp8266-kitchen-01',
          },
          {
            'user_id': userId,
            'name': 'Medical Cabinet',
            'location': 'Bathroom — Top Shelf',
            'sensor_id': 'esp8266-medical-02',
          },
          {
            'user_id': userId,
            'name': 'Office Supplies',
            'location': 'Home Office — Desk',
            'sensor_id': null,
          },
        ])
        .select('id');

    if (shelves == null || (shelves as List).isEmpty) return;

    final kitchenId = shelves[0]['id'] as String;
    final medicalId = shelves[1]['id'] as String;
    final officeId = shelves[2]['id'] as String;

    // ── 5 items per shelf ───────────────────────────────────────────────────
    await supabase.from('items').insert([
      // ── Kitchen Pantry ────────────────────────────────────────────────────
      {
        'shelf_id': kitchenId,
        'name': 'Olive Oil',
        'unit_weight_g': 250.0,
        'tare_weight_g': 180.0,
        'min_threshold': 2,
        'current_weight': 680.0,
        'slot_number': 1,
        'image_url':
            'https://images.unsplash.com/photo-1474979266404-7eaacbcd87c5?auto=format&fit=crop&w=400&q=80',
      },
      {
        'shelf_id': kitchenId,
        'name': 'White Sugar',
        'unit_weight_g': 1000.0,
        'tare_weight_g': 220.0,
        'min_threshold': 1,
        'current_weight': 2240.0,
        'slot_number': 2,
        'image_url':
            'https://images.unsplash.com/photo-1559181567-c3190ca9959b?auto=format&fit=crop&w=400&q=80',
      },
      {
        'shelf_id': kitchenId,
        'name': 'Basmati Rice',
        'unit_weight_g': 1000.0,
        'tare_weight_g': 50.0,
        'min_threshold': 2,
        'current_weight': 1050.0,
        'slot_number': 3,
        'image_url':
            'https://images.unsplash.com/photo-1586201375761-83865001e31c?auto=format&fit=crop&w=400&q=80',
      },
      {
        'shelf_id': kitchenId,
        'name': 'Sea Salt',
        'unit_weight_g': 500.0,
        'tare_weight_g': 100.0,
        'min_threshold': 1,
        'current_weight': 600.0,
        'slot_number': 4,
        'image_url':
            'https://images.unsplash.com/photo-1518110925495-5fe2fda0a5b2?auto=format&fit=crop&w=400&q=80',
      },
      {
        'shelf_id': kitchenId,
        'name': 'Coffee Beans',
        'unit_weight_g': 250.0,
        'tare_weight_g': 60.0,
        'min_threshold': 1,
        'current_weight': 60.0,
        'slot_number': 5,
        'image_url':
            'https://images.unsplash.com/photo-1447933601403-0c6688de566e?auto=format&fit=crop&w=400&q=80',
      },

      // ── Medical Cabinet ───────────────────────────────────────────────────
      {
        'shelf_id': medicalId,
        'name': 'Paracetamol 500 mg',
        'unit_weight_g': 1.5,
        'tare_weight_g': 20.0,
        'min_threshold': 10,
        'current_weight': 65.0,
        'slot_number': 1,
        'image_url':
            'https://images.unsplash.com/photo-1584308666744-24d5c474f2ae?auto=format&fit=crop&w=400&q=80',
      },
      {
        'shelf_id': medicalId,
        'name': 'Vitamin C 1000 mg',
        'unit_weight_g': 2.0,
        'tare_weight_g': 25.0,
        'min_threshold': 5,
        'current_weight': 45.0,
        'slot_number': 2,
        'image_url':
            'https://images.unsplash.com/photo-1550572017-edd951b55104?auto=format&fit=crop&w=400&q=80',
      },
      {
        'shelf_id': medicalId,
        'name': 'Band-Aids (box)',
        'unit_weight_g': 30.0,
        'tare_weight_g': 10.0,
        'min_threshold': 1,
        'current_weight': 40.0,
        'slot_number': 3,
        'image_url':
            'https://images.unsplash.com/photo-1587854692152-cbe660dbde88?auto=format&fit=crop&w=400&q=80',
      },
      {
        'shelf_id': medicalId,
        'name': 'Antiseptic Spray',
        'unit_weight_g': 150.0,
        'tare_weight_g': 80.0,
        'min_threshold': 1,
        'current_weight': 80.0,
        'slot_number': 4,
        'image_url':
            'https://images.unsplash.com/photo-1584036561566-baf8f5f1b144?auto=format&fit=crop&w=400&q=80',
      },
      {
        'shelf_id': medicalId,
        'name': 'Digital Thermometer',
        'unit_weight_g': 60.0,
        'tare_weight_g': 0.0,
        'min_threshold': 1,
        'current_weight': 60.0,
        'slot_number': 5,
        'image_url':
            'https://images.unsplash.com/photo-1585435557343-3b348031e799?auto=format&fit=crop&w=400&q=80',
      },

      // ── Office Supplies ───────────────────────────────────────────────────
      {
        'shelf_id': officeId,
        'name': 'A4 Paper Ream',
        'unit_weight_g': 2500.0,
        'tare_weight_g': 0.0,
        'min_threshold': 1,
        'current_weight': 5000.0,
        'slot_number': 1,
        'image_url':
            'https://images.unsplash.com/photo-1568667256549-094345857637?auto=format&fit=crop&w=400&q=80',
      },
      {
        'shelf_id': officeId,
        'name': 'Ballpoint Pens',
        'unit_weight_g': 8.0,
        'tare_weight_g': 0.0,
        'min_threshold': 5,
        'current_weight': 96.0,
        'slot_number': 2,
        'image_url':
            'https://images.unsplash.com/photo-1589634749000-1a0f4e7cd78a?auto=format&fit=crop&w=400&q=80',
      },
      {
        'shelf_id': officeId,
        'name': 'Staples Box',
        'unit_weight_g': 100.0,
        'tare_weight_g': 20.0,
        'min_threshold': 1,
        'current_weight': 120.0,
        'slot_number': 3,
        'image_url':
            'https://images.unsplash.com/photo-1583248369069-9d91f1640fe6?auto=format&fit=crop&w=400&q=80',
      },
      {
        'shelf_id': officeId,
        'name': 'Scissors',
        'unit_weight_g': 80.0,
        'tare_weight_g': 0.0,
        'min_threshold': 1,
        'current_weight': 80.0,
        'slot_number': 4,
        'image_url':
            'https://images.unsplash.com/photo-1619468129361-605ebea04b44?auto=format&fit=crop&w=400&q=80',
      },
      {
        'shelf_id': officeId,
        'name': 'Sticky Notes',
        'unit_weight_g': 50.0,
        'tare_weight_g': 0.0,
        'min_threshold': 2,
        'current_weight': 150.0,
        'slot_number': 5,
        'image_url':
            'https://images.unsplash.com/photo-1544816155-12df9643f363?auto=format&fit=crop&w=400&q=80',
      },
    ]);
  }
}
