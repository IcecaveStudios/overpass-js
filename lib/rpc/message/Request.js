(function() {
  var Request;

  module.exports = Request = (function() {
    function Request(name, _arguments) {
      this.name = name;
      this["arguments"] = _arguments;
    }

    Request.prototype.toString = function() {
      return this.name + '(' + this["arguments"].map(JSON.stringify).join(', ') + ')';
    };

    return Request;

  })();

}).call(this);

//# sourceMappingURL=Request.js.map
