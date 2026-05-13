const {
  asRequiredString, asNullableString, asNumber, asBoolean, asEnum,
  requireSettingsRef, nextSequentialId,
} = require('../invoicing.validators');

module.exports = {
  entity: 'bankDeposits',

  async sanitize({ uid, body, id }) {
    const errors = [];

    const depositId = id
      ? asNullableString(body.depositId)
      : await nextSequentialId(uid, 'bankDeposits', 'DEP');

    const depositType = asEnum(body.depositType, 'depositType', errors, ['cash', 'cheque'], 'cash');

    const bankAccountId = asRequiredString(body.bankAccountId, 'bankAccountId', errors);
    await requireSettingsRef(uid, 'accounts', bankAccountId, 'bankAccountId', errors);

    const fromAccountId = asNullableString(body.fromAccountId);
    if (fromAccountId) await requireSettingsRef(uid, 'accounts', fromAccountId, 'fromAccountId', errors);

    const amount = asNumber(body.amount, 'amount', errors, { required: true, min: 0.01 });

    const chequeNo        = depositType === 'cheque' ? asRequiredString(body.chequeNo, 'chequeNo', errors) : asNullableString(body.chequeNo);
    const chequeDate      = asNullableString(body.chequeDate);
    const drawerName      = asNullableString(body.drawerName);
    const drawerBankName  = asNullableString(body.drawerBankName);

    return {
      data: {
        depositId,
        depositType,
        depositDate:     asRequiredString(body.depositDate, 'depositDate', errors),
        bankAccountId,
        bankAccountName: asNullableString(body.bankAccountName),
        depositSlipNo:   asNullableString(body.depositSlipNo),
        amount,
        fromAccountId,
        fromAccountName: asNullableString(body.fromAccountName),
        narration:       asNullableString(body.narration),
        isConfirmed:     asBoolean(body.isConfirmed, false),
        confirmedDate:   asNullableString(body.confirmedDate),
        isReconciled:    asBoolean(body.isReconciled, false),
        reconciledDate:  asNullableString(body.reconciledDate),
        bankStatementRef: asNullableString(body.bankStatementRef),
        chequeNo,
        chequeDate,
        drawerName,
        drawerBankName,
      },
      errors,
    };
  },
};
