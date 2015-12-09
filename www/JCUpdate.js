var exec = require('cordova/exec');

//全部更新
exports.allUpdate = function(host, packPath, success, error) {
    exec(success, error, "JCUpdate", "allUpdate", [host, packPath]);
};

//增量更新
exports.incrementalUpdate = function(host, packPath, success, error) {
    exec(success, error, "JCUpdate", "incrementalUpdate", [host, packPath]);
};

//调试模式
exports.debugWeb = function(arg0, success, error) {
    exec(success, error, "JCUpdate", "debugWeb", [arg0]);
};

