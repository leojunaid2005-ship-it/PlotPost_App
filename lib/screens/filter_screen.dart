import 'package:flutter/material.dart';

import '../theme/app_colors.dart';

class FilterScreen extends StatefulWidget {
  const FilterScreen({
    super.key,
    this.initialPlatform = 'All',
    this.initialDeal = 'Any',
    this.initialTypes = const {},
    this.initialLocality = 'Nadakkavu',
    this.onApply,
  });

  final String initialPlatform;
  final String initialDeal;
  final Set<String> initialTypes;
  final String initialLocality;
  final ValueChanged<Map<String, dynamic>>? onApply;

  @override
  State<FilterScreen> createState() => _FilterScreenState();
}

class _FilterScreenState extends State<FilterScreen> {
  late String _platform;
  late String _deal;
  late Set<String> _types;
  late String _locality;

  RangeValues _priceRange = const RangeValues(10, 200); // in Lakhs
  bool _videoOnly = false;
  int _minBedrooms = 0;

  static const List<String> _platforms = [
    'All',
    'Instagram',
    'Facebook',
    'YouTube',
  ];
  static const List<String> _deals = ['Any', 'For sale', 'For rent'];
  static const List<String> _propertyTypes = [
    'Plot',
    'House',
    'Villa',
    'Flat',
    'Commercial',
  ];
  static const List<String> _localities = [
    'All Kozhikode',
    'Nadakkavu',
    'Eranhipalam',
    'West Hill',
    'Chevayur',
    'Mavoor Road',
    'Mananchira',
    'Civil Station',
    'Beach Road',
  ];

  @override
  void initState() {
    super.initState();
    _platform = widget.initialPlatform;
    _deal = widget.initialDeal;
    _types = Set<String>.from(widget.initialTypes);
    _locality = widget.initialLocality;
  }

  void _resetFilters() {
    setState(() {
      _platform = 'All';
      _deal = 'Any';
      _types.clear();
      _locality = 'All Kozhikode';
      _priceRange = const RangeValues(10, 200);
      _videoOnly = false;
      _minBedrooms = 0;
    });
  }

  void _applyFilters() {
    final filterData = <String, dynamic>{
      'platform': _platform,
      'deal': _deal,
      'types': _types,
      'locality': _locality,
      'priceRange': _priceRange,
      'videoOnly': _videoOnly,
      'minBedrooms': _minBedrooms,
    };

    widget.onApply?.call(filterData);
    Navigator.pop(context, filterData);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: theme.scaffoldBackgroundColor,
        elevation: 0,
        titleSpacing: 0,
        leading: IconButton(
          icon: Icon(
            Icons.close_rounded,
            size: 22,
            color: theme.colorScheme.onSurface,
          ),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Filter Properties',
          style: TextStyle(
            fontSize: 19,
            fontWeight: FontWeight.w800,
            color: theme.colorScheme.onSurface,
          ),
        ),
        actions: [
          TextButton(
            onPressed: _resetFilters,
            child: Text(
              'Reset',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: plotPostTextAccent(context, theme.colorScheme.primary),
              ),
            ),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Platform Origin Section
            _buildSectionHeader('Social Platform Source', theme),
            const SizedBox(height: 10),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _platforms.map((p) {
                final isSelected = _platform == p;
                return ChoiceChip(
                  label: Text(p),
                  selected: isSelected,
                  selectedColor: theme.colorScheme.primary.withValues(
                    alpha: 0.18,
                  ),
                  backgroundColor: isDark
                      ? const Color(0xFF242826)
                      : const Color(0xFFF0F7F4),
                  labelStyle: TextStyle(
                    fontSize: 12.5,
                    fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
                    color: isSelected
                        ? theme.colorScheme.primary
                        : theme.colorScheme.onSurface,
                  ),
                  onSelected: (_) => setState(() => _platform = p),
                );
              }).toList(),
            ),

            const SizedBox(height: 24),

            // Deal Type Section
            _buildSectionHeader('Listing Type', theme),
            const SizedBox(height: 10),
            Row(
              children: _deals.map((d) {
                final isSelected = _deal == d;
                return Expanded(
                  child: Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: ChoiceChip(
                      label: Center(child: Text(d)),
                      selected: isSelected,
                      selectedColor: theme.colorScheme.primary.withValues(
                        alpha: 0.18,
                      ),
                      backgroundColor: isDark
                          ? const Color(0xFF242826)
                          : const Color(0xFFF0F7F4),
                      labelStyle: TextStyle(
                        fontSize: 12.5,
                        fontWeight: isSelected
                            ? FontWeight.w800
                            : FontWeight.w600,
                        color: isSelected
                            ? theme.colorScheme.primary
                            : theme.colorScheme.onSurface,
                      ),
                      onSelected: (_) => setState(() => _deal = d),
                    ),
                  ),
                );
              }).toList(),
            ),

