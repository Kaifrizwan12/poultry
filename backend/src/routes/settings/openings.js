const express = require('express');
const { createEntityRouter } = require('./_helpers');

const router = express.Router();

router.use('/stock', createEntityRouter('openingStock'));
router.use('/receivables', createEntityRouter('openingReceivables'));
router.use('/payables', createEntityRouter('openingPayables'));

module.exports = router;
