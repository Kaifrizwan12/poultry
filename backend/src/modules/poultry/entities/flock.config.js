const {
  asRequiredString, asNullableString, asNumber, asEnum, asDateString,
  cleanStringList, requireSettingsRef, requirePoultryRef, poultryCollection,
} = require('../poultry.validators');

const BIRD_TYPES    = ['broiler', 'layer', 'breeder', 'desi'];
const FLOCK_STATUSES = ['active', 'sold', 'closed'];

module.exports = {
  entity: 'flocks',

  async sanitize({ uid, body, id }) {
    const errors = [];

    const vendorId = asNullableString(body.vendorId);
    if (vendorId) await requireSettingsRef(uid, 'vendors', vendorId, 'vendorId', errors);

    // Unique flockNo check
    const flockNo = asRequiredString(body.flockNo, 'flockNo', errors);
    if (flockNo) {
      const snap = await poultryCollection(uid, 'flocks')
        .where('flockNo', '==', flockNo)
        .limit(1)
        .get();
      if (!snap.empty && snap.docs[0].id !== id) {
        errors.push('flockNo must be unique');
      }
    }

    const feedScheduleIds = cleanStringList(body.feedScheduleIds);
    for (const fsId of feedScheduleIds) {
      await requirePoultryRef(uid, 'feedSchedules', fsId, 'feedScheduleIds', errors);
    }

    const vaccineScheduleIds = cleanStringList(body.vaccineScheduleIds);
    for (const vsId of vaccineScheduleIds) {
      await requirePoultryRef(uid, 'vaccineSchedules', vsId, 'vaccineScheduleIds', errors);
    }

    const status = asEnum(body.status, 'status', errors, FLOCK_STATUSES, 'active');
    const initialBirdsCount = asNumber(body.initialBirdsCount, 'initialBirdsCount', errors, { required: true, min: 1, integer: true });

    const data = {
      flockNo,
      flockName:        asRequiredString(body.flockName, 'flockName', errors),
      birdType:         asEnum(body.birdType, 'birdType', errors, BIRD_TYPES),
      breed:            asNullableString(body.breed),
      placementDate:    asDateString(body.placementDate, 'placementDate', errors, { required: true }),
      initialBirdsCount,
      currentBirdsCount: id ? undefined : initialBirdsCount, // set on create only
      shedNo:           asRequiredString(body.shedNo, 'shedNo', errors),
      vendorId,
      placementWeightKg: asNumber(body.placementWeightKg, 'placementWeightKg', errors, { min: 0, defaultValue: 0 }),
      targetWeightKg:    asNumber(body.targetWeightKg,    'targetWeightKg',    errors, { min: 0, defaultValue: 0 }),
      targetAgeDays:     asNumber(body.targetAgeDays,     'targetAgeDays',     errors, { min: 1, integer: true }),
      feedScheduleIds,
      vaccineScheduleIds,
      status,
      closureDate:   (status !== 'active') ? asDateString(body.closureDate,   'closureDate',   errors) : '',
      closureReason: asNullableString(body.closureReason),
      notes:         asNullableString(body.notes),
    };

    // Remove undefined (currentBirdsCount on update)
    if (data.currentBirdsCount === undefined) delete data.currentBirdsCount;

    return { data, errors };
  },
};
