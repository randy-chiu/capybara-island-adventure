# 卡皮巴拉海岛探险

面向小学四年级学生的 SwiftUI 数学学习游戏 MVP。孩子跟随小巴完成海岛剧情、数学闯关、错题复盘与家长日报。第一版完全离线，无账号、广告、内购、外链或第三方分析 SDK。

## MVP 内容

- 两章共 10 个关卡：行程问题 5 关，小学几何 5 关。
- 30 道结构化原创题，每关 3 题；难度分布为 A 级 6 道、B 级 10 道、C 级 8 道、D 级 6 道。
- 首页、地图、剧情、答题、逐步提示、完整讲解、奖励、错题本、家长报告、设置页面。
- SwiftUI 自绘小巴、海岛背景、路线图与几何示意图；不含外部美术或 IP 素材。
- `UserDefaults + Codable` 保存关卡、奖励、作答、提示使用与错题复习状态。

## 文件结构

```text
CapybaraIslandAdventure.xcodeproj/
CapybaraIslandAdventure/
  App/                 App 入口
  Models/              Question、来源、奖励、进度和报告模型
  Data/                关卡剧情及 30 道本地结构化题库
  Services/            UserDefaults 持久化
  ViewModels/          游戏状态、过滤、统计与解锁逻辑
  Components/          小巴头像、卡片、地图节点、路线图、几何图
  Views/               首页及全部功能页面
  Assets.xcassets/     AccentColor 与发布图标插槽
  Resources/Info.plist
```

关键实现：

- `Models/GameModels.swift`：题目契约与来源/版权字段定义。
- `Data/QuestionBank.swift`：题库、发布过滤、skill 正确率及 errorType 统计。
- `ViewModels/GameViewModel.swift`：试玩闭环、错题复习、日报生成。

## 在 Xcode 运行

1. 使用 Xcode 15 或更高版本打开 `CapybaraIslandAdventure.xcodeproj`。
2. 在 target `CapybaraIslandAdventure` 的 Signing & Capabilities 中选择开发团队，并将 bundle identifier 换成自己的唯一标识。
3. 选择 iPad 模拟器，例如 iPad Pro 13-inch，建议旋转为横屏。
4. 点击 Run。部署目标为 iOS/iPadOS 17.0 或更高版本。

项目本身不需要网络、包依赖、服务端配置或登录凭据。

## 添加新题目

1. 在 `AdventureContent.levels` 增加关卡元数据，或选择一个已有 `levelId`。
2. 在 `QuestionBank.swift` 的对应题组中使用 `q(...)` 增加题目，填写故事、题面、答案、解法、提示、能力与错误标签、图示类型/参数。
3. 题目发布前必须完整保留 `Question` 中的来源、版权与审批字段。当前工厂方法会写入原创来源模板；外部授权题应改为独立数据并填写真实授权记录。
4. 只有 `reviewStatus == .approved` 且 `copyrightStatus` 为 `original`、`teacherCreated`、`licensed` 或 `publicDomain` 的题目会由 `QuestionBank` 加载到正式关卡。
5. 新增关卡时确保它恰有可玩的题，并检查奖励和解锁顺序。

## 题库来源与版权说明

首批 30 道题为本项目原创题面、数值、海岛剧情与讲解，知识范围参照中国《义务教育数学课程标准（2022 年版）》中数与代数、图形与几何、综合与实践相关学习主题，并参考小学问题解决中常见的模型训练方向。未直接复制教材、教辅、培训资料或竞赛原题。

题库审核流程：

1. `draft`：AI 或人工生成题面草案，不进入正式玩法。
2. `reviewed`：家长、教师或产品负责人检查数学正确性、难度、表述与儿童适宜性。
3. `approved`：确认答案/讲解准确且无版权风险，才允许在正式关卡加载。
4. `copyrightStatus == unknown`、`adapted` 且未取得明确授权，或任何未达 `approved` 的题，不得进入发布题库。

发布团队应保留每次复核的人员、日期与修订记录。若未来引入授权内容，需要保存许可范围、期限及署名要求。

## 本地数据与儿童隐私

- 应用不要求姓名、生日、手机号、邮箱或位置等个人身份信息。
- 关卡进度和作答记录存于本设备 `UserDefaults`，可从设置页一键清除。
- 当前未接入网络接口、广告、第三方 SDK、推送、账号体系或购买功能。
- `Resources/PrivacyInfo.xcprivacy` 已按本应用自身进度存储用途声明 `UserDefaults` required-reason API（`CA92.1`）。
- 面向儿童发布前，应由法律/合规人员根据实际发行地区复核儿童隐私政策、年龄分级与家长门机制要求。

## App Store 提交前 Checklist

- [ ] 完成全部题目的教师/内容负责人真实复核，并保存审核记录。
- [ ] 制作原创 1024 x 1024 App Icon，填入 `AppIcon.appiconset`。
- [ ] 准备 iPad 与 iPhone 要求尺寸的真实运行截图、预览文案与应用描述。
- [ ] 设置正式 bundle identifier、签名、版本号、支持网址与隐私政策网址。
- [ ] 在 App Store Connect 填写隐私营养标签、年龄分级与儿童类别相关信息。
- [ ] 上传前再次核对 `PrivacyInfo.xcprivacy` 与最终代码/依赖实际使用的 required-reason API 一致。
- [ ] 在真机与多种 iPad 横屏尺寸上测试布局、触控目标、动态字体与 VoiceOver 基本可用性。
- [ ] 增加单元测试/UI 测试，覆盖题库过滤、解锁、持久化、报告统计与完整关卡路径。
- [ ] 进行中文文案、数学正确性、版权、无外链/无 SDK 的发布前检查。
- [ ] 如加入音效、字体或插画，仅使用原创或可证明授权的发布资源。
