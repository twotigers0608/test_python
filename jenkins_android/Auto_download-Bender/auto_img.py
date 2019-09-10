#!/usr/bin/python3
import os
import time
import requests
import zipfile
import shutil
import sys
import datetime

requests.packages.urllib3.disable_warnings()
from requests.packages.urllib3.exceptions import InsecureRequestWarning
requests.packages.urllib3.disable_warnings(InsecureRequestWarning)


class APIPATH:
    # 镜像文件保存路径
    GP419B = '/jenkins/4.19_baseline'
    GP419 = '/jenkins/4.19'
    GP419Q = '/jenkins/4.19_q'
    GP419QB = '/jenkins/4.19_q_baseline'
    GP414B = '/jenkins/4.14_baseline'
    GP414 = '/jenkins/4.14'
    GP49 = '/jenkins/4.9'
    GP49B = '/jenkins/4.9_baseline'
    GPDEV = '/jenkins/dev'
    GPDEVB = '/jenkins/dev_baseline'
    GPMIN = '/jenkins/mainline'
    GPMINB = '/jenkins/mainline_baseline'
    # 保存镜像具体信息文件路径
    info_file_path = '/jenkins/workspace/local_img_file_path'
    # 关于测试的文件路径(测试脚本位置,结果保存位置,邮件信息位置)
    auto_flash_scrip_path = '/jenkins/workspace/Auto_BAT-bender/gp_auto_flash.sh'
    auto_test_scrip_path = '/jenkins/workspace/Auto_BAT-bender/android_bat_case/androidbat.sh'
    test_result_path = '/jenkins/workspace/Auto_BAT-bender/android_bat_case/results'
    to = '/jenkins/workspace/Auto_BAT-bender/to.txt'
    subject = '/jenkins/workspace/Auto_BAT-bender/subject.txt'
    message = '/jenkins/workspace/Auto_BAT-bender/message.html'
    img_to = '/jenkins/workspace/Auto_download-Bender/to.txt'
    img_subject = '/jenkins/workspace/Auto_download-Bender/subject.txt'
    img_message = '/jenkins/workspace/Auto_download-Bender/message.txt'


