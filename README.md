# NEU_ipgw_autologin

东北大学校园网 IPGW 自动登录工具 🚀

## 功能简介
一键实现东北大学校园网自动登录，无需手动输入账号密码，提升上网体验。

## 安装教程
### Windows 系统
1. 下载对应版本的压缩包
2. 解压到任意目录（建议无中文、无空格路径）
3. 双击运行 `install.bat` 脚本，等待安装完成

### Linux 系统
1. 下载对应版本的压缩包
2. 解压到任意目录
3. 运行 `install.sh` 脚本[^1]

   [^1]:如果提示$'\r': command not found等换行符错误，可使用下面的命令安装工具进行换行符转换
       ```
       sudo apt update && sudo apt install dos2unix -y
       dos2unix install.sh
       ```

## 手动安装流程（如果install脚本运行失败）
1. 将py文件放在一个文件夹下
2. 在当前文件夹打开终端（win用户可以在资源管理器地址栏直接输入`cmd`即可打开终端）
3. 依次输入以下指令
   ```
   python -m venv .venv   #创建虚拟环境
   python -m pip install --upgrade pip   #更新pip
   pip install pyinstaller playwright   #安装库文件
   playwright install chromium   #安装谷歌内核
   ```
4. win用户在终端输入`playwright install --dry-run`  
   从输出结果中找到chrome的install location  
   默认值应该为`C:\Users\用户名\AppData\Local\ms-playwright\chromium-1208`  
   打开该路径，再打开`chrome-win64`，复制该目录的所有文件  
   在ipgw.py所在的根目录下新建文件夹`chromium`，将刚才复制的所有文件粘贴到`chromium`中  
   ubuntu用户操作类似，默认路径应为`/home/用户名/.cache/ms-playwright/chromium-1208`  
5. 在终端输入命令  
   `pyinstaller --name "ipgw" --onedir --add-data ".\chromium" "ipgw.py"`  
6. 将`dist`中的文件全部复制到根目录下  
   此时可以删除`ipgw.spec`,`build`,`chromium`,`.venv`  
7. 设置开机自启动  
   win用户：创建`ipgw.exe`的快捷方式，将快捷方式移动至启动文件夹  
   启动文件夹打开方式：win+r运行输入`shell:startup`  
   ubuntu用户：在`~/.config/autostart/下创建文件`ipgw.desktop`  
   在文件中写入以下内容  
      ```
      [Desktop Entry]  
      Type=Application  
      Name=IPGW自动登录  
      Comment=开机弹出终端运行校园网登录  
      Exec=gnome-terminal -- bash -c "cd /home/kxn/ipgw && ./start.sh"  
      Path=/home/kxn/ipgw/ipgw_app  
      Terminal=false  
      StartupNotify=false  
      ``` 
   在ipgw中创建`start.sh`脚本，脚本写入以下代码  
      ```
      #!/bin/bash  
      cd "/home/kxn/ipgw/ipgw_app"  
      ./ipgw  
      ```   
   在终端输入`chmod +x ./start.sh`  

## 作者
### 主要作者： 豆包
### 名誉作者： 我
