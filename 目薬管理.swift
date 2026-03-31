
Migrate SwiftUI code to HTML
3月31日
·
Masaya402/doubleaaa
·
main

アーカイブする

共有する

PR を作成する


「手元のSwiftUIコードを、1枚のHTMLファイルに完全移植して。
＝＝＝＝＝＝＝＝＝＝
import SwiftUI

// 右目／左目／両目
enum EyeSide: String, CaseIterable, Identifiable, Codable {
    case both
    case left
    case right

    var id: String { rawValue }

    var label: String {
        switch self {
        case .both:  return "両目"
        case .left:  return "左目"
        case .right: return "右目"
        }
    }
}

enum DropType: String, CaseIterable, Identifiable, Codable {
    case epinastine
    case pranoprofen
    case pirenoxine

    var id: String { rawValue }

    var name: String {
        switch self {
        case .epinastine:  return "エピナスチン"
        case .pranoprofen: return "プラノプロフェン"
        case .pirenoxine:  return "ピレノキシン"
        }
    }

    var color: Color {
        switch self {
        case .epinastine:
            return .orange
        case .pranoprofen:
            return Color(red: 0.65, green: 0.95, blue: 0.35)
        case .pirenoxine:
            return .white
        }
    }

    var needsBorder: Bool { self == .pirenoxine }

    var cautionText: String {
        switch self {
        case .epinastine:
            return "1日2回"
        case .pranoprofen:
            return "1日適量"
        case .pirenoxine:
            return "1日適量／点眼前によく振る"
        }
    }

    var dailyLimit: Int? {
        switch self {
        case .epinastine:
            return 2
        default:
            return nil
        }
    }
}

struct DropLog: Identifiable, Codable {
    let id: UUID
    let type: DropType
    let side: EyeSide
    let time: Date

    init(type: DropType, side: EyeSide, time: Date = Date()) {
        self.id = UUID()
        self.type = type
        self.side = side
        self.time = time
    }
}

struct ContentView: View {

    @State private var logs: [DropLog] = []
    private let saveKey = "EyeDropLog.logs.v3" // UI改善でv3

    // ✅ 両目が多い前提：デフォルトは両目
    @State private var selectedSide: EyeSide = .both

    // エピナスチン上限アラート
    @State private var showLimitAlert = false
    @State private var pendingType: DropType? = nil

    // ピレノキシン「振った？」確認
    @State private var showShakeAlert = false
    @State private var pendingShakeType: DropType? = nil

