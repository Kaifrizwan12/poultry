const {
  asRequiredString, asNullableString, asNumber,
  requireSettingsRef, requireInvoicingRef, nextSequentialId,
} = require('../invoicing.validators');

module.exports = {
  entity: 'recoveryInvoices',

  async sanitize({ uid, body, id }) {
    const errors = [];

    const recoveryId = id
      ? asNullableString(body.recoveryId)
      : await nextSequentialId(uid, 'recoveryInvoices', 'REC');

    const salesmanId = asRequiredString(body.salesmanId, 'salesmanId', errors);
    await requireSettingsRef(uid, 'salesmen', salesmanId, 'salesmanId', errors);

    const rawRecoveries = Array.isArray(body.customerRecoveries) ? body.customerRecoveries : [];
    const customerRecoveries = [];
    for (let i = 0; i < rawRecoveries.length; i++) {
      const r = rawRecoveries[i];
      const customerId = asRequiredString(r.customerId, `customerRecoveries[${i}].customerId`, errors);
      if (customerId) await requireSettingsRef(uid, 'customers', customerId, `customerRecoveries[${i}].customerId`, errors);

      const saleId = asRequiredString(r.saleId, `customerRecoveries[${i}].saleId`, errors);
      if (saleId) await requireInvoicingRef(uid, 'salesInvoices', saleId, `customerRecoveries[${i}].saleId`, errors);

      const received = asNumber(r.received, `customerRecoveries[${i}].received`, errors, { min: 0, defaultValue: 0 });
      const discount = asNumber(r.discount, `customerRecoveries[${i}].discount`, errors, { min: 0, defaultValue: 0 });
      const finalCredit = received + discount;

      customerRecoveries.push({
        customerId,
        customerName: asNullableString(r.customerName),
        saleId,
        saleValue:    asNumber(r.saleValue, `customerRecoveries[${i}].saleValue`, errors, { defaultValue: 0 }),
        adjusted:     asNumber(r.adjusted, `customerRecoveries[${i}].adjusted`, errors, { defaultValue: 0 }),
        receivable:   asNumber(r.receivable, `customerRecoveries[${i}].receivable`, errors, { defaultValue: 0 }),
        received,
        discount,
        finalCredit,
        narration:    asNullableString(r.narration),
      });
    }

    const totalNoInvoices = customerRecoveries.length;
    const amount   = customerRecoveries.reduce((s, r) => s + r.received, 0);
    const discount = customerRecoveries.reduce((s, r) => s + r.discount, 0);

    return {
      data: {
        recoveryId,
        date:        asRequiredString(body.date, 'date', errors),
        salesmanId,
        salesmanName: asNullableString(body.salesmanName),
        customerRecoveries,
        totalNoInvoices,
        amount,
        discount,
      },
      errors,
    };
  },
};
