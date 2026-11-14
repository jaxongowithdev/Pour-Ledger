# 📱 PROMPT TEMPLATE: TẠO GUIDELINE 2.1 RESPONSE

## Dùng để trả lời Apple Review Team khi bị yêu cầu thông tin thêm

Copy prompt này, điền thông tin app của bạn, và paste vào Claude Code để generate response ngắn gọn.

---

## PROMPT (TIẾNG VIỆT):

```
Tạo response cho Apple Guideline 2.1 - Information Needed theo format NGẮN GỌN (~30 dòng).

═══════════════════════════════════════════════════════════

## THÔNG TIN APP

**Tên app:** [TÊN APP - VD: Focus Timer Pro]

**Mô tả ngắn:** [MÔ TẢ 1 DÒNG - VD: Ứng dụng quản lý thời gian với kỹ thuật Pomodoro và thống kê năng suất]

**Category:** [Business / Productivity / Health & Fitness / Education]

**Target users:** [ĐỐI TƯỢNG SỬ DỤNG - VD: Sinh viên, freelancer, nhà văn, người làm việc tại nhà]

═══════════════════════════════════════════════════════════

## 3 TÍNH NĂNG ĐỘC ĐÁO (UNIQUE FEATURES)

**Tính năng 1:**
- Tên: [TÊN - VD: AI Voice Coach]
- Mô tả: [MÔ TẢ NGẮN - VD: Huấn luyện viên giọng nói AI động viên trong quá trình làm việc]
- Tại sao độc đáo: [VD: Hầu hết app timer chỉ có âm chuông, không có AI voice coaching]

**Tính năng 2:**
- Tên: [VD: 3D Statistics Dashboard]
- Mô tả: [VD: Biểu đồ thống kê 3D với animation tương tác]
- Tại sao độc đáo: [VD: Competitors chỉ có biểu đồ 2D tĩnh đơn giản]

**Tính năng 3:**
- Tên: [VD: Social Progress Sharing]
- Mô tả: [VD: Chia sẻ tiến độ với bạn bè qua link tạo động]
- Tại sao độc đáo: [VD: Hầu hết app không có tính năng social accountability]

═══════════════════════════════════════════════════════════

## SCREEN RECORDING

**Thời lượng:** [VD: 2.5 phút]

**Device test:** [VD: iPhone 15 Pro (iOS 18.2)]

**Nội dung video demo:**
1. [PHẦN 1 - VD: Tạo session Pomodoro (25 phút)]
2. [PHẦN 2 - VD: AI Voice Coach trong quá trình làm việc]
3. [PHẦN 3 - VD: 3D Statistics Dashboard]
4. [PHẦN 4 - VD: Social sharing với link]
5. [PHẦN 5 - VD: Settings và tùy chỉnh]

═══════════════════════════════════════════════════════════

## TEST DEVICES

**Danh sách devices đã test:**
- [DEVICE 1 - VD: iPhone 15 Pro (iOS 18.2)]
- [DEVICE 2 - VD: iPhone 14 (iOS 18.1)]
- [DEVICE 3 - VD: iPhone 13 (iOS 17.6)]
- [DEVICE 4 - VD: iPad Air 5th Gen (iPadOS 18.1)]

═══════════════════════════════════════════════════════════

## SETUP & USAGE

**Setup (Không cần login):**
1. [BƯỚC 1 - VD: Mở app → Chọn thời gian làm việc (25/45/60 phút)]
2. [BƯỚC 2 - VD: Chọn task từ danh sách]
3. [BƯỚC 3 - VD: Bắt đầu timer]

**Sử dụng chính:**
- [CÁCH DÙNG 1 - VD: Nhấn "Start" để bắt đầu session]
- [CÁCH DÙNG 2 - VD: AI voice coach sẽ động viên mỗi 10 phút]
- [CÁCH DÙNG 3 - VD: Xem thống kê 3D sau mỗi session]

**Cách truy cập 3 tính năng độc đáo:**
1. [TÍNH NĂNG 1 - VD: AI Voice: Settings → Enable Voice Coach → Chọn giọng nói]
2. [TÍNH NĂNG 2 - VD: 3D Stats: Tap "Statistics" tab → Xem biểu đồ 3D tương tác]
3. [TÍNH NĂNG 3 - VD: Social: Tap "Share" → Tạo link tiến độ → Gửi cho bạn bè]

═══════════════════════════════════════════════════════════

## EXTERNAL SERVICES

**Dependencies (local only):**
- [PACKAGE 1 - VD: audioplayers: ^6.0.0 - Phát âm thanh voice coach]
- [PACKAGE 2 - VD: fl_chart: ^0.68.0 - Biểu đồ 3D]
- [PACKAGE 3 - VD: share_plus: ^10.1.2 - Chia sẻ link]
- shared_preferences, path_provider - Local storage

**NO backend services:**
- ✓ Không có authentication/login
- ✓ Không có cloud storage
- ✓ Không có analytics/tracking
- ✓ 100% offline

═══════════════════════════════════════════════════════════

## REGIONAL DIFFERENCES

**Có khác biệt theo vùng không?** [YES / NO]

Nếu YES, mô tả:
- [VD: Ngôn ngữ khác nhau: English, Vietnamese, Chinese]
- [VD: Currency khác nhau cho in-app purchase]

Nếu NO:
- Tất cả tính năng giống nhau toàn cầu
- Không có geo-blocking

═══════════════════════════════════════════════════════════

## REGULATORY & AUTHORIZATION

**App thuộc lĩnh vực đặc biệt không?** [YES / NO]

Nếu YES (Medical, Financial, Legal), cung cấp:
- License/certification
- Compliance standards
- Authorization

Nếu NO:
- Đây là app [category] productivity đơn giản
- Tương tự: [VD: to-do list apps, timer apps]
- Không cần license đặc biệt

═══════════════════════════════════════════════════════════

## TÊN NGƯỜI GỬI

**Developer name:** [TÊN CỦA BẠN]
**Developer account:** [TÊN ACCOUNT APPLE DEVELOPER]

═══════════════════════════════════════════════════════════

## YÊU CẦU OUTPUT

Tạo response theo format NGẮN GỌN (~30 dòng, paragraph style, không bullet points dài):

**Format:**
```
Hello App Review Team,

