import 'package:farm_mgt_auth/core/app_theme.dart';
import 'package:farm_mgt_auth/modules/settings/config/settings_definitions.dart';
import 'package:farm_mgt_auth/modules/settings/controllers/accounts_controller.dart';
import 'package:farm_mgt_auth/modules/settings/controllers/base_settings_controller.dart';
import 'package:farm_mgt_auth/modules/settings/controllers/companies_controller.dart';
import 'package:farm_mgt_auth/modules/settings/controllers/customers_controller.dart';
import 'package:farm_mgt_auth/modules/settings/controllers/discount_schemes_controller.dart';
import 'package:farm_mgt_auth/modules/settings/controllers/opening_payables_controller.dart';
import 'package:farm_mgt_auth/modules/settings/controllers/opening_receivables_controller.dart';
import 'package:farm_mgt_auth/modules/settings/controllers/opening_stock_controller.dart';
import 'package:farm_mgt_auth/modules/settings/controllers/packings_controller.dart';
import 'package:farm_mgt_auth/modules/settings/controllers/product_groups_controller.dart';
import 'package:farm_mgt_auth/modules/settings/controllers/product_sub_groups_controller.dart';
import 'package:farm_mgt_auth/modules/settings/controllers/products_controller.dart';
import 'package:farm_mgt_auth/modules/settings/controllers/salesmen_controller.dart';
import 'package:farm_mgt_auth/modules/settings/controllers/sectors_controller.dart';
import 'package:farm_mgt_auth/modules/settings/controllers/settings_controller.dart';
import 'package:farm_mgt_auth/modules/settings/controllers/towns_controller.dart';
import 'package:farm_mgt_auth/modules/settings/controllers/units_controller.dart';
import 'package:farm_mgt_auth/modules/settings/controllers/vendors_controller.dart';
import 'package:farm_mgt_auth/modules/settings/models/base_settings_model.dart';
import 'package:farm_mgt_auth/modules/settings/models/lookup_option.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key, this.onOpenHome});

  final VoidCallback? onOpenHome;

  @override
  Widget build(BuildContext context) {
    return Consumer<SettingsController>(
      builder: (context, settingsController, _) {
        final width = MediaQuery.of(context).size.width;

        if (width < 600) {
          return _MobileSettingsList(
            onTapCategory: (id) {
              final category = SettingsDefinitions.categoryById(id);
              if (category.isOpeningsGroup && category.children.isNotEmpty) {
                settingsController
                    .selectOpeningChild(category.children.first.id);
              }
              settingsController.selectCategory(id);
              Navigator.of(context).push(
                MaterialPageRoute<void>(
                  builder: (_) => _buildScopedMobileCategoryPage(context, id),
                ),
              );
            },
          );
        }

        final categories = SettingsDefinitions.categories;
        final selectedCategoryId =
            settingsController.selectedCategoryId ?? categories.first.id;
        if (settingsController.selectedCategoryId == null) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            settingsController.selectCategory(selectedCategoryId);
          });
        }
        final category = SettingsDefinitions.categoryById(selectedCategoryId);

        return Padding(
          padding: AppTheme.pagePadding(context),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: width <= 1024 ? 260 : 280,
                decoration: AppTheme.cardDecor,
                child: ListView.separated(
                  shrinkWrap: true,
                  itemCount: categories.length,
                  separatorBuilder: (_, __) => Divider(
                    height: 1,
                    color: AppTheme.listTileDivider,
                  ),
                  itemBuilder: (context, index) {
                    final item = categories[index];
                    final selected = item.id == category.id;
                    return ListTile(
                      contentPadding: AppTheme.tilePadding,
                      minLeadingWidth: 24,
                      leading: CircleAvatar(
                        backgroundColor: AppTheme.terra50,
                        child: Icon(item.icon, color: AppTheme.terra600),
                      ),
                      title: Text(item.title),
                      trailing: const Icon(
                        Icons.chevron_right,
                        color: AppTheme.textSecondary,
                      ),
                      selected: selected,
                      onTap: () => settingsController.selectCategory(item.id),
                    );
                  },
                ),
              ),
              const SizedBox(width: 20),
              Expanded(
                child: _SettingsDetailScaffold(
                  category: category,
                  showBreadcrumb: width > 1024,
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

Widget _buildScopedMobileCategoryPage(BuildContext context, String categoryId) {
  return MultiProvider(
    providers: [
      ChangeNotifierProvider<SettingsController>.value(
        value: context.read<SettingsController>(),
      ),
      ChangeNotifierProvider<UnitsController>.value(
        value: context.read<UnitsController>(),
      ),
      ChangeNotifierProvider<PackingsController>.value(
        value: context.read<PackingsController>(),
      ),
      ChangeNotifierProvider<CompaniesController>.value(
        value: context.read<CompaniesController>(),
      ),
      ChangeNotifierProvider<ProductGroupsController>.value(
        value: context.read<ProductGroupsController>(),
      ),
      ChangeNotifierProvider<ProductSubGroupsController>.value(
        value: context.read<ProductSubGroupsController>(),
      ),
      ChangeNotifierProvider<ProductsController>.value(
        value: context.read<ProductsController>(),
      ),
      ChangeNotifierProvider<DiscountSchemesController>.value(
        value: context.read<DiscountSchemesController>(),
      ),
      ChangeNotifierProvider<VendorsController>.value(
        value: context.read<VendorsController>(),
      ),
      ChangeNotifierProvider<TownsController>.value(
        value: context.read<TownsController>(),
      ),
      ChangeNotifierProvider<SectorsController>.value(
        value: context.read<SectorsController>(),
      ),
      ChangeNotifierProvider<CustomersController>.value(
        value: context.read<CustomersController>(),
      ),
      ChangeNotifierProvider<SalesmenController>.value(
        value: context.read<SalesmenController>(),
      ),
      ChangeNotifierProvider<AccountsController>.value(
        value: context.read<AccountsController>(),
      ),
      ChangeNotifierProvider<OpeningStockController>.value(
        value: context.read<OpeningStockController>(),
      ),
      ChangeNotifierProvider<OpeningReceivablesController>.value(
        value: context.read<OpeningReceivablesController>(),
      ),
      ChangeNotifierProvider<OpeningPayablesController>.value(
        value: context.read<OpeningPayablesController>(),
      ),
    ],
    child: _MobileCategoryDetailPage(categoryId: categoryId),
  );
}

class _MobileSettingsList extends StatelessWidget {
  const _MobileSettingsList({required this.onTapCategory});

  final void Function(String id) onTapCategory;

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      padding: AppTheme.pagePadding(context),
      itemCount: SettingsDefinitions.categories.length,
      itemBuilder: (context, index) {
        final category = SettingsDefinitions.categories[index];
        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          decoration: AppTheme.cardDecor,
          child: ListTile(
            contentPadding: AppTheme.tilePadding,
            minLeadingWidth: 24,
            leading: CircleAvatar(
              backgroundColor: AppTheme.terra50,
              child: Icon(category.icon, color: AppTheme.terra600),
            ),
            title: Text(category.title),
            trailing: const Icon(
              Icons.chevron_right,
              color: AppTheme.textSecondary,
            ),
            onTap: () => onTapCategory(category.id),
          ),
        );
      },
    );
  }
}

