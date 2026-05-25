#!/bin/bash
# https://github.com/Hyy2001X/AutoBuild-Actions
# AutoBuild Module by Hyy2001
# AutoBuild Functions
AUTOUPDATE_VERSION=8.0

function Patch_Autoupdate_NoProxy() {
	local script="${HOME_PATH}/package/autoupdate/files/bin/autoupdate"

	if [[ ! -f "${script}" ]]; then
		echo "未找到 autoupdate 主程序,跳过去代理补丁: ${script}"
		return 0
	fi

	cp -f "${script}" "${script}.bak-noproxy"

	# 1. API 解析: 只访问 GitHub 官方地址,不再拼接 ghgo/ghps/ghproxy 等镜像
	sed -i 's|--url "${Github_API}@@1 $(Proxy_X ${Github_Release}/API G@@1 F@@1 E@@1)"|--url "${Github_API}@@1 ${Github_Release}/API@@1"|g' "${script}"

	# 2. 更新日志: 只访问 GitHub 官方地址
	sed -i 's|--url "$(Proxy_X ${Github_Release} G@@1 F@@1 E@@1)"|--url "${Github_Release}"|g' "${script}"

	# 3. 固件下载: 只使用 API 返回的 GitHub 官方 browser_download_url
	sed -i \
		-e 's|URL="$(Proxy_X ${CLOUD_FW_Url} ${Proxy_Type}@@5)"|URL="${CLOUD_FW_Url}"|g' \
		-e 's|URL="$(Proxy_X ${CLOUD_FW_Url} G@@2 X@@1 E@@1 F@@1)"|URL="${CLOUD_FW_Url}"|g' \
		-e 's|URL="$(Proxy_X ${CLOUD_FW_Url} X@@2 G@@1 E@@1 F@@1)"|URL="${CLOUD_FW_Url}"|g' \
		"${script}"

	# 4. 即使 Google 连通性检测失败,也不自动切换到镜像代理
	sed -i \
		-e 's|ECHO r "Google 连接错误,优先使用镜像加速下载!"|ECHO y "Google 连接失败,但已禁用镜像代理,继续直连 GitHub ..."|g' \
		-e 's|Proxy_Type="All"|Proxy_Type="Direct"|g' \
		"${script}"

	# 5. -P/--proxy 参数保留兼容,但不再启用任何镜像代理
	sed -i \
		-e 's|Special_Commands="${Special_Commands} \[镜像加速 Automatic\]"|Special_Commands="${Special_Commands} [已禁用镜像代理]"|g' \
		-e 's|Special_Commands="${Special_Commands} \[ghproxy.cn\]"|Special_Commands="${Special_Commands} [已禁用镜像代理]"|g' \
		-e 's|Special_Commands="${Special_Commands} \[ghps.cc\]"|Special_Commands="${Special_Commands} [已禁用镜像代理]"|g' \
		-e 's|Special_Commands="${Special_Commands} \[ghgo.xyz\]"|Special_Commands="${Special_Commands} [已禁用镜像代理]"|g' \
		"${script}"

	chmod +x "${script}"
	echo "已禁用 autoupdate GitHub 镜像代理,仅使用直连 GitHub"
}

function Diy_Part1() {
	find . -type d -name 'luci-app-autoupdate' | xargs -i rm -rf {}
	tmpdir="$(mktemp -d)"
	if git clone -q --depth=1 https://github.com/Hyy2001X/AutoBuild-Packages "$tmpdir"; then
		rm -rf "$HOME_PATH/package/autoupdate" "$HOME_PATH/package/luci-app-autoupdate"
		[ -d "$tmpdir/autoupdate" ] && cp -r "$tmpdir/autoupdate" "$HOME_PATH/package/autoupdate"
		cp -r "$tmpdir/luci-app-autoupdate" "$HOME_PATH/package/luci-app-autoupdate"
		rm -rf "$tmpdir"
		Patch_Autoupdate_NoProxy
		if ! grep -q "luci-app-autoupdate" "${HOME_PATH}/include/target.mk"; then
			sed -i 's?DEFAULT_PACKAGES:=?DEFAULT_PACKAGES:=luci-app-autoupdate autoupdate luci-app-ttyd ?g' ${HOME_PATH}/include/target.mk
		fi
		echo "增加定时更新固件的插件下载完成"
	else
		rm -rf "$tmpdir"
		echo "增加定时更新固件的插件下载失败"
	fi
}


