import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/fish_repository.dart';
import '../../data/models/fish.dart';
import '../../providers/zone_provider.dart';
import '../../shared/utils/season_checker.dart';
import '../../shared/utils/date_utils.dart' as du;

final _selectedFishIdProvider = StateProvider<String?>((ref) => null);
final _inputLengthProvider = StateProvider<String>((ref) => '');

class MeasureCheckScreen extends ConsumerWidget {
  final String? preselectedFishId;

  const MeasureCheckScreen({super.key, this.preselectedFishId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final fishAsync = ref.watch(fishListProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Tjek din fangst')),
      body: fishAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Fejl: $e')),
        data: (fishList) => _MeasureForm(
          fishList: fishList,
          preselectedFishId: preselectedFishId,
        ),
      ),
    );
  }
}

class _MeasureForm extends ConsumerStatefulWidget {
  final List<Fish> fishList;
  final String? preselectedFishId;

  const _MeasureForm({required this.fishList, this.preselectedFishId});

  @override
  ConsumerState<_MeasureForm> createState() => _MeasureFormState();
}

class _MeasureFormState extends ConsumerState<_MeasureForm> {
  late final TextEditingController _lengthController;
  String? _selectedId;

  @override
  void initState() {
    super.initState();
    _selectedId = widget.preselectedFishId;
    _lengthController = TextEditingController();
    _lengthController.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _lengthController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final zone = ref.watch(zoneProvider);
    final fish = _selectedId != null
        ? widget.fishList.firstWhere(
            (f) => f.id == _selectedId,
            orElse: () => widget.fishList.first,
          )
        : null;

    final lengthText = _lengthController.text;
    final length = double.tryParse(lengthText.replaceAll(',', '.'));

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Species dropdown
          DropdownButtonFormField<String>(
            value: _selectedId,
            decoration: const InputDecoration(
              labelText: 'Vælg art',
              border: OutlineInputBorder(),
              prefixIcon: Icon(Icons.set_meal_outlined),
            ),
            items: widget.fishList.map((f) {
              return DropdownMenuItem(value: f.id, child: Text(f.nameDa));
            }).toList(),
            onChanged: (v) => setState(() => _selectedId = v),
          ),
          const SizedBox(height: 20),
          // Length input
          TextField(
            controller: _lengthController,
            autofocus: _selectedId != null,
            keyboardType:
                const TextInputType.numberWithOptions(decimal: true),
            inputFormatters: [
              FilteringTextInputFormatter.allow(RegExp(r'[\d,.]')),
            ],
            style: const TextStyle(fontSize: 32, fontWeight: FontWeight.bold),
            textAlign: TextAlign.center,
            decoration: const InputDecoration(
              labelText: 'Længde (cm)',
              border: OutlineInputBorder(),
              hintText: '0',
              suffixText: 'cm',
            ),
          ),
          const SizedBox(height: 24),
          // Live result
          _ResultBox(fish: fish, zone: zone, length: length),
        ],
      ),
    );
  }
}

class _ResultBox extends StatelessWidget {
  final Fish? fish;
  final FishingZone zone;
  final double? length;

  const _ResultBox({required this.fish, required this.zone, this.length});

  @override
  Widget build(BuildContext context) {
    if (fish == null || length == null) {
      return _resultContainer(
        context,
        color: Colors.grey.shade200,
        textColor: Colors.grey.shade700,
        icon: Icons.straighten,
        message: 'Vælg art og indtast en længde',
      );
    }

    final result = checkSeason(fish!, zone, DateTime.now());

    if (result.status == SeasonStatus.closed) {
      final reopensText = result.reopensOn != null
          ? ' — åbner ${du.formatDanishDate(result.reopensOn!)}'
          : '';
      return _resultContainer(
        context,
        color: const Color(0xFFFFEBEE),
        textColor: const Color(0xFFC62828),
        icon: Icons.do_not_disturb_outlined,
        message: 'Sæson lukket$reopensText — genudsæt',
      );
    }

    final minSize = switch (zone) {
      FishingZone.nordsoen => fish!.minimumSizeCm.nordsoen,
      FishingZone.skagerrakKattegat => fish!.minimumSizeCm.skagerrakKattegat,
      FishingZone.baelterOestersoe => fish!.minimumSizeCm.baelterOestersoe,
      FishingZone.ferskvand => fish!.minimumSizeCm.ferskvand,
    };

    if (minSize == null || minSize == 0) {
      return _resultContainer(
        context,
        color: const Color(0xFFE8F5E9),
        textColor: const Color(0xFF2E7D32),
        icon: Icons.check_circle_outline,
        message: 'Lovlig ✓ — tag den med hjem',
      );
    }

    if (length! >= minSize) {
      return _resultContainer(
        context,
        color: const Color(0xFFE8F5E9),
        textColor: const Color(0xFF2E7D32),
        icon: Icons.check_circle_outline,
        message: 'Lovlig ✓ — tag den med hjem',
      );
    } else {
      final missing = (minSize - length!).toStringAsFixed(1);
      return _resultContainer(
        context,
        color: const Color(0xFFFFEBEE),
        textColor: const Color(0xFFC62828),
        icon: Icons.cancel_outlined,
        message: 'For lille — genudsæt. Mangler: $missing cm',
      );
    }
  }

  Widget _resultContainer(
    BuildContext context, {
    required Color color,
    required Color textColor,
    required IconData icon,
    required String message,
  }) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Icon(icon, color: textColor, size: 32),
          const SizedBox(width: 14),
          Expanded(
            child: Text(
              message,
              style: TextStyle(
                color: textColor,
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
