import SwiftUI
import Combine


// MARK: - Theme

let themePink = Color(
    red: 0.95,
    green: 0.40,
    blue: 0.62
)


// MARK: - Category

enum TodoCategory: String, Codable, CaseIterable {
    case today = "Today"
    case work = "Work"
    case personal = "Personal"
}


// MARK: - Subtask

struct SubtaskItem: Identifiable, Codable {

    var id = UUID()
    var title: String
    var isCompleted: Bool = false
}


// MARK: - Main Task

struct TodoItem: Identifiable, Codable {

    var id = UUID()
    var title: String
    var category: TodoCategory

    var isCompleted: Bool = false
    var subtasks: [SubtaskItem] = []
    var isExpanded: Bool = false


    var completedSubtaskCount: Int {

        subtasks.filter {
            $0.isCompleted
        }.count
    }


    var progress: Double {

        if subtasks.isEmpty {
            return isCompleted ? 1.0 : 0.0
        }

        return Double(completedSubtaskCount)
            / Double(subtasks.count)
    }


    var isFullyCompleted: Bool {

        if subtasks.isEmpty {
            return isCompleted
        }

        return completedSubtaskCount == subtasks.count
    }
}


// MARK: - Store

final class TodoStore: ObservableObject {

    @Published var todos: [TodoItem] = [] {
        didSet {
            save()
        }
    }

    private let saveKey = "floatingTodoItemsV04"


    init() {
        load()
    }


    // MARK: Add Main Task

    func addTodo(
        _ title: String,
        category: TodoCategory
    ) {

        let cleanTitle = title.trimmingCharacters(
            in: .whitespacesAndNewlines
        )

        guard !cleanTitle.isEmpty else {
            return
        }

        todos.append(
            TodoItem(
                title: cleanTitle,
                category: category
            )
        )
    }


    // MARK: Delete Main Task

    func deleteTask(_ task: TodoItem) {

        todos.removeAll {
            $0.id == task.id
        }
    }


    // MARK: Toggle Main Task

    func toggleTask(_ task: TodoItem) {

        guard let index = todos.firstIndex(
            where: { $0.id == task.id }
        ) else {
            return
        }

        if todos[index].subtasks.isEmpty {

            todos[index].isCompleted.toggle()

        } else {

            let shouldComplete =
                !todos[index].isFullyCompleted

            for subIndex in todos[index].subtasks.indices {

                todos[index]
                    .subtasks[subIndex]
                    .isCompleted = shouldComplete
            }
        }
    }


    // MARK: Expand / Collapse

    func toggleExpanded(_ task: TodoItem) {

        guard let index = todos.firstIndex(
            where: { $0.id == task.id }
        ) else {
            return
        }

        todos[index].isExpanded.toggle()
    }


    // MARK: Add Subtask

    func addSubtask(
        _ title: String,
        to task: TodoItem
    ) {

        let cleanTitle = title.trimmingCharacters(
            in: .whitespacesAndNewlines
        )

        guard !cleanTitle.isEmpty else {
            return
        }

        guard let taskIndex = todos.firstIndex(
            where: { $0.id == task.id }
        ) else {
            return
        }

        todos[taskIndex].subtasks.append(
            SubtaskItem(
                title: cleanTitle
            )
        )

        todos[taskIndex].isExpanded = true
        todos[taskIndex].isCompleted = false
    }


    // MARK: Toggle Subtask

    func toggleSubtask(
        task: TodoItem,
        subtask: SubtaskItem
    ) {

        guard let taskIndex = todos.firstIndex(
            where: { $0.id == task.id }
        ) else {
            return
        }

        guard let subtaskIndex =
            todos[taskIndex]
                .subtasks
                .firstIndex(
                    where: {
                        $0.id == subtask.id
                    }
                )
        else {
            return
        }

        todos[taskIndex]
            .subtasks[subtaskIndex]
            .isCompleted
            .toggle()
    }


    // MARK: Delete Subtask

