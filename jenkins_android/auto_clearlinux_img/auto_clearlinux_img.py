#!/usr/bin/python3
import sys
import time
sys.path.append('/jenkins/workspace/Auto_download-Bender/')
from auto_img import ApiLocalImgTool, IMGAPITOOL


class ClearIMGAPITOOL(IMGAPITOOL):
    @staticmethod
    @IMGAPITOOL.get_lastest_file_zsq
    def check_img_version(job_info, local_lastestimg_no):
        '''
        检查当前本地保存的镜像是否与jenkins上的一致
        :param job_info: 从jenkins上获取的最新的build版本信息  元祖('350', 'https://www.jenkins/4.19/gordon_peak-350.zip')
        :param local_lastestimg_info: 本地保存镜像的目录
        :return: 如果一致就返回None,不一致就返回当前jenkins最新版本信息
        '''
        if local_lastestimg_no != -1:
            local_lastestimg_no = local_lastestimg_no.split('-')[-1].split('.')[0]
        return [None, job_info][job_info[0] != local_lastestimg_no]


class ApiConfig:
    # local_img_file_path的路径
    LOCAL_IMG_FILE_PATH = '/jenkins/workspace/clearlinux_image_info'  ########

    # 4.14 clearlinux jenkins url
    CLEAR_414_IMG_URL = 'https://oak-jenkins.ostc.intel.com/job/4.14-bkc-staging-clear-linux/lastSuccessfulBuild/api/json'

    # 4.19 clearlinux jenkins url
    CLEAR_419_IMG_URL = 'https://oak-jenkins.ostc.intel.com/job/4.19-build_clear_on_clear/lastSuccessfulBuild/api/json'

    # dev clearlinux jenkins url
    CLEAR_DEV_IMG_URL = 'https://oak-jenkins.ostc.intel.com/job/intel-next-dev_build-clear-on-clear/lastSuccessfulBuild/api/json'

    # mai clearlinux jenkins url
    CLEAR_MAI_IMG_URL = 'https://oak-jenkins.ostc.intel.com/job/mainline-tracking-build-clear-on-clear/lastSuccessfulBuild/api/json'

    # clearlinx镜像保存的路径
    CLR414 = '/jenkins/clear_4.14'
    CLR419 = '/jenkins/clear_4.19'
    CLRDEV = '/jenkins/clear_dev'
    CLRMAI = '/jenkins/clear_mainline'

    def __init__(self):
        self.clr_url_list = [
            self.CLEAR_419_IMG_URL,
            # self.CLEAR_414_IMG_URL,
            self.CLEAR_DEV_IMG_URL,
            self.CLEAR_MAI_IMG_URL
        ]
        self.clr_img_list = [
            self.CLR419,
            # self.CLR414,
            self.CLRDEV,
            self.CLRMAI
        ]


class ClearApiTool:
    @staticmethod
    def download_img(url, local_clear_img_path):
        '''
        使用ClearIMGAPITOOL类提供的接口,下载clearlinux镜像
        :param url: clearlinux的url
        :param local_clear_img_path: 本地镜像文件保存目录
        :return: 如果下载了新的镜像文件就返回本地镜像保存路径 '/jenkins/419_clr/clr-dsaaa.zip',如果没有下载新的镜像就返回None
        '''
        # 获取clearlinux最新的build号
        jobinfo = ClearIMGAPITOOL.handle_jenkins_param(IMGAPITOOL.request_get(url, isjson=True), url)
        # 如果返回的不是False代表有数据
        if jobinfo != False:
            # 检测当前本地的镜像和jenkins是否一致,返回None就是一致
            if ClearIMGAPITOOL.check_img_version(jobinfo, local_clear_img_path) != None:
                # 下载镜像到本地
                local_img_path = ClearIMGAPITOOL.download_img_with_progressBar(jobinfo[1], local_clear_img_path)
                return local_img_path, jobinfo
        return None, None


if __name__ == '__main__':
    api = ApiConfig()
    while True:
        for i in range(len(api.clr_img_list)):
            # 删除旧文件
            ApiLocalImgTool.delete_old_FileOrDir(api.clr_img_list[i])
            # 下载镜像文件
            download_img, jobinfo = ClearApiTool.download_img(api.clr_url_list[i], api.clr_img_list[i])
            if download_img != None:
                jobna = 'lts v4.19' if api.clr_img_list[i].split('_')[-1] == '4.19' \
                    else 'intel-next-dev' if api.clr_img_list[i].split('_')[-1] == 'dev' else 'mainline-tracking'
                ClearIMGAPITOOL.handle_jobinfo_to_file(jobinfo[0], jobna,
                    '/'.join(jobinfo[1].split('/')[:-4]), download_img, api.LOCAL_IMG_FILE_PATH, download_img_url=jobinfo[1])
                sys.exit(0)
            time.sleep(30)
