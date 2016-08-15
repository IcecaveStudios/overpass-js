(function() {
  var Request;

  module.exports = Request = (function() {
    function Request(name, args) {
      this.name = name;
      this.args = args;
    }

    Request.prototype.toString = function() {
      var argsString;
      argsString = this.args.map(JSON.stringify).join(", ");
      return "" + this.name + "(" + argsString + ")";
    };

    return Request;

  })();

}).call(this);

//# sourceMappingURL=Request.js.map
