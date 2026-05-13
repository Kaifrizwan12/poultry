const {
  asRequiredString, asNullableString, asNumber, asEnum,
  requireSettingsRef, requireInvoicingRef, nextSequentialId,
} = require('../invoicing.validators');

module.exports = {
  entity: 'salesmanCashReconciliations',

  async sanitize({ uid, body, id }) {
    const errors = [];

    const reconciliationId = id
      ? asNullableString(body.reconciliationId)
      : await nextSequentialId(uid, 'salesmanCashReconciliations', 'SCR');

    const salesmanId = asRequiredString(body.salesmanId, 'salesmanId', errors);
    await requireSettingsRef(uid, 'salesmen', salesmanId, 'salesmanId', errors);

    const openingBalance = asNumber(body.openingBalance, 'openingBalance', errors, { defaultValue: 0 });

    const rawRecoveries = Array.isArray(body.recoveryEntries) ? body.recoveryEntries : [];
    const recoveryEntries = [];
    for (let i = 0; i < rawRecoveries.length; i++) {
      const r = rawRecoveries[i];
      const recoveryId = asRequiredString(r.recoveryId, `recoveryEntries[${i}].recoveryId`, errors);
      if (recoveryId) await requireInvoicingRef(uid, 'recoveryInvoices', recoveryId, `recoveryEntries[${i}].recoveryId`, errors);

      recoveryEntries.push({
        recoveryId,
        recoveryDate:   asNullableString(r.recoveryDate),
        cashReceived:   asNumber(r.cashReceived, `recoveryEntries[${i}].cashReceived`, errors, { min: 0, defaultValue: 0 }),
        discountGiven:  asNumber(r.discountGiven, `recoveryEntries[${i}].discountGiven`, errors, { min: 0, defaultValue: 0 }),
        narration:      asNullableString(r.narration),
      });
    }

    const rawExpenses = Array.isArray(body.expenseEntries) ? body.expenseEntries : [];
    const expenseEntries = [];
    for (let i = 0; i < rawExpenses.length; i++) {
      const e = rawExpenses[i];
      expenseEntries.push({
        description: asRequiredString(e.description, `expenseEntries[${i}].description`, errors),
        amount:      asNumber(e.amount, `expenseEntries[${i}].amount`, errors, { min: 0, defaultValue: 0 }),
      });
    }

    const totalCashReceived = recoveryEntries.reduce((s, r) => s + r.cashReceived, 0);
    const totalDiscount     = recoveryEntries.reduce((s, r) => s + r.discountGiven, 0);
    const totalExpenses     = expenseEntries.reduce((s, e) => s + e.amount, 0);
    const cashDeposited     = asNumber(body.cashDeposited, 'cashDeposited', errors, { min: 0, defaultValue: 0 });
    const closingBalance    = openingBalance + totalCashReceived - totalExpenses - cashDeposited;

    return {
      data: {
        reconciliationId,
        date:            asRequiredString(body.date, 'date', errors),
        salesmanId,
        salesmanName:    asNullableString(body.salesmanName),
        openingBalance,
        recoveryEntries,
        expenseEntries,
        totalCashReceived,
        totalDiscount,
        totalExpenses,
        cashDeposited,
        closingBalance,
        status:          asEnum(body.status, 'status', errors, ['pending', 'saved'], 'pending'),
      },
      errors,
    };
  },
};
