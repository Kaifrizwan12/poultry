const {
  asRequiredString, asNullableString, asNumber, asEnum, asDateString,
  asBoolean, cleanStringList, requireSettingsRef, accountsCollection, nowIso,
} = require('../accounts.validators');

const ENTRY_TYPES      = ['debit', 'credit'];
const REFERENCE_TYPES  = ['manual', 'chicken_invoice', 'opening_receivable', 'opening_payable', 'other'];

module.exports = {
  entity: 'ledgerEntries',

  async sanitize({ uid, body, id }) {
    const errors = [];

    // Unique entryNo check
    const entryNo = asRequiredString(body.entryNo, 'entryNo', errors);
    if (entryNo) {
      const snap = await accountsCollection(uid, 'ledgerEntries')
        .where('entryNo', '==', entryNo)
        .limit(1)
        .get();
      if (!snap.empty && snap.docs[0].id !== id) {
        errors.push('entryNo must be unique');
      }
    }

    const accountId = asRequiredString(body.accountId, 'accountId', errors);
    if (accountId) await requireSettingsRef(uid, 'accounts', accountId, 'accountId', errors);

    const isReconciled = asBoolean(body.isReconciled, false);

    // Auto-set reconciledAt when isReconciled flips to true
    let reconciledAt = asNullableString(body.reconciledAt) || null;
    if (isReconciled && !reconciledAt) {
      reconciledAt = nowIso();
    } else if (!isReconciled) {
      reconciledAt = null;
    }

    const data = {
      entryNo,
      entryDate:     asDateString(body.entryDate, 'entryDate', errors, { required: true }),
      accountId,
      entryType:     asEnum(body.entryType, 'entryType', errors, ENTRY_TYPES, ''),
      amount:        asNumber(body.amount, 'amount', errors, { required: true, min: 0.000001 }),
      description:   asNullableString(body.description),
      referenceType: asEnum(body.referenceType, 'referenceType', errors, REFERENCE_TYPES, 'manual'),
      referenceId:   asNullableString(body.referenceId) || null,
      referenceNo:   asNullableString(body.referenceNo) || null,
      tags:          cleanStringList(body.tags),
      isReconciled,
      reconciledAt,
      notes:         asNullableString(body.notes) || null,
    };

    if (data.description && data.description.length > 500) {
      errors.push('description must be at most 500 characters');
    }

    return { data, errors };
  },
};
