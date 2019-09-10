#!/usr/bin/python3

class APIHTML:
    def_sty = 'style=\'font-size:11.0pt;font-family:"Calibri",sans-serif\''
    tab_sty = 'border="0" cellspacing="0" cellpadding="0" width="0" style="width:548.75pt;border-collapse:collapse;"'
    tab_1 = 'width="47" style="border:solid windowtext 1.0pt;background:#D9D9D9;"'
    tab_2 = 'width="131" style="border:solid windowtext 1.0pt;background:#D9D9D9;"'
    tab_3 = 'width="174" style="border:solid windowtext 1.0pt;background:#D9D9D9;"'
    tab_4 = 'width="73" style="border:solid windowtext 1.0pt;background:#D9D9D9;"'
    tab_5 = 'width="307" style="border:solid windowtext 1.0pt;background:#D9D9D9;"'
    no_tab_1 = 'width="47" style="border:solid windowtext 1.0pt;"'
    no_tab_2 = 'width="131" style="border:solid windowtext 1.0pt;"'
    no_tab_3 = 'width="174" style="border:solid windowtext 1.0pt;"'
    no_tab_4 = 'width="73" style="border:solid windowtext 1.0pt;"'
    no_tab_5 = 'width="307" style="border:solid windowtext 1.0pt;"'
    def __add_custom_lable(func):
        def inner(*args, **kwargs):
            c_l = kwargs.get('custom_lables')
            if c_l:
                args = list(args)
                for l in c_l:
                    if l.__class__ == tuple:
                        args[0] = "<%s %s>%s</%s>" % (l[0], l[1], args[0], l[0])
                        continue
                    args[0] = '<%s>%s</%s>' % (l, args[0], l)
            return func(*args, **kwargs)
        return inner

    @staticmethod
    def custom(content, custom_lables=[]):
        for l in custom_lables:
            custom_text = "<{lable} {style}>\n    {content}\n</{lable}>" \
                if l.__class__ == tuple else '<{lable}>\n    {content}\n</{lable}>'
            content = custom_text.format(lable=l[0], style=l[1], content=content) \
                if l.__class__ == tuple else custom_text.format(lable=l, content=content)
        return content

    @staticmethod
    @__add_custom_lable
    def p(p_content, p_style=None, custom_lables=[]):
        p_text = "<p {p_style}>\n    {content}\n</p>" \
            if p_style else '<p>\n    {content}\n</p>'
        return p_text.format(p_style=p_style, content=p_content) \
            if p_style else p_text.format(content=p_content)

    @staticmethod
    @__add_custom_lable
    def span(span_content, span_style=None, custom_lables=[]):
        span_text = "<span {span_style}>\n    {content}\n</span>" \
            if span_style else '<span>\n    {content}\n</span>'
        return span_text.format(span_style=span_style, content=span_content) \
            if span_style else span_text.format(content=span_content)

    @staticmethod
    def td(td_content, td_style=None):
        td_text = "<td {td_style}>\n    {content}\n</td>" \
            if td_style else '<td>\n    {content}\n</td>'
        return td_text.format(td_style=td_style, content=td_content) \
            if td_style else td_text.format(content=td_content)

    @staticmethod
    def tr(tr_content, tr_style=None):
        tr_text = "<tr {tr_style}>\n    {content}\n</tr>" \
            if tr_style else '<tr>\n    {content}\n</tr>'
        return tr_text.format(tr_style=tr_style, content=tr_content) \
            if tr_style else tr_text.format(content=tr_content)

    @staticmethod
    def table(table_content, table_style=None):
        table_text = "<table {table_style}>\n    <tbody>\n    {content}\n</tbody>\n</table>" \
            if table_style else '<table>\n    <tbody>\n    {content}\n</tbody>\n</table>'
        return table_text.format(table_style=table_style, content=table_content) \
            if table_style else table_text.format(content=table_content)


if __name__ == '__main__':
    h = APIHTML()
    mail_title_list = ['#Executive Summary:', '#Coverity Summary:', '#Banned Words Summary:', '#Known issue:', '#Android Bare Metal Result:']
    mail_content_list = [
        '</br>Android and Yocto are' + h.span('"go".', "style='background:lime'"),
        '</br>None.',
        '</br>None.',
        '</br>None.',
        '</br>HW: GP D0 8G (Model:J17532-502)</br>Staging build: #378</br>' + \
        h.custom('https://oak-jenkins.ostc.intel.com/job/4.14-bkc-android-staging-gordon_peak/378/',
        [('a', 'href="https://oak-jenkins.ostc.intel.com/job/4.14-bkc-android-staging-gordon_peak/378/"')])
                         ]

    table_title_list = [('Num', h.tab_1), ('Type', h.tab_2), ('Tests suite name', h.tab_3), ('Android P on GP D0', h.tab_4), ('Remark', h.tab_5)]
    block = h.p(h.span('Hi All,', h.def_sty)) + h.p(h.span('Android test success'), h.def_sty)
    for i in range(len(mail_title_list)):
        block += h.p(h.span(h.custom(mail_title_list[i], ['u', 'b']) + mail_content_list[i], h.def_sty))

    # d = h.p(h.span(h.custom('#Coverity Summary:', ['u', 'b'])+'</br>None.', h.def_sty))
    # e = h.p(h.span(h.custom('#Banned Words Summary:', ['u', 'b'])+'</br>None.', h.def_sty))
    # f = h.p(h.span(h.custom('#Known issue:', ['u', 'b'])+'</br>None.', h.def_sty))
    # g = h.p(h.span(h.custom('#Android Bare Metal Result:', ['u', 'b'])+
    #     '</br>HW: GP D0 8G (Model:J17532-502)</br>Staging build: #378</br>'+
    #     h.custom('https://oak-jenkins.ostc.intel.com/job/4.14-bkc-android-staging-gordon_peak/378/',
    #     [('a', 'href="https://oak-jenkins.ostc.intel.com/job/4.14-bkc-android-staging-gordon_peak/378/"')]), h.def_sty))
    w = [('1', h.no_tab_1), ('system', h.no_tab_2), ('build-regression-check', h.no_tab_3), ('Pass', h.no_tab_4), ('', h.no_tab_5)]
    table_title = ''
    for i in range(len(table_title_list)):
        table_title += h.td(h.p(table_title_list[i][0], h.tp_sty, custom_lables=['b']), table_title_list[i][1])
    table_title = h.tr(table_title)
    tr_c = ''
    for i in range(34):
        td_c = ''
        for j in range(len(table_title_list)):
            td_c += h.td([w[j][0], h.p(w[j][0], h.tp_sty)][w[j][0] != ''], w[j][1])
        tr_c += h.tr(td_c)
    block += h.table(table_title+tr_c, h.tab_sty)
    with open('a.html', 'w') as fil:
        fil.write(block)