function Diy_Part2() {
	export UPDATE_TAG="Update-${TARGET_BOARD}"
	export FILESETC_UPDATE="${HOME_PATH}/package/base-files/files/etc/openwrt_update"
	export GITHUB_PROXY=""
	export RELEASE_DOWNLOAD="\$GITHUB_LINK/releases/download/${UPDATE_TAG}"
	export GITHUB_RELEASE="${GITHUB_LINK}/releases/tag/${UPDATE_TAG}"
        if [[ ! -f "$LINSHI_COMMON/autoupdate/replace" ]]; then
		echo -e "\n\033[0;31m缺少autoupdate/replace文件\033[0m"
   		exit 1
  	fi
	if [[ "${TARGET_PROFILE}" == *"k3"* ]]; then
		export TARGET_PROFILE_ER="phicomm-k3"
	elif [[ "${TARGET_PROFILE}" == *"k2p"* ]]; then
		export TARGET_PROFILE_ER="phicomm-k2p"
	elif [[ "$TARGET_PROFILE" == *xiaomi* && "$TARGET_PROFILE" == *3g* && "$TARGET_PROFILE" == *v2* ]]; then
		export TARGET_PROFILE_ER="xiaomi_mir3g-v2"
	elif [[ "$TARGET_PROFILE" == *xiaomi* && "$TARGET_PROFILE" == *3g* ]]; then
		export TARGET_PROFILE_ER="xiaomi_mir3g"
 	elif [[ "$TARGET_PROFILE" == *xiaomi* && "$TARGET_PROFILE" == *3* && "$TARGET_PROFILE" == *pro* ]]; then
		export TARGET_PROFILE_ER="xiaomi_mi3pro"
	else
		export TARGET_PROFILE_ER="${TARGET_PROFILE}"
	fi
	
	case "${TARGET_BOARD}" in
	ramips | reltek | ath* | ipq* | bmips | kirkwood | mediatek |bcm4908 |gemini |lantiq |layerscape |qualcommax |qualcommbe |siflower |silicon)
		export FIRMWARE_SUFFIX=".bin"
		export AUTOBUILD_FIRMWARE="${LUCI_EDITION}-${SOURCE}-${TARGET_PROFILE_ER}-${UPGRADE_DATE}"
	;;
 	bcm47xx)
          	if echo "$TARGET_PROFILE" | grep -Eq 'asus'; then
			export FIRMWARE_SUFFIX=".trx"
             	elif echo "$TARGET_PROFILE" | grep -Eq 'netgear'; then
			export FIRMWARE_SUFFIX=".chk"
		else
			export FIRMWARE_SUFFIX=".bin"
		fi
		export AUTOBUILD_FIRMWARE="${LUCI_EDITION}-${SOURCE}-${TARGET_PROFILE_ER}-${UPGRADE_DATE}"
	;;
	x86)
		export FIRMWARE_SUFFIX=".img.gz"
		export AUTOBUILD_FIRMWARE_UEFI="${LUCI_EDITION}-${SOURCE}-${TARGET_PROFILE_ER}-${UPGRADE_DATE}"
		export AUTOBUILD_FIRMWARE="${LUCI_EDITION}-${SOURCE}-${TARGET_PROFILE_ER}-${UPGRADE_DATE}"
	;;
	rockchip | bcm27xx | mxs | sunxi | zynq |loongarch64 |omap |sifiveu |tegra |amlogic)
		export FIRMWARE_SUFFIX=".img.gz"
		export AUTOBUILD_FIRMWARE="${LUCI_EDITION}-${SOURCE}-${TARGET_PROFILE_ER}-${UPGRADE_DATE}"
	;;
	mvebu)
		export FIRMWARE_SUFFIX=".img.gz"
		export AUTOBUILD_FIRMWARE="${LUCI_EDITION}-${SOURCE}-${TARGET_PROFILE_ER}-${UPGRADE_DATE}"
	;;
	bcm53xx)
 		if echo "$TARGET_PROFILE" | grep -Eq 'mr32|tplink|dlink'; then
			export FIRMWARE_SUFFIX=".bin"
     		elif echo "$TARGET_PROFILE" | grep -Eq 'luxul'; then
			export FIRMWARE_SUFFIX=".lxl"
        	elif echo "$TARGET_PROFILE" | grep -Eq 'netgear'; then
			export FIRMWARE_SUFFIX=".chk"
		else
			export FIRMWARE_SUFFIX=".trx"
		fi
		export AUTOBUILD_FIRMWARE="${LUCI_EDITION}-${SOURCE}-${TARGET_PROFILE_ER}-${UPGRADE_DATE}"
	;;
	octeon | oxnas | pistachio)
		export FIRMWARE_SUFFIX=".tar"
		export AUTOBUILD_FIRMWARE="${LUCI_EDITION}-${SOURCE}-${TARGET_PROFILE_ER}-${UPGRADE_DATE}"
	;;
	*)
		export FIRMWARE_SUFFIX=".bin"
		export AUTOBUILD_FIRMWARE="${LUCI_EDITION}-${SOURCE}-${TARGET_PROFILE_ER}-${UPGRADE_DATE}"
	;;
	esac
	
	export FIRMWARE_VERSION="${SOURCE}-${TARGET_PROFILE_ER}-${UPGRADE_DATE}"

	if [[ "${TARGET_BOARD}" == "x86" ]]; then
   		BOOT_TYPE="legacy"
 		echo "AUTOBUILD_FIRMWARE_UEFI=${AUTOBUILD_FIRMWARE_UEFI}-uefi" >> ${GITHUB_ENV}
		echo "AUTOBUILD_FIRMWARE=${AUTOBUILD_FIRMWARE}-${BOOT_TYPE}" >> ${GITHUB_ENV}
	elif [[ "${FIRMWARE_SUFFIX}" == ".img.gz" ]]; then
   		BOOT_TYPE="legacy"
		echo "AUTOBUILD_FIRMWARE=${AUTOBUILD_FIRMWARE}-${BOOT_TYPE}" >> ${GITHUB_ENV}
	else
 		BOOT_TYPE="sysupgrade"
		echo "AUTOBUILD_FIRMWARE=${AUTOBUILD_FIRMWARE}-${BOOT_TYPE}" >> ${GITHUB_ENV}
	fi

 	echo "UPDATE_TAG=${UPDATE_TAG}" >> ${GITHUB_ENV}
	echo "FIRMWARE_SUFFIX=${FIRMWARE_SUFFIX}" >> ${GITHUB_ENV}
	echo "AUTOUPDATE_VERSION=${AUTOUPDATE_VERSION}" >> ${GITHUB_ENV}
	echo "FIRMWARE_VERSION=${FIRMWARE_VERSION}" >> ${GITHUB_ENV}
	echo "GITHUB_RELEASE=${GITHUB_RELEASE}" >> ${GITHUB_ENV}


	# 写入openwrt_update文件
	install -m 0755 /dev/null "${FILESETC_UPDATE}"
	echo "GITHUB_LINK=\"${GITHUB_LINK}\"" >> ${FILESETC_UPDATE}
 	echo "FIRMWARE_VERSION=\"${FIRMWARE_VERSION}\"" >> ${FILESETC_UPDATE}
 	echo "LUCI_EDITION=\"${LUCI_EDITION}\"" >> ${FILESETC_UPDATE}
 	echo "SOURCE=\"${SOURCE}\"" >> ${FILESETC_UPDATE}
   	echo "DEVICE_MODEL=\"${TARGET_PROFILE_ER}\"" >> ${FILESETC_UPDATE}
 	echo "FIRMWARE_SUFFIX=\"${FIRMWARE_SUFFIX}\"" >> ${FILESETC_UPDATE}
 	echo "TARGET_BOARD=\"${TARGET_BOARD}\"" >> ${FILESETC_UPDATE}
 	echo "GITHUB_PROXY=\"${GITHUB_PROXY}\"" >> ${FILESETC_UPDATE}
 	echo "RELEASE_DOWNLOAD=\"${RELEASE_DOWNLOAD}\"" >> ${FILESETC_UPDATE}
	cat "$LINSHI_COMMON/autoupdate/replace" >> ${FILESETC_UPDATE}

 	# 写入del_assets文件
	install -m 0755 /dev/null "${GITHUB_WORKSPACE}/del_assets"
  	echo "UPDATE_TAG=\"${UPDATE_TAG}\"" >> "${GITHUB_WORKSPACE}/del_assets"
  	echo "BOOT_TYPE=\"${BOOT_TYPE}\"" >> "${GITHUB_WORKSPACE}/del_assets"
	echo "FIRMWARE_SUFFIX=\"${FIRMWARE_SUFFIX}\"" >> "${GITHUB_WORKSPACE}/del_assets"
 	echo "FIRMWARE_PROFILEER=\"${LUCI_EDITION}-${SOURCE}-${TARGET_PROFILE_ER}\"" >> "${GITHUB_WORKSPACE}/del_assets"
}