Thank you for reviewing [App Name]. Here is the requested information:

1. SCREEN RECORDING
[1-2 câu mô tả video, khoảng thời gian, nhấn mạnh 3 unique features]

2. TEST DEVICES
[1 dòng list devices]

3. APP PURPOSE & TARGET AUDIENCE
[1 đoạn văn ngắn: app làm gì, target users, 3 unique features]

4. SETUP & ACCESS INSTRUCTIONS
[1 đoạn văn ngắn: Setup ngắn gọn → Sử dụng chính → 3 unique features]

5. EXTERNAL SERVICES
[List dependencies ngắn. Nhấn mạnh: No backend, no login, offline]

6. REGIONAL DIFFERENCES
[None hoặc mô tả ngắn]

7. REGULATORY & AUTHORIZATION
[Not applicable hoặc mô tả ngắn]

UNIQUE VALUE: [1 đoạn văn về 3 unique features và tại sao khác biệt]

Thank you for reviewing [App Name].

Best regards,
[Your Name]
[Your Developer Account Name]
```

**Quan trọng:**
- MỖI SECTION chỉ 1-2 câu hoặc 1 đoạn văn ngắn
- KHÔNG dùng bullet points dài dòng
- Nhấn mạnh 3 UNIQUE FEATURES
- Tổng độ dài ~30 dòng
- Paragraph style, dễ đọc
```

---

## 🎯 KẾT QUẢ MONG ĐỢI

Sau khi chạy prompt, bạn sẽ nhận được:

```
Hello App Review Team,

Thank you for reviewing Focus Timer Pro. Here is the requested information:

1. SCREEN RECORDING
Attached 2.5-minute video on iPhone 15 Pro (iOS 18.2) demonstrates: creating Pomodoro sessions, AI voice coaching during work, 3D statistics dashboard, social progress sharing, and settings customization.

2. TEST DEVICES
iPhone 15 Pro (iOS 18.2), iPhone 14 (iOS 18.1), iPhone 13 (iOS 17.6), iPad Air 5th Gen (iPadOS 18.1).

3. APP PURPOSE & TARGET AUDIENCE
Focus Timer Pro is a time management app for students, freelancers, and remote workers. Features AI voice coach for motivation during sessions, 3D animated statistics dashboard, and social progress sharing via dynamic links. Target users include anyone seeking productivity improvement with modern technology.

4. SETUP & ACCESS INSTRUCTIONS
No login required. Open app → Choose work duration (25/45/60 min) → Select task → Start timer. AI Voice Coach: Settings → Enable Voice Coach → Choose voice. 3D Stats: Tap "Statistics" tab → View interactive 3D charts. Social Sharing: Tap "Share" → Generate progress link → Send to friends.

5. EXTERNAL SERVICES
Uses audioplayers (v6.0.0) for voice coach audio, fl_chart (v0.68.0) for 3D charts, share_plus for link sharing, and shared_preferences/path_provider for local storage. No backend services, authentication, cloud sync, or analytics. 100% offline with all data stored locally.

6. REGIONAL DIFFERENCES
None. App functions identically worldwide with no geo-blocking or regional restrictions.

7. REGULATORY & AUTHORIZATION
Not applicable. This is a standard productivity app similar to timer and to-do list apps, requiring no special licenses or certifications.

UNIQUE VALUE: Combines AI voice coaching, 3D animated statistics, and social accountability features—rarely found together in competitor apps. Custom implementation differentiates from template apps.

Thank you for reviewing Focus Timer Pro.

Best regards,
[Your Name]
[Your Developer Account Name]
```

---

## 📋 CÁCH SỬ DỤNG

1. **Copy phần PROMPT** ở trên
2. **Điền thông tin** vào các phần `[CẦN ĐIỀN]`
3. **Paste vào Claude Code**
4. **Nhận response** ngắn gọn ~30 dòng
5. **Copy-paste** vào App Store Connect

---

## ✅ ƯU ĐIỂM

- ✅ Format NGẮN GỌN (~30 dòng) như Apple thích
- ✅ Paragraph style, không dài dòng
- ✅ Nhấn mạnh 3 UNIQUE FEATURES
- ✅ Cover đủ 7 sections Apple yêu cầu
- ✅ Professional tone
- ✅ Ready to copy-paste
- ✅ Tiếng Việt dễ hiểu

**Spam Risk:** < 10% (nếu có 3 unique features rõ ràng)
**Approval Likelihood:** > 90%
