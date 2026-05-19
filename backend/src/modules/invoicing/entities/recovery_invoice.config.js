const {
  asRequiredString, asNullableString, asNumber,
  requireSettingsRef, requireInvoicingRef, nextBusinessId, invoicingCollection,
} = require('../invoicing.validators');

module.exports = {
  entity: 'recoveryInvoices',

  async sanitize({ uid, body, id }) {
    const errors = [];

    const recoveryId = id
      ? asNullableString(body.recoveryId)
      : await nextBusinessId(uid, 'recoveryInvoices', 'REC');

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

      // Server-verify saleValue from actual Sales Invoice — never trust client value
      let saleValue = asNumber(r.saleValue, `customerRecoveries[${i}].saleValue`, errors, { defaultValue: 0 });
      if (saleId) {
        const siSnap = await invoicingCollection(uid, 'salesInvoices').doc(saleId).get();
        if (siSnap.exists) saleValue = siSnap.data().totalPayable || 0;
      }

      const received = asNumber(r.received, `customerRecoveries[${i}].received`, errors, { min: 0, defaultValue: 0 });
      const discount = asNumber(r.discount, `customerRecoveries[${i}].discount`, errors, { min: 0, defaultValue: 0 });
      const finalCredit = received + discount;

      // Validate: reject if SI is already fully paid, and check cumulative does not exceed saleValue
      if (saleId && received > 0) {
        // Check current remBalance from SI document
        const siSnap = await invoicingCollection(uid, 'salesInvoices').doc(saleId).get();
        if (siSnap.exists) {
          const siRemBalance = siSnap.data().remBalance ?? siSnap.data().totalPayable ?? 0;
          if (siRemBalance <= 0.01) {
            errors.push(`customerRecoveries[${i}]: sales invoice ${saleId} is already fully settled (remBalance: ${siRemBalance})`);
          }
        }

        const prevSnap = await invoicingCollection(uid, 'recoveryInvoices').get();
        let alreadyReceived = 0;
        prevSnap.docs.forEach(doc => {
          if (id && doc.id === id) return;
          const recoveries = doc.data().customerRecoveries || [];
          recoveries.forEach(rc => {
            if (rc.saleId === saleId) alreadyReceived += (rc.finalCredit || 0);
          });
        });
        if (alreadyReceived + finalCredit > saleValue + 0.01) {
          errors.push(`customerRecoveries[${i}]: total recovery (${(alreadyReceived + finalCredit).toFixed(2)}) exceeds invoice value (${saleValue})`);
        }
      }

      customerRecoveries.push({
        customerId,
        customerName: asNullableString(r.customerName),
        saleId,
        saleValue,   // server-verified from actual SI
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