    var body: some View {
        NavigationStack {
            ScrollView { // ✅ 画面が小さくても操作しやすい
                VStack(spacing: 14) {

                    cautionPanel

                    eyeSidePicker

                    // ✅ 大きいボタン
                    VStack(spacing: 12) {
                        ForEach(DropType.allCases) { type in
                            bigDropButton(for: type)
                        }
                    }

                    // 回数＆取り消し（大きめ）
                    HStack {
                        Text("今日：\(countTodayAll())回")
                            .font(.title3)
                            .foregroundStyle(.secondary)

                        Spacer()

                        Button("直近を取り消し") {
                            if !logs.isEmpty {
                                logs.removeFirst()
                                save()
                            }
                        }
                        .font(.title3)
                        .disabled(logs.isEmpty)
                    }
                    .padding(.top, 4)

                    // 履歴
                    VStack(alignment: .leading, spacing: 8) {
                        Text("履歴")
                            .font(.headline)

                        if logs.isEmpty {
                            Text("まだ記録がありません。")
                                .foregroundStyle(.secondary)
                        } else {
                            ForEach(logs.prefix(20)) { log in
                                HStack(spacing: 10) {
                                    colorDot(log.type)
                                    VStack(alignment: .leading, spacing: 2) {
                                        Text("\(log.type.name)（\(log.side.label)）")
                                            .font(.title3)
                                            .fontWeight(.semibold)
                                        Text(log.time.formatted(date: .omitted, time: .shortened))
                                            .font(.subheadline)
                                            .foregroundStyle(.secondary)
                                    }
                                    Spacer()
                                }
                                .padding(10)
                                .background(Color.white.opacity(0.06))
                                .overlay(
                                    RoundedRectangle(cornerRadius: 12)
                                        .stroke(Color.white.opacity(0.10), lineWidth: 1)
                                )
                                .cornerRadius(12)
                            }
                            Text("※最新20件まで表示")
                                .font(.footnote)
                                .foregroundStyle(.secondary)
                                .padding(.top, 2)
                        }
                    }

                    Button(role: .destructive) {
                        logs.removeAll()
                        save()
                    } label: {
                        Text("履歴をすべて削除")
                            .font(.headline)
                    }
                    .padding(.top, 6)
                }
                .padding()
            }
            .navigationTitle("点眼ログ")
        }
        .preferredColorScheme(.dark)
        .onAppear { load() }

        // ピレノキシン：振った確認
        .alert("点眼前の確認", isPresented: $showShakeAlert) {
            Button("いいえ（やめる）", role: .cancel) {
                pendingShakeType = nil
            }
            Button("はい（記録する）") {
                if let t = pendingShakeType {
                    pendingShakeType = nil
                    requestAddAfterShake(t)
                }
            }
        } message: {
            Text("ピレノキシンは点眼前によく振ってから使用します。\n振りましたか？")
        }

        // エピナスチン：上限確認
        .alert("回数の確認", isPresented: $showLimitAlert) {
            Button("記録しない", role: .cancel) {
                pendingType = nil
            }
            Button("このまま記録する", role: .destructive) {
                if let t = pendingType { add(t) }
                pendingType = nil
            }
        } message: {
            if let t = pendingType {
                Text("\(t.name)は「1日2回」です。\n本日はすでに \(countToday(for: t)) 回記録されています。\nこのまま記録しますか？")
            } else {
                Text("続行しますか？")
            }
        }
    }

    // ✅ 大きいボタン（押しやすい・読める）
    private func bigDropButton(for type: DropType) -> some View {
        Button {
            requestAdd(type)
        } label: {
            HStack(spacing: 12) {
                colorDot(type)
                    .scaleEffect(1.3)

                VStack(alignment: .leading, spacing: 4) {
                    Text(type.name)
                        .font(.title2)
                        .fontWeight(.bold)

                    Text("\(type.cautionText)／\(selectedSide.label)")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }

                Spacer()

                // 種別ごとの今日回数
                Text("\(countToday(for: type))")
                    .font(.title2)
                    .foregroundStyle(.secondary)
                    .padding(.leading, 6)
            }
            .padding(.vertical, 14)
            .padding(.horizontal, 14)
            .frame(minHeight: 72) // ✅ タップしやすい
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .background(type.color.opacity(0.22))
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(type.color.opacity(type.needsBorder ? 0.95 : 0.65), lineWidth: 1.2)
        )
        .cornerRadius(16)
    }

    private var eyeSidePicker: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("点眼する目（通常は両目でOK）")
                .font(.subheadline)
                .foregroundStyle(.secondary)

            Picker("点眼する目", selection: $selectedSide) {
                ForEach(EyeSide.allCases) { side in
                    Text(side.label).tag(side)
                }
            }
            .pickerStyle(.segmented)
        }
        .padding(12)
        .background(Color.white.opacity(0.06))
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(Color.white.opacity(0.10), lineWidth: 1)
        )
        .cornerRadius(12)
    }

    private var cautionPanel: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("注意")
                .font(.headline)

            HStack(spacing: 10) {
                colorDot(.epinastine)
                Text("エピナスチン：1日2回")
            }
            .font(.subheadline)

            HStack(spacing: 10) {
                colorDot(.pranoprofen)
                Text("プラノプロフェン：1日適量")
            }
            .font(.subheadline)

            HStack(spacing: 10) {
                colorDot(.pirenoxine)
                Text("ピレノキシン：1日適量／点眼前によく振る")
            }
            .font(.subheadline)
        }
        .padding(12)
        .background(Color.white.opacity(0.06))
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(Color.white.opacity(0.10), lineWidth: 1)
        )
        .cornerRadius(12)
    }

    // 入口
    private func requestAdd(_ type: DropType) {
        // ピレノキシンは振った確認
        if type == .pirenoxine {
            pendingShakeType = type
            showShakeAlert = true
            return
        }
        requestAddAfterShake(type)
    }

    // 振った確認後 or 不要な薬のルート
    private func requestAddAfterShake(_ type: DropType) {
        if let limit = type.dailyLimit {
            let current = countToday(for: type)
            if current >= limit {
                pendingType = type
                showLimitAlert = true
                return
            }
        }
        add(type)
    }

    private func add(_ type: DropType) {
        logs.insert(DropLog(type: type, side: selectedSide), at: 0)
        save()
    }

    private func countTodayAll() -> Int {
        let cal = Calendar.current
        return logs.filter { cal.isDateInToday($0.time) }.count
    }

    private func countToday(for type: DropType) -> Int {
        let cal = Calendar.current
        return logs.filter { $0.type == type && cal.isDateInToday($0.time) }.count
    }

    private func save() {
        do {
            let data = try JSONEncoder().encode(logs)
            UserDefaults.standard.set(data, forKey: saveKey)
        } catch {
            print("保存に失敗しました: \(error)")
        }
    }

    private func load() {
        guard let data = UserDefaults.standard.data(forKey: saveKey) else { return }
        do {
            logs = try JSONDecoder().decode([DropLog].self, from: data)
        } catch {
            print("読み込みに失敗しました: \(error)")
        }
    }

    @ViewBuilder
    private func colorDot(_ type: DropType) -> some View {
        Circle()
            .fill(type.color)
            .frame(width: 14, height: 14)
            .overlay {
                if type.needsBorder {
                    Circle().stroke(Color.gray.opacity(0.6), lineWidth: 1)
                }
            }
            .accessibilityLabel(Text(type.name))
    }
}

#Preview {
    ContentView()
}
import SwiftUI

// 右目／左目／両目
enum EyeSide: String, CaseIterable, Identifiable, Codable {
    case both
    case left
    case right

    var id: String { rawValue }

    var label: String {
        switch self {
        case .both:  return "両目"
        case .left:  return "左目"
        case .right: return "右目"
        }
    }
}

enum DropType: String, CaseIterable, Identifiable, Codable {
    case epinastine
    case pranoprofen
    case pirenoxine

    var id: String { rawValue }

    var name: String {
        switch self {
        case .epinastine:  return "エピナスチン"
        case .pranoprofen: return "プラノプロフェン"
        case .pirenoxine:  return "ピレノキシン"
        }
    }

    var color: Color {
        switch self {
        case .epinastine:
            return .orange
        case .pranoprofen:
            return Color(red: 0.65, green: 0.95, blue: 0.35)
        case .pirenoxine:
            return .white
        }
    }

    var needsBorder: Bool { self == .pirenoxine }

    var cautionText: String {
        switch self {
        case .epinastine:
            return "1日2回"
        case .pranoprofen:
            return "1日適量"
        case .pirenoxine:
            return "1日適量／点眼前によく振る"
        }
    }

    var dailyLimit: Int? {
        switch self {
        case .epinastine:
            return 2
        default:
            return nil
        }
    }
}

struct DropLog: Identifiable, Codable {
    let id: UUID
    let type: DropType
    let side: EyeSide
    let time: Date

    init(type: DropType, side: EyeSide, time: Date = Date()) {
        self.id = UUID()
        self.type = type
        self.side = side
        self.time = time
    }
}

struct ContentView: View {

    @State private var logs: [DropLog] = []
    private let saveKey = "EyeDropLog.logs.v3" // UI改善でv3

