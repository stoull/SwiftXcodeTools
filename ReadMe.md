


# Xcode项目工具集


## 翻译文本处理

### 翻译处理`LocalizeTools.swift`的使用

#### 一， 找出项目中没有引用到的翻译文本

1. 将`LocalizeTools.swift`拖到ShineTools工程根目录下
2. 在终端运行`swift LocalizeTools.swift`，对应没有用到的翻译文件会生成到目录`/0CheckResult`下,有如下文件

	* `中文整理过后的.strings` : 记录的是原zh文件中移除空格，注释，去重后的所有翻译keyvalue对
	* `整理过(剔除没有引用的翻译)后_cn.strings` : 记录的是原zh文件中移除空格，注释，去重，及移除没有用到的keyvalue后的翻译keyvalue对
	* `整理过(剔除没有引用的翻译)后_en.strings` : 记录的是原en文件中移除空格，注释，去重，及移除没有用到的keyvalue后的翻译keyvalue对
	* `移除工程中没有用到的翻译后的翻译.csv` : 记录最终给翻译的，也是最终导入工程的翻译文件
	* `工程中没有用到的翻译.csv` : 记录工程中没有用到的翻译

**注意：仅限ShineTools !!!!!!!**

**注意：仅限ShineTools**，其它的项目需要按本地化多语言的其体实现方式实现

#### 二， 找出项目中没有翻译的文本

todo: ...

参考：[Localize-Github](https://github.com/freshOS/Localize)