            const SizedBox(height: 24),

            // Property Categories Section
            _buildSectionHeader('Property Category', theme),
            const SizedBox(height: 10),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _propertyTypes.map((t) {
                final isSelected = _types.contains(t);
                return FilterChip(
                  label: Text(t),
                  selected: isSelected,
                  selectedColor: theme.colorScheme.primary.withValues(
                    alpha: 0.18,
                  ),
                  backgroundColor: isDark
                      ? const Color(0xFF242826)
                      : const Color(0xFFF0F7F4),
                  labelStyle: TextStyle(
                    fontSize: 12.5,
                    fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
                    color: isSelected
                        ? theme.colorScheme.primary
                        : theme.colorScheme.onSurface,
                  ),
                  onSelected: (selected) {
                    setState(() {
                      if (selected) {
                        _types.add(t);
                      } else {
                        _types.remove(t);
                      }
                    });
                  },
                );
              }).toList(),
            ),

            const SizedBox(height: 24),

            // Locality Dropdown
            _buildSectionHeader('Locality / Area', theme),
            const SizedBox(height: 10),
            DropdownButtonFormField<String>(
              value: _localities.contains(_locality)
                  ? _locality
                  : _localities.first,
              decoration: InputDecoration(
                prefixIcon: Icon(
                  Icons.location_on_outlined,
                  color: theme.colorScheme.onSurfaceVariant,
                ),
                filled: true,
                fillColor: isDark
                    ? const Color(0xFF242826)
                    : const Color(0xFFF0F7F4),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 12,
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
              ),
              items: _localities
                  .map((loc) => DropdownMenuItem(value: loc, child: Text(loc)))
                  .toList(),
              onChanged: (val) {
                if (val != null) setState(() => _locality = val);
              },
            ),

            const SizedBox(height: 24),

            // Price Range Slider
            Row(
              children: [
                _buildSectionHeader('Price Range', theme),
                const Spacer(),
                Text(
                  '₹${_priceRange.start.round()} Lakhs - ₹${_priceRange.end.round()} Lakhs+',
                  style: TextStyle(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w800,
                    color: plotPostTextAccent(
                      context,
                      theme.colorScheme.primary,
                    ),
                  ),
                ),
              ],
            ),
            RangeSlider(
              values: _priceRange,
              min: 5,
              max: 300,
              divisions: 59,
              activeColor: theme.colorScheme.primary,
              labels: RangeLabels(
                '₹${_priceRange.start.round()}L',
                '₹${_priceRange.end.round()}L',
              ),
              onChanged: (values) => setState(() => _priceRange = values),
            ),

            const SizedBox(height: 16),

            // Video Tours Only Switch
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: Text(
                'Video Tours Only',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: theme.colorScheme.onSurface,
                ),
              ),
              subtitle: Text(
                'Show only properties with video walkthroughs',
                style: TextStyle(
                  fontSize: 11.5,
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
              activeColor: theme.colorScheme.primary,
              value: _videoOnly,
              onChanged: (val) => setState(() => _videoOnly = val),
            ),

            const SizedBox(height: 32),

            // Apply Button
            SizedBox(
              width: double.infinity,
              height: 48,
              child: FilledButton(
                onPressed: _applyFilters,
                child: const Text(
                  'Apply Filters',
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.w800),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title, ThemeData theme) {
    return Text(
      title,
      style: TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.w800,
        color: theme.colorScheme.onSurface,
      ),
    );
  }
}