class _MobileCategoryDetailPage extends StatelessWidget {
  const _MobileCategoryDetailPage({
    required this.categoryId,
  });

  final String categoryId;

  @override
  Widget build(BuildContext context) {
    return Consumer<SettingsController>(
      builder: (context, settingsController, _) {
        final selectedCategory = SettingsDefinitions.categoryById(categoryId);
        // Ensure an opening child is selected when viewing the openings group on mobile
        if (selectedCategory.isOpeningsGroup &&
            selectedCategory.children.isNotEmpty) {
          final matchesSelected = selectedCategory.children
              .any((c) => c.id == settingsController.selectedOpeningChildId);
          if (!matchesSelected) {
            settingsController
                .selectOpeningChild(selectedCategory.children.first.id);
          }
        }
        return Scaffold(
          appBar: AppBar(
            title: Text(selectedCategory.title),
          ),
          body: Padding(
            padding: AppTheme.pagePadding(context),
            child: _SettingsDetailScaffold(
              category: selectedCategory,
              showBreadcrumb: false,
            ),
          ),
        );
      },
    );
  }
}

class _SettingsDetailScaffold extends StatelessWidget {
  const _SettingsDetailScaffold({
    required this.category,
    required this.showBreadcrumb,
  });

  final SettingsCategoryConfig category;
  final bool showBreadcrumb;

