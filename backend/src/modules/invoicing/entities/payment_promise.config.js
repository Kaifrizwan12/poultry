const {
  asRequiredString, asNullableString, asNumber, asEnum, cleanStringList,
  requireSettingsRef, requireInvoicingRef, nextSequentialId,
} = require('../invoicing.validators');

module.exports = {
  entity: 'paymentPromises',

  async sanitize({ uid, body, id }) {
    const errors = [];

    const promiseId = id
      ? asNullableString(body.promiseId)
      : await nextSequentialId(uid, 'paymentPromises', 'PP');

    const promiseType = asEnum(body.promiseType, 'promiseType', errors, ['recovery', 'payment'], 'recovery');

    const customerId = asNullableString(body.customerId);
    if (promiseType === 'recovery') {
      if (!customerId) errors.push('customerId is required for recovery promise');
      else await requireSettingsRef(uid, 'customers', customerId, 'customerId', errors);
    }

    const vendorId = asNullableString(body.vendorId);
    if (promiseType === 'payment') {
      if (!vendorId) errors.push('vendorId is required for payment promise');
      else await requireSettingsRef(uid, 'vendors', vendorId, 'vendorId', errors);
    }

    const salesmanId = asNullableString(body.salesmanId);
    if (salesmanId) await requireSettingsRef(uid, 'salesmen', salesmanId, 'salesmanId', errors);

    const amount = asNumber(body.amount, 'amount', errors, { required: true, min: 0.01 });

    const linkedSaleIds = cleanStringList(body.linkedSaleIds);
    if (promiseType === 'recovery') {
      for (const sid of linkedSaleIds) {
        await requireInvoicingRef(uid, 'salesInvoices', sid, 'linkedSaleIds', errors);
      }
    }

    const linkedPurchaseIds = cleanStringList(body.linkedPurchaseIds);
    if (promiseType === 'payment') {
      for (const pid of linkedPurchaseIds) {
        await requireInvoicingRef(uid, 'purchaseInvoices', pid, 'linkedPurchaseIds', errors);
      }
    }

    return {
      data: {
        promiseId,
        promiseType,
        entryDate:      asRequiredString(body.entryDate, 'entryDate', errors),
        promiseDate:    asRequiredString(body.promiseDate, 'promiseDate', errors),
        customerId,
        customerName:   asNullableString(body.customerName),
        vendorId,
        vendorName:     asNullableString(body.vendorName),
        salesmanId,
        salesmanName:   asNullableString(body.salesmanName),
        chequeNo:       asNullableString(body.chequeNo),
        bankName:       asNullableString(body.bankName),
        amount,
        narration:      asNullableString(body.narration),
        linkedSaleIds,
        linkedPurchaseIds,
        status:         asEnum(body.status, 'status', errors, ['pending', 'cleared', 'bounced', 'cancelled'], 'pending'),
        processedDate:  asNullableString(body.processedDate),
      },
      errors,
    };
  },
};