class ApiUrl:
    # 北京jenkins的用户名
    bj_user = 'weizhe'
    # 北京jenkins的用户token
    bj_user_api_token = 'd0ed154ca6a2ea39bd89af578fa90f0a'
    # 获取crumb ['Jenkins-Crumb', '6f8ea2fe6e510aac30cc66e1ac6e801a']
    result = requests.get(
        'http://otcpkt.bj.intel.com:8080/crumbIssuer/api/xml?xpath=concat(//crumbRequestField,":",//crumb)',
        verify=False)
    csrf_token_list = result.text.split(':')
    # 触发的测试job的url
    TEST_JOB_URL = 'http://otcpkt.bj.intel.com:8080/job/Auto_BAT-bender/buildWithParameters'

    # 美国jenkins GET
    __US_BASE_JENKINS_URL = 'https://oak-jenkins.ostc.intel.com/'

    # 4.19-bkc-staging-gordon_peak GET
    __GP419_JENKINS_API_URL = __US_BASE_JENKINS_URL + 'job/4.19-bkc-staging-gordon_peak/lastSuccessfulBuild/api/json'

    # 4.19-bkc-staging-gordon_peak-baseline GET
    __GP419_BASELINE_API_URL = __US_BASE_JENKINS_URL + 'job/4.19-bkc-staging-gordon_peak-baseline/lastSuccessfulBuild/api/json'

    # 4.19-bkc-staging-gordon_peak_q GET
    __GP419_Q_API_URL = __US_BASE_JENKINS_URL + 'job/4.19-bkc-staging-gordon_peak_q/lastSuccessfulBuild/api/json'

    # 4.19-bkc-staging-gordon_peak_q-baseline GET
    __GP419_Q_BASELINE_API_URL = __US_BASE_JENKINS_URL + 'job/4.19-bkc-staging-gordon_peak_q-baseline/lastSuccessfulBuild/api/json'

    # 4.14-bkc-android-staging-gordon_peak GET
    __GP414_JENKINS_API_URL = __US_BASE_JENKINS_URL + 'job/4.14-bkc-android-staging-gordon_peak/lastSuccessfulBuild/api/json'

    # 4.14-bkc-android-staging-gordon_peak-baseline GET
    __GP414_BASELINE_API_URL = __US_BASE_JENKINS_URL + 'job/4.14-bkc-android-staging-gordon_peak-baseline/lastSuccessfulBuild/api/json'

    # 4.9-bkc-android-staging-gordon_peak_omr1 GET
    __GP49_ORM1_API_URL = __US_BASE_JENKINS_URL + 'job/4.9-bkc-android-staging-gordon_peak_omr1/lastSuccessfulBuild/api/json'

    # 4.9-bkc-android-staging-gordon_peak_omr1-baseline GET
    __GP49_ORM1_BASELINE_API_URL = __US_BASE_JENKINS_URL + 'job/4.9-bkc-android-staging-gordon_peak_omr1-baseline/lastSuccessfulBuild/api/json'

    # dev-bkc-android-embargoed-staging-gordon_peak GET
    __DEVBKC_API_URL = __US_BASE_JENKINS_URL + 'job/intel-next-dev_android-embargoed-staging-gordon_peak/lastSuccessfulBuild/api/json'

    # dev-bkc-android-embargoed-staging-gordon_peak-baseline GET
    __DEVBKC_BASELINE_API_URL = __US_BASE_JENKINS_URL + 'job/intel-next-dev_android-embargoed-staging-gordon_peak-baseline/lastSuccessfulBuild/api/json'

    # mainline-tracking-staging-gordon_peak GET
    __MAINLINE_API_URL = __US_BASE_JENKINS_URL + 'job/mainline-tracking-staging-gordon_peak/lastSuccessfulBuild/api/json'

    # mainline-tracking-staging-gordon_peak-baseline
    __MAINLINE_BASELINE_API_URL = __US_BASE_JENKINS_URL + 'job/mainline-tracking-staging-gordon_peak-baseline/lastSuccessfulBuild/api/json'

    # 北京jenkins测试android的api
    BJ_AUTO_BAT_BENDER_URL = 'http://otcpkt.bj.intel.com:8080/job/Auto_BAT-bender/lastBuild/api/json'

    def __init__(self):
        self.url_list = [
            self.__GP419_BASELINE_API_URL,
            self.__GP419_JENKINS_API_URL,
            self.__GP419_Q_API_URL,
            self.__GP419_Q_BASELINE_API_URL,
            self.__GP414_BASELINE_API_URL,
            self.__GP414_JENKINS_API_URL,
            self.__GP49_ORM1_API_URL,
            self.__GP49_ORM1_BASELINE_API_URL,
            self.__DEVBKC_API_URL,
            self.__DEVBKC_BASELINE_API_URL,
            self.__MAINLINE_API_URL,
            self.__MAINLINE_BASELINE_API_URL
        ]

    def __call__(self):
        for i in self.url_list:
            yield i

    def __len__(self):
        return len(self.url_list)

    def __getitem__(self, key):
        return self.url_list[key]


class ApiLocalImgTool:
    def __init__(self):
        self.img_path_lists = [
            APIPATH.GP419B,
            APIPATH.GP419,
            APIPATH.GP419Q,
            APIPATH.GP419QB,
            APIPATH.GP414B,
            APIPATH.GP414,
            APIPATH.GP49,
            APIPATH.GP49B,
            APIPATH.GPDEV,
            APIPATH.GPDEVB,
            APIPATH.GPMIN,
            APIPATH.GPMINB
        ]
        for d in self.img_path_lists:
            if not os.path.exists(d):
                os.mkdir(d)

    def __getitem__(self, key):
        return self.img_path_lists[key]

    def __get_old_fileOrDir_zsq(func):
        def inner(path):
            path_list = []
            if path.__class__ == list:
                for d in path:
                    file_lists = ['/'.join((d, f)) for f in os.listdir(d)]
                    file_lists.sort(key=lambda fn: os.path.getmtime(fn))
                    f_l = [[], file_lists[:-3]][len(file_lists) > 3]
                    path_list += f_l
            elif path.__class__ == str:
                file_lists = ['/'.join((path, f)) for f in os.listdir(path)]
                file_lists.sort(key=lambda fn: os.path.getmtime(fn))
                f_l = [[], file_lists[:-3]][len(file_lists) > 3]
                path_list += f_l
            return func(path_list)
        return inner

    @staticmethod
    @__get_old_fileOrDir_zsq
    def delete_old_FileOrDir(path):
        for f in path:
            print('Delete old file [%s]' % f, flush=True)
            os.remove(f) if os.path.isfile(f) else shutil.rmtree(f)