    func deleteSubtask(
        task: TodoItem,
        subtask: SubtaskItem
    ) {

        guard let taskIndex = todos.firstIndex(
            where: { $0.id == task.id }
        ) else {
            return
        }

        todos[taskIndex].subtasks.removeAll {
            $0.id == subtask.id
        }
    }


    // MARK: Save

    private func save() {

        guard let data =
            try? JSONEncoder().encode(todos)
        else {
            return
        }

        UserDefaults.standard.set(
            data,
            forKey: saveKey
        )
    }


    // MARK: Load

    private func load() {

        guard
            let data =
                UserDefaults.standard.data(
                    forKey: saveKey
                ),
            let savedTodos =
                try? JSONDecoder().decode(
                    [TodoItem].self,
                    from: data
                )
        else {
            return
        }

        todos = savedTodos
    }
}


// MARK: - Floating Root

struct FloatingRootView: View {

    @State private var isExpanded = false

    @StateObject private var store = TodoStore()

    let onExpandedChanged: (Bool) -> Void


    private var todayTasks: [TodoItem] {

        store.todos.filter {
            $0.category == .today
        }
    }


    private var todayProgress: Double {

        guard !todayTasks.isEmpty else {
            return 0
        }

        let totalProgress =
            todayTasks.reduce(0.0) {
                $0 + $1.progress
            }

        return totalProgress
            / Double(todayTasks.count)
    }


    var body: some View {

        Group {

            if isExpanded {

                TodoPanel(
                    store: store,
                    close: {

                        isExpanded = false
                        onExpandedChanged(false)
                    }
                )

            } else {

                FloatingDot(
                    progress: todayProgress
                ) {

                    isExpanded = true
                    onExpandedChanged(true)
                }
            }
        }
        .animation(
            .easeInOut(duration: 0.2),
            value: isExpanded
        )
    }
}


// MARK: - Collapsed Floating Circle

struct FloatingDot: View {

    let progress: Double
    let action: () -> Void


    var body: some View {

        Button(action: action) {

            ZStack {

                Circle()
                    .fill(Color.clear)

                Circle()
                    .stroke(
                        themePink.opacity(0.20),
                        lineWidth: 3
                    )

                Circle()
                    .trim(
                        from: 0,
                        to: progress
                    )
                    .stroke(
                        themePink,
                        style: StrokeStyle(
                            lineWidth: 3,
                            lineCap: .round
                        )
                    )
                    .rotationEffect(
                        .degrees(-90)
                    )

                Text(
                    "\(Int(progress * 100))%"
                )
                .font(
                    .system(
                        size: 9,
                        weight: .bold
                    )
                )
                .foregroundStyle(.primary)
            }
            .frame(
                width: 32,
                height: 32
            )
        }
        .buttonStyle(.plain)
        .frame(
            width: 40,
            height: 40
        )
    }
}


// MARK: - Todo Panel

struct TodoPanel: View {

    @ObservedObject var store: TodoStore

    let close: () -> Void

    @State private var selectedCategory:
        TodoCategory = .today

    @State private var newTaskTitle = ""

    @State private var isAddingMainTask = false


    private var visibleTasks: [TodoItem] {

        store.todos.filter {
            $0.category == selectedCategory
        }
    }


    private var todayTasks: [TodoItem] {

        store.todos.filter {
            $0.category == .today
        }
    }


    private var todayProgress: Double {

        guard !todayTasks.isEmpty else {
            return 0
        }

        let total =
            todayTasks.reduce(0.0) {
                $0 + $1.progress
            }

        return total
            / Double(todayTasks.count)
    }


    var body: some View {

        VStack(
            alignment: .leading,
            spacing: 13
        ) {

            header

            tabs

            taskList

            Spacer(minLength: 0)

            addMainTaskArea
        }
        .padding(16)
        .frame(
            maxWidth: .infinity,
            maxHeight: .infinity
        )
        .background(.ultraThinMaterial)
        .clipShape(
            RoundedRectangle(
                cornerRadius: 22,
                style: .continuous
            )
        )
    }


    // MARK: Header