  @override
  Widget build(BuildContext context) {
    if (category.isOpeningsGroup) {
      return _OpeningsGroupView(
          category: category, showBreadcrumb: showBreadcrumb);
    }

    return _CategoryCrudView(
      category: category,
      showBreadcrumb: showBreadcrumb,
    );
  }
}

class _OpeningsGroupView extends StatelessWidget {
  const _OpeningsGroupView({
    required this.category,
    required this.showBreadcrumb,
  });

  final SettingsCategoryConfig category;
  final bool showBreadcrumb;

  @override
  Widget build(BuildContext context) {
    return Consumer<SettingsController>(
      builder: (context, settingsController, _) {
        final selectedChild = category.children.firstWhere(
          (item) => item.id == settingsController.selectedOpeningChildId,
          orElse: () => category.children.first,
        );
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (showBreadcrumb)
              Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Text(
                  'Settings > ${category.title}',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: category.children.map((child) {
                final selected = child.id == selectedChild.id;
                return ChoiceChip(
                  label: Text(child.title),
                  selected: selected,
                  selectedColor: AppTheme.sidebarActive,
                  side: const BorderSide(color: AppTheme.softBorder),
                  labelStyle: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: selected
                            ? AppTheme.terra800
                            : AppTheme.textSecondary,
                        fontWeight: FontWeight.w500,
                      ),
                  onSelected: (_) =>
                      settingsController.selectOpeningChild(child.id),
                );
              }).toList(),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: _CategoryCrudView(
                category: selectedChild,
                showBreadcrumb: false,
              ),
            ),
          ],
        );
      },
    );
  }
}

class _CategoryCrudView extends StatelessWidget {
  const _CategoryCrudView({
    required this.category,
    required this.showBreadcrumb,
  });

  final SettingsCategoryConfig category;
  final bool showBreadcrumb;