class IMGAPITOOL:
    __to_someone_list = [
        'zhex.wei@intel.com',
        'gaix.wang@intel.com',
        'minx1.wang@intel.com',
        # 'fan.c.zhang@intel.com'
        # 'pk.sdk.cw@intel.com'
    ]

    @staticmethod
    def handle_jobinfo_to_file(buildNo, jobNa, jenkinsUrl, zipImgFilePath, infoFilePath=APIPATH.info_file_path, download_img_url=None):
        '''
        将下载的image信息写进local_img_file_path里方便测试使用
        :param buildNo: build号
        :param jobNa: job名
        :param jenkinsUrl: jenkins的url
        :param zipImgFilePath: 下载的本地镜像的路径
        :param infoFilePath: local_img_file_path的路径
        :param download_img_url: 下载镜像的url地址,后期触发hongli的job时候需要
        '''
        default_content = '{zipfile},{buildno},{jobna},{jenkinsurl},{d_i_l}' if download_img_url \
            else '{zipfile},{buildno},{jobna},{jenkinsurl}'
        _ = default_content.format(zipfile=zipImgFilePath, buildno=buildNo, jobna=jobNa, jenkinsurl=jenkinsUrl, d_i_l=download_img_url) if \
            download_img_url else default_content.format(zipfile=zipImgFilePath, buildno=buildNo, jobna=jobNa, jenkinsurl=jenkinsUrl)
        with open(infoFilePath, 'w') as f:
            f.write(_)

    @staticmethod
    def build_test_job(buildNo, jobNa, jenkinsUrl, zipImgFilePath):
        params_dic = {
            'jobname': jobNa,
            'buildnumber': buildNo,
            'url': jenkinsUrl,
            'zipfilePath': zipImgFilePath
        }
        requests.post(ApiUrl.TEST_JOB_URL, headers={'cache-control': 'no-cache',
            'content-type': 'application/x-www-form-urlencoded',
            ApiUrl.csrf_token_list[0]: ApiUrl.csrf_token_list[1]},
            data=params_dic, auth=(ApiUrl.bj_user, ApiUrl.bj_user_api_token), verify=False)

    @staticmethod
    def time_sleep_with_print(sleep_time):
        for t in range(1, sleep_time + 1):
            print('\r[The program will sleep for %d seconds]: %3d' % (sleep_time, t), end='', flush=True)
            time.sleep(1)
        print('\n[Now the program will run again]...')

    @staticmethod
    def request_get(url, auth=False, verify=False, isjson=False):
        # 需要写进日志文件
        resp = requests.get(url, auth=auth, verify=verify) if auth else requests.get(url, verify=verify)
        if resp.status_code != 200:
            print('Error: request %s failed' % url, flush=True)
            return {'number': -1, 'artifacts': []}
        result = resp.json() if isjson else resp.text
        return result

    @staticmethod
    def handle_jenkins_param(json_param, url):
        '''
        处理jenkins的参数
        :param json_param: jenkins返回的json字符
        :param url: jenkins的url
        :return: 元祖(最后一次成功build的号, 对应的.zip文件的下载url)
        '''
        # print('Now check the [%s] info' % url, flush=True)
        # 生成build号码 378
        lastest_buildno = str(json_param['number'])
        for a in json_param['artifacts']:
            if '.zip' in a['fileName'] or '.bz2' in a['fileName']:
                # .zip或者.bz2在'fileName'就生成镜像url
                lastest_artifact_url = '/'.join((url[:-29], lastest_buildno, 'artifact', a['relativePath']))
        try:
            lastest_artifact_url
        except NameError:
            return False
        return (lastest_buildno, lastest_artifact_url)

    def get_lastest_file_zsq(func):
        def inner(job_info, local_img_path):
            # 生成当前目录下所有文件的列表
            file_lists = os.listdir(local_img_path)
            if len(file_lists) == 0:
                return func(job_info, -1)
            # 将列表排序按照时间
            # os.path.getmtime()生成文件的时间戳,lambda返回的值是每个文件的时间戳,按照这个排序最后一个就是最新的文件
            file_lists.sort(key=lambda fn: os.path.getmtime(local_img_path + "/" + fn))
            return func(job_info, '/'.join((local_img_path, file_lists[-1])))
        return inner

    @staticmethod
    @get_lastest_file_zsq
    def check_img_version(job_info, local_lastestimg_no):
        '''
        检查当前本地保存的镜像是否与jenkins上的一致
        :param job_info: 从jenkins上获取的最新的build版本信息
        :param local_lastestimg_info: 本地保存镜像的目录
        :return: 如果一致就返回None,不一致就返回当前jenkins最新版本信息
        '''
        if local_lastestimg_no != -1:
            local_lastestimg_no = local_lastestimg_no.split('/')[-1].split('.')[0].split('-')[-1]
        return [None, job_info][job_info[0] != local_lastestimg_no]

    def __check_zip_file_zsq(func):
        def inner(*args, **kwargs):
            while True:
                return_value = func(*args, **kwargs)
                if zipfile.is_zipfile(return_value[0]):
                    return return_value[0]
                elif os.path.getsize(return_value[0]) == return_value[1]:
                    return return_value[0]
                os.remove(return_value[0])
                print('下载镜像失败,尝试再次下载')
        return inner

    @classmethod
    @__check_zip_file_zsq
    def download_img(cls, download_url, file_save_path):
        '''
        下载镜像无进度条显示
        :param download_url: 下载镜像地址
        :param file_save_path: 文件保存地址
        :return: 镜像文件保存路径
        '''
        fileName = '/'.join((file_save_path, download_url.split('/')[-1]))
        file_content = cls.requests_get(download_url)
        total_size = int(file_content.headers['Content-Length'])
        with open(fileName, 'wb') as f:
            f.write(file_content.content)
        return (fileName, total_size)

    @staticmethod
    @__check_zip_file_zsq
    def download_img_with_progressBar(download_url, file_save_path):
        '''
        下载镜像有进度条显示
        :param download_url: 下载镜像地址  http://***/gordon_peak-flashfiles-16.zip
        :param file_save_path: 文件保存地址
        :return: 镜像文件保存路径
        '''
        fileName = '/'.join((file_save_path, download_url.split('/')[-1]))
        r = requests.get(download_url, stream=True, verify=False)
        # 得到文件总大小
        total_size = int(r.headers['Content-Length'])
        temp_size = 0
        print('[File Path]: %s' % fileName)
        print('[File Info]: %s' % download_url.split('/')[-1], flush=True)
        print('[File Size]: %dMB' % (total_size / 1024 / 1024), flush=True)

        with open(fileName, 'wb') as f:
            for chunk in r.iter_content(chunk_size=1024):
                if chunk:
                    temp_size += len(chunk)  # 当前已经下载的大小
                    f.write(chunk)
                    print('\r[Download Progress]: %s  %.2f%%' %
                        ('>' * int(temp_size * 50 / total_size), float(temp_size / total_size * 100)),
                        end='', flush=True)
            print('\nDone', flush=True)
        r.close()
        return (fileName, total_size)

    def __handle_mailSubject_zsq(func):
        def inner(cls, buildna, jenkins_url, subject=None, message=None):
            # 默认的邮件主题格式
            default_sub = '[QA][Staging][v{buildno}][Android][LTS][{tag}] / {N}/{date}'
            # 请求jenkins的api,生成邮件标题里面的日期
            resp = cls.request_get(jenkins_url + '/api/json', isjson=True)
            timestamp = resp['timestamp']
            # 将jenkins的时间戳格式化 2019-09-03 16:53:24
            d = time.strftime('%Y-%m-%d %H:%M:%S', time.localtime(timestamp / 1000))
            _ = d.split(' ')[0].split('-')
            # 将日期格式化成  (年 周 天)    (2019, 24, 4) 2019年第24周第4天
            n = datetime.date(int(_[0]), int(_[1]), int(_[2])).isocalendar()
            # 将jenkins行的tag信息过滤出来  tag = '121212T030813Z'
            for i in resp['actions']:
                if 'parameters' in i:
                    for j in i['parameters']:
                        if 'staging' in j['value']:
                            tag = j['value'].split('-')[-1]
            # 格式化邮件标题里的内容 2019w24.4-030813
            n = '%sw%s.%s-%s' % (n[0], n[1], n[2], tag[tag.index('T')+1: -1])
            subject = default_sub.format(buildno=buildna, tag=tag, N=n, date=d)
            return func(cls, buildna, jenkins_url, subject, message)
        return inner

    def __handle_mailResult_zsq(func):
        def inner(cls, buildna, jenkins_url, subject=None, message=None):
            default_message = 'Hi,all,\nDownload image success. we will start to test android bat.\nImage link: {im_ur}\nTest job link: {te_ur}'
            resp = cls.request_get(ApiUrl.BJ_AUTO_BAT_BENDER_URL, isjson=True)
            # test_url = '/'.join(jenkins_url.split('/')[:-3]) + '/' + str(resp['number'] + 1)
            test_url = 'http://otcpkt.bj.intel.com:8080/job/Auto_BAT-bender/' + str(resp['number'] + 1)
            message = default_message.format(im_ur=jenkins_url, te_ur=test_url)
            return func(cls, buildna, jenkins_url, subject, message)
        return inner

    @classmethod
    @__handle_mailSubject_zsq
    @__handle_mailResult_zsq
    def handle_result(cls, buildna, jenkins_url, subject=None, message=None):
        with open(APIPATH.img_message, 'w') as m, \
        open(APIPATH.img_to, 'w') as t, \
        open(APIPATH.img_subject, 'w') as s:
            t.write(', '.join(IMGAPITOOL.__to_someone_list))
            s.write(subject)
            m.write(message)


