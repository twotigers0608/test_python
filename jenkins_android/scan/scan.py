#!/usr/bin/python3
import requests, time, threading
import os
from bs4 import BeautifulSoup

def find_dir(resp, last_dir=None):
    def in_find_dir(response):
        bs = BeautifulSoup(response, features="lxml")
        e = bs.table.contents
        for i in e:
            if i == '\n':
                e.remove(i)
        w = []
        for i in e[3:-1]:
            w.append((i.contents[1].text, 
                      i.contents[2].text, 
                      i.contents[3].text))
        os.system('echo "%s"' % w)
        os.system('echo "%s"' % len(w))
        return w

    if last_dir:
        return in_find_dir(resp)[-1]
    return in_find_dir(resp)

def custom_mail_format(dir_tup, log_path=None, report_html_url=None, job_name=None):
    with open(log_path + '%s_message.txt' % job_name, 'w') as m, \
         open(log_path + '%s_subject.txt' % job_name, 'w') as s:
        s.write('SCAN %s' % job_name)
        m.write('The Protex IP Scan for "%s" has been finished. Please check below info for more detail:\n\n' % ('/'.join(report_html_url.split('/')[-3:]))[:-1])
        m.write('Full directory:\n')
        m.write(report_html_url + '\n\n')
        m.write('Report.html:\n')
        for i in dir_tup:
            if 'Report.html' in i[0]:
                report_html_name = i[0]

        m.write(report_html_url + report_html_name + '\n')
        requests.post('http://otcpkt.bj.intel.com:8080/job/send_scan_mail/buildWithParameters',
                      headers={'cache-control':'no-cache',
                               'content-type':'application/x-www-form-urlencoded',
                               csrf_token_list[0]:csrf_token_list[1]},
                      data={'scan_name': job_name},
                      auth=('weizhe', bj_user_api_token), 
                      verify=False)


def main(url, mail_file_path, job_name):
    resp = requests.get(url)
    dir_tup_1 = find_dir(resp.text)
    
    while True:
        resp = requests.get(url)
        dir_tup_2 = find_dir(resp.text)
        
        if len(dir_tup_1) != len(dir_tup_2):
            for i in dir_tup_2[len(dir_tup_1):]:
                next_url = url + i[0]
                res = requests.get(next_url)
                dir_tup = find_dir(res.text)
                custom_mail_format(dir_tup, log_path=mail_file_path, report_html_url=next_url, job_name=job_name)
                dir_tup_1 = dir_tup_2
        else:
            for i in range(len(dir_tup_2)):
                if dir_tup_1[i] != dir_tup_2[i]:
                    res = requests.get(url+(dir_tup_2[i])[0])
                    dir_tup = find_dir(res.text)
                    custom_mail_format(dir_tup, log_path=mail_file_path, report_html_url=url+(dir_tup_2[i])[0], job_name=job_name)
                    dir_tup_1 = dir_tup_2
        time.sleep(100)


if __name__ == '__main__':
    bj_user_api_token = 'd0ed154ca6a2ea39bd89af578fa90f0a'
    result = requests.get('http://otcpkt.bj.intel.com:8080/crumbIssuer/api/xml?xpath=concat(//crumbRequestField,":",//crumb)', verify = False)
    csrf_token_list = result.text.split(':')
    scan_url = 'http://ccprotexscan.jf.intel.com/BranchData/'
    url_in = ['PKTLTS2018BASE/', 
              'PKTLTS2018ANDROID/', 
              'KERNELBKCYOCTOEMB/',
              'KERNELBKCMAINTRK/',
              'KERNELBKCDEVEMB/',
              'KERNELBKCANDEMB/',
              'KERNELBKC414YOCTORT/',
              'KERNELBKC414YOCTO/',
              'KERNELBKC414BASE/',
              'KERNELBKC414AND/',
              'KERNELBKC49YOCTO/',
              'KERNELBKC49BASE/',
              'KERNELBKC49AND/']
    mail_file_path = os.getenv('WORKSPACE') + '/../send_scan_mail/'
    with open(mail_file_path + 'to.txt', 'w') as f:
        f.write('zhex.wei@intel.com')
    for i in url_in:
        t = threading.Thread(target=main, args=(scan_url + i, mail_file_path, i[:-1]))
        t.start()
 #   t1 = threading.Thread(target=main, args=(scan_url + 'PKTLTS2018BASE/', os.getenv('WORKSPACE') + '/../scan_base/base.txt', 'scan_base'))
 #   t2 = threading.Thread(target=main, args=(scan_url + 'PKTLTS2018ANDROID/', os.getenv('WORKSPACE') + '/../scan_android/android.txt', 'scan_android'))
 #   t1.start()
 #   t2.start()
