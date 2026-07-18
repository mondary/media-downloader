import SwiftUI

struct ActiveDownloadView: View {
    let progress: DownloadProgress

    var body: some View {
        ZStack(alignment: .leading) {
            RoundedRectangle(cornerRadius: 22, style: .continuous)
                .fill(.ultraThinMaterial)

            GeometryReader { geometry in
                RoundedRectangle(cornerRadius: 22, style: .continuous)
                    .fill(Color.accentColor.opacity(0.2))
                    .frame(width: geometry.size.width * (progress.fractionCompleted ?? 0))
            }

            HStack(spacing: 14) {
                thumbnail

                VStack(alignment: .leading, spacing: 5) {
                    Text(progress.playlistPosition ?? "Downloading video")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(.secondary)

                    Text(progress.title)
                        .font(.headline)
                        .lineLimit(1)

                    Text(progress.sourceURL)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                }

                Spacer(minLength: 12)

                Text(progress.progressLabel)
                    .font(.title3.monospacedDigit().weight(.semibold))
                    .foregroundStyle(.primary)
            }
            .padding(12)
        }
        .frame(width: 680, height: 88)
        .clipShape(RoundedRectangle(cornerRadius: 22, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 22, style: .continuous)
                .strokeBorder(.white.opacity(0.16), lineWidth: 1)
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Downloading \(progress.title), \(progress.progressLabel)")
    }

    @ViewBuilder
    private var thumbnail: some View {
        if let thumbnailURL = progress.thumbnailURL {
            AsyncImage(url: thumbnailURL) { image in
                image.resizable().scaledToFill()
            } placeholder: {
                placeholderThumbnail
            }
            .frame(width: 96, height: 64)
            .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
        } else {
            placeholderThumbnail
        }
    }

    private var placeholderThumbnail: some View {
        Image(systemName: "play.rectangle.fill")
            .font(.title2)
            .foregroundStyle(.secondary)
            .frame(width: 96, height: 64)
            .background(.black.opacity(0.12), in: RoundedRectangle(cornerRadius: 12, style: .continuous))
    }
}
