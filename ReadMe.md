# 📱 MobileBenchmark

**MobileBenchmark** is an open-source iOS benchmarking suite that lets developers measure key performance characteristics of a device and app runtime — including CPU computation, memory behavior, disk I/O, GPU throughput, network performance, frame rendering quality, and sustained performance under thermal load.

The goal of this project is to **provide reproducible, structured benchmarks for iOS devices** so you can understand performance, track regressions, and automate performance checks in your development workflow.

> Benchmarks like this are essential because mobile performance *directly impacts* user experience and satisfaction — from smooth animation to fast load times and responsive interactions.:contentReference[oaicite:0]{index=0}

---

## 🚀 Key Features

MobileBenchmark provides:

- 💪 **CPU Benchmark** – Measures compute throughput under a defined workload  
- 🧠 **Memory Benchmark** – Tests allocation and memory usage behavior  
- 💾 **Disk I/O Benchmark** – Writes and reads sizeable payloads to measure throughput  
- 📊 **GPU (Metal) Benchmark** – Runs a SAXPY compute shader to test GPU throughput  
- 📈 **FPS & Jank Analysis** – Tracks frame times and frame rate stability  
- 🌡 **Sustained & Thermal Benchmark** – Measures performance under sustained CPU load and samples device thermal state  
- 🌍 **Network Benchmark** – Measures download latency and throughput  
- 🧪 **Median-of-N CI Mode** – Runs multiple attempts and aggregates results for repeatable performance baselines  
- 📈 **Regression Testing** – Save baselines, compare new runs, and report pass/fail against thresholds  
- 📊 **Charts Support** – Visualize FPS histograms and performance trends

---

## 🧩 Typical Use Cases

- 📌 **Performance regression tracking** in CI/CD pipelines  
- 🔍 **Device capability comparison** across iPhone/iPad models  
- 📊 **Performance dashboards** for feature releases  
- 📱 **Developer insights** during optimization sprints

---

## 🧠 Why Benchmark Mobile Performance

Benchmarking goes beyond unit testing — it enables teams to **quantify performance metrics** like execution time, resource utilization, and responsiveness. These measurements are crucial when evaluating real-world behavior on devices (emulators/simulators often don’t reflect actual device performance).:contentReference[oaicite:1]{index=1}

---

## 🛠 Installation

**Requirements**

- Xcode 15+  
- iOS 16+ (device preferred for accurate measurements)  
- Swift 5.8+

Clone the repository:

```bash
git clone https://github.com/Mulla6518/MobileBenchmark.git
```

**Open the Xcode Package:**

```bash
open Package.swift
```
Build and run on your package.

**Open the Example Xcode project:**

```bash
cd Example
open Example.xcodeproj
```
Build and run on target device.

## 📦 Integrating MobileBenchmark Into Another Project/Package

MobileBenchmark can be used in two ways:

- **Option A (Recommended): Swift Package (SPM)** – reuse the benchmark engine inside your app
- **Option B: Importing MobileBenchmark into Another Swift Package** – Add MobileBenchmark as a Dependency

> Note: Device benchmarking should be run on real hardware for accurate results.

---

### ✅ Option A — Swift Package Manager (Recommended)

#### 1) Add the package in Xcode
1. In your app project, go to **File → Add Packages…**
2. Paste this URL: https://github.com/Mulla6518/MobileBenchmark
3. Select the product (e.g. `MobileBenchmark`) and add it to your app target.

#### 2) Import and run benchmarks
In your app code:

```swift
import MobileBenchmark

let suite = MobileBenchmarkSuite.default(profile: .ciBaseline)

Task {
 let results = await suite.run()
 print(results)
}
```

#### 2) (Optional) Export results
```swift
import MobileBenchmark

let exportDir = FileManager.default.temporaryDirectory
let jsonURL = exportDir.appendingPathComponent("bench.json")
let csvURL = exportDir.appendingPathComponent("bench.csv")

try ExportService.exportJSON(results: results, to: jsonURL)
try ExportService.exportCSV(results: results, to: csvURL)
```

