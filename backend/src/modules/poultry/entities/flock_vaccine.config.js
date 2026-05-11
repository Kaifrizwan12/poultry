const {
  asRequiredString, asNullableString, asNumber, asEnum, asDateString,
  requireSettingsRef, requirePoultryRef, poultryCollection,
} = require('../poultry.validators');

const ADMIN_ROUTES = ['drinking_water', 'eye_drop', 'spray', 'injection', 'wing_stab'];

module.exports = {
  entity: 'flockVaccines',

  async sanitize({ uid, body }) {
    const errors = [];

    const flockId = asRequiredString(body.flockId, 'flockId', errors);
    await requirePoultryRef(uid, 'flocks', flockId, 'flockId', errors);

    const vaccineScheduleId = asNullableString(body.vaccineScheduleId);
    if (vaccineScheduleId) await requirePoultryRef(uid, 'vaccineSchedules', vaccineScheduleId, 'vaccineScheduleId', errors);

    const productId = asRequiredString(body.productId, 'productId', errors);
    await requireSettingsRef(uid, 'products', productId, 'productId', errors);

    const birdsVaccinated = asNumber(body.birdsVaccinated, 'birdsVaccinated', errors, { required: true, min: 1, integer: true });
    const dosePerBird     = asNumber(body.dosePerBird,     'dosePerBird',     errors, { required: true, min: 0.0001 });
    const totalDoseUsed   = (dosePerBird && birdsVaccinated) ? dosePerBird * birdsVaccinated : null;

    // Auto-calc nextDueDate from schedule if booster required
    let nextDueDate = asDateString(body.nextDueDate, 'nextDueDate', errors);
    const vaccineDate = asDateString(body.date, 'date', errors, { required: true });
    if (!nextDueDate && vaccineScheduleId && vaccineDate) {
      try {
        const snap = await poultryCollection(uid, 'vaccineSchedules').doc(vaccineScheduleId).get();
        if (snap.exists && snap.data().boosterRequired && snap.data().boosterIntervalDays) {
          const due = new Date(vaccineDate);
          due.setDate(due.getDate() + snap.data().boosterIntervalDays);
          nextDueDate = due.toISOString();
        }
      } catch (_) { /* ignore */ }
    }

    const data = {
      flockId,
      vaccineScheduleId,
      date:                vaccineDate,
      ageDays:             asNumber(body.ageDays, 'ageDays', errors, { required: true, min: 0, integer: true }),
      birdsVaccinated,
      productId,
      batchNo:             asNullableString(body.batchNo),
      administrationRoute: asEnum(body.administrationRoute, 'administrationRoute', errors, ADMIN_ROUTES),
      dosePerBird,
      totalDoseUsed,
      administeredBy:      asNullableString(body.administeredBy),
      nextDueDate,
      notes:               asNullableString(body.notes),
    };

    return { data, errors };
  },
};
