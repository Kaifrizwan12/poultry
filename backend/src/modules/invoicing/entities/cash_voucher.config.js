const {
  asRequiredString, asNullableString, asNumber, asBoolean, asEnum,
  requireSettingsRef, invoicingEntityDoc, nowIso,
} = require('../invoicing.validators');
const { getDb } = require('../../../core/firebase/firebase');

async function nextVoucherNo(uid, voucherType) {
  const db       = getDb();
  const counterRef = invoicingEntityDoc(uid, `cashVoucherCounter_${voucherType}`);
  let no;
  await db.runTransaction(async (tx) => {
    const snap = await tx.get(counterRef);
    const last = snap.exists ? (snap.data().lastNo || 0) : 0;
    no = last + 1;
    tx.set(counterRef, { lastNo: no, updatedAt: nowIso() }, { merge: true });
  });
  const prefix = voucherType === 'credit' ? 'CRV' : voucherType === 'debit' ? 'DBV' : 'JRV';
  return `${prefix}-${String(no).padStart(4, '0')}`;
}

module.exports = {
  entity: 'cashVouchers',

  async sanitize({ uid, body, id }) {
    const errors = [];

    const voucherType = asEnum(body.voucherType, 'voucherType', errors, ['credit', 'debit', 'journal'], 'journal');

    const voucherNo = id
      ? asNullableString(body.voucherNo)
      : await nextVoucherNo(uid, voucherType);

    const rawLines = Array.isArray(body.lines) ? body.lines : [];
    const lines = [];
    for (let i = 0; i < rawLines.length; i++) {
      const r = rawLines[i];
      const accountId = asRequiredString(r.accountId, `lines[${i}].accountId`, errors);
      if (accountId) await requireSettingsRef(uid, 'accounts', accountId, `lines[${i}].accountId`, errors);

      const debit  = asNumber(r.debit,  `lines[${i}].debit`,  errors, { min: 0, defaultValue: 0 });
      const credit = asNumber(r.credit, `lines[${i}].credit`, errors, { min: 0, defaultValue: 0 });

      if (voucherType === 'credit' && debit !== 0) errors.push(`lines[${i}].debit must be 0 for credit voucher`);
      if (voucherType === 'debit'  && credit !== 0) errors.push(`lines[${i}].credit must be 0 for debit voucher`);

      lines.push({
        accountId,
        accountCode: asNullableString(r.accountCode) || asNullableString(r.accountNo), // accountNo kept for backward compat
        accountName: asNullableString(r.accountName),
        debit,
        credit,
        narration:   asNullableString(r.narration),
      });
    }

    const totalDebit  = lines.reduce((s, l) => s + l.debit, 0);
    const totalCredit = lines.reduce((s, l) => s + l.credit, 0);

    if (voucherType === 'journal' && Math.abs(totalDebit - totalCredit) > 0.001) {
      errors.push('Journal voucher: sum(debit) must equal sum(credit)');
    }

    return {
      data: {
        voucherType,
        voucherNo,
        voucherDate:   asRequiredString(body.voucherDate, 'voucherDate', errors),
        isConfirmed:   asBoolean(body.isConfirmed, false),
        confirmedDate: asNullableString(body.confirmedDate),
        confirmedBy:   asNullableString(body.confirmedBy),
        lines,
        totals: { debit: totalDebit, credit: totalCredit },
      },
      errors,
    };
  },
};
