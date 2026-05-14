import 'package:farm_mgt_auth/core/app_theme.dart';
import 'package:farm_mgt_auth/services/api_service.dart';
import 'package:farm_mgt_auth/modules/settings/controllers/accounts_controller.dart';
import 'package:farm_mgt_auth/modules/settings/controllers/products_controller.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

/// Singleton settings screen for accounting integration configuration.
/// Calls GET /settings/posting-config on load, PUT on save.
/// No separate controller needed — this is a pure form screen.
class PostingConfigScreen extends StatefulWidget {
  const PostingConfigScreen({super.key});

  @override
  State<PostingConfigScreen> createState() => _PostingConfigScreenState();
}

class _PostingConfigScreenState extends State<PostingConfigScreen> {
  final ApiService _api = ApiService();
  bool _loading = true;
  bool _saving  = false;
  String? _error;

  String _arAccountId            = '';
  String _apAccountId            = '';
  String _salesRevenueAccountId  = '';
  String _purchaseExpenseAccountId = '';
  String _cashAccountId          = '';
  String _defaultBankAccountId   = '';
  String _chickenProductId       = '';
  final _notesCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _notesCtrl.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() { _loading = true; _error = null; });
    try {
      final res = await _api.get('/settings/posting-config', auth: true);
      final d   = res['data'] as Map<String, dynamic>? ?? {};
      setState(() {
        _arAccountId             = '${d['arAccountId']             ?? ''}';
        _apAccountId             = '${d['apAccountId']             ?? ''}';
        _salesRevenueAccountId   = '${d['salesRevenueAccountId']   ?? ''}';
        _purchaseExpenseAccountId= '${d['purchaseExpenseAccountId']?? ''}';
        _cashAccountId           = '${d['cashAccountId']           ?? ''}';
        _defaultBankAccountId    = '${d['defaultBankAccountId']    ?? ''}';
        _chickenProductId        = '${d['chickenProductId']        ?? ''}';
        _notesCtrl.text          = '${d['notes']                   ?? ''}';
        _loading = false;
      });
    } catch (e) {
      setState(() { _error = e.toString(); _loading = false; });
    }
  }

  Future<void> _save() async {
    setState(() => _saving = true);
    try {
      await _api.put('/settings/posting-config', {
        'arAccountId':              _arAccountId,
        'apAccountId':              _apAccountId,
        'salesRevenueAccountId':    _salesRevenueAccountId,
        'purchaseExpenseAccountId': _purchaseExpenseAccountId,
        'cashAccountId':            _cashAccountId,
        'defaultBankAccountId':     _defaultBankAccountId,
        'chickenProductId':         _chickenProductId,
        'notes':                    _notesCtrl.text,
      }, auth: true);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Posting configuration saved')));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')));
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) return const Center(child: CircularProgressIndicator());
    if (_error != null) return Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
      Text(_error!, style: const TextStyle(color: AppTheme.dangerText)),
      const SizedBox(height: 12),
      ElevatedButton(onPressed: _load, child: const Text('Retry')),
    ]));

    final accounts = context.read<AccountsController>().typedItems;
    final products  = context.read<ProductsController>().typedItems;

    List<DropdownMenuItem<String>> accountItems(String currentId) => [
      const DropdownMenuItem(value: '', child: Text('— Not set —')),
      ...accounts.map((a) => DropdownMenuItem(
        value: a.id,
        child: Text('${a.accountCode}  ${a.accountName}', overflow: TextOverflow.ellipsis),
      )),
    ];

    return SingleChildScrollView(
      padding: AppTheme.pagePadding(context),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('Posting Configuration',
            style: Theme.of(context).textTheme.titleLarge),
        const SizedBox(height: 6),
        const Text(
          'Map your GL accounts here so that Chicken Invoices (and future auto-posting features) '
          'can create ledger entries and Sales Invoices automatically.',
          style: TextStyle(fontSize: 13, color: AppTheme.textSecondary),
        ),
        const SizedBox(height: 20),

        Container(
          decoration: AppTheme.cardDecor,
          padding: AppTheme.cardPadding,
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            _sectionHead('Accounts Receivable & Payable'),
            _accountDrop('Accounts Receivable (AR)', _arAccountId, accountItems(_arAccountId),
                (v) => setState(() => _arAccountId = v ?? '')),
            _accountDrop('Accounts Payable (AP)', _apAccountId, accountItems(_apAccountId),
                (v) => setState(() => _apAccountId = v ?? '')),

            _sectionHead('Revenue & Expense'),
            _accountDrop('Sales Revenue Account', _salesRevenueAccountId,
                accountItems(_salesRevenueAccountId),
                (v) => setState(() => _salesRevenueAccountId = v ?? '')),
            _accountDrop('Purchase / Cost of Goods Account', _purchaseExpenseAccountId,
                accountItems(_purchaseExpenseAccountId),
                (v) => setState(() => _purchaseExpenseAccountId = v ?? '')),

            _sectionHead('Cash & Bank'),
            _accountDrop('Cash in Hand Account', _cashAccountId, accountItems(_cashAccountId),
                (v) => setState(() => _cashAccountId = v ?? '')),
            _accountDrop('Default Bank Account', _defaultBankAccountId,
                accountItems(_defaultBankAccountId),
                (v) => setState(() => _defaultBankAccountId = v ?? '')),

            _sectionHead('Chicken Invoice → Sales Invoice'),
            const Text(
              'When "Create Sales Invoice" is enabled on a Chicken Invoice, '
              'this product is used as the line item in the generated Sales Invoice.',
              style: TextStyle(fontSize: 11, color: AppTheme.textSecondary),
            ),
            const SizedBox(height: 8),
            DropdownButtonFormField<String>(
              value: _chickenProductId.isEmpty ? null : _chickenProductId,
              decoration: AppTheme.inputDecoration('Chicken / Live Birds Product'),
              isExpanded: true,
              items: [
                const DropdownMenuItem(value: '', child: Text('— Not set —')),
                ...products.map((p) => DropdownMenuItem(
                  value: p.id,
                  child: Text('${p.code.isNotEmpty ? "[${p.code}] " : ""}${p.name}',
                      overflow: TextOverflow.ellipsis),
                )),
              ],
              onChanged: (v) => setState(() => _chickenProductId = v ?? ''),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _notesCtrl,
              decoration: AppTheme.inputDecoration('Notes'),
              maxLines: 2,
            ),
          ]),
        ),

        const SizedBox(height: 20),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: _saving ? null : _save,
            child: _saving
                ? const SizedBox(width: 16, height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                : const Text('Save Configuration'),
          ),
        ),
      ]),
    );
  }

  Widget _sectionHead(String label) => Padding(
    padding: const EdgeInsets.only(top: 16, bottom: 8),
    child: Text(label, style: const TextStyle(
        fontSize: 13, fontWeight: FontWeight.w700, color: AppTheme.terra600)),
  );

  Widget _accountDrop(String label, String current,
      List<DropdownMenuItem<String>> items, ValueChanged<String?> onChanged) =>
    Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: DropdownButtonFormField<String>(
        value: current.isEmpty ? null : current,
        decoration: AppTheme.inputDecoration(label),
        isExpanded: true,
        items: items,
        onChanged: onChanged,
      ),
    );
}
