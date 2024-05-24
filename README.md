# script
各种脚本

执行命令：  
bash <(curl -sL https://raw.githubusercontent.com/cui2000/script/dev/**path**/**filename**.sh)  

推荐先下载，查看内容没问题再执行，有些定时任务也需要sh文件存在，比如blackList2Firewalld.sh  
wget -q https://raw.githubusercontent.com/cui2000/script/dev/**path**/**filename**.sh  
chmod +x **filename**.sh  
./**filename**.sh

### 命令
**应用安装入口**
```
bash <(curl -sL https://raw.githubusercontent.com/cui2000/script/dev/vps/install.sh)
```
**安装nginx**  
```
bash <(curl -sL https://raw.githubusercontent.com/cui2000/script/dev/vps/installNginx.sh)
```
**自动添加黑名单功能（需要安装并启动了firewalld服务）**  
```
wget -q https://raw.githubusercontent.com/cui2000/script/dev/vps/blackList2Firewalld.sh
chmod +x blackList2Firewalld.sh
./blackList2Firewalld.sh
```
**安装prometheus**  
```
bash <(curl -sL https://raw.githubusercontent.com/cui2000/script/dev/vps/prometheus/install.sh)
```
**安装node exporter**  
```
bash <(curl -sL https://raw.githubusercontent.com/cui2000/script/dev/vps/prometheus/installNodeExporter.sh)
```
**安装grafana**  
```
bash <(curl -sL https://raw.githubusercontent.com/cui2000/script/dev/vps/prometheus/installGrafana.sh)
```
**安装docker**  
```
bash <(curl -sL https://raw.githubusercontent.com/cui2000/script/dev/vps/installDocker.sh)
```
**设置tcp参数**  
```
bash <(curl -sL https://raw.githubusercontent.com/cui2000/script/dev/vps/setTcpConf.sh)
```
**升级内核**  
```
bash <(curl -sL https://raw.githubusercontent.com/cui2000/script/dev/vps/updateKernel.sh)
```