    private var header: some View {

        HStack(spacing: 14) {

            LargeProgressCircle(
                progress: todayProgress
            )

            VStack(
                alignment: .leading,
                spacing: 4
            ) {

                Text(greeting)
                    .font(
                        .system(
                            size: 20,
                            weight: .bold
                        )
                    )

                Text(formattedDate)
                    .font(
                        .system(size: 12)
                    )
                    .foregroundStyle(.secondary)
            }

            Spacer()

            Button(action: close) {

                Image(
                    systemName: "xmark"
                )
                .font(
                    .system(
                        size: 10,
                        weight: .bold
                    )
                )
                .frame(
                    width: 24,
                    height: 24
                )
                .background(.thinMaterial)
                .clipShape(Circle())
            }
            .buttonStyle(.plain)
        }
    }


    // MARK: Tabs

    private var tabs: some View {

        HStack(spacing: 5) {

            ForEach(
                TodoCategory.allCases,
                id: \.self
            ) { category in

                Button {

                    selectedCategory = category

                } label: {

                    Text(category.rawValue)
                        .font(
                            .system(
                                size: 11,
                                weight:
                                    selectedCategory == category
                                    ? .semibold
                                    : .medium
                            )
                        )
                        .frame(
                            maxWidth: .infinity
                        )
                        .padding(
                            .vertical,
                            6
                        )
                        .background {

                            if selectedCategory == category {

                                RoundedRectangle(
                                    cornerRadius: 8
                                )
                                .fill(
                                    themePink.opacity(0.15)
                                )
                            }
                        }
                }
                .buttonStyle(.plain)
            }
        }
        .padding(3)
        .background(
            Color.primary.opacity(0.035)
        )
        .clipShape(
            RoundedRectangle(
                cornerRadius: 10
            )
        )
    }


    // MARK: Task List

    private var taskList: some View {

        ScrollView {

            LazyVStack(spacing: 9) {

                if visibleTasks.isEmpty {

                    Text("No tasks")
                        .font(.system(size: 12))
                        .foregroundStyle(.secondary)
                        .padding(.top, 24)

                } else {

                    ForEach(visibleTasks) { task in

                        MainTaskCard(
                            task: task,
                            store: store
                        )
                    }
                }
            }
        }
    }


    // MARK: Add Main Task

    @ViewBuilder
    private var addMainTaskArea: some View {

        if isAddingMainTask {

            HStack(spacing: 8) {

                // + stays as +

                Button {

                    addMainTask()

                } label: {

                    Image(
                        systemName: "plus"
                    )
                    .font(
                        .system(
                            size: 12,
                            weight: .bold
                        )
                    )
                    .foregroundStyle(.white)
                    .frame(
                        width: 28,
                        height: 28
                    )
                    .background(themePink)
                    .clipShape(Circle())
                }
                .buttonStyle(.plain)


                TextField(
                    "Add a main task...",
                    text: $newTaskTitle
                )
                .textFieldStyle(.plain)
                .font(.system(size: 12))
                .onSubmit {

                    addMainTask()
                }
            }
            .padding(.horizontal, 4)
            .frame(height: 34)

        } else {

            Button {

                isAddingMainTask = true

            } label: {

                HStack(spacing: 8) {

                    Image(
                        systemName: "plus"
                    )
                    .font(
                        .system(
                            size: 12,
                            weight: .bold
                        )
                    )
                    .foregroundStyle(.white)
                    .frame(
                        width: 28,
                        height: 28
                    )
                    .background(themePink)
                    .clipShape(Circle())

                    Text("Add a main task...")
                        .font(.system(size: 12))
                        .foregroundStyle(.secondary)

                    Spacer()
                }
            }
            .buttonStyle(.plain)
            .padding(.horizontal, 4)
            .frame(height: 34)
        }
    }


    private func addMainTask() {

        let cleanTitle =
            newTaskTitle.trimmingCharacters(
                in: .whitespacesAndNewlines
            )

        // First click on + only opens the field.
        // If nothing has been typed yet, do nothing.

        guard !cleanTitle.isEmpty else {
            isAddingMainTask = true
            return
        }

        store.addTodo(
            cleanTitle,
            category: selectedCategory
        )

        newTaskTitle = ""
        isAddingMainTask = false
    }


