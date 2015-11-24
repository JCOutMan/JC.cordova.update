var exec = require('cordova/exec');

exports.update = function(arg0, success, error) {
    exec(success, error, "update", "update", [arg0]);
};