  @override
  Widget build(BuildContext context) {
    final controller = SettingsDefinitions.controllerOf(context, category.id);
    return AnimatedBuilder(
      animation: controller,
      builder: (context, _) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (showBreadcrumb)
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Text(
                  'Settings > ${category.title}',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ),
            LayoutBuilder(
              builder: (context, constraints) {
                final compact = constraints.maxWidth < 520;
                if (compact) {
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        category.title,
                        style:
                            Theme.of(context).textTheme.headlineSmall?.copyWith(
                                  fontWeight: FontWeight.w600,
                                ),
                      ),
                      const SizedBox(height: 12),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          onPressed: () =>
                              _openEditor(context, controller, category),
                          icon: const Icon(Icons.add),
                          label: Text(category.addLabel),
                        ),
                      ),
                    ],
                  );
                }
                return Row(
                  children: [
                    Expanded(
                      child: Text(
                        category.title,
                        style:
                            Theme.of(context).textTheme.headlineSmall?.copyWith(
                                  fontWeight: FontWeight.w600,
                                ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    ElevatedButton.icon(
                      onPressed: () =>
                          _openEditor(context, controller, category),
                      icon: const Icon(Icons.add),
                      label: Text(category.addLabel),
                    ),
                  ],
                );
              },
            ),
            const SizedBox(height: 16),
            TextField(
              onChanged: controller.setSearchQuery,
              decoration: const InputDecoration(
                prefixIcon: Icon(Icons.search),
                hintText: 'Search',
              ),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: Container(
                decoration: AppTheme.cardDecor,
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  child: _buildList(context, controller),
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildList(BuildContext context, SettingsCrudController controller) {
    if (controller.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (controller.error != null) {
      return Center(
        child: Text(controller.error!),
      );
    }

    final items = controller.filteredItems;
    if (items.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.inbox_outlined,
              size: 64,
              color: AppTheme.textTertiary,
            ),
            const SizedBox(height: 12),
            Text(
              'No ${category.title.toLowerCase()} added yet',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppTheme.textSecondary,
                  ),
            ),
            const SizedBox(height: 12),
            ElevatedButton(
              onPressed: () => _openEditor(context, controller, category),
              child: Text(category.addLabel),
            ),
          ],
        ),
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      itemCount: items.length,
      separatorBuilder: (_, __) => const SizedBox(height: 10),
      itemBuilder: (context, index) {
        final item = items[index];
        return _SettingsRecordCard(
          titleLabel: _fieldForKey(category.listTitleKey)?.label ??
              _humanizeKey(category.listTitleKey),
          titleValue: _displayValue(context, category.listTitleKey, item),
          rows: _listRowKeys()
              .map((key) => _metadataRow(context, key, item))
              .whereType<_MetadataRow>()
              .toList(),
          onEdit: () => _openEditor(context, controller, category, item),
          onDelete: () => _confirmDelete(context, controller, item),
        );
      },
    );
  }

  String _displayValue(
    BuildContext context,
    String key,
    BaseSettingsModel item,
  ) {
    if (key.isEmpty) {
      return '';
    }
    SettingsFieldConfig? field;
    for (final candidate in category.fields) {
      if (candidate.key == key) {
        field = candidate;
        break;
      }
    }
    if (field == null) {
      return item.text(key);
    }
    if (field.type == SettingsFieldType.dropdown &&
        field.optionsBuilder != null &&
        item.text(key).isNotEmpty) {
      final options = field.optionsBuilder!(context, item.toJson(), item);
      for (final option in options) {
        if (option.value == item.text(key)) {
          return option.label;
        }
      }
    }
    if (field.type == SettingsFieldType.multiSelect &&
        field.optionsBuilder != null) {
      final options = field.optionsBuilder!(context, item.toJson(), item);
      final selected = item.stringList(key);
      final labels = options
          .where((option) => selected.contains(option.value))
          .map((option) => option.label)
          .toList();
      return labels.join(', ');
    }
    return item.text(key);
  }

  _MetadataRow? _metadataRow(
    BuildContext context,
    String key,
    BaseSettingsModel item,
  ) {
    final value = _displayValue(context, key, item).trim();
    if (value.isEmpty) {
      return null;
    }
    final field = _fieldForKey(key);
    return _MetadataRow(
      label: field?.label ?? _humanizeKey(key),
      value: value,
    );
  }

  SettingsFieldConfig? _fieldForKey(String key) {
    for (final candidate in category.fields) {
      if (candidate.key == key) {
        return candidate;
      }
    }
    return null;
  }

  List<String> _listRowKeys() {
    final ordered = <String>[];
    final seen = <String>{};

    for (final key in category.listSubtitleKeys) {
      if (key.isNotEmpty && key != category.listTitleKey && seen.add(key)) {
        ordered.add(key);
      }
    }

    for (final field in category.fields) {
      final key = field.key;
      if (key.isNotEmpty && key != category.listTitleKey && seen.add(key)) {
        ordered.add(key);
      }
    }

    return ordered;
  }

  String _humanizeKey(String key) {
    final buffer = key.replaceAllMapped(
      RegExp(r'([A-Z])'),
      (match) => ' ${match.group(1)}',
    );
    final words = buffer
        .replaceAll('_', ' ')
        .split(' ')
        .where((word) => word.trim().isNotEmpty)
        .toList();
    return words
        .map(
          (word) => '${word[0].toUpperCase()}${word.substring(1)}',
        )
        .join(' ');
  }

  Future<void> _confirmDelete(
    BuildContext context,
    SettingsCrudController controller,
    BaseSettingsModel item,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Delete item'),
          content: const Text('Are you sure you want to delete this record?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(true),
              style: TextButton.styleFrom(foregroundColor: AppTheme.dangerText),
              child: const Text('Delete'),
            ),
          ],
        );
      },
    );

    if (confirmed == true) {
      try {
        await controller.deleteItem(item.id);
        _showSnackBar(context, 'Deleted successfully', AppTheme.successText);
      } catch (e) {
        _showSnackBar(context, e.toString(), AppTheme.dangerText);
      }
    }
  }

  void _openEditor(BuildContext context, SettingsCrudController controller,
      SettingsCategoryConfig category,
      [BaseSettingsModel? item]) {
    final lookupContext = context;
    showDialog<void>(
      context: context,
      builder: (context) {
        final dialogWidth = MediaQuery.of(context).size.width < 600
            ? MediaQuery.of(context).size.width - 24
            : 540.0;
        return Dialog(
          child: ConstrainedBox(
            constraints: BoxConstraints(maxWidth: dialogWidth),
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: _SettingsEditorSheet(
                category: category,
                controller: controller,
                lookupContext: lookupContext,
                item: item,
                dialogMode: true,
              ),
            ),
          ),
        );
      },
    );
  }
}

