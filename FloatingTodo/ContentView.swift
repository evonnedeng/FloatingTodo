import SwiftUI

struct FloatingRootView: View {

    var onExpandedChanged: (Bool) -> Void

    @State private var isExpanded = false

    var body: some View {

        ZStack {

            if isExpanded {

                TodoPanel {
                    collapse()
                }

                .transition(
                    .scale(
                        scale: 0.92,
                        anchor: .topTrailing
                    )
                    .combined(with: .opacity)
                )

            } else {

                FloatingDot {
                    expand()
                }

                .transition(
                    .scale
                    .combined(with: .opacity)
                )
            }
        }
        .frame(
            maxWidth: .infinity,
            maxHeight: .infinity
        )
        .animation(
            .spring(
                response: 0.3,
                dampingFraction: 0.82
            ),
            value: isExpanded
        )
    }

    private func expand() {

        onExpandedChanged(true)

        withAnimation {
            isExpanded = true
        }
    }

    private func collapse() {

        withAnimation {
            isExpanded = false
        }

        DispatchQueue.main.asyncAfter(
            deadline: .now() + 0.08
        ) {
            onExpandedChanged(false)
        }
    }
}


// MARK: - Floating Dot

struct FloatingDot: View {

    var action: () -> Void

    @State private var hovering = false

    var body: some View {

        Button(action: action) {

            ZStack {

                Circle()
                    .fill(.regularMaterial)

                Circle()
                    .stroke(
                        Color.primary.opacity(0.12),
                        lineWidth: 1
                    )

                Circle()
                    .trim(from: 0, to: 0.68)
                    .stroke(
                        Color.green,
                        style: StrokeStyle(
                            lineWidth: 4,
                            lineCap: .round
                        )
                    )
                    .rotationEffect(.degrees(-90))

                Text("3")
                    .font(
                        .system(
                            size: 13,
                            weight: .bold
                        )
                    )
            }

            .frame(
                width: 46,
                height: 46
            )

            .scaleEffect(
                hovering ? 1.07 : 1
            )

            .shadow(
                color: .black.opacity(0.18),
                radius: 8,
                y: 3
            )
        }

        .buttonStyle(.plain)

        .onHover { inside in
            withAnimation(
                .easeOut(duration: 0.15)
            ) {
                hovering = inside
            }
        }
    }
}


// MARK: - Todo Panel

struct TodoPanel: View {

    var onCollapse: () -> Void

    var body: some View {

        VStack(
            alignment: .leading,
            spacing: 0
        ) {

            // HEADER

            HStack(
                alignment: .center,
                spacing: 14
            ) {

                ProgressCircle()

                VStack(
                    alignment: .leading,
                    spacing: 5
                ) {

                    Text("Good evening")
                        .font(
                            .system(
                                size: 23,
                                weight: .bold
                            )
                        )

                    Text("Friday, October 23")
                        .font(.system(size: 14))
                        .foregroundStyle(.secondary)

                    HStack(spacing: 12) {

                        Label(
                            "1-day streak",
                            systemImage: "flame.fill"
                        )

                        Label(
                            "2 done today",
                            systemImage: "checkmark.seal.fill"
                        )
                    }

                    .font(
                        .system(
                            size: 11,
                            weight: .semibold
                        )
                    )
                }


                Spacer()


                Button(action: onCollapse) {

                    Image(
                        systemName:
                            "chevron.down.circle.fill"
                    )

                    .font(.system(size: 22))

                    .foregroundStyle(
                        .secondary
                    )
                }

                .buttonStyle(.plain)
            }

            .padding(
                EdgeInsets(
                    top: 20,
                    leading: 20,
                    bottom: 18,
                    trailing: 20
                )
            )


            Text(
                "Past halfway — keep going."
            )

            .font(
                .system(
                    size: 14,
                    weight: .semibold
                )
            )

            .padding(.horizontal, 20)
            .padding(.bottom, 15)


            Divider()
                .opacity(0.4)


            // TASKS

            VStack(spacing: 9) {

                TaskRow(
                    title:
                        "Audit paper 1 report",
                    completed: true,
                    progress: "3/3"
                )


                TaskRow(
                    title:
                        "Paper 2 - h0 part notes",
                    completed: true,
                    progress: "2/2"
                )


                TaskRow(
                    title:
                        "Cosmology lecture notes",
                    completed: false,
                    progress: nil
                )
            }

            .padding(14)


            Spacer()


            Divider()
                .opacity(0.4)


            Button {

            } label: {

                HStack(spacing: 10) {

                    Image(
                        systemName:
                            "plus.circle.fill"
                    )

                    .font(.system(size: 21))

                    .foregroundStyle(
                        Color.green
                    )


                    Text("Add a main task")

                        .font(
                            .system(size: 15)
                        )

                        .foregroundStyle(
                            .secondary
                        )


                    Spacer()
                }

                .padding(.horizontal, 18)
                .padding(.vertical, 16)
            }

            .buttonStyle(.plain)
        }

        .frame(
            maxWidth: .infinity,
            maxHeight: .infinity
        )

        .background(.regularMaterial)

        .clipShape(
            RoundedRectangle(
                cornerRadius: 24,
                style: .continuous
            )
        )

        .overlay {

            RoundedRectangle(
                cornerRadius: 24,
                style: .continuous
            )

            .stroke(
                Color.primary.opacity(0.10),
                lineWidth: 1
            )
        }

        .padding(8)
    }
}


// MARK: - Progress Circle

struct ProgressCircle: View {

    var body: some View {

        ZStack {

            Circle()

                .stroke(
                    Color.secondary.opacity(0.15),
                    lineWidth: 6
                )


            Circle()

                .trim(
                    from: 0,
                    to: 0.68
                )

                .stroke(
                    Color.green,
                    style: StrokeStyle(
                        lineWidth: 6,
                        lineCap: .round
                    )
                )

                .rotationEffect(
                    .degrees(-90)
                )


            Text("68%")

                .font(
                    .system(
                        size: 14,
                        weight: .bold
                    )
                )
        }

        .frame(
            width: 68,
            height: 68
        )
    }
}


// MARK: - Task Row

struct TaskRow: View {

    let title: String

    let completed: Bool

    let progress: String?


    var body: some View {

        HStack(spacing: 11) {

            Image(
                systemName:
                    completed
                    ? "checkmark.circle.fill"
                    : "circle"
            )

            .font(.system(size: 21))

            .foregroundStyle(
                completed
                ? Color.green
                : Color.secondary
            )


            Text(title)

                .font(
                    .system(
                        size: 15,
                        weight: .medium
                    )
                )

                .strikethrough(
                    completed
                )

                .foregroundStyle(
                    completed
                    ? .secondary
                    : .primary
                )


            Spacer()


            if let progress {

                Text(progress)

                    .font(
                        .system(
                            size: 12,
                            weight: .bold
                        )
                    )

                    .foregroundStyle(
                        Color.green
                    )
            }


            Image(
                systemName:
                    "chevron.right"
            )

            .font(
                .system(
                    size: 11,
                    weight: .semibold
                )
            )

            .foregroundStyle(
                .tertiary
            )
        }

        .padding(.horizontal, 14)

        .frame(height: 56)

        .background {

            RoundedRectangle(
                cornerRadius: 14
            )

            .fill(
                Color.primary.opacity(
                    0.04
                )
            )
        }
    }
}
