import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../config/theme.dart';
import '../models/media.dart';

/// Preset filters for article publication date (datee).
enum ArticleDatePreset {
  today,
  yesterday,
  last7,
  all,
}

class ArticleDateFilterState {
  ArticleDatePreset preset;
  DateTime? customStart;
  DateTime? customEnd;

  ArticleDateFilterState({this.preset = ArticleDatePreset.today});

  ({String? start, String? end}) get apiRange {
    final fmt = DateFormat('yyyy-MM-dd');
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    switch (preset) {
      case ArticleDatePreset.all:
        return (start: null, end: null);
      case ArticleDatePreset.today:
        return (start: fmt.format(today), end: fmt.format(today));
      case ArticleDatePreset.yesterday:
        final y = today.subtract(const Duration(days: 1));
        return (start: fmt.format(y), end: fmt.format(y));
      case ArticleDatePreset.last7:
        return (start: fmt.format(today.subtract(const Duration(days: 6))), end: fmt.format(today));
    }
  }

  String get label {
    switch (preset) {
      case ArticleDatePreset.today:
        return 'Today';
      case ArticleDatePreset.yesterday:
        return 'Yesterday';
      case ArticleDatePreset.last7:
        return 'Last 7 days';
      case ArticleDatePreset.all:
        return 'All dates';
    }
  }
}

class ArticleDateFilterRow extends StatelessWidget {
  const ArticleDateFilterRow({
    super.key,
    required this.state,
    required this.onChanged,
  });

  final ArticleDateFilterState state;
  final ValueChanged<ArticleDatePreset> onChanged;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: ArticleDatePreset.values.map((p) {
          final selected = state.preset == p;
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: FilterChip(
              label: Text(_presetLabel(p), style: TextStyle(fontSize: 12, fontWeight: selected ? FontWeight.w600 : FontWeight.w400)),
              selected: selected,
              onSelected: (_) => onChanged(p),
              selectedColor: AppColors.white,
              checkmarkColor: AppColors.navy,
              labelStyle: TextStyle(color: selected ? AppColors.navy : AppColors.textSecondary),
              side: BorderSide(color: selected ? AppColors.navy : AppColors.border),
            ),
          );
        }).toList(),
      ),
    );
  }

  static String _presetLabel(ArticleDatePreset p) {
    switch (p) {
      case ArticleDatePreset.today:
        return 'Today';
      case ArticleDatePreset.yesterday:
        return 'Yesterday';
      case ArticleDatePreset.last7:
        return '7 days';
      case ArticleDatePreset.all:
        return 'All';
    }
  }
}

/// QC upload-date window (createdAt).
enum QcPeriod { todayOnly, todayYesterday }

class QcPeriodFilterRow extends StatelessWidget {
  const QcPeriodFilterRow({super.key, required this.period, required this.onChanged});

  final QcPeriod period;
  final ValueChanged<QcPeriod> onChanged;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _chip('Today + Yesterday', period == QcPeriod.todayYesterday, () => onChanged(QcPeriod.todayYesterday)),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _chip('Today only', period == QcPeriod.todayOnly, () => onChanged(QcPeriod.todayOnly)),
        ),
      ],
    );
  }

  Widget _chip(String label, bool selected, VoidCallback onTap) {
    return FilterChip(
      label: Text(label, style: const TextStyle(fontSize: 11)),
      selected: selected,
      onSelected: (_) => onTap(),
      selectedColor: AppColors.white,
      checkmarkColor: AppColors.navy,
      side: BorderSide(color: selected ? AppColors.navy : AppColors.border),
    );
  }

  static ({String start, String end}) dateRange(QcPeriod period) {
    final fmt = DateFormat('yyyy-MM-dd');
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    if (period == QcPeriod.todayOnly) {
      final s = fmt.format(today);
      return (start: s, end: s);
    }
    final yesterday = today.subtract(const Duration(days: 1));
    return (start: fmt.format(yesterday), end: fmt.format(today));
  }
}

class MediaFilterDropdown extends StatelessWidget {
  const MediaFilterDropdown({
    super.key,
    required this.options,
    required this.selectedId,
    required this.onChanged,
    this.label = 'All media',
  });

  final List<MediaModel> options;
  final int? selectedId;
  final ValueChanged<int?> onChanged;
  final String label;

  @override
  Widget build(BuildContext context) {
    return DropdownButtonFormField<int?>(
      value: selectedId,
      isExpanded: true,
      decoration: InputDecoration(
        labelText: 'Media filter',
        isDense: true,
        prefixIcon: const Icon(Icons.business_outlined, size: 20),
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      ),
      items: [
        DropdownMenuItem<int?>(value: null, child: Text(label, overflow: TextOverflow.ellipsis)),
        ...options.map((m) => DropdownMenuItem<int?>(
              value: m.mediaId,
              child: Text(m.mediaName, overflow: TextOverflow.ellipsis),
            )),
      ],
      onChanged: onChanged,
    );
  }
}

class StatusFilterRow extends StatelessWidget {
  const StatusFilterRow({
    super.key,
    required this.selected,
    required this.onChanged,
  });

  final String? selected;
  final ValueChanged<String?> onChanged;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          _chip('All', selected == null, () => onChanged(null)),
          _chip('Active', selected == 'Active', () => onChanged('Active')),
          _chip('Inactive', selected == 'Inactive', () => onChanged('Inactive')),
        ],
      ),
    );
  }

  Widget _chip(String label, bool selected, VoidCallback onTap) {
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: FilterChip(
        label: Text(label, style: const TextStyle(fontSize: 12)),
        selected: selected,
        onSelected: (_) => onTap(),
        selectedColor: AppColors.white,
        checkmarkColor: AppColors.navy,
        side: BorderSide(color: selected ? AppColors.navy : AppColors.border),
      ),
    );
  }
}
