


# Xcode项目工具集


## 翻译文本处理

### 翻译处理`LocalizeTools.swift`的使用

#### 一， 找出项目中没有引用到的翻译文本

1. 将`LocalizeTools.swift`拖到ShineTools工程根目录下
2. 在终端运行`swift LocalizeTools.swift`，对应没有用到的翻译文件会生成到目录`0CheckResult/unused.strings`下。

注意：因工程中使用的引用的翻译key形式多样，目前使用的是最大匹配范围

#### 二， 找出项目中没有翻译的文本

todo: ...

参考：[Localize-Github](https://github.com/freshOS/Localize)