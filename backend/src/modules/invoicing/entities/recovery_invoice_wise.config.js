const {
  asRequiredString, asNullableString, asNumber, asBoolean,
  requireSettingsRef, requireInvoicingRef, nextBusinessId,
} = require('../invoicing.validators');

module.exports = {
  entity: 'recoveryInvoicesWise',

  async sanitize({ uid, body, id }) {
    const errors = [];

    const recoveryId = id
      ? asNullableString(body.recoveryId)
      : await nextBusinessId(uid, 'recoveryInvoicesWise', 'RIW');

    const salesmanId = asRequiredString(body.salesmanId, 'salesmanId', errors);
    await requireSettingsRef(uid, 'salesmen', salesmanId, 'salesmanId', errors);

    const rawRecoveries = Array.isArray(body.customerRecoveries) ? body.customerRecoveries : [];
    const customerRecoveries = [];
    for (let i = 0; i < rawRecoveries.length; i++) {
      const r = rawRecoveries[i];
      const customerId = asRequiredString(r.customerId, `customerRecoveries[${i}].customerId`, errors);
      if (customerId) await requireSettingsRef(uid, 'customers', customerId, `customerRecoveries[${i}].customerId`, errors);

      const rawInvoices = Array.isArray(r.invoices) ? r.invoices : [];
      const invoices = [];
      for (let j = 0; j < rawInvoices.length; j++) {
        const inv = rawInvoices[j];
        const saleId = asRequiredString(inv.saleId, `customerRecoveries[${i}].invoices[${j}].saleId`, errors);
        if (saleId) await requireInvoicingRef(uid, 'salesInvoices', saleId, `customerRecoveries[${i}].invoices[${j}].saleId`, errors);

        const received = asNumber(inv.received, `customerRecoveries[${i}].invoices[${j}].received`, errors, { min: 0, defaultValue: 0 });
        const discount = asNumber(inv.discount, `customerRecoveries[${i}].invoices[${j}].discount`, errors, { min: 0, defaultValue: 0 });
        const balance  = asNumber(inv.receivable, `customerRecoveries[${i}].invoices[${j}].receivable`, errors, { defaultValue: 0 }) - received - discount;

        invoices.push({
          saleId,
          date:         asNullableString(inv.date),
          invoiceValue: asNumber(inv.invoiceValue, `customerRecoveries[${i}].invoices[${j}].invoiceValue`, errors, { defaultValue: 0 }),
          adjusted:     asNumber(inv.adjusted, `customerRecoveries[${i}].invoices[${j}].adjusted`, errors, { defaultValue: 0 }),
          receivable:   asNumber(inv.receivable, `customerRecoveries[${i}].invoices[${j}].receivable`, errors, { defaultValue: 0 }),
          received,
          discount,
          balance,
          narration:    asNullableString(inv.narration),
        });
      }

      customerRecoveries.push({
        customerId,
        customerName: asNullableString(r.customerName),
        sector:       asNullableString(r.sector),
        invoices,
      });
    }

    const allInvoices = customerRecoveries.flatMap(c => c.invoices);
    const netReceived      = allInvoices.reduce((s, inv) => s + inv.received, 0);
    const discount         = allInvoices.reduce((s, inv) => s + inv.discount, 0);
    const grossRecoveries  = netReceived + discount;

    return {
      data: {
        recoveryId,
        recoveryDate:          asRequiredString(body.recoveryDate, 'recoveryDate', errors),
        salesmanId,
        salesmanName:          asNullableString(body.salesmanName),
        townId:                asNullableString(body.townId),
        sectorId:              asNullableString(body.sectorId),
        showSalesmanInNarration: asBoolean(body.showSalesmanInNarration, false),
        customerRecoveries,
        netReceived,
        discount,
        grossRecoveries,
      },
      errors,
    };
  },
};
