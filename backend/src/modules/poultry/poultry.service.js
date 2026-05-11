// Business logic: flock status report + demand analysis.
const { poultryCollection } = require('./poultry.validators');
const { settingsCollection } = require('../../utils/firestore');

// ─── Flock Status Report ───────────────────────────────────────────────────────

async function getFlockStatus(uid, flockId) {
  const flockSnap = await poultryCollection(uid, 'flocks').doc(flockId).get();
  if (!flockSnap.exists) throw Object.assign(new Error('Flock not found'), { statusCode: 404 });

  const flock = { id: flockSnap.id, ...flockSnap.data() };
  const today = new Date();
  const placement = new Date(flock.placementDate);
  const ageDays = Math.max(0, Math.floor((today - placement) / 86400000));

  // Feed history (ordered by date desc)
  const feedSnap = await poultryCollection(uid, 'flockFeeds')
    .where('flockId', '==', flockId)
    .orderBy('date', 'asc')
    .get();
  const feedHistory = feedSnap.docs.map((d) => ({ id: d.id, ...d.data() }));

  const totalMortality = feedHistory.reduce((sum, r) => sum + (r.mortalityCount || 0), 0);
  const currentBirdsCount = flock.currentBirdsCount ?? (flock.initialBirdsCount - totalMortality);
  const totalFeedConsumedKg = feedHistory.reduce((sum, r) => sum + (r.feedConsumedKg || 0), 0);
  const averageDailyFeedKg  = feedHistory.length > 0 ? totalFeedConsumedKg / feedHistory.length : 0;

  const latestFeed = feedHistory.length > 0 ? feedHistory[feedHistory.length - 1] : null;
  const averageCurrentWeightKg = latestFeed?.averageWeightKg || 0;
  const fcr = (currentBirdsCount > 0 && averageCurrentWeightKg > 0)
    ? totalFeedConsumedKg / (currentBirdsCount * averageCurrentWeightKg)
    : 0;

  const mortalityRate = flock.initialBirdsCount > 0
    ? ((totalMortality / flock.initialBirdsCount) * 100).toFixed(2) + '%'
    : '0%';

  // Vaccine history
  const vacSnap = await poultryCollection(uid, 'flockVaccines')
    .where('flockId', '==', flockId)
    .orderBy('date', 'asc')
    .get();
  const vaccineHistory = vacSnap.docs.map((d) => ({ id: d.id, ...d.data() }));

  // Pending vaccines from schedules
  const pendingVaccines = [];
  const completedVaccineScheduleIds = new Set(vaccineHistory.map((v) => v.vaccineScheduleId).filter(Boolean));
  const scheduleIds = flock.vaccineScheduleIds || [];
  for (const sid of scheduleIds) {
    if (completedVaccineScheduleIds.has(sid)) continue;
    const sSnap = await poultryCollection(uid, 'vaccineSchedules').doc(sid).get();
    if (!sSnap.exists) continue;
    const sched = sSnap.data();
    const dueDate = new Date(placement);
    dueDate.setDate(dueDate.getDate() + (sched.targetAgeDays || 0));
    const overdueDays = Math.max(0, Math.floor((today - dueDate) / 86400000));
    pendingVaccines.push({
      scheduleId: sid,
      name: sched.name,
      dueDate: dueDate.toISOString().split('T')[0],
      overdueDays,
    });
  }

  const projectedHarvestDate = flock.targetAgeDays
    ? new Date(placement.getTime() + flock.targetAgeDays * 86400000).toISOString().split('T')[0]
    : null;

  return {
    flock,
    ageDays,
    currentBirdsCount,
    totalMortality,
    mortalityRate,
    totalFeedConsumedKg: +totalFeedConsumedKg.toFixed(2),
    averageDailyFeedKg:  +averageDailyFeedKg.toFixed(2),
    feedConversionRatio: +fcr.toFixed(3),
    averageCurrentWeightKg,
    projectedHarvestDate,
    pendingVaccines,
    completedVaccines: vaccineHistory,
    feedHistory,
  };
}

// ─── Demand Analysis Report ────────────────────────────────────────────────────

