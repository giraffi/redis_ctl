# Redis ctl sample

## Rake task

* rake rstart : Redisを3つ立てる
* rake rstop : Redisを3つ止める
* rake rping : RedisにPing  
* rake rmas : Redisの誰かをMasterにする  
* rake rroll : みんなの今のRollをGet
* rake rmasall : みんなMasterにもどす

## app.rb
1秒おきに現在の状況をチェックしてローカルのredisにストア。

使うにはbrew標準のredis-server を起動しておく。