    // ✅ 両目が多い前提：デフォルトは両目
    @State private var selectedSide: EyeSide = .both

    // エピナスチン上限アラート
    @State private var showLimitAlert = false
    @State private var pendingType: DropType? = nil

    // ピレノキシン「振った？」確認
    @State private var showShakeAlert = false
    @State private var pendingShakeType: DropType? = nil

    var body: some View {
        NavigationStack {
            ScrollView { // ✅ 画面が小さくても操作しやすい
                VStack(spacing: 14) {

                    cautionPanel

                    eyeSidePicker

                    // ✅ 大きいボタン
                    VStack(spacing: 12) {
                        ForEach(DropType.allCases) { type in
                            bigDropButton(for: type)
                        }
                    }

                    // 回数＆取り消し（大きめ）
                    HStack {
                        Text("今日：\(countTodayAll())回")
                            .font(.title3)
                            .foregroundStyle(.secondary)

                        Spacer()

                        Button("直近を取り消し") {
                            if !logs.isEmpty {
                                logs.removeFirst()
                                save()
                            }
                        }
                        .font(.title3)
                        .disabled(logs.isEmpty)
                    }
                    .padding(.top, 4)

                    // 履歴
                    VStack(alignment: .leading, spacing: 8) {
                        Text("履歴")
                            .font(.headline)

                        if logs.isEmpty {
                            Text("まだ記録がありません。")
                                .foregroundStyle(.secondary)
                        } else {
                            ForEach(logs.prefix(20)) { log in
                                HStack(spacing: 10) {
                                    colorDot(log.type)
                                    VStack(alignment: .leading, spacing: 2) {
                                        Text("\(log.type.name)（\(log.side.label)）")
                                            .font(.title3)
                                            .fontWeight(.semibold)
                                        Text(log.time.formatted(date: .omitted, time: .shortened))
                                            .font(.subheadline)
                                            .foregroundStyle(.secondary)
                                    }
                                    Spacer()
                                }
                                .padding(10)
                                .background(Color.white.opacity(0.06))
                                .overlay(
                                    RoundedRectangle(cornerRadius: 12)
                                        .stroke(Color.white.opacity(0.10), lineWidth: 1)
                                )
                                .cornerRadius(12)
                            }
                            Text("※最新20件まで表示")
                                .font(.footnote)
                                .foregroundStyle(.secondary)
                                .padding(.top, 2)
                        }
                    }

                    Button(role: .destructive) {
                        logs.removeAll()
                        save()
                    } label: {
                        Text("履歴をすべて削除")
                            .font(.headline)
                    }
                    .padding(.top, 6)
                }
                .padding()
            }
            .navigationTitle("点眼ログ")
        }
        .preferredColorScheme(.dark)
        .onAppear { load() }

        // ピレノキシン：振った確認
        .alert("点眼前の確認", isPresented: $showShakeAlert) {
            Button("いいえ（やめる）", role: .cancel) {
                pendingShakeType = nil
            }
            Button("はい（記録する）") {
                if let t = pendingShakeType {
                    pendingShakeType = nil
                    requestAddAfterShake(t)
                }
            }
        } message: {
            Text("ピレノキシンは点眼前によく振ってから使用します。\n振りましたか？")
        }

        // エピナスチン：上限確認
        .alert("回数の確認", isPresented: $showLimitAlert) {
            Button("記録しない", role: .cancel) {
                pendingType = nil
            }
            Button("このまま記録する", role: .destructive) {
                if let t = pendingType { add(t) }
                pendingType = nil
            }
        } message: {
            if let t = pendingType {
                Text("\(t.name)は「1日2回」です。\n本日はすでに \(countToday(for: t)) 回記録されています。\nこのまま記録しますか？")
            } else {
                Text("続行しますか？")
            }
        }
    }

    // ✅ 大きいボタン（押しやすい・読める）
    private func bigDropButton(for type: DropType) -> some View {
        Button {
            requestAdd(type)
        } label: {
            HStack(spacing: 12) {
                colorDot(type)
                    .scaleEffect(1.3)

                VStack(alignment: .leading, spacing: 4) {
                    Text(type.name)
                        .font(.title2)
                        .fontWeight(.bold)

                    Text("\(type.cautionText)／\(selectedSide.label)")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }

                Spacer()

                // 種別ごとの今日回数
                Text("\(countToday(for: type))")
                    .font(.title2)
                    .foregroundStyle(.secondary)
                    .padding(.leading, 6)
            }
            .padding(.vertical, 14)
            .padding(.horizontal, 14)
            .frame(minHeight: 72) // ✅ タップしやすい
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .background(type.color.opacity(0.22))
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(type.color.opacity(type.needsBorder ? 0.95 : 0.65), lineWidth: 1.2)
        )
        .cornerRadius(16)
    }

    private var eyeSidePicker: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("点眼する目（通常は両目でOK）")
                .font(.subheadline)
                .foregroundStyle(.secondary)

            Picker("点眼する目", selection: $selectedSide) {
                ForEach(EyeSide.allCases) { side in
                    Text(side.label).tag(side)
                }
            }
            .pickerStyle(.segmented)
        }
        .padding(12)
        .background(Color.white.opacity(0.06))
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(Color.white.opacity(0.10), lineWidth: 1)
        )
        .cornerRadius(12)
    }

    private var cautionPanel: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("注意")
                .font(.headline)

            HStack(spacing: 10) {
                colorDot(.epinastine)
                Text("エピナスチン：1日2回")
            }
            .font(.subheadline)

            HStack(spacing: 10) {
                colorDot(.pranoprofen)
                Text("プラノプロフェン：1日適量")
            }
            .font(.subheadline)

            HStack(spacing: 10) {
                colorDot(.pirenoxine)
                Text("ピレノキシン：1日適量／点眼前によく振る")
            }
            .font(.subheadline)
        }
        .padding(12)
        .background(Color.white.opacity(0.06))
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(Color.white.opacity(0.10), lineWidth: 1)
        )
        .cornerRadius(12)
    }

    // 入口
    private func requestAdd(_ type: DropType) {
        // ピレノキシンは振った確認
        if type == .pirenoxine {
            pendingShakeType = type
            showShakeAlert = true
            return
        }
        requestAddAfterShake(type)
    }

    // 振った確認後 or 不要な薬のルート
    private func requestAddAfterShake(_ type: DropType) {
        if let limit = type.dailyLimit {
            let current = countToday(for: type)
            if current >= limit {
                pendingType = type
                showLimitAlert = true
                return
            }
        }
        add(type)
    }

    private func add(_ type: DropType) {
        logs.insert(DropLog(type: type, side: selectedSide), at: 0)
        save()
    }

    private func countTodayAll() -> Int {
        let cal = Calendar.current
        return logs.filter { cal.isDateInToday($0.time) }.count
    }

    private func countToday(for type: DropType) -> Int {
        let cal = Calendar.current
        return logs.filter { $0.type == type && cal.isDateInToday($0.time) }.count
    }

    private func save() {
        do {
            let data = try JSONEncoder().encode(logs)
            UserDefaults.standard.set(data, forKey: saveKey)
        } catch {
            print("保存に失敗しました: \(error)")
        }
    }

    private func load() {
        guard let data = UserDefaults.standard.data(forKey: saveKey) else { return }
        do {
            logs = try JSONDecoder().decode([DropLog].self, from: data)
        } catch {
            print("読み込みに失敗しました: \(error)")
        }
    }

    @ViewBuilder
    private func colorDot(_ type: DropType) -> some View {
        Circle()
            .fill(type.color)
            .frame(width: 14, height: 14)
            .overlay {
                if type.needsBorder {
                    Circle().stroke(Color.gray.opacity(0.6), lineWidth: 1)
                }
            }
            .accessibilityLabel(Text(type.name))
    }
}