    // MARK: Greeting

    private var greeting: String {

        let hour =
            Calendar.current.component(
                .hour,
                from: Date()
            )

        switch hour {

        case 5..<12:
            return "Good morning"

        case 12..<18:
            return "Good afternoon"

        default:
            return "Good evening"
        }
    }


    // MARK: Date

    private var formattedDate: String {

        let formatter = DateFormatter()

        formatter.dateFormat =
            "EEEE, MMMM d"

        return formatter.string(
            from: Date()
        )
    }
}


// MARK: - Main Task Card

struct MainTaskCard: View {

    let task: TodoItem

    @ObservedObject var store: TodoStore

    @State private var newSubtask = ""

    @State private var isAddingSubtask = false


    var body: some View {

        VStack(
            alignment: .leading,
            spacing: 8
        ) {

            // MARK: Main Row

            HStack(spacing: 8) {

                // Expand

                Button {

                    store.toggleExpanded(task)

                } label: {

                    Image(
                        systemName:
                            task.isExpanded
                            ? "chevron.down"
                            : "chevron.right"
                    )
                    .font(
                        .system(
                            size: 11,
                            weight: .semibold
                        )
                    )
                    .foregroundStyle(.secondary)
                    .frame(width: 14)
                }
                .buttonStyle(.plain)


                // Complete

                Button {

                    store.toggleTask(task)

                } label: {

                    Image(
                        systemName:
                            task.isFullyCompleted
                            ? "checkmark.circle.fill"
                            : "circle"
                    )
                    .font(.system(size: 19))
                    .foregroundStyle(
                        task.isFullyCompleted
                        ? themePink
                        : Color.secondary
                    )
                }
                .buttonStyle(.plain)


                // Title

                Text(task.title)
                    .font(
                        .system(
                            size: 13,
                            weight: .semibold
                        )
                    )
                    .strikethrough(
                        task.isFullyCompleted
                    )
                    .foregroundStyle(
                        task.isFullyCompleted
                        ? Color.secondary
                        : Color.primary
                    )
                    .lineLimit(2)


                Spacer()


                // Counter

                if !task.subtasks.isEmpty {

                    Text(
                        "\(task.completedSubtaskCount)/\(task.subtasks.count)"
                    )
                    .font(
                        .system(
                            size: 11,
                            weight: .bold
                        )
                    )
                    .foregroundStyle(themePink)
                }


                // DELETE MAIN TASK

                Button {

                    store.deleteTask(task)

                } label: {

                    Image(
                        systemName: "trash"
                    )
                    .font(.system(size: 11))
                    .foregroundStyle(.secondary)
                }
                .buttonStyle(.plain)
            }


            // MARK: Progress Bar

            if !task.subtasks.isEmpty {

                GeometryReader { geometry in

                    ZStack(
                        alignment: .leading
                    ) {

                        Capsule()
                            .fill(
                                themePink.opacity(0.15)
                            )

                        Capsule()
                            .fill(themePink)
                            .frame(
                                width:
                                    geometry.size.width
                                    * task.progress
                            )
                    }
                }
                .frame(height: 4)
                .padding(.leading, 42)
            }


            // MARK: Expanded Subtasks

            if task.isExpanded {

                VStack(
                    alignment: .leading,
                    spacing: 7
                ) {

                    ForEach(task.subtasks) { subtask in

                        SubtaskRow(
                            subtask: subtask,
                            toggle: {

                                store.toggleSubtask(
                                    task: task,
                                    subtask: subtask
                                )
                            },
                            delete: {

                                store.deleteSubtask(
                                    task: task,
                                    subtask: subtask
                                )
                            }
                        )
                    }


                    // MARK: Add Subtask

                    if isAddingSubtask {

                        HStack(spacing: 8) {

                            // + stays as +

                            Button {

                                addSubtask()

                            } label: {

                                Image(
                                    systemName: "plus"
                                )
                                .font(
                                    .system(
                                        size: 12,
                                        weight: .semibold
                                    )
                                )
                                .foregroundStyle(themePink)
                            }
                            .buttonStyle(.plain)


                            TextField(
                                "Add a detailed step...",
                                text: $newSubtask
                            )
                            .textFieldStyle(.plain)
                            .font(.system(size: 12))
                            .onSubmit {

                                addSubtask()
                            }
                        }
                        .padding(.leading, 43)

                    } else {

                        Button {

                            isAddingSubtask = true

                        } label: {

                            HStack(spacing: 8) {

                                Image(
                                    systemName: "plus"
                                )
                                .font(
                                    .system(
                                        size: 12,
                                        weight: .semibold
                                    )
                                )

                                Text(
                                    "Add a detailed step..."
                                )
                                .font(
                                    .system(size: 12)
                                )

                                Spacer()
                            }
                            .foregroundStyle(.secondary)
                        }
                        .buttonStyle(.plain)
                        .padding(.leading, 43)
                    }
                }
            }
        }
        .padding(
            .horizontal,
            11
        )
        .padding(
            .vertical,
            10
        )
        .background(
            task.isFullyCompleted
            ? themePink.opacity(0.06)
            : Color.primary.opacity(0.035)
        )
        .overlay {

            RoundedRectangle(
                cornerRadius: 12
            )
            .stroke(
                task.isFullyCompleted
                ? themePink.opacity(0.45)
                : Color.clear,
                lineWidth: 1
            )
        }
        .clipShape(
            RoundedRectangle(
                cornerRadius: 12
            )
        )
    }