class _SettingsEditorSheet extends StatefulWidget {
  const _SettingsEditorSheet({
    required this.category,
    required this.controller,
    required this.lookupContext,
    this.item,
    this.dialogMode = true,
  });

  final SettingsCategoryConfig category;
  final SettingsCrudController controller;
  final BuildContext lookupContext;
  final BaseSettingsModel? item;
  final bool dialogMode;

  @override
  State<_SettingsEditorSheet> createState() => _SettingsEditorSheetState();
}

class _SettingsEditorSheetState extends State<_SettingsEditorSheet> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  late Map<String, dynamic> _values;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _values = widget.item != null
        ? widget.item!.toJson()
        : <String, dynamic>{...?widget.category.initialValues?.call()};
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
        ),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(0),
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.item == null
                      ? widget.category.addLabel
                      : 'Edit ${widget.category.title}',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 20),
                ...widget.category.fields.map(_buildField).toList(),
                const SizedBox(height: 20),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed:
                            _saving ? null : () => Navigator.of(context).pop(),
                        child: const Text('Cancel'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: _saving ? null : _save,
                        child: Text(_saving ? 'Saving...' : 'Save'),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildField(SettingsFieldConfig field) {
    switch (field.type) {
      case SettingsFieldType.multiline:
      case SettingsFieldType.text:
      case SettingsFieldType.number:
        return _LabeledField(
          label: field.label,
          child: TextFormField(
            initialValue: _stringValue(field.key),
            minLines: field.type == SettingsFieldType.multiline ? 3 : 1,
            maxLines: field.type == SettingsFieldType.multiline ? 4 : 1,
            keyboardType: field.type == SettingsFieldType.number
                ? const TextInputType.numberWithOptions(decimal: true)
                : TextInputType.text,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
            decoration: InputDecoration(
              hintText: field.label,
            ),
            validator: (value) {
              if (field.required && (value ?? '').trim().isEmpty) {
                return 'Required';
              }
              return null;
            },
            onChanged: (value) {
              _values[field.key] = field.type == SettingsFieldType.number
                  ? _parseNumber(value)
                  : value;
            },
          ),
        );
      case SettingsFieldType.dropdown:
        final options = field.optionsBuilder
                ?.call(widget.lookupContext, _values, widget.item) ??
            const <LookupOption>[];
        return _LabeledField(
          label: field.label,
          child: DropdownButtonFormField<String>(
            value: _stringValue(field.key).isEmpty
                ? null
                : _stringValue(field.key),
            items: options
                .map(
                  (option) => DropdownMenuItem<String>(
                    value: option.value,
                    child: Text(option.label),
                  ),
                )
                .toList(),
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
            decoration: InputDecoration(
              hintText: 'Select ${field.label}',
            ),
            validator: (value) {
              if (field.required && (value ?? '').isEmpty) {
                return 'Required';
              }
              return null;
            },
            onChanged: (value) {
              setState(() {
                _values[field.key] = value ?? '';
                if (field.key == 'groupId') {
                  _values['subGroupId'] = '';
                }
                if (field.key == 'townId') {
                  _values['sectorId'] = '';
                }
                if (field.key == 'applicableTo') {
                  _values['refId'] = '';
                }
              });
            },
          ),
        );
      case SettingsFieldType.boolToggle:
        final current = _values[field.key] == true;
        return _LabeledField(
          label: field.label,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            decoration: BoxDecoration(
              color: AppTheme.surfaceWhite,
              borderRadius: BorderRadius.circular(AppTheme.inputRadius),
              border: Border.all(color: AppTheme.inputBorderColor),
            ),
            child: SwitchListTile(
              contentPadding: EdgeInsets.zero,
              activeColor: AppTheme.terra400,
              value: current,
              title: Text(
                current ? 'Enabled' : 'Disabled',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
              ),
              onChanged: (value) {
                setState(() => _values[field.key] = value);
              },
            ),
          ),
        );
      case SettingsFieldType.date:
        return _LabeledField(
          label: field.label,
          child: TextFormField(
            key: ValueKey<String>('${field.key}:${_stringValue(field.key)}'),
            readOnly: true,
            initialValue: _stringValue(field.key),
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
            decoration: InputDecoration(
              hintText: field.label,
              suffixIcon: const Icon(Icons.calendar_today_outlined),
            ),
            validator: (value) {
              if (field.required && (value ?? '').trim().isEmpty) {
                return 'Required';
              }
              return null;
            },
            onTap: () async {
              final now = DateTime.now();
              final picked = await showDatePicker(
                context: context,
                initialDate: now,
                firstDate: DateTime(2000),
                lastDate: DateTime(2100),
              );
              if (picked != null) {
                setState(() {
                  _values[field.key] = picked.toIso8601String();
                });
              }
            },
          ),
        );
      case SettingsFieldType.multiSelect:
        final options = field.optionsBuilder
                ?.call(widget.lookupContext, _values, widget.item) ??
            const <LookupOption>[];
        final selected = (_values[field.key] is List)
            ? List<String>.from(_values[field.key] as List)
            : <String>[];
        return _LabeledField(
          label: field.label,
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: AppTheme.surfaceWhite,
              borderRadius: BorderRadius.circular(AppTheme.inputRadius),
              border: Border.all(color: AppTheme.inputBorderColor),
            ),
            child: Wrap(
              spacing: 8,
              runSpacing: 8,
              children: options.map((option) {
                final isSelected = selected.contains(option.value);
                return FilterChip(
                  label: Text(option.label),
                  selected: isSelected,
                  selectedColor: AppTheme.sidebarActive,
                  checkmarkColor: AppTheme.terra800,
                  side: const BorderSide(color: AppTheme.softBorder),
                  labelStyle: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: isSelected
                            ? AppTheme.terra800
                            : AppTheme.textPrimary,
                        fontWeight: FontWeight.w500,
                      ),
                  onSelected: (value) {
                    setState(() {
                      if (value) {
                        selected.add(option.value);
                      } else {
                        selected.remove(option.value);
                      }
                      _values[field.key] = selected.toSet().toList();
                    });
                  },
                );
              }).toList(),
            ),
          ),
        );
    }
  }

  String _stringValue(String key) {
    final value = _values[key];
    if (value == null) {
      return '';
    }
    if (value is String) {
      return value;
    }
    return '$value';
  }

  double _parseNumber(String value) {
    return double.tryParse(value.trim()) ?? 0;
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() => _saving = true);
    try {
      final messenger = ScaffoldMessenger.of(context);
      if (widget.item == null) {
        await widget.controller.add(_values);
      } else {
        await widget.controller.updateItem(widget.item!.id, _values);
      }
      if (!mounted) {
        return;
      }
      Navigator.of(context).pop();
      messenger.showSnackBar(
        SnackBar(
          backgroundColor: AppTheme.successText,
          duration: const Duration(milliseconds: 2500),
          content: const Text('Saved successfully'),
        ),
      );
    } catch (e) {
      _showSnackBar(context, e.toString(), AppTheme.dangerText);
    } finally {
      if (mounted) {
        setState(() => _saving = false);
      }
    }
  }
}