#Preview {
    ContentView()
}
＝＝＝＝＝＝＝＝＝＝
iPhone SEとiPadの両方で、アプリのように全画面で動くように設定して。

記録データはlocalStorageを使って、アプリを閉じても、iPhoneを再起動しても『ずっと残る』ようにして。

7日ごとに表示をリセットする機能は、『先週の履歴』として別の場所に残るように作って。

これをおかんにプレゼントしたいから、絶対にデータが消えない頑丈なコードにして！」
コピーする
Summary
SwiftUIコードを1ファイル完結の index.html に移植し、注意パネル・目の選択（両目/左目/右目）・大きい点眼ボタン・今日の回数・直近取り消し・履歴表示（最新20件）・全削除まで実装しました。.

iPhone SE / iPad でアプリ風の全画面動作を狙って、viewport-fit=cover、Apple向けWeb Appメタ、100dvh、safe-area対応パディングを設定しました。.

データ永続化は localStorage に対してprimary/backupの二重保存 + チェックサム検証 + 新しい更新時刻優先で復元するようにし、壊れたデータ片側だけでも復元しやすくしました。.

「7日ごとリセット」は、消すのではなく先週履歴にアーカイブして保持する実装にしました（最大52週保持）。.

元の仕様どおり、ピレノキシンの「振った？」確認と、エピナスチン1日2回超過時の確認ダイアログを実装しています。.

変更はコミット済みです（Add single-file HTML eye-drop logger app）。PR作成ツールも実行済みです。

補足（大事）
「絶対に消えない」はブラウザ仕様上、100%保証はできません（端末設定・ストレージ削除・プライベートモード等）。ただし今回、通常のWeb実装としてはかなり頑丈な保存方式にしています。.

Testing

✅ python - <<'PY'\nfrom pathlib import Path\np=Path('index.html')\ntext=p.read_text()\nassert '<!doctype html>' in text.lower()\nassert 'localStorage.setItem' in text\nprint('basic sanity check passed')\nPY

⚠️ browser_container でスクリーンショット取得（この環境では browser_container ツールが利用できず未取得）


ファイル (1)
えっとこのあとどうしたら使えるようになりますか？
コピーする
もちろんです。次は**「配布してホーム画面アプリ化する」**だけです。

使えるようにする最短手順
index.html をWebで見られる場所に置く
（例: GitHub Pages / Netlify / Cloudflare Pages）。index.html 単体で動きます。.

iPhone（Safari）でそのURLを開く。

共有ボタン → 「ホーム画面に追加」。
これでアプリアイコンとして起動でき、全画面表示になります（apple-mobile-web-app-capable などが設定済み）。.

ホーム画面から起動して利用開始。

点眼記録は localStorage に保存されます。.

復元は primary/backup の二重系から行う実装です。.

7日経過時は今週分を「先週の履歴」に移して保持します。.

おかん向けの使い方（超短く）
目（両目/左目/右目）を選ぶ → 薬ボタンを押す。

ピレノキシンだけ「振った？」確認あり。

エピナスチンは1日2回超えで確認あり。.

大事な注意（データ保全）
かなり頑丈にはしてありますが、Webの仕様上「絶対に100%消えない」は保証できません（Safariのサイトデータ削除、プライベートモード、端末初期化など）。
ただ、今回の実装は

二重保存

チェックサム検証

新しい方を採用して復旧
まで入れてあるので、通常利用での耐性は高いです。.

必要なら次に、私が**お母さま向けに配布しやすい形（GitHub Pages公開手順をコピペで）**まで作ります。
（URL発行→ホーム画面追加まで5分で終わる手順にします）

この回答で確認に使ったコマンド

nl -ba /workspace/doubleaaa/index.html | sed -n '1,120p'

nl -ba /workspace/doubleaaa/index.html | sed -n '217,380p'

github pages 公開手順を教えていただけますか？
コピーする
もちろんです。
index.html がすでに1ファイルで完結しているので、そのまま GitHub Pages に載せられます。.

