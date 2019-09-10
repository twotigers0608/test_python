#!/usr/bin/python3
import paramiko
import sys
import json
import time
import os
import datetime
sys.path.append('/jenkins/workspace/Auto_download-Bender/')
sys.path.append('/jenkins/workspace/Auto_BAT-bender/')
from auto_img import IMGAPITOOL
from html_tool import APIHTML as h


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
    # NUC信息
    NUC_IP = 'SSP-KBL-Y-CDI191.jf.intel.com'
    NUC_USER = 'labuser'
    NUC_PWD = 'labuser'
    NUC_PORT = 22

    MESSAGE = '/jenkins/workspace/auto_clearlinux_test-CDI/message.html'
    TO = '/jenkins/workspace/auto_clearlinux_test-CDI/to.txt'
    SUBJECT = '/jenkins/workspace/auto_clearlinux_test-CDI/subject.txt'

    # NUC上进行自动测试的文件夹
    NUC_CLR_TEST_DIR = '/home/labuser/auto_test'

    # NUC上测试脚本保存路径
    NUC_TEST_SCRIPT_DIR = '%s/nuc' % NUC_CLR_TEST_DIR

    # 本地保存测试结果的文件夹
    LOCAL_TEST_RESULT_DIR = '/jenkins/workspace/auto_clearlinux_test-CDI'

    # 本地测试结果文件
    LOCAL_TEST_RESULT = '%s/clear_bat.json' % LOCAL_TEST_RESULT_DIR

    # NUC上spectre测试脚本文件夹
    NUC_SPECTRE_TEST_DIR = '%s/spectre-meltdown-checker' % NUC_TEST_SCRIPT_DIR

    # local_img_file_path的路径
    LOCAL_IMG_FILE_PATH = '/jenkins/workspace/clearlinux_image_info'  ########

    # spectre测试脚本文件夹
    SPECTRE_TEST_DIR = '/jenkins/workspace/spectre-meltdown-checker'

    # NUC上clearlinux测试脚本路径
    CLR_TEST_SCRIPT = '%s/clear_BAT.sh' % NUC_TEST_SCRIPT_DIR

    # NUC上自动替换clearlinux内核的脚本
    NUC_CLR_SCRIPT = '%s/clr_rpls_kernel_nuc_oak.sh' % NUC_CLR_TEST_DIR

    # 本地替换clearlinux内核的脚本
    LOCAL_CLR_SCRIPT = '/jenkins/workspace/clr_rpls_kernel_nuc_oak.sh'   ##########

    # 本地测试clearlinux的脚本
    LOCAL_TEST_SCRIPT = '/jenkins/workspace/clear_BAT.sh'   #########

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

    # 邮件表格html样式
    title_td1_style = 'rowspan="2" style="width:33.3pt;border:solid windowtext 1.0pt;border-bottom:solid black 1.0pt;background:#D9D9D9;padding:0in 5.4pt 0in 5.4pt; height:15.0pt" width="44"'
    title_td2_style = 'rowspan="2" style="width:46.3pt;border-top:solid windowtext 1.0pt;border-left:none;border-bottom:solid black 1.0pt;border-right:solid windowtext 1.0pt;background:#D9D9D9;padding:0in 5.4pt 0in 5.4pt;height:15.0pt" width="62"'
    title_td3_style = 'rowspan="2" style="width:173.55pt;border-top:solid windowtext 1.0pt;border-left:none;border-bottom:solid black 1.0pt;border-right:solid windowtext 1.0pt;background:#D9D9D9;padding:0in 5.4pt 0in 5.4pt;height:15.0pt" width="231"'
    title_td4_style = 'rowspan="2" style="width:67.5pt;border-top:solid windowtext 1.0pt;border-left:none;border-bottom:solid black 1.0pt;border-right:solid windowtext 1.0pt;background:#D9D9D9;padding:0in 5.4pt 0in 5.4pt;height:15.0pt" width="90"'
    title_td5_style = 'rowspan="2" style="width:58.0pt;border:solid windowtext 1.0pt;border-left:none;background:#D9D9D9;padding:0in 0in 0in 0in;height:15.0pt" width="77"'
    title_td6_style = 'rowspan="2" style="width:76.15pt;border-top:solid windowtext 1.0pt;border-left:none;border-bottom:solid black 1.0pt;border-right:solid windowtext 1.0pt;background:#D9D9D9;padding:0in 5.4pt 0in 5.4pt;height:15.0pt" width="102"'
    title_td7_style = 'rowspan="2" style="width:84.95pt;border-top:solid windowtext 1.0pt;border-left:none;border-bottom:solid black 1.0pt;border-right:solid windowtext 1.0pt;background:#D9D9D9;padding:0in 0in 0in 0in;height:15.0pt" width="113"'
    title_td8_style = 'rowspan="2" style="width:396.7pt;border-top:solid windowtext 1.0pt;border-left:none;border-bottom:solid black 1.0pt;border-right:solid windowtext 1.0pt;background:#D9D9D9;padding:0in 5.4pt 0in 5.4pt;height:15.0pt" width="529"'

    other_td1_style = 'style="width:33.3pt;border:solid windowtext 1.0pt;border-top:none;padding:0in 5.4pt 0in 5.4pt;height:15.0pt" width="44"'
    other_td2_style = 'style="width:46.3pt;border-top:none;border-left:none;border-bottom:solid windowtext 1.0pt;border-right:solid windowtext 1.0pt;padding:0in 5.4pt 0in 5.4pt;height:15.0pt" width="62"'
    other_td3_style = 'style="width:173.55pt;border-top:none;border-left:none;border-bottom:solid windowtext 1.0pt;border-right:solid windowtext 1.0pt;padding:0in 5.4pt 0in 5.4pt;height:15.0pt" width="231"'
    other_td4_style = 'style="width:67.5pt;border-top:none;border-left:none;border-bottom:solid windowtext 1.0pt;border-right:solid windowtext 1.0pt;padding:0in 5.4pt 0in 5.4pt;height:15.0pt" width="90"'
    other_td5_style = 'style="width:58.0pt;border-top:none;border-left:none;border-bottom:solid windowtext 1.0pt;border-right:solid windowtext 1.0pt;padding:0in 0in 0in 0in;height:15.0pt" width="77"'
    other_td6_style = 'style="width:76.15pt;border-top:none;border-left:none;border-bottom:solid windowtext 1.0pt;border-right:solid windowtext 1.0pt;padding:0in 5.4pt 0in 5.4pt;height:15.0pt" width="102"'
    other_td7_style = 'style="width:84.95pt;border-top:none;border-left:none;border-bottom:solid windowtext 1.0pt;border-right:solid windowtext 1.0pt;padding:0in 0in 0in 0in;height:15.0pt" width="113"'
    other_td8_style = 'style="width:396.7pt;border-top:none;border-left:none;border-bottom:solid windowtext 1.0pt;border-right:solid windowtext 1.0pt;padding:0in 5.4pt 0in 5.4pt;height:15.0pt" width="529"'

    title_tr_style = 'style="mso-yfti-irow:0;mso-yfti-firstrow:yes;height:15.0pt"'
    other_tr_style = 'style="mso-yfti-irow:1;height:15.0pt"'
    title_p1238_style = 'class="MsoNormal" style="text-align:justify"'
    title_p4567_style = 'class="MsoNormal" style="text-align:center" align="center"'
    title_span_style = 'style="color:black"'
    table_style = 'class="MsoNormalTable" style="width:937.25pt;margin-left:-.15pt;border-collapse:collapse;mso-yfti-tbllook:1184;mso-padding-alt:0in 0in 0in 0in" width="0" cellspacing="0" cellpadding="0" border="0"'


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


