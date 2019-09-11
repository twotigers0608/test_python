#!/usr/bin/python3
import os
import sys
import time
import datetime
import zipfile
import shutil
sys.path.append('/jenkins/workspace/Auto_download-Bender/')
from .auto_img import IMGAPITOOL, APIPATH, ApiLocalImgTool
from .html_tool import APIHTML as h


class CustomError(Exception):
    def __init__(self, ErrorInfo):
        super().__init__(self)
        self.errorinfo = ErrorInfo

    def __str__(self):
        return self.errorinfo

class ApiUnzip:
    def check_file_exists_zsq(func):
        def inner(*args):
            for f in args:
                if not os.path.exists(f):
                    # return False
                    raise CustomError('Not found %s' % f)
            return func(*args)
        return inner

    @staticmethod
    @check_file_exists_zsq
    def unzip_file(zip_src, dst_dir):
        if zipfile.is_zipfile(zip_src):
            fz = zipfile.ZipFile(zip_src, 'r')
            for file in fz.namelist():
                fz.extract(file, dst_dir)

    @staticmethod
    @check_file_exists_zsq
    def delete_dir(unzipfile_path):
        shutil.rmtree(unzipfile_path)

    @staticmethod
    @check_file_exists_zsq
    def mkdir_unzipdir(unzipfile_path):
        fileNameList = unzipfile_path.split('/')
        fileNameList[-2] = '_'.join((fileNameList[-2], fileNameList[-1].split('.')[0].split('-')[-1]))
        unzip_path = '/'.join(fileNameList[:-1])
        os.mkdir(unzip_path)
        return unzip_path


