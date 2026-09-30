import SwiftUI
import MediaDownloaderCore

struct HistoryListView: View {
    let items: [DownloadItem]
    let onCopy: (DownloadItem) -> Void
    let onReveal: (DownloadItem) -> Void
    let onOpenSource: (DownloadItem) -> Void
    let onDelete: (DownloadItem) -> Void
    let onEdit: (DownloadItem) -> Void
    let onClear: () -> Void
    @Binding var height: CGFloat?
    let selectedIndex: Int?
    let selectedItemID: DownloadItem.ID?
    let copiedItemID: DownloadItem.ID?
    let onMarkCopied: (DownloadItem.ID) -> Void
    let onHoverItem: (DownloadItem.ID) -> Void
    let suppressHoverHighlight: Bool
    @State private var viewport = HistoryKeyboardViewport(visibleRowLimit: 4)
    private let rowHeight: CGFloat = 74
    private let verticalPadding: CGFloat = 20
    private let headerHeight: CGFloat = 42
    private let minimumHeight: CGFloat = 140
    private let maximumHeight: CGFloat = 460
    @State private var dragStartHeight: CGFloat?

    var body: some View {
        ScrollViewReader { proxy in
            VStack(spacing: 0) {
                HStack(spacing: 8) {
                    Text("Downloads")
                        .font(.subheadline.weight(.semibold))
                    Text("\(items.count)")
                        .font(.caption.monospacedDigit().weight(.medium))
                        .foregroundStyle(.secondary)

                    Spacer()

                    Button(action: onClear) {
                        Label("Clear", systemImage: "trash")
                            .font(.caption.weight(.medium))
                    }
                    .buttonStyle(.plain)
                    .foregroundStyle(.secondary)
                    .help("Clear download history. Downloaded files are kept.")
                }
                .padding(.horizontal, 20)
                .frame(height: headerHeight)

                ScrollView {
                    LazyVStack(spacing: 0) {
                        ForEach(items) { item in
                            HistoryRowView(
                                item: item,
                                isKeyboardSelected: selectedItemID == item.id,
                                copySucceeded: copiedItemID == item.id,
                                suppressHoverHighlight: suppressHoverHighlight,
                                onCopy: { onCopy(item) },
                                onMarkCopied: { onMarkCopied(item.id) },
                                onReveal: { onReveal(item) },
                                onOpenSource: { onOpenSource(item) },
                                onDelete: { onDelete(item) },
                                onEdit: { onEdit(item) },
                                onHoverChange: { isHovering in
                                    if isHovering {
                                        onHoverItem(item.id)
                                    }
                                }
                            )
                            .id(item.id)
                        }
                    }
                    .padding(.horizontal, 12)
                    .padding(.vertical, 10)
                }
                .scrollIndicators(.hidden)
                .onChange(of: selectedIndex) { _, index in
                    scrollIfNeeded(to: index, proxy: proxy)
                }
                .onChange(of: items.count) { _, _ in
                    viewport.clamp(itemCount: items.count)
                }

                Rectangle()
                    .fill(.clear)
                    .frame(height: 14)
                    .overlay {
                        Capsule()
                            .fill(Color.primary.opacity(0.16))
                            .frame(width: 34, height: 3)
                    }
                    .contentShape(Rectangle())
                    .gesture(resizeGesture)
            }
        }
        .frame(width: 680)
        .frame(height: displayHeight)
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 24, style: .continuous))
        .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .strokeBorder(.white.opacity(0.16), lineWidth: 1)
        }
        .shadow(color: .black.opacity(0.16), radius: 24, x: 0, y: 14)
    }

    private var idealHeight: CGFloat {
        let visibleCount = min(max(items.count, 1), 4)
        let cappedListAdjustment: CGFloat = items.count > 4 ? 4 : 0
        return headerHeight + CGFloat(visibleCount) * rowHeight + verticalPadding - cappedListAdjustment
    }

    private var displayHeight: CGFloat {
        min(max(height ?? idealHeight, minimumHeight), maximumHeight)
    }

    private var resizeGesture: some Gesture {
        DragGesture(minimumDistance: 0)
            .onChanged { value in
                if dragStartHeight == nil {
                    dragStartHeight = displayHeight
                }

                guard let dragStartHeight else { return }
                height = min(max(dragStartHeight + value.translation.height, minimumHeight), maximumHeight)
            }
            .onEnded { _ in
                dragStartHeight = nil
            }
    }

    private func scrollIfNeeded(to index: Int?, proxy: ScrollViewProxy) {
        guard let target = viewport.scrollTarget(for: index, itemCount: items.count),
              items.indices.contains(target.index) else {
            return
        }

        let anchorY = target.edge == .top ? rowTopAnchorY : rowBottomAnchorY
        proxy.scrollTo(items[target.index].id, anchor: UnitPoint(x: 0.5, y: anchorY))
    }

    private var rowTopAnchorY: CGFloat {
        10 / rowHeight
    }

    private var rowBottomAnchorY: CGFloat {
        1 - 10 / rowHeight
    }

}