    private func addSubtask() {

        let cleanTitle =
            newSubtask.trimmingCharacters(
                in: .whitespacesAndNewlines
            )

        guard !cleanTitle.isEmpty else {
            isAddingSubtask = true
            return
        }

        store.addSubtask(
            cleanTitle,
            to: task
        )

        newSubtask = ""

        // Keep the input open so you can quickly add another one.
        isAddingSubtask = true
    }
}


// MARK: - Subtask Row

struct SubtaskRow: View {

    let subtask: SubtaskItem

    let toggle: () -> Void
    let delete: () -> Void


    var body: some View {

        HStack(spacing: 8) {

            // Complete

            Button(action: toggle) {

                Image(
                    systemName:
                        subtask.isCompleted
                        ? "checkmark.circle.fill"
                        : "circle"
                )
                .font(.system(size: 15))
                .foregroundStyle(
                    subtask.isCompleted
                    ? themePink
                    : Color.secondary
                )
            }
            .buttonStyle(.plain)


            // Title

            Text(subtask.title)
                .font(.system(size: 12))
                .strikethrough(
                    subtask.isCompleted
                )
                .foregroundStyle(
                    subtask.isCompleted
                    ? Color.secondary
                    : Color.primary
                )


            Spacer()


            // DELETE SUBTASK

            Button(action: delete) {

                Image(
                    systemName: "trash"
                )
                .font(.system(size: 10))
                .foregroundStyle(.secondary)
            }
            .buttonStyle(.plain)
        }
        .padding(.leading, 43)
    }
}


// MARK: - Large Today Progress

struct LargeProgressCircle: View {

    let progress: Double


    var body: some View {

        ZStack {

            Circle()
                .stroke(
                    themePink.opacity(0.16),
                    lineWidth: 7
                )

            Circle()
                .trim(
                    from: 0,
                    to: progress
                )
                .stroke(
                    themePink,
                    style: StrokeStyle(
                        lineWidth: 7,
                        lineCap: .round
                    )
                )
                .rotationEffect(
                    .degrees(-90)
                )

            Text(
                "\(Int(progress * 100))%"
            )
            .font(
                .system(
                    size: 14,
                    weight: .bold
                )
            )
        }
        .frame(
            width: 64,
            height: 64
        )
        .animation(
            .easeInOut(duration: 0.25),
            value: progress
        )
    }
}
