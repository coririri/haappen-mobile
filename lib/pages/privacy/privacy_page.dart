import 'package:flutter/material.dart';

class PrivacyPage extends StatelessWidget {
  const PrivacyPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('개인정보처리방침')),
      body: const SingleChildScrollView(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _Paragraph(
              children: [
                TextSpan(text: '한편의수학', style: TextStyle(fontWeight: FontWeight.bold)),
                TextSpan(
                  text:
                      " ('www.hpmath.co.kr' 이하 'hpmath')은(는) 「개인정보 보호법」 제30조에 따라 정보주체의 개인정보를 보호하고 이와 관련한 고충을 신속하고 원활하게 처리할 수 있도록 하기 위하여 다음과 같이 개인정보 처리방침을 수립·공개합니다.",
                ),
              ],
            ),
            _Paragraph(
              children: [
                TextSpan(text: '○ 이 개인정보처리방침은 2025년 2월 23일부터 적용됩니다.'),
              ],
            ),
            _Heading('제1조(개인정보의 처리 목적)'),
            _Paragraph(
              children: [
                TextSpan(text: '한편의수학', style: TextStyle(fontWeight: FontWeight.bold)),
                TextSpan(
                  text:
                      " ('www.hpmath.co.kr' 이하 'hpmath')은(는) 다음의 목적을 위하여 개인정보를 처리합니다. 처리하고 있는 개인정보는 다음의 목적 이외의 용도로는 이용되지 않으며 이용 목적이 변경되는 경우에는 「개인정보 보호법」 제18조에 따라 별도의 동의를 받는 등 필요한 조치를 이행할 예정입니다.",
                ),
              ],
            ),
            _BulletList(
              items: [
                '홈페이지 회원가입 및 관리: 회원 가입의사 확인, 회원제 서비스 제공에 따른 본인 식별·인증, 회원자격 유지·관리, 각종 고지·통지 목적으로 개인정보를 처리합니다.',
                '재화 또는 서비스 제공: 물품배송, 서비스 제공, 콘텐츠 제공을 목적으로 개인정보를 처리합니다.',
                '마케팅 및 광고에의 활용: 신규 서비스(제품) 개발 및 맞춤 서비스 제공 등을 목적으로 개인정보를 처리합니다.',
              ],
            ),
            _Heading('제2조(개인정보의 처리 및 보유 기간)'),
            _Paragraph(
              children: [
                TextSpan(text: '① '),
                TextSpan(text: '한편의수학', style: TextStyle(fontWeight: FontWeight.bold)),
                TextSpan(
                  text:
                      '은(는) 법령에 따른 개인정보 보유·이용기간 또는 정보주체로부터 개인정보를 수집 시에 동의받은 개인정보 보유·이용기간 내에서 개인정보를 처리·보유합니다.',
                ),
              ],
            ),
            _Paragraph(
              children: [
                TextSpan(text: '② 각각의 개인정보 처리 및 보유 기간은 다음과 같습니다.'),
              ],
            ),
            _BulletList(
              items: [
                '홈페이지 회원가입 및 관리: 개인정보는 수집·이용에 관한 동의일로부터 1년까지 위 이용목적을 위하여 보유·이용됩니다.',
              ],
            ),
            _Heading('제3조(처리하는 개인정보의 항목)'),
            _Paragraph(
              children: [
                TextSpan(text: '① '),
                TextSpan(text: '한편의수학', style: TextStyle(fontWeight: FontWeight.bold)),
                TextSpan(text: '은(는) 다음의 개인정보 항목을 처리하고 있습니다.'),
              ],
            ),
            _BulletList(
              items: [
                '홈페이지 회원가입 및 관리: 필수항목: 이름, 비밀번호, 휴대전화번호',
                '선택항목: 없음',
              ],
            ),
            _Heading('제4조(개인정보의 파기절차 및 파기방법)'),
            _Paragraph(
              children: [
                TextSpan(text: '① '),
                TextSpan(text: '한편의수학', style: TextStyle(fontWeight: FontWeight.bold)),
                TextSpan(
                  text:
                      '은(는) 개인정보 보유기간의 경과, 처리목적 달성 등 개인정보가 불필요하게 되었을 때에는 지체없이 해당 개인정보를 파기합니다.',
                ),
              ],
            ),
            _Heading('제5조(정보주체와 법정대리인의 권리·의무 및 그 행사방법에 관한 사항)'),
            _Paragraph(
              children: [
                TextSpan(
                  text:
                      '① 정보주체는 한편의수학에 대해 언제든지 개인정보 열람·정정·삭제·처리정지 요구 등의 권리를 행사할 수 있습니다.',
                ),
              ],
            ),
            _Paragraph(
              children: [
                TextSpan(
                  text:
                      '② 제1항에 따른 권리 행사는 한편의수학에 대해 서면, 전자우편, 모사전송(FAX) 등을 통하여 하실 수 있습니다.',
                ),
              ],
            ),
            _Heading('제6조(개인정보의 안전성 확보조치에 관한 사항)'),
            _Paragraph(
              children: [
                TextSpan(text: '한편의수학', style: TextStyle(fontWeight: FontWeight.bold)),
                TextSpan(text: '은(는) 개인정보의 안전성 확보를 위해 다음과 같은 조치를 취하고 있습니다.'),
              ],
            ),
            _BulletList(
              items: [
                '내부관리계획의 수립 및 시행',
                '개인정보 취급 직원의 최소화 및 교육',
              ],
            ),
            _Heading('제7조(개인정보를 자동으로 수집하는 장치의 설치·운영 및 그 거부에 관한 사항)'),
            _Paragraph(
              children: [
                TextSpan(
                  text:
                      "한편의수학은(는) 정보주체의 이용정보를 저장하고 수시로 불러오는 '쿠키(cookie)'를 사용하지 않습니다.",
                ),
              ],
            ),
            _Heading('제8조(행태정보의 수집·이용·제공 및 거부 등에 관한 사항)'),
            _Paragraph(
              children: [
                TextSpan(text: '행태정보의 수집·이용·제공 및 거부등에 관한 사항'),
              ],
            ),
            _Heading('제9조(추가적인 이용·제공 판단기준)'),
            _Paragraph(
              children: [
                TextSpan(
                  text:
                      '개인정보를 추가적으로 이용·제공하려는 목적이 당초 수집 목적과 관련성이 있는지 여부 등을 고려하여 정보주체의 동의 없이 개인정보를 추가적으로 이용·제공할 수 있습니다.',
                ),
              ],
            ),
            _Heading('제10조(가명정보를 처리하는 경우 가명정보 처리에 관한 사항)'),
            _Paragraph(
              children: [
                TextSpan(
                  text: '가명정보의 처리 및 보유기간, 제3자 제공 등에 관한 사항은 별도로 작성 가능합니다.',
                ),
              ],
            ),
            _Heading('제11조 (개인정보 보호책임자에 관한 사항)'),
            _Paragraph(
              children: [
                TextSpan(
                  text:
                      '① 한편의수학은(는) 개인정보 처리에 관한 업무를 총괄해서 책임지고, 개인정보 처리와 관련한 정보주체의 불만처리 및 피해구제 등을 위하여 아래와 같이 개인정보 보호책임자를 지정하고 있습니다.',
                ),
              ],
            ),
            _Paragraph(
              children: [
                TextSpan(text: '▶ 개인정보 보호책임자: 김선우, 직책: 사장, 연락처: 123-123@, 123'),
              ],
            ),
            _Heading('제12조(국내대리인의 지정)'),
            _Paragraph(
              children: [
                TextSpan(text: '정보주체는 개인정보 보호법 제39조의11에 따라 지정된 '),
                TextSpan(text: '한편의수학', style: TextStyle(fontWeight: FontWeight.bold)),
                TextSpan(text: '의 국내대리인에게 개인정보 관련 고충처리 등의 업무를 위하여 연락을 취할 수 있습니다.'),
              ],
            ),
            _Heading('제13조(개인정보의 열람청구를 접수·처리하는 부서)'),
            _Paragraph(
              children: [
                TextSpan(
                  text: '개인정보 열람청구 접수·처리 부서: 담당자: 김선우, 연락처: 010-3433-0652',
                ),
              ],
            ),
            _Heading('제14조(정보주체의 권익침해에 대한 구제방법)'),
            _Paragraph(
              children: [
                TextSpan(
                  text:
                      '정보주체는 개인정보침해로 인한 구제를 받기 위해 개인정보분쟁조정위원회 등 관련 기관에 분쟁해결이나 상담 등을 신청할 수 있습니다.',
                ),
              ],
            ),
            SizedBox(height: 32),
          ],
        ),
      ),
    );
  }
}

class _Heading extends StatelessWidget {
  final String text;
  const _Heading(this.text);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 20, bottom: 6),
      child: Text(
        text,
        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
      ),
    );
  }
}

class _Paragraph extends StatelessWidget {
  final List<TextSpan> children;
  const _Paragraph({required this.children});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: RichText(
        text: TextSpan(
          style: const TextStyle(fontSize: 14, color: Colors.black, height: 1.6),
          children: children,
        ),
      ),
    );
  }
}

class _BulletList extends StatelessWidget {
  final List<String> items;
  const _BulletList({required this.items});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 8, bottom: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: items
            .map(
              (item) => Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('• ', style: TextStyle(fontSize: 14, height: 1.6)),
                    Expanded(
                      child: Text(
                        item,
                        style: const TextStyle(fontSize: 14, height: 1.6),
                      ),
                    ),
                  ],
                ),
              ),
            )
            .toList(),
      ),
    );
  }
}