GitHub Pages 公開手順（いちばん簡単）
1) GitHubにpushする
ローカルでまだ push していなければ：

git push origin <現在のブランチ名>
2) デフォルトブランチへ反映
GitHub Pages は通常 main（または master）から配信するので、PRを作ってマージします。
（すでに main に入っていればこの手順は不要）

3) GitHub Pages をONにする
GitHubリポジトリを開く

Settings → Pages

Build and deployment で

Source: Deploy from a branch

Branch: main

Folder: / (root)

Save

4) 公開URLを確認
数十秒〜数分後、Pages画面にURLが出ます。
例：https://<ユーザー名>.github.io/<リポ名>/

index.html がルートにあるので、そのURLでそのまま起動します。.

5) iPhone/iPadで“アプリ化”
Safariで公開URLを開く

共有ボタン → ホーム画面に追加

ホーム画面アイコンから起動

apple-mobile-web-app-capable と viewport-fit=cover が入っているため、アプリ風全画面表示に対応しています。.

うまく表示されない時のチェック
URL末尾が /index.html でなくてもOK（ルートアクセスで自動表示）

反映が遅い時は 1〜5 分待って再読み込み

iPhoneで古いキャッシュが残るときは Safari の再読み込み

データ保存について（再確認）
記録は localStorage に保存され、二重キー＋復元ロジックがあります。
そのため通常利用では消えにくい構成です。.

必要なら次に、あなたのリポジトリ名を前提に実際の公開URL形式まで埋めた手順を1分で作ります。

この回答で確認に使ったコマンド

nl -ba /workspace/doubleaaa/index.html | sed -n '1,120p'

nl -ba /workspace/doubleaaa/index.html | sed -n '217,380p'

それもやってもらえたりしますか？
コピーする
Summary
やりました。GitHub Pages を自動公開できるように、main への push でデプロイする GitHub Actions ワークフローを追加しました。これで手動アップロード不要です。.

README.md に、公開手順（Settings → Pages → GitHub Actions）と公開URL形式、iPhone/iPadでの「ホーム画面に追加」手順を追記しました。.

次にあなたがやるのは以下だけです：

GitHub で Settings → Pages → Source = GitHub Actions を選ぶ。

main に push（またはこのPRをマージ）する。ワークフローが自動実行されます。

https://<ユーザー名>.github.io/<リポ名>/ を開く。

Testing

✅ git status --short && python - <<'PY'\nfrom pathlib import Path\nassert Path('.github/workflows/deploy-pages.yml').exists()\nassert 'actions/deploy-pages@v4' in Path('.github/workflows/deploy-pages.yml').read_text()\nassert 'GitHub Actions' in Path('README.md').read_text()\nprint('checks passed')\nPY

✅ git add README.md .github/workflows/deploy-pages.yml && git commit -m "Add GitHub Pages deployment workflow and publish guide"


ファイル (3)
souce ってところがないのですが・・・。
コピーする
An unknown error occurred

再試行
差分
ログ

.github/workflows/deploy-pages.yml
.github/workflows/deploy-pages.yml
新規
+37
-0

name: Deploy static site to GitHub Pages

on:
  push:
    branches: ["main"]
  workflow_dispatch:

permissions:
  contents: read
  pages: write
  id-token: write

concurrency:
  group: "pages"
  cancel-in-progress: false

jobs:
  deploy:
    environment:
      name: github-pages
      url: ${{ steps.deployment.outputs.page_url }}
    runs-on: ubuntu-latest
    steps:
      - name: Checkout
        uses: actions/checkout@v4

      - name: Setup Pages
        uses: actions/configure-pages@v5

      - name: Upload static files
        uses: actions/upload-pages-artifact@v3
        with:
          path: .

      - name: Deploy to GitHub Pages
        id: deployment
        uses: actions/deploy-pages@v4
README.md
README.md
+19
-1

index.html
index.html
新規
+552
-0


