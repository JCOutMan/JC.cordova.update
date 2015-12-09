# JC.cordova.update 
一个作用于ios版本的cordova插件,可以在线更新web内容.

#安装
cordova plugin add https://github.com/JCOutMan/JC.cordova.update

#使用
#host:  主机地址 如:www.baidu.com
#packPath:  更新包地址  如:/download/www.zip   必需要zip包

#全部更新
JCUpdate.allUpdate(host, packPath, function(){
  alert("update success");
}, function(reason){
  alert("error:" + reason);
})

#增量更新
JCUpdate.incrementalUpdate(host, packPath, function(){
        alert("update ok");
}, function(reason){
  alert("error:" + reason);
});

#调试模式(调试web页面时需开启调试模式,否则页面内容不会改变) 
JCUpdate.debugWeb();

#加微信JCOutMan获取正式版插件
