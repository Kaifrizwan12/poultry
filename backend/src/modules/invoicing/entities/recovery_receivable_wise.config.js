const {
  asRequiredString, asNullableString, asNumber, asBoolean,
  requireSettingsRef, nextBusinessId,
} = require('../invoicing.validators');

module.exports = {
  entity: 'recoveryReceivableWise',

  async sanitize({ uid, body, id }) {
    const errors = [];

    const recoveryId = id
      ? asNullableString(body.recoveryId)
      : await nextBusinessId(uid, 'recoveryReceivableWise', 'RRW');

    const salesmanId = asRequiredString(body.salesmanId, 'salesmanId', errors);
    await requireSettingsRef(uid, 'salesmen', salesmanId, 'salesmanId', errors);

    const rawRecoveries = Array.isArray(body.customerRecoveries) ? body.customerRecoveries : [];
    const customerRecoveries = [];
    for (let i = 0; i < rawRecoveries.length; i++) {
      const r = rawRecoveries[i];
      const customerId = asRequiredString(r.customerId, `customerRecoveries[${i}].customerId`, errors);
      if (customerId) await requireSettingsRef(uid, 'customers', customerId, `customerRecoveries[${i}].customerId`, errors);

      const received   = asNumber(r.received, `customerRecoveries[${i}].received`, errors, { min: 0, defaultValue: 0 });
      const discount   = asNumber(r.discount, `customerRecoveries[${i}].discount`, errors, { min: 0, defaultValue: 0 });
      const receivable = asNumber(r.receivable, `customerRecoveries[${i}].receivable`, errors, { defaultValue: 0 });
      const balance    = receivable - received - discount;

      customerRecoveries.push({
        customerId,
        customerName: asNullableString(r.customerName),
        sector:       asNullableString(r.sector),
        receivable,
        received,
        discount,
        balance,
        narration:    asNullableString(r.narration),
      });
    }

    const netReceived     = customerRecoveries.reduce((s, r) => s + r.received, 0);
    const discount        = customerRecoveries.reduce((s, r) => s + r.discount, 0);
    const grossRecoveries = netReceived + discount;

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