class SSHConnection:
    def __init__(self, host=ApiConfig.NUC_IP, port=ApiConfig.NUC_PORT, username=ApiConfig.NUC_USER, pwd=ApiConfig.NUC_PWD):
        self.host = host
        self.port = port
        self.username = username
        self.password = pwd

    def close(self):
        self.ssh.close()

    def upload(self, local_path, remote_path):
        self.ssh = paramiko.Transport((self.host, self.port))
        self.ssh.connect(username=self.username, password=self.password)
        sftp = paramiko.SFTPClient.from_transport(self.ssh)
        sftp.put(local_path, remote_path)

    def download(self, local_path, remote_path):
        self.ssh = paramiko.Transport((self.host, self.port))
        self.ssh.connect(username=self.username, password=self.password)
        sftp = paramiko.SFTPClient.from_transport(self.ssh)
        sftp.get(remote_path, local_path)

    def cmd(self, command):
        self.ssh = paramiko.SSHClient()
        self.ssh.set_missing_host_key_policy(paramiko.AutoAddPolicy())
        self.ssh.connect(self.host, self.port, self.username, self.password)
        stdin, stdout, sterr = self.ssh.exec_command(command)
        return stdout.read()


class ClearApiTool:
    __to_someone_list = [
        'zhex.wei@intel.com',
        'gaix.wang@intel.com',
        'minx1.wang@intel.com',
        'fan.c.zhang@intel.com',
        'pk.sdk.cw@intel.com'
    ]

    @staticmethod
    def execute_cmd_to_nuc(cmd):
        '''
        使用SSHConnection类提供的接口,远程执行替换内核的脚本
        :param clr_script: 替换内核脚本的位置
        :return: 返回执行脚本的结果
        '''
        # s = paramiko.SSHClient()
        # s.set_missing_host_key_policy(paramiko.AutoAddPolicy())
        # s.connect('10.238.158.194', 22, 'root', password)
        # stdin, stdout, sterr = s.exec_command('bash {clr_script}')
        # s.close()
        # return stdout.read()
        print('execute', cmd)

        ssh = SSHConnection()
        return_value = ssh.cmd(cmd)
        ssh.close()
        return return_value

    @staticmethod
    def push_file_to_nuc(local_path, remote_path):
        '''
        拷贝本地镜像文件到nuc上
        :param local_path: 本地镜像路径 '/jenkins/419_clr/clr-da.zip'
        :param remote_path: 远程nuc路径 '/root/clr-da.zip'
        '''
        # 将本地的镜像文件拷贝到nuc上
        # conn = paramiko.Transport(('10.238.158.194', 22))
        # conn.connect(username='root', password='intel@123')
        # sftp = paramiko.SFTPClient.from_transport(conn)
        # sftp.put(local_path, remote_path)
        # conn.close()

        ssh = SSHConnection()
        ssh.upload(local_path, remote_path)
        ssh.close()

    @staticmethod
    def pull_file_from_nuc(local_path, remote_path):
        ssh = SSHConnection()
        ssh.download(local_path, remote_path)
        ssh.close()

    @staticmethod
    def handle_vmlinuz(file_str):
        for i in file_str.decode().split('\n'):
            if 'vmlinuz' in i:
                return i

    def __handle_testResult_zsq(func):
        def inner(cls, jobNa, buildNo, testResu, jenkins_url, result_file, failed_reason=None, subject=None):
            if testResu == False:
                result = 'Automatic test failed, please change to manual... </br>Failed reason:%s' % failed_reason
                return func(cls, jobNa, buildNo, testResu, jenkins_url, result, failed_reason, subject)
            with open(result_file, 'r') as f:
                result = f.read()
            # 生成的json文件不完整,需要处理完整,去掉最后的","添加上"}"
            result = json.loads(result[:-2] + '}')

            # 邮件里最上面的那句话 Hi All, Please find staging...........
            mail_1 = h.p(h.span('Hi All,', h.def_sty)) + h.p(h.span('Clear BAT test success'), h.def_sty)

            # 邮件标题列表
            mail_title_list = ['#Executive Summary:', '#Banned Words:',
                               '#Coverity Scan:', '#CVE Scan:', '#Spectre & Meltdown:',
                               '#Known Issue:', '#Testing Information:', '#Test Suite:',
                               '#Test Log Archived:', '#Test reports Archived:']
            # #Test Information:
            # AgainstHW: KBLNUC(Model: NUC7i5DNHE)******
            # Regular: https://*********
            mail_2 = ''.join((
                # h.custom('#Clear BAT Results:', custom_lables=['u', 'b']),
                '</br>',
                h.custom('Against HW: ', custom_lables=['b']),
                # 'APL NUC (Model: NUC6CAY) and KBL NUC (Model: NUC7i5DNHE) with Clear Version #29450:',
                'CDI Test device ID: 191   Type: RVP   Model: KBL-Y   Platform: Kaby Lake:',
                '</br>Regular: ',
                h.custom(jenkins_url, custom_lables=[('a', 'href="%s"' % jenkins_url)])))

            # 邮件里面表格的标题行的内容和样式
            table_title_list = [('Num', ApiConfig.title_p1238_style, ApiConfig.title_td1_style),
                                ('Type', ApiConfig.title_p1238_style, ApiConfig.title_td2_style),
                                ('Tests suite name', ApiConfig.title_p1238_style, ApiConfig.title_td3_style),
                                ('KBL NUC (Model: NUC7i5DNHE)', ApiConfig.title_p4567_style, ApiConfig.title_td6_style),
                                ('Remarks', ApiConfig.title_p1238_style, ApiConfig.title_td8_style)]
            td = [(h.p(h.custom(h.span(i[0], ApiConfig.title_span_style), ['b']), i[1]), i[2]) for i in table_title_list]
            td1 = h.td(td[0][0], td[0][1])
            td2 = h.td(td[1][0], td[1][1])
            td3 = h.td(td[2][0], td[2][1])
            td4 = h.td(td[3][0], td[3][1])
            td5 = h.td(td[4][0], td[4][1])
            tr1 = h.tr(''.join((td1, td2, td3, td4, td5)), ApiConfig.title_tr_style)
            tr1 += h.tr(h.td('', 'style="width:.8pt;padding:0in 0in 0in 0in;height:15.0pt" width="1"'),
                        ApiConfig.other_tr_style)

            data_list = []
            n = 1
            for i in result:
                if i == 'tc_wifi_driver_loaded':
                    continue
                w = [(str(n), ApiConfig.other_td1_style), ('BAT', ApiConfig.other_td2_style)]
                w.append((i, ApiConfig.other_td3_style))
                w.append((result[i][0], ApiConfig.other_td4_style))
                w.append(('', ApiConfig.other_td8_style))
                data_list.append(w)
                n += 1
            # 生成表格里所有其他行的数据
            for n in data_list:
                td = [h.td(h.p(h.span(i[0], ApiConfig.title_span_style), ApiConfig.title_p1238_style), i[1])
                      for i in n]
                tr = h.tr(''.join(td), ApiConfig.other_tr_style)
                # 将每一行的数据和第一行加在一起
                tr1 += tr
            # 生成整个tab
            tab = h.table(tr1, ApiConfig.table_style)
            # 邮件里面标题下的文本
            mail_content_list = [
                '</br>Clear BAT is ' + h.span('"go".', "style='background:lime'"),
                '</br>None.',
                '</br>None.',
                '</br>None.',
                '</br>None.',
                '</br>None.',
                mail_2,
                tab,
                '</br>None.',
                '</br>None.</br></br>Best Regards</br>PKT QA Team'
            ]
            #################      下面的方法和上面的结果一样,可以用于单独定制每一个行的内容用      ################
            # td = [h.td(h.p(h.span(i[0], ApiConfig.title_span_style), ApiConfig.title_p1238_style), i[1]) for i in
            #       data_list[0]]
            # tr2 = h.tr(''.join(td), ApiConfig.other_tr_style)
            # td = [h.td(h.p(h.span(i[0], ApiConfig.title_span_style), ApiConfig.title_p1238_style), i[1]) for i in
            #       data_list[1]]
            # tr3 = h.tr(''.join(td), ApiConfig.other_tr_style)
            # td = [h.td(h.p(h.span(i[0], ApiConfig.title_span_style), ApiConfig.title_p1238_style), i[1]) for i in
            #       data_list[2]]
            # tr4 = h.tr(''.join(td), ApiConfig.other_tr_style)
            # td = [h.td(h.p(h.span(i[0], ApiConfig.title_span_style), ApiConfig.title_p1238_style), i[1]) for i in
            #       data_list[3]]
            # tr5 = h.tr(''.join(td), ApiConfig.other_tr_style)
            # td = [h.td(h.p(h.span(i[0], ApiConfig.title_span_style), ApiConfig.title_p1238_style), i[1]) for i in
            #       data_list[4]]
            # tr6 = h.tr(''.join(td), ApiConfig.other_tr_style)
            # td = [h.td(h.p(h.span(i[0], ApiConfig.title_span_style), ApiConfig.title_p1238_style), i[1]) for i in
            #       data_list[5]]
            # tr7 = h.tr(''.join(td), ApiConfig.other_tr_style)
            # td = [h.td(h.p(h.span(i[0], ApiConfig.title_span_style), ApiConfig.title_p1238_style), i[1]) for i in
            #       data_list[6]]
            # tr8 = h.tr(''.join(td), ApiConfig.other_tr_style)
            # td = [h.td(h.p(h.span(i[0], ApiConfig.title_span_style), ApiConfig.title_p1238_style), i[1]) for i in
            #       data_list[7]]
            # tr9 = h.tr(''.join(td), ApiConfig.other_tr_style)
            #
            # tab = h.table(''.join((tr1, h.tr(h.td('', 'style="width:.8pt;padding:0in 0in 0in 0in;height:15.0pt" width="1"'),
            #                     ApiConfig.other_tr_style), tr2, tr3, tr4, tr5, tr6, tr7, tr8, tr9)), ApiConfig.table_style)
            # result = ''.join((mail_1, mail_2, tab))
            result = [h.p(h.span(h.custom(mail_title_list[i], ['u', 'b']) + mail_content_list[i], h.def_sty))
                      for i in range(len(mail_title_list))]
            result.insert(0, mail_1)
            result = ''.join(result)
            return func(cls, jobNa, buildNo, testResu, jenkins_url, result, failed_reason, subject)
        return inner

    def __handle_testSubject_zsq(func):
        def inner(cls, jobNa, buildNo, testResu, jenkins_url, result_file, failed_reason=None, subject=None):
            # 默认的邮件主题格式
            default_subject = '[CDI_QA][{buildno}][ClearLinux] [staging: {tag}] / {N}/{date}'
            # 请求jenkins的api,生成邮件标题里面的日期
            resp = ClearIMGAPITOOL.request_get(jenkins_url + '/api/json', isjson=True)
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
            n = '%sw%s.%s-%s' % (n[0], n[1], n[2], tag[tag.index('T') + 1: -1])
            subject = default_subject.format(buildno=jobNa, tag=tag, N=n, date=d)
            return func(cls, jobNa, buildNo, testResu, jenkins_url, result_file, failed_reason, subject)
        return inner

    @classmethod
    @__handle_testSubject_zsq
    @__handle_testResult_zsq
    def handle_result(cls, jobNa, buildNo, testResu, jenkins_url, result_file, failed_reason=None, subject=None):
        # result_status = ['failed', 'success'][testResu]
        with open(ApiConfig.MESSAGE, 'w') as m, \
            open(ApiConfig.TO, 'w') as t, \
            open(ApiConfig.SUBJECT, 'w') as s:
            s.write(subject)
            if testResu:
                t.write(', '.join(cls.__to_someone_list[-1:]))
            else:
                t.write(', '.join(cls.__to_someone_list[:3]))
                # t.write(', '.join(cls.__to_someone_list[-1:]))
            m.write(result_file)

    @classmethod
    def run(cls, tar_file):
        api = ApiConfig()
        # 拷贝替换内核脚本文件到nuc
        cls.push_file_to_nuc(api.LOCAL_CLR_SCRIPT, api.NUC_CLR_SCRIPT)
        # 拷贝测试脚本文件到nuc
        cls.execute_cmd_to_nuc('mkdir %s' % api.NUC_TEST_SCRIPT_DIR)
        cls.push_file_to_nuc(api.LOCAL_TEST_SCRIPT, api.CLR_TEST_SCRIPT)
        # 创建spectre目录
        cls.execute_cmd_to_nuc('mkdir %s' % api.NUC_SPECTRE_TEST_DIR)
        # 拷贝spectre测试文件到NUC
        for i in os.listdir(api.SPECTRE_TEST_DIR):
            if not i.startswith('.'):
                cls.push_file_to_nuc('/'.join((api.SPECTRE_TEST_DIR, i)), '/'.join((api.NUC_SPECTRE_TEST_DIR, i)))
        # 处理镜像文件的名字 "/root/auto_test/*****.tar.bz2"
        remote_path = '/'.join((api.NUC_CLR_TEST_DIR, tar_file.split('/')[-1]))
        # 拷贝镜像文件到nuc
        cls.push_file_to_nuc(tar_file, remote_path)
        # 解压缩镜像文件  "tar -jxf /root/auto_test/***.tar.bz2 -C /root/auto_test/"
        cls.execute_cmd_to_nuc('tar -jxf {tar_file} -C {d}'.format(tar_file=remote_path, d=api.NUC_CLR_TEST_DIR))
        # 查看解压缩后的文件
        vm = cls.execute_cmd_to_nuc('ls %s' % api.NUC_CLR_TEST_DIR)
        # 处理替换内核脚本的-k参数  -k vmlinuz-4.19.35-PKT-2b522fe5
        vm = cls.handle_vmlinuz(vm)
        lib = cls.execute_cmd_to_nuc('ls %s/lib/modules' % api.NUC_CLR_TEST_DIR)
        # 处理替换内核脚本的-l参数   -l lib/modules/4.19.35-PKT-2b522fe5
        lib = '/'.join(('lib/modules', lib.decode()[:-1]))
        # 执行替换内核脚本
        cls.execute_cmd_to_nuc('cd {d} && echo "{p}"|sudo -S bash {clr_script} -k {vm} -l {lib}'.format(d=api.NUC_CLR_TEST_DIR, clr_script=api.NUC_CLR_SCRIPT, vm=vm, lib=lib, p=api.NUC_PWD))
        # 重启nuc
        cls.execute_cmd_to_nuc('echo "%s"|sudo -S reboot' % api.NUC_PWD)
        ClearIMGAPITOOL.time_sleep_with_print(50)
        # 查询内核版本
        kernel_version = cls.execute_cmd_to_nuc('uname -a')
        if lib.split('/')[-1] in kernel_version.decode():
            # 如果内核版本一致就执行测试脚本
            cls.execute_cmd_to_nuc('cd %s && bash %s' % (api.NUC_TEST_SCRIPT_DIR, api.CLR_TEST_SCRIPT))
            # 查看测试结果文件
            result_files = cls.execute_cmd_to_nuc('ls %s' % api.NUC_TEST_SCRIPT_DIR)
            result_file_list = result_files.decode().split('\n')
            # 将测试结果文件拷贝到当前主机
            for i in result_file_list:
                if i and '/'.join((api.NUC_TEST_SCRIPT_DIR, i)) not in [api.NUC_SPECTRE_TEST_DIR, api.CLR_TEST_SCRIPT]:
                    cls.pull_file_from_nuc('/'.join((api.LOCAL_TEST_RESULT_DIR, i)), '/'.join((api.NUC_TEST_SCRIPT_DIR, i)))
        # 删除nuc上的镜像和测试文件下的东西
        cls.execute_cmd_to_nuc('cd %s && rm -rf *' % api.NUC_CLR_TEST_DIR)


if __name__ == '__main__':
    with open(ApiConfig.LOCAL_IMG_FILE_PATH, 'r') as f:
        info = f.read()
    info = info.split(',')
    jobname = info[2]
    buildnumber = info[1]
    jenkinsurl = info[3]
    tar_file = info[0]
    print('Test clear bat [%s][%s]' % (jobname, buildnumber))
    try:
        ClearApiTool.run(tar_file)
    except Exception as e:
        ClearApiTool.handle_result(jobname, buildnumber, False, jenkinsurl, ApiConfig.LOCAL_TEST_RESULT, e)
    else:
        # 生成结果文件
        ClearApiTool.handle_result(jobname, buildnumber, True, jenkinsurl, ApiConfig.LOCAL_TEST_RESULT)