class TESTAPITOOL:
    __to_someone_list = [
        'zhex.wei@intel.com',
        'gaix.wang@intel.com',
        'minx1.wang@intel.com',
        'fan.c.zhang@intel.com',
        'pk.sdk.cw@intel.com'
    ]

    def __unzip_file_zsq(func):
        def inner(file_path):
            unzipfile = ApiUnzip.mkdir_unzipdir(file_path)
            ApiUnzip.unzip_file(file_path, unzipfile)
            # shutil.copyfile(APIPATH.auto_flash_scrip_path, unzipfile)
            return_value = func(unzipfile)
            ApiUnzip.delete_dir(unzipfile)
            return return_value
        return inner

    @staticmethod
    @ApiUnzip.check_file_exists_zsq
    @__unzip_file_zsq
    def flash_gp(flash_zipFile_path):
        return_result_no = os.system('echo "intel@123"|sudo -S bash %s -t %s' %
                            (APIPATH.auto_flash_scrip_path, flash_zipFile_path))
        if return_result_no != 0:
            # return False  # print('刷机失败')
            raise CustomError('Flash failed')
        IMGAPITOOL.time_sleep_with_print(100)

    def __retry_test_gp_zsq(retry_no):
        def __retry_zsq(func):
            def inner(jobna, buildno, devices_id=None):
                _ = os.popen("adb devices|grep R|awk '{print $1}'").read()
                devices_id = _ if len(_) == 0 else _[:-1]
                for t in range(1, retry_no + 1):
                    if devices_id == '':
                        os.system('echo "r" > /dev/ttyUSB2')
                        time.sleep(2)
                        os.system('echo "n1#" > /dev/ttyUSB2')
                        IMGAPITOOL.time_sleep_with_print(100)
                        _ = os.popen("adb devices|grep R|awk '{print $1}'").read()
                        devices_id = _ if len(_) == 0 else _[:-1]
                    if devices_id != '':
                        return func(jobna, buildno, devices_id)
                    elif t == retry_no:
                        # return False
                        raise CustomError('Boot failed')
            return inner
        return __retry_zsq

    @staticmethod
    @__retry_test_gp_zsq(3)
    def test_gp(jobna, buildno, devices_id=None):
        if devices_id == None:
            _ = os.popen("adb devices|grep R|awk '{print $1}'").read()
            devices_id = _ if len(_) == 0 else _[:-1]

        os.system('echo "intel@123"|sudo -S bash {auto_script} -j {job_name} -d {devicesid} -b {build_no}'.format(
            auto_script=APIPATH.auto_test_scrip_path, devicesid=devices_id, job_name=jobna, build_no=buildno))
        return devices_id

    @staticmethod
    @IMGAPITOOL.get_lastest_file_zsq
    def check_test_result(job_info, test_result_path):
        '''
        测试完成后检查是否有测试结果文件夹
        :param job_info: 格式"<jobNumber>_<jobName>", 示例"165_4.19_baseline" "733_dev"
        :param test_result_path: 测试结果文件夹路径
        :return: 有符合条件的结果文件就返回测试结果"results.csv"文件路径,没有就返回False
        '''
        if test_result_path == -1:
            # return False
            raise CustomError('Not found the test result file')
        result_file = '/'.join((test_result_path, 'results.csv'))
        # return [False, result_file][job_info in test_result_path.split('/')[-1] and os.path.exists(result_file)]
        if job_info in test_result_path.split('/')[-1] and os.path.exists(result_file):
            return result_file
        raise CustomError('Not found the test result file')

    def __handle_mailSubject_zsq(func):
        def inner(cls, jobNa, buildNo, testResu, jenkins_url, result_file_path=None, failed_reason=None, subject=None):
            # 默认的邮件主题格式
            default_sub = '[QA][Staging][v{buildno}][Android][LTS][{tag}] / {N}/{date}'
            # 请求jenkins的api,生成邮件标题里面的日期
            resp = IMGAPITOOL.request_get(jenkins_url + '/api/json', isjson=True)
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
            if testResu:
                # 执行adb命令将内核信息版本过滤
                # Linux version 4.9.178-PKT-699e09f7-08086-gab8b76df024e (jenkins@oak-04) (gcc version 7.3.0 (GCC) ) #1 SMP PREEMPT Fri May 24 19:26:01 PDT 2019
                k_v = os.popen('adb shell cat /proc/version').read()
                # buildno = '4.9.178'
                try:
                    buildno = k_v.split(' ')[2].split('-')[0]
                except IndexError:
                    print('Get image verson ERROR')
                    buildno = jobNa
            else:
                buildno = jobNa
            subject = (default_sub.format(buildno=buildno, tag=tag, N=n, date=d), buildno)
            return func(cls, jobNa, buildNo, testResu, jenkins_url, result_file_path, failed_reason, subject)
        return inner

    def __handle_testResult_zsq(func):
        def inner(cls, jobNa, buildNo, testResu, jenkins_url, result_file_path=None, failed_reason=None, subject=None):
            if testResu == False:
                result = 'Automatic test failed, please change to manual......</br>Failed reason: %s' % failed_reason
                return func(cls, jobNa, buildNo, testResu, jenkins_url, result, failed_reason, subject)
            # 邮件里最上面的那句话 Hi All, Please find staging...........
            mail_1 = h.p(h.span('Hi,all,', h.def_sty)) + h.p(h.span('Please find staging %s report.' % subject[1]), h.def_sty)

            # 邮件里面标题
            mail_title_list = ['#Executive Summary:', '#Banned Words:',
                               '#Coverity Scan:', '#CVE Scan:', '#Spectre & Meltdown:',
                               '#Known Issue:', '#Testing Information:', '#Test Suite:',
                               '#Test Log Archived:', '#Test reports Archived:']

            # 邮件里面表格的标题行的内容和样式
            table_title_list = [('Num', h.tab_1), ('Type', h.tab_2), ('Tests suite name', h.tab_3),
                                ('Android P on GP D0', h.tab_4), ('Remark', h.tab_5)]

            # 生成表格标题行,是一个列表包含每一个td列,需要join在一起
            table_1 = [h.td(h.p(table_title_list[i][0], custom_lables=['b']), table_title_list[i][1])
                       for i in range(len(table_title_list))]
            # 生成列表第一行完整tr
            table_1 = h.tr(''.join(table_1))

            # 生成其余表格内容
            with open(result_file_path, 'r') as f:
                table_2 = []
                for i in f.readlines():
                    line = i.split(',')
                    td1 = h.td(h.p(int(line[0])+1), h.no_tab_1)
                    td2 = h.td(h.p(line[1]), h.no_tab_2)
                    td3 = h.td(h.p(line[2]), h.no_tab_3)
                    td4 = h.td(h.p(line[3]), h.no_tab_4)
                    td5 = h.td('', h.no_tab_5)
                    tr = h.tr(''.join((td1, td2, td3, td4, td5)))
                    table_2.append(tr)
            table_2.insert(0, table_1)
            table_2 = h.table(''.join(table_2), h.tab_sty)

            # 邮件里面标题下的文本
            mail_content_list = [
                '</br>Android BAT is ' + h.span('"go".', "style='background:lime'"),
                '</br>None.',
                '</br>None.',
                '</br>None.',
                '</br>None.',
                '</br>None.',
                '</br>HW device: GP D0 8G (Model:J17532-502)</br>Tested target: Android native</br>Tested staging build link:</br>ANDROID: %s'
                % h.custom(jenkins_url, [('a', 'href="%s"' % jenkins_url)]),
                table_2,
                '</br>None.',
                '</br>None.</br></br>Best Regards</br>PKT QA Team'
            ]

            # 生成邮件内容,是一个列表包含每一个p标签,最后需要join在一起形成一个完整的内容
            mail_2 = [h.p(h.span(h.custom(mail_title_list[i], ['u', 'b']) + mail_content_list[i], h.def_sty))
                      for i in range(len(mail_title_list))]

            # 将邮件内容添加进内容列表
            mail_2.insert(0, mail_1)
            result = ''.join(mail_2)
            return func(cls, jobNa, buildNo, testResu, jenkins_url, result, failed_reason, subject)
        return inner

    @classmethod
    @__handle_mailSubject_zsq
    @__handle_testResult_zsq
    def handle_mailFile_format(cls, jobNa, buildNo, testResu, jenkins_url, result=None, failed_reason=None, subject=None):
        # result_status = ['failed', 'success'][testResu]
        with open(APIPATH.message, 'w') as m, \
            open(APIPATH.to, 'w') as t, \
            open(APIPATH.subject, 'w') as s:
            s.write(subject[0])
            if testResu:
                t.write(', '.join(cls.__to_someone_list[-1:]))
            else:
                t.write(', '.join(cls.__to_someone_list[:3]))
            m.write(result)


if __name__ == '__main__':
    jobname = os.getenv('jobname')
    buildnumber = os.getenv('buildnumber')
    jenkinsurl = os.getenv('url')
    zip_file = os.getenv('zipfilePath')
    # 删除旧镜像文件
    apiimg = ApiLocalImgTool()
    apiimg.delete_old_FileOrDir(apiimg.img_path_lists)

    try:
        # 刷机
        flash_result = TESTAPITOOL.flash_gp(zip_file)
        # 执行测试
        testResult = TESTAPITOOL.test_gp(jobname, buildnumber)
        # 检查测试结果是否存在
        # android_version = os.popen("adb -s %s shell getprop ro.build.version.incremental | tr -d '\r'" % testResult).read()[:-1]
        result = TESTAPITOOL.check_test_result('_'.join((buildnumber, jobname)), APIPATH.test_result_path)
    except CustomError as e:
        TESTAPITOOL.handle_mailFile_format(jobname, buildnumber, False, jenkinsurl, failed_reason=e)
    else:
        TESTAPITOOL.handle_mailFile_format(jobname, buildnumber, True, jenkinsurl, result)
    finally:
        os.system('rm -rf /jenkins/%s' % '_'.join((jobname, buildnumber)))