if __name__ == '__main__':
    apiurl = ApiUrl()
    apiimg = ApiLocalImgTool()
    # 删除旧镜像文件
    # apiimg.delete_old_FileOrDir(apiimg.img_path_lists)
    # 删除旧的测试结果文件
    # apiimg.delete_old_FileOrDir(APIPATH.test_result_path)
    while True:
        for n in range(len(apiurl)):
            # 处理jenkins参数
            jobinfo = IMGAPITOOL.handle_jenkins_param(IMGAPITOOL.request_get(apiurl[n], isjson=True), apiurl[n])
            if jobinfo == False:
                continue
            if IMGAPITOOL.check_img_version(jobinfo, apiimg[n]) != None:
                # 下载镜像...
                local_img_path = IMGAPITOOL.download_img_with_progressBar(jobinfo[1], apiimg[n])
                # 将镜像文件信息写进文件,测试使用
                # IMGAPITOOL.handle_jobinfo_to_file(jobinfo[0], local_img_path.split('/')[-2],
                #         '/'.join(apiurl[n].split('/')[:-3])+'/'+jobinfo[0], local_img_path)
                # trigger测试
                IMGAPITOOL.build_test_job(jobinfo[0], local_img_path.split('/')[-2],
                    '/'.join(apiurl[n].split('/')[:-3])+'/'+jobinfo[0], local_img_path)
                # 生成邮件
                # IMGAPITOOL.handle_result(local_img_path.split('/')[-2], '/'.join(apiurl[n].split('/')[:-3])+'/'+jobinfo[0])
                # sys.exit(0)
        time.sleep(300)