function Diy_Part3() {
	BIN_PATH="${HOME_PATH}/bin/Firmware"
	echo "BIN_PATH=${BIN_PATH}" >> ${GITHUB_ENV}
	[[ ! -d "${BIN_PATH}" ]] && mkdir -p "${BIN_PATH}" || rm -rf "${BIN_PATH}"/*
	
	cd "${FIRMWARE_PATH}"
 	if [[ -n "$(ls -1 | grep -Eo '.img')" ]] && [[ -z "$(ls -1 | grep -Eo '.img.gz')" ]]; then
		gzip -f9n *.img
	fi
	
	case "${TARGET_BOARD}" in
	x86)
		if [[ -n "$(ls -1 | grep -E 'efi')" ]]; then
			EFI_ZHONGZHUAN="$(ls -1 |grep -Eo ".*squashfs.*efi.*img.gz" |grep -v ".vm\|.vb\|.vh\|.qco\|ext4\|root\|factory\|kernel")"
			if [[ -f "${EFI_ZHONGZHUAN}" ]]; then
		  		EFIMD5="$(md5sum ${EFI_ZHONGZHUAN} |cut -c1-3)$(sha256sum ${EFI_ZHONGZHUAN} |cut -c1-3)"
		  		cp -Rf "${EFI_ZHONGZHUAN}" "${BIN_PATH}/${AUTOBUILD_FIRMWARE_UEFI}-${EFIMD5}${FIRMWARE_SUFFIX}"
      				echo "BOOT_UEFI=\"uefi\"" >> "${GITHUB_WORKSPACE}/del_assets"
			else
				echo "没找到在线升级可用的efi${FIRMWARE_SUFFIX}格式固件"
			fi
		fi
  		
  		if [[ -n "$(ls -1 | grep -E 'squashfs')" ]]; then
			UP_ZHONGZHUAN="$(ls -1 |grep -Eo ".*squashfs.*img.gz" |grep -v ".vm\|.vb\|.vh\|.qco\|efi\|ext4\|root\|factory\|kernel")"
			if [[ -f "${UP_ZHONGZHUAN}" ]]; then
   				MD5="$(md5sum ${UP_ZHONGZHUAN} | cut -c1-3)$(sha256sum ${UP_ZHONGZHUAN} | cut -c1-3)"
				cp -Rf "${UP_ZHONGZHUAN}" "${BIN_PATH}/${AUTOBUILD_FIRMWARE}-${MD5}${FIRMWARE_SUFFIX}"
			else
				echo "没找到在线升级可用的${FIRMWARE_SUFFIX}格式固件"
			fi
		else
			echo "没有squashfs格式固件"
		fi
	;;
	*)
  		if [[ -n "$(ls -1 | grep -E 'sysupgrade')" ]]; then
			UP_ZHONGZHUAN="$(ls -1 |grep -Eo ".*${TARGET_PROFILE}.*sysupgrade.*${FIRMWARE_SUFFIX}" |grep -v ".vm\|.vb\|.vh\|.qco\|efi\|ext4\|root\|factory\|kernel")"
		elif [[ -n "$(ls -1 | grep -E 'squashfs')" ]]; then
			UP_ZHONGZHUAN="$(ls -1 |grep -Eo ".*${TARGET_PROFILE}.*squashfs.*${FIRMWARE_SUFFIX}" |grep -v ".vm\|.vb\|.vh\|.qco\|efi\|ext4\|root\|factory\|kernel")"
   		elif [[ -n "$(ls -1 | grep -E 'combined')" ]]; then
			UP_ZHONGZHUAN="$(ls -1 |grep -Eo ".*${TARGET_PROFILE}.*combined.*${FIRMWARE_SUFFIX}" |grep -v ".vm\|.vb\|.vh\|.qco\|efi\|ext4\|root\|factory\|kernel")"
      		elif [[ -n "$(ls -1 | grep -E 'sdcard')" ]]; then
			UP_ZHONGZHUAN="$(ls -1 |grep -Eo ".*${TARGET_PROFILE}.*sdcard.*${FIRMWARE_SUFFIX}" |grep -v ".vm\|.vb\|.vh\|.qco\|efi\|ext4\|root\|factory\|kernel")"
   		else
     			echo "没找到在线升级可用的${FIRMWARE_SUFFIX}格式固件，或者没适配该机型"
		fi
		if [[ -f "${UP_ZHONGZHUAN}" ]]; then
   			MD5="$(md5sum ${UP_ZHONGZHUAN} | cut -c1-3)$(sha256sum ${UP_ZHONGZHUAN} | cut -c1-3)"
			cp -Rf "${UP_ZHONGZHUAN}" "${BIN_PATH}/${AUTOBUILD_FIRMWARE}-${MD5}${FIRMWARE_SUFFIX}"
		fi
	;;
	esac
 	echo -e "\n\033[0;32m远程更新固件\033[0m"
 	ls -1 $BIN_PATH
	cd ${HOME_PATH}
}