async function getDemandAnalysis(uid, flockIds, daysAhead) {
  const today   = new Date();
  today.setHours(0, 0, 0, 0);
  const asOfDate = today.toISOString().split('T')[0];

  const flockResults = [];

  for (const flockId of flockIds) {
    const flockSnap = await poultryCollection(uid, 'flocks').doc(flockId).get();
    if (!flockSnap.exists) continue;
    const flock = { id: flockSnap.id, ...flockSnap.data() };
    const placement = new Date(flock.placementDate);

    // Fetch feed schedules linked to this flock
    const feedSchedules = [];
    for (const fsId of (flock.feedScheduleIds || [])) {
      const fsSnap = await poultryCollection(uid, 'feedSchedules').doc(fsId).get();
      if (fsSnap.exists) feedSchedules.push({ id: fsSnap.id, ...fsSnap.data() });
    }

    // Fetch vaccine schedules linked to this flock
    const vaccineSchedules = [];
    for (const vsId of (flock.vaccineScheduleIds || [])) {
      const vsSnap = await poultryCollection(uid, 'vaccineSchedules').doc(vsId).get();
      if (vsSnap.exists) vaccineSchedules.push({ id: vsSnap.id, ...vsSnap.data() });
    }

    const currentBirds = flock.currentBirdsCount ?? flock.initialBirdsCount;
    const projectedFeed = [];
    const projectedVaccines = [];

    for (let d = 0; d < daysAhead; d++) {
      const date = new Date(today);
      date.setDate(date.getDate() + d);
      const ageDays = Math.max(0, Math.floor((date - placement) / 86400000));
      const dateStr = date.toISOString().split('T')[0];

      // Match feed schedule for this age.
      // null ageToDays means open-ended; fall back to the last schedule whose
      // ageFromDays <= ageDays when no exact range covers the current age.
      const inRange = feedSchedules.find(
        (fs) => ageDays >= fs.ageFromDays && (fs.ageToDays == null || ageDays <= fs.ageToDays),
      );
      const sched = inRange ?? feedSchedules
        .filter((fs) => ageDays >= fs.ageFromDays)
        .sort((a, b) => b.ageFromDays - a.ageFromDays)[0];
      if (sched) {
        const requiredKg = (sched.dailyFeedPerBirdGrams * currentBirds) / 1000;
        // Packing size to calc bags (default 50 kg bag)
        let bagSizeKg = 50;
        if (sched.packingId) {
          try {
            const pkSnap = await settingsCollection(uid, 'packings').doc(sched.packingId).get();
            if (pkSnap.exists) bagSizeKg = pkSnap.data().quantity || 50;
          } catch (_) {}
        }

        let productName = sched.productId;
        try {
          const pSnap = await settingsCollection(uid, 'products').doc(sched.productId).get();
          if (pSnap.exists) productName = pSnap.data().name || sched.productId;
        } catch (_) {}

        projectedFeed.push({
          date: dateStr,
          ageDays,
          scheduleName: sched.name,
          productId: sched.productId,
          productName,
          requiredKg: +requiredKg.toFixed(2),
          requiredBags: +(requiredKg / bagSizeKg).toFixed(1),
        });
      }

      // Match vaccine schedule for this day
      for (const vs of vaccineSchedules) {
        if (vs.targetAgeDays === ageDays) {
          let productName = vs.productId;
          try {
            const pSnap = await settingsCollection(uid, 'products').doc(vs.productId).get();
            if (pSnap.exists) productName = pSnap.data().name || vs.productId;
          } catch (_) {}

          projectedVaccines.push({
            date: dateStr,
            scheduleName: vs.name,
            productId: vs.productId,
            productName,
            birdsCount: currentBirds,
            totalDose: +(vs.dosePerBird * currentBirds).toFixed(2),
          });
        }
      }
    }

    flockResults.push({
      flockId: flock.id,
      flockName: flock.flockName,
      projectedFeed,
      projectedVaccines,
    });
  }

  // Aggregate by product
  const feedByProductMap = {};
  const vaccineByProductMap = {};
  for (const f of flockResults) {
    for (const pf of f.projectedFeed) {
      const key = pf.productId;
      if (!feedByProductMap[key]) feedByProductMap[key] = { productId: key, productName: pf.productName, totalKg: 0 };
      feedByProductMap[key].totalKg += pf.requiredKg;
    }
    for (const pv of f.projectedVaccines) {
      const key = pv.productId;
      if (!vaccineByProductMap[key]) vaccineByProductMap[key] = { productId: key, productName: pv.productName, totalDose: 0 };
      vaccineByProductMap[key].totalDose += pv.totalDose;
    }
  }

  return {
    asOfDate,
    projectionDays: daysAhead,
    flocks: flockResults,
    aggregated: {
      feedByProduct:    Object.values(feedByProductMap),
      vaccineByProduct: Object.values(vaccineByProductMap),
    },
  };
}

// ─── Update flock currentBirdsCount after feed record save ────────────────────

async function updateFlockCurrentBirds(uid, flockId) {
  // Get the latest feed record ordered by date desc
  const snap = await poultryCollection(uid, 'flockFeeds')
    .where('flockId', '==', flockId)
    .orderBy('date', 'desc')
    .limit(1)
    .get();

  if (snap.empty) return;
  const latest = snap.docs[0].data();
  const currentBirdsCount = Math.max(0, (latest.birdsCount || 0) - (latest.mortalityCount || 0));
  await poultryCollection(uid, 'flocks').doc(flockId).update({ currentBirdsCount });
}

module.exports = { getFlockStatus, getDemandAnalysis, updateFlockCurrentBirds };
