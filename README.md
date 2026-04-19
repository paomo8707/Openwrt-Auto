## 使用帮助
[![Wiki](https://img.shields.io/badge/Wiki-使用帮助-blue?style=for-the-badge)](../../wiki)

 ##### 固件更新下载:

[![固件更新下载](https://img.shields.io/badge/dynamic/json?url=https%3A%2F%2Fapi.github.com%2Frepos%2Fdatout%2FOpenwrt-Auto%2Freleases%2Flatest&query=%24.name&style=for-the-badge&label=%E5%9B%BA%E4%BB%B6%E6%9B%B4%E6%96%B0%E4%B8%8B%E8%BD%BD)](https://github.com/datout/Openwrt-Auto/releases/latest)
[![Tag](https://img.shields.io/badge/dynamic/json?url=https%3A%2F%2Fapi.github.com%2Frepos%2Fdatout%2FOpenwrt-Auto%2Freleases%2Flatest&query=%24.tag_name&style=for-the-badge&label=TAG)](https://github.com/datout/Openwrt-Auto/releases/latest)


<details>
<summary>⬆️更新说明（2026年4月19号）</summary>

 ---
 <br>
  2026年4月29号
 <br><br>
 修复autoupdate

 ---
 <br>
  2026年2月24号
 <br><br>
 修复用Imm源码编译某些插件报错问题

 ---
 <br>
  2026年2月23号
 <br><br>
 编译下载时增加aria2c加快下载（优化云编译默认拉去国内源慢）
 
 ---
 <br>
  2026年1月24号
 <br><br>
加了FW4开关，更新了AdGuardhome，等 

 ---
 <br>
  2025年12月25号
 <br><br>
基于上游脚本二次维护（已移除对外部个人仓库的依赖）。
 
 
 ---
 <br>
  2023年6月16号
 <br><br>
 
 修复个别源码不能编译N1固件的问题
 
 有些源码的【armvirt】文件夹已经改成了【armsr】，机型文件也跟着改变的，查看源码文件夹在对应源码分支的[target/linux]里面查看，要么有【armvirt】，要么就是【armsr】
 
 以前的机型文件一般为：
 ````
CONFIG_TARGET_armvirt=y
CONFIG_TARGET_armvirt_64=y
CONFIG_TARGET_armvirt_64_Default=y
 ````
 
 现在的机型文件有些改为：
 ````
CONFIG_TARGET_armvirt=y
CONFIG_TARGET_armvirt_64=y
CONFIG_TARGET_armvirt_64_DEVICE_generic=y
 ````
 
 如果源码文件为【armsr】的，机型文件一般为：
 ````
CONFIG_TARGET_armsr=y
CONFIG_TARGET_armsr_armv8=y
CONFIG_TARGET_armsr_armv8_DEVICE_generic=y
 ````
</details> 
 
 ---



<details>
<summary>🔎教程</summary>
<br><br>

[![Wiki](https://img.shields.io/badge/Wiki-使用帮助-blue)](../../wiki)

<br/>
</details>




---

 ### 鸣谢！
 感谢以下各位大佬（排名无分先后）<br />
 
 [`coolsnowwolf`](https://github.com/coolsnowwolf/lede)
 [`Lienol`](https://github.com/Lienol/openwrt)
 [`immortalwrt`](https://github.com/immortalwrt/immortalwrt)
 [`openwrt`](https://github.com/openwrt/openwrt)
 [`x-wrt`](https://github.com/x-wrt/x-wrt)
 [`P3TERX`](https://github.com/P3TERX/Actions-OpenWrt)
 [`Hyy2001X`](https://github.com/Hyy2001X/AutoBuild-Actions-Template)
 [`dhxh`](https://github.com/dhxh/Openwrt-Build)
 [`ophub`](https://github.com/ophub/amlogic-s9xxx-openwrt)
 [`nicholas-opensource`](https://github.com/nicholas-opensource/OpenWrt-Autobuild)
 [`hx210`](https://github.com/hx210/Actions-OpenWrt)
 [`hyird`](https://github.com/hyird/EasyTier)
 [`World Peace`](#/README.md)
 [`klever1988`](https://github.com/klever1988/cachewrtbuild)
 [`actions`](https://github.com/actions/upload-artifact)
 [`svenstaro`](https://github.com/svenstaro/upload-release-action)
 [`jerrykuku`](https://github.com/jerrykuku/luci-theme-argon)