### ⚡ Option B — Importing MobileBenchmark into Another Swift Package

Open Package.swift of your package and add MobileBenchmark as a dependency.

```swift
.package( url: "https://github.com/Mulla6518/MobileBenchmark.git", from: "1.0")
```

#### ✅ Key points:

* url → GitHub repo URL
* from: → semantic version tag (recommended)
* .product(name: "MobileBenchmark", …) → the library product, not the repo name

### Example: Running Benchmarks from Another Package
```swift
import Foundation
import MobileBenchmark

public struct PerformanceRunner {

    public init() {}

    public func runBenchmarks() async {
        let suite = MobileBenchmarkSuite.default(profile: .ciBaseline)
        let results = await suite.run()

        for r in results {
            print("\(r.name): \(r.metrics)")
        }
    }
}
```
This works in:

* another Swift package
* an app target that depends on your package
* CI tooling (as long as it runs on iOS device/simulator)

## Running Benchmarks

* Launch the app on your device
* Select configuration settings (iterations, payload sizes, network URL, etc.)
* Tap Run Benchmarks or CI Run
* Review results in the UI or export them (CSV/JSON)

## 📈 Benchmarking Modes
### 🧪 Normal Run

Runs each benchmark once and displays results.

### 🔁 CI Run (Median-of-N)

Executes the benchmark suite multiple times to compute median performance metrics for stability — suitable for automated regression testing.

## 📦 Output & Export

Results can be exported to:

### 📄 JSON for structured storage
### 📊 CSV for charting and spreadsheets

Use the share sheet to export results to Files or your preferred destination.

## 🧠 Interpreting Results

Each benchmark produces:

* Elapsed time (ms)
* Throughput (ops/sec, MB/s, FPS)
* Thermal sampling during sustained tests

Use the Charts UI to view FPS histograms or performance trends.

## 🤝 Contributing

Contributions are welcome! Feel free to:

* 🤖 Add new benchmarks (e.g., launch time, scroll jank, automated UI flows)
* 🧹 Improve existing metrics or UI
* 📄 Enhance documentation or examples
* ✅ Add test cases and CI integration

### ➕ Adding a New Benchmark

* Create a new file under:
```swift
Core/Benchmarks/
```
* Conform to the Benchmark protocol:
```swift
struct MyBenchmark: Benchmark {
    let name = "My Benchmark"
    let category: BenchmarkCategory = .cpu

    func run(context: BenchmarkContext) async throws -> BenchmarkResult {
        // benchmark logic
    }
}
```

* Add it to the benchmark suite in DashboardViewModel.
* Ensure results are:
    * Deterministic where possible
    * Clearly labeled
    * Meaningful on real devices


### 📊 Metrics Guidelines

* Prefer throughput and latency over raw scores
* Always include units
* Avoid “magic numbers” without explanation
* Document known sources of variance (thermal, network, power mode)

### 🔍 Code Style

* Follow Swift API Design Guidelines
* Use SwiftUI + MVVM for UI additions
* Keep benchmark logic isolated from UI
* Avoid blocking the main thread

### 🧪 Testing & Validation

Before submitting a PR:

* Run benchmarks on a real device
* Verify results don’t crash on older devices
* Ensure CI Mode (median aggregation) still works

### 🚀 Submitting a Pull Request

* Fork the repository
* Create a feature branch:
```bash
git checkout -b feature/my-improvement
```
* Commit with a clear message
* Open a Pull Request describing:
    * What you changed
    * Why it matters
    * Any tradeoffs or limitations

### 💬 Feedback & Ideas

Issues and discussions are welcome for:

* New benchmark ideas
* Performance metrics suggestions
* CI integrations
* Visualization improvements

Thanks for helping improve MobileBenchmark! 🙌


## 📄 License

This project is open-source and licensed under the MIT License.

## 🏷️ Acknowledgements

MobileBenchmark draws inspiration from other mobile benchmarking efforts and emphasizes reproducibility and automation in performance tracking.