function log(level, message, data = null) {
  const timestamp = new Date().toISOString();
  const logMsg = `[${timestamp}] [${level}] ${message}`;
  if (data) {
    console.log(logMsg, JSON.stringify(data, null, 2));
  } else {
    console.log(logMsg);
  }
}

module.exports = { log };
