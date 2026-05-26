import Foundation

enum AdventureContent {
    static let chapters: [Chapter] = [
        Chapter(id: "chapter-1", title: "第 1 章 小巴穿越海岛", subtitle: "用路线图寻找椰子林和淡水", topic: "行程问题", colorName: "ocean"),
        Chapter(id: "chapter-2", title: "第 2 章 小巴建造营地", subtitle: "量一量，搭出安全的小营地", topic: "小学几何", colorName: "palm")
    ]

    static let levels: [Level] = [
        level("1-1", "chapter-1", 1, "去椰子林", "沙滩小径", ["海浪把小巴送到软软的沙滩上。", "肚子咕咕叫，椰子林就在岛的另一边。", "小巴拿出地图：先算清路程和时间，就不会迷路啦。"], .coconut, "找到香香的椰子啦！"),
        level("1-2", "chapter-1", 2, "寻找淡水湖", "林间水迹", ["椰子能解渴，可营地还需要干净淡水。", "地上有一串闪亮的水滴脚印。", "算准速度和时间，我们追着线索出发。"], .mapPiece, "淡水湖的位置画进地图啦！"),
        level("1-3", "chapter-1", 3, "约见小海龟", "椰子桥", ["小海龟知道最平坦的扎营地。", "它和小巴要从桥的两端同时出发。", "画出两支相向的箭头，就能找到相遇时刻。"], .shell, "小海龟送来亮亮的贝壳！"),
        level("1-4", "chapter-1", 4, "追回鱼篓", "潮湿礁岸", ["小螃蟹误把鱼篓当成小屋，拖着它先跑啦。", "小巴轻轻喊：等等，那是晚饭的工具！", "别急，比较速度差，就能温柔地追上它。"], .fish, "鱼篓找回来，今晚有收获啦！"),
        level("1-5", "chapter-1", 5, "划木筏去虾岛", "蓝蓝海湾", ["小岛对面飘来虾岛的香味。", "潮水会帮忙，也会在回程轻轻阻拦木筏。", "分清顺水和逆水，小巴就能平安来回。"], .shrimp, "木筏带回了新鲜小虾！"),
        level("2-1", "chapter-2", 6, "围营地", "草地边缘", ["夜晚快到了，小巴要圈出安全的营地。", "藤条要刚好围住四条边，不能浪费。", "把不知道的边叫做 x 吧！"], .wood, "围栏稳稳地立好啦！"),
        level("2-2", "chapter-2", 7, "铺草垫", "营地中央", ["脚下的沙子有一点凉。", "小巴想铺一张方方正正的暖草垫。", "面积会告诉我们需要准备多少草叶。"], .coconut, "营地有了软软的草垫！"),
        level("2-3", "chapter-2", 8, "防潮布谜题", "雨棚下面", ["云朵送来一阵温柔的小雨。", "防潮布标了面积，却忘了写长度。", "从面积反过来寻找边长，帐篷就干爽啦。"], .shell, "防潮布铺得严严实实！"),
        level("2-4", "chapter-2", 9, "修木筏", "木工沙滩", ["小巴的木筏需要一块 L 形甲板。", "不规则的形状也能拆开或补完整来计算。", "先画图，小巴就不迷路啦。"], .wood, "结实的新甲板装好啦！"),
        level("2-5", "chapter-2", 10, "山洞石门", "星光山洞", ["地图碎片指向一扇圆圆的石门。", "门上的角度像两束星光。", "解开最后的几何线索，宝藏就是勇敢思考的回忆。"], .mapPiece, "找到了海岛探险纪念地图！")
    ]

    private static func level(_ id: String, _ chapter: String, _ order: Int, _ title: String, _ scene: String, _ story: [String], _ item: RewardItemType, _ message: String) -> Level {
        Level(id: id, chapterId: chapter, order: order, title: title, scene: scene, storyLines: story, reward: Reward(itemType: item, amount: 1, message: message))
    }
}