class _LabeledField extends StatelessWidget {
  const _LabeledField({
    required this.label,
    required this.child,
  });

  final String label;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.textSecondary,
                  height: 1,
                ),
          ),
          const SizedBox(height: 6),
          child,
        ],
      ),
    );
  }
}

class _MetadataRow {
  const _MetadataRow({
    required this.label,
    required this.value,
  });

  final String label;
  final String value;
}

class _RecordMetaBlock extends StatelessWidget {
  const _RecordMetaBlock({
    required this.rows,
  });

  final List<_MetadataRow> rows;

  @override
  Widget build(BuildContext context) {
    if (rows.isEmpty) {
      return const SizedBox.shrink();
    }

    return Wrap(
      spacing: 12,
      runSpacing: 10,
      children: rows
          .map(
            (row) => Container(
              constraints: const BoxConstraints(maxWidth: 280),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              decoration: BoxDecoration(
                color: AppTheme.pageBg,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: AppTheme.softBorder),
              ),
              child: RichText(
                text: TextSpan(
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppTheme.textSecondary,
                        height: 1.45,
                      ),
                  children: [
                    TextSpan(
                      text: '${row.label}; ',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: AppTheme.textSecondary,
                            fontWeight: FontWeight.w600,
                            fontSize: 12,
                          ),
                    ),
                    TextSpan(
                      text: row.value,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: AppTheme.textPrimary,
                            fontWeight: FontWeight.w500,
                            fontSize: 12,
                          ),
                    ),
                  ],
                ),
              ),
            ),
          )
          .toList(),
    );
  }
}

