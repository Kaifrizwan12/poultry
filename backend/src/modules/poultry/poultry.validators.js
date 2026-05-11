// Shared validation utilities for the poultry module.
// Mirrors the helpers in models/settings.config.js (not exported there).

const { getDb } = require('../../core/firebase/firebase');

function requireDb() {
  const db = getDb();
  if (!db) {
    const err = new Error('Firestore is not initialized');
    err.statusCode = 503;
    throw err;
  }
  return db;
}

// ─── Poultry Firestore helpers ────────────────────────────────────────────────

function poultryEntityDoc(uid, entity) {
  return requireDb()
    .collection('users')
    .doc(uid)
    .collection('poultry')
    .doc(entity);
}

function poultryCollection(uid, entity) {
  return poultryEntityDoc(uid, entity).collection('items');
}

async function ensurePoultryExists(uid, entity, id) {
  if (!id) return false;
  const snap = await poultryCollection(uid, entity).doc(id).get();
  return snap.exists;
}

// Reuse settings collection for cross-entity FK checks (products, vendors, etc.)
const { ensureExists: ensureSettingsExists } = require('../../utils/firestore');

// ─── Primitive validators ─────────────────────────────────────────────────────

function trimString(value, fallback) {
  if (value === undefined || value === null) return fallback === undefined ? undefined : fallback;
  return String(value).trim();
}

function asNullableString(value) {
  return trimString(value, '');
}

function asRequiredString(value, field, errors, options = {}) {
  const next = trimString(value);
  if (!next) { errors.push(`${field} is required`); return ''; }
  if (options.maxLength && next.length > options.maxLength)
    errors.push(`${field} must be at most ${options.maxLength} characters`);
  return next;
}

function asNumber(value, field, errors, options = {}) {
  if (value === undefined || value === null || value === '') {
    if (options.required) errors.push(`${field} is required`);
    return options.defaultValue !== undefined ? options.defaultValue : null;
  }
  const next = Number(value);
  if (Number.isNaN(next)) {
    errors.push(`${field} must be a number`);
    return options.defaultValue !== undefined ? options.defaultValue : null;
  }
  if (options.min !== undefined && next < options.min)
    errors.push(`${field} must be at least ${options.min}`);
  if (options.integer && !Number.isInteger(next))
    errors.push(`${field} must be a whole number`);
  return next;
}

function asBoolean(value, defaultValue) {
  if (value === undefined || value === null) return defaultValue;
  return Boolean(value);
}

function asEnum(value, field, errors, allowed, defaultValue) {
  const next = trimString(value, defaultValue);
  if (!next) { errors.push(`${field} is required`); return defaultValue; }
  if (!allowed.includes(next)) errors.push(`${field} must be one of: ${allowed.join(', ')}`);
  return next;
}

function asDateString(value, field, errors, options = {}) {
  if (!value) {
    if (options.required) errors.push(`${field} is required`);
    return '';
  }
  const d = new Date(value);
  if (Number.isNaN(d.getTime())) { errors.push(`${field} must be a valid date`); return ''; }
  return d.toISOString();
}

function cleanStringList(value) {
  if (!Array.isArray(value)) return [];
  return value.map((item) => String(item).trim()).filter((item) => item.length > 0);
}

async function requireSettingsRef(uid, entity, id, field, errors) {
  if (!id) return;
  const exists = await ensureSettingsExists(uid, entity, id);
  if (!exists) errors.push(`${field} references a non-existent ${entity} record`);
}

async function requirePoultryRef(uid, entity, id, field, errors) {
  if (!id) return;
  const exists = await ensurePoultryExists(uid, entity, id);
  if (!exists) errors.push(`${field} references a non-existent ${entity} record`);
}

function nowIso() {
  return new Date().toISOString();
}

function stampNew(uid, data) {
  const ts = nowIso();
  return { ...data, uid, createdAt: ts, updatedAt: ts };
}

function stampUpdated(existing, data) {
  return { ...existing, ...data, updatedAt: nowIso() };
}

module.exports = {
  poultryCollection,
  poultryEntityDoc,
  ensurePoultryExists,
  asNullableString,
  asRequiredString,
  asNumber,
  asBoolean,
  asEnum,
  asDateString,
  cleanStringList,
  requireSettingsRef,
  requirePoultryRef,
  stampNew,
  stampUpdated,
  nowIso,
};
