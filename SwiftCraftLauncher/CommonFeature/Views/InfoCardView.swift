//
//  InfoCardView.swift
//  SwiftCraftLauncher
//
//  Created by Hongbro886 on 2026/3/21.
//

import SwiftUI

// MARK: - Icon Source

/// 图标来源类型
enum IconSource {
    case url(String)
    case base64(String)
    case none
}

// MARK: - Left Content Configuration

/// 左侧内容配置（可以是图标或自定义视图配置）
struct LeftContentConfig {
    let iconSource: IconSource
    let iconPlaceholder: String
    let topText: String?      // 顶部文本（如版本号）
    let bottomText: String?   // 底部文本（如玩家数）
    
    init(
        iconSource: IconSource = .none,
        iconPlaceholder: String = "cube.box",
        topText: String? = nil,
        bottomText: String? = nil
    ) {
        self.iconSource = iconSource
        self.iconPlaceholder = iconPlaceholder
        self.topText = topText
        self.bottomText = bottomText
    }
}

// MARK: - Info Card Configuration

/// 信息卡片配置协议
protocol InfoCardConfigurable {
    var leftContent: LeftContentConfig { get }
    var title: String { get }
    var subtitle: String? { get }
    var tags: [String] { get }
    var infoItems: [(text: String, icon: String)] { get }
}

// MARK: - Info Card View

/// 通用信息卡片视图
/// 用于展示：左侧内容(图标/文本) + 标题 + 描述 + 标签 + 信息行
struct InfoCardView: View {
    let config: InfoCardConfigurable
    var iconSize: CGFloat = 64
    var cornerRadius: CGFloat = 12
    var backgroundColor: Color = .clear
    var strokeColor: Color? = nil

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(alignment: .top, spacing: 12) {
                // 左侧内容
                leftContentView

                VStack(alignment: .leading, spacing: 4) {
                    HStack {
                        Text(config.title)
                            .font(.headline)
                        Spacer()
                        infoRow
                    }

                    if let subtitle = config.subtitle, !subtitle.isEmpty {
                        Text(subtitle)
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                            .lineLimit(3)
                    }

                    // 标签
                    if !config.tags.isEmpty {
                        tagsView
                    }
                }

                Spacer()
            }
        }
        .padding(12)
        .background(backgroundColor)
        .cornerRadius(cornerRadius)
        .overlay(
            Group {
                if let strokeColor = strokeColor {
                    RoundedRectangle(cornerRadius: cornerRadius)
                        .stroke(strokeColor, lineWidth: 1)
                }
            }
        )
    }

    // MARK: - Subviews

    private var leftContentView: some View {
        let leftConfig = config.leftContent
        
        // 如果有顶部或底部文本，显示为文本堆叠
        if leftConfig.topText != nil || leftConfig.bottomText != nil {
            return AnyView(textStackView)
        }
        
        // 否则显示图标
        return AnyView(iconView)
    }
    
    /// 文本堆叠视图（用于服务器版本和玩家数）
    private var textStackView: some View {
        let leftConfig = config.leftContent
        
        return VStack(alignment: .leading, spacing: 4) {
            if let topText = leftConfig.topText {
                HStack(spacing: 4) {
                    Image(systemName: "cube")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Text(topText)
                        .font(.subheadline)
                        .fontWeight(.medium)
                }
            }
            
            if let bottomText = leftConfig.bottomText {
                HStack(spacing: 4) {
                    Image(systemName: "person.2")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Text(bottomText)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
        }
        .frame(width: iconSize, alignment: .leading)
    }

    private var iconView: some View {
        let leftConfig = config.leftContent
        
        return Group {
            switch leftConfig.iconSource {
            case .url(let iconUrl):
                if let url = URL(string: iconUrl) {
                    AsyncImage(url: url) { image in
                        image
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                    } placeholder: {
                        RoundedRectangle(cornerRadius: 8)
                            .fill(Color.secondary.opacity(0.2))
                    }
                    .frame(width: iconSize, height: iconSize)
                    .cornerRadius(8)
                } else {
                    placeholderIcon
                }
            case .base64(let base64String):
                if let imageData = CommonUtil.imageDataFromBase64(base64String),
                   let nsImage = NSImage(data: imageData) {
                    Image(nsImage: nsImage)
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(width: iconSize, height: iconSize)
                        .cornerRadius(8)
                } else {
                    placeholderIcon
                }
            case .none:
                placeholderIcon
            }
        }
    }

    private var placeholderIcon: some View {
        RoundedRectangle(cornerRadius: 8)
            .fill(Color.secondary.opacity(0.2))
            .frame(width: iconSize, height: iconSize)
            .overlay(
                Image(systemName: config.leftContent.iconPlaceholder)
                    .foregroundColor(.secondary)
            )
    }

    private var tagsView: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack {
                ForEach(config.tags, id: \.self) { tag in
                    Text(tag)
                        .font(.caption2)
                        .padding(
                            .horizontal,
                            ModrinthConstants.UIConstants.tagHorizontalPadding
                        )
                        .padding(
                            .vertical,
                            ModrinthConstants.UIConstants.tagVerticalPadding
                        )
                        .background(Color.gray.opacity(0.15))
                        .cornerRadius(
                            ModrinthConstants.UIConstants.tagCornerRadius
                        )
                }
            }
        }
    }

    private var infoRow: some View {
        HStack {
            ForEach(Array(config.infoItems.enumerated()), id: \.offset) { index, item in
                if index > 0 {
                    Divider().frame(height: 12)
                }
                Label(item.text, systemImage: item.icon)
            }
        }
        .font(.caption)
        .foregroundColor(.secondary)
    }
}

// MARK: - Modrinth Project Configuration

/// Modrinth 项目配置
struct ModrinthProjectCardConfig: Info
extension InfoCardView {
    /// 创建 Modrinth 项目卡片
    init(projectDetail: ModrinthProjectDetail) {
        self.config = ModrinthProjectCardConfig(projectDetail: projectDetail)
    }

    /// 创建 Minecraft 服务器信息卡片
    init(serverInfo: MinecraftServerInfo, iconSize: CGFloat = 48) {
        self.config = MinecraftServerCardConfig(serverInfo: serverInfo)
        self.iconSize = iconSize
        self.backgroundColor = Color.gray.opacity(0.1)
        self.strokeColor = Color.green.opacity(0.3)
    }
}
