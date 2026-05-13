const {
  asRequiredString, asNullableString, asNumber, asBoolean, asEnum,
  requireSettingsRef, nextSequentialId,
} = require('../invoicing.validators');

module.exports = {
  entity: 'bankCheques',

  async sanitize({ uid, body, id }) {
    const errors = [];

    const chequeId = id
      ? asNullableString(body.chequeId)
      : await nextSequentialId(uid, 'bankCheques', 'CHQ');

    const bankAccountId = asRequiredString(body.bankAccountId, 'bankAccountId', errors);
    await requireSettingsRef(uid, 'accounts', bankAccountId, 'bankAccountId', errors);

    const payeeType = asEnum(body.payeeType, 'payeeType', errors, ['vendor', 'account', 'other'], 'other');

    const vendorId = asNullableString(body.vendorId);
    if (payeeType === 'vendor') {
      if (!vendorId) errors.push('vendorId is required for vendor payeeType');
      else await requireSettingsRef(uid, 'vendors', vendorId, 'vendorId', errors);
    }

    const payeeAccountId = asNullableString(body.payeeAccountId);
    if (payeeType === 'account') {
      if (!payeeAccountId) errors.push('payeeAccountId is required for account payeeType');
      else await requireSettingsRef(uid, 'accounts', payeeAccountId, 'payeeAccountId', errors);
    }

    const payeeName = asNullableString(body.payeeName);
    if (payeeType === 'other' && !payeeName) errors.push('payeeName is required for other payeeType');

    const amount = asNumber(body.amount, 'amount', errors, { required: true, min: 0.01 });

    return {
      data: {
        chequeId,
        chequeNo:       asRequiredString(body.chequeNo, 'chequeNo', errors),
        chequeDate:     asRequiredString(body.chequeDate, 'chequeDate', errors),
        bankAccountId,
        bankAcNo:       asNullableString(body.bankAcNo),
        bankAccountName: asNullableString(body.bankAccountName),
        payeeType,
        vendorId,
        vendorName:     asNullableString(body.vendorName),
        payeeAccountId,
        payeeAccountName: asNullableString(body.payeeAccountName),
        payeeName,
        amount,
        narration:      asNullableString(body.narration),
        isPostDated:    asBoolean(body.isPostDated, false),
        status:         asEnum(body.status, 'status', errors, ['issued', 'cleared', 'bounced', 'cancelled'], 'issued'),
        clearedDate:    asNullableString(body.clearedDate),
      },
      errors,
    };
  },
};