class _SettingsRecordCard extends StatelessWidget {
  const _SettingsRecordCard({
    required this.titleLabel,
    required this.titleValue,
    required this.rows,
    required this.onEdit,
    required this.onDelete,
  });

  final String titleLabel;
  final String titleValue;
  final List<_MetadataRow> rows;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final stacked = constraints.maxWidth < 420;
        return Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppTheme.surfaceWhite,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: AppTheme.softBorder),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (stacked)
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _RecordTitleBlock(
                      titleLabel: titleLabel,
                      titleValue: titleValue,
                    ),
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        _RecordActionButton(
                          icon: Icons.edit_outlined,
                          color: AppTheme.textSecondary,
                          onTap: onEdit,
                        ),
                        _RecordActionButton(
                          icon: Icons.delete_outline,
                          color: AppTheme.dangerText,
                          onTap: onDelete,
                        ),
                      ],
                    ),
                  ],
                )
              else
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: _RecordTitleBlock(
                        titleLabel: titleLabel,
                        titleValue: titleValue,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        _RecordActionButton(
                          icon: Icons.edit_outlined,
                          color: AppTheme.textSecondary,
                          onTap: onEdit,
                        ),
                        const SizedBox(width: 8),
                        _RecordActionButton(
                          icon: Icons.delete_outline,
                          color: AppTheme.dangerText,
                          onTap: onDelete,
                        ),
                      ],
                    ),
                  ],
                ),
              if (rows.isNotEmpty) ...[
                const SizedBox(height: 14),
                Container(
                  height: 1,
                  color: AppTheme.listTileDivider,
                ),
                const SizedBox(height: 14),
                _RecordMetaBlock(rows: rows),
              ],
            ],
          ),
        );
      },
    );
  }
}

class _RecordTitleBlock extends StatelessWidget {
  const _RecordTitleBlock({
    required this.titleLabel,
    required this.titleValue,
  });

  final String titleLabel;
  final String titleValue;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '$titleLabel;'.toUpperCase(),
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: AppTheme.textSecondary,
                fontWeight: FontWeight.w600,
                fontSize: 11,
                letterSpacing: 0.3,
              ),
        ),
        const SizedBox(height: 6),
        Text(
          titleValue,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                color: AppTheme.textPrimary,
                fontWeight: FontWeight.w600,
              ),
        ),
      ],
    );
  }
}

class _RecordActionButton extends StatelessWidget {
  const _RecordActionButton({
    required this.icon,
    required this.color,
    required this.onTap,
  });

  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppTheme.pageBg,
      borderRadius: BorderRadius.circular(10),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(10),
        child: Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: AppTheme.softBorder),
          ),
          child: Icon(icon, size: 18, color: color),
        ),
      ),
    );
  }
}

void _showSnackBar(BuildContext context, String message, Color color) {
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      backgroundColor: color,
      duration: const Duration(milliseconds: 2500),
      content: Text(message),
    ),
  );
}
