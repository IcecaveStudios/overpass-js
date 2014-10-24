module.exports = (path) -> require (process.env.TEST_ROOT or '../lib') + '/